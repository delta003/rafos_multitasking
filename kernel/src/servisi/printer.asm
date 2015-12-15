; ======================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ======================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Sistem datoteka FAT12 
;
;  Rutina za rad sa stampacem na paralelnom portu
; -----------------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Vanja Petrovic Tankovic RN05/09, 15.01.2011.)
; -----------------------------------------------------------------------------

; -------------------------------------------------
; _print_file
; Ulaz: BX = adresa podataka, CX = broj bajtova
; Izlaz: CF = 1 ako nema mesta u queue
; -------------------------------------------------

%define MAX_QUE 5

_print_file:
		pusha
		inc		byte [QueueBrojac]			; Povecavamo queue brojac
		cmp		byte [QueueBrojac], 6		; Proveravamo da li je pun queue
		je		.NemaMesta		
		cmp		byte [DodajQueue], 5		; Da li je pokazivac na kraju?
		jne		.Dodaj						; Ako jeste
		and		byte [DodajQueue], 0		; stavljamo ga na pocetak reda (kruzni queue)
.Dodaj		
		inc		byte [DodajQueue]		
		mov		dl, byte [DodajQueue]		; Stavljamo temp ime za datoteku za stampanje
		add		dl, '0'
		mov		byte [ImeDatoteke+4], dl
		mov		ax, ImeDatoteke		
		pusha								; Cuvamo registre jer _file_exists menja AX i mozda jos nesto :(
		call	_file_exists				; Brisemo ako datoteka sa takvim imenom postoji
		popa
		jc		.Snimi
		pusha								; cuvamo registre jer ih ni _remove_file ne cuva :(
		call	_remove_file
		popa				
.Snimi
		call	_write_file					; Cuvamo temp datoteku na disku
		mov		cx, 0						; Dodajemo ime datoteke u queue
		mov		si, ImeDatoteke
		mov		di, Queue					; Racunamo poziciju u queue na koju dodajemo
		mov		bl, 9						; Pocetak reda + 9*(DodajQueue-1)
		mov		al, byte [DodajQueue]
		dec		al
		mul		bl
		add		di, ax
.DodajUQueue								; Upisujemo u red
		mov		bl, byte [si]
		mov		byte [di], bl
		inc		si
		inc		di
		inc		cx
		cmp		cx, 9
		jne 	.DodajUQueue
		popa
		clc
		ret
			
.NemaMesta
		dec		byte [QueueBrojac]	
		popa
		stc
		ret
		
; ------------------------------------------------------------------------
; printer (u okviru prekidne rutine) ucitava datoteku iz reda i stampa ga
; ------------------------------------------------------------------------		
printer:
		pushf
		pusha
		push	ds							; Pamtimo trenutni DS da bi ga na kraju spoolera vratili
		push	cs							; Postavljamo DS za spooler tako sto ga vadimo iz CS
		pop 	ds							
;		inc		word [brojacUlaz]			; Ulazimo svakih 100*55ms u red za stampanje
;		cmp		word [brojacUlaz], 100		
;		jne		near .neUlazi
;		and		word [brojacUlaz], 0		
		cmp		byte [inSpooler], 0			; Provera da li smo u spooleru
		jne		near .neUlazi				; Ako jesmo, izlazimo da ne bi poremetili stampanje
		cmp		byte [inBios], 0			; Provera da li smo u BIOSu
		jne		near .neUlazi				; Ako jesmo, ne radimo nista
		cmp		byte [QueueBrojac], 0		; Da li je red prazan?
		je		near .neUlazi
		inc		byte [inSpooler]
		cmp		byte [KrajDat], 1			; Da li smo zavrsili citanje trenutnog?
		je		.Nova						; Ako jesmo, ucitavamo novu datoteku
		and		byte [CitajNovu], 0
		mov		ax, ImeStampa				; U suprotnom u ImeStampa vec imamo ime trenutne
		call	.UcitajDat					
		jmp		.Stampaj
.Nova
		and		byte [KrajDat], 0
		mov		al, 1
		mov		byte [CitajNovu], al
		mov		cx, 0						; Prepisujemo ime sledece datoteke u redu za stampanje 
		mov		si, Queue					; u ImeStampa da bi kasnije ucitali tu datoteku 
		mov		di, ImeStampa				; u radnu memoriju
		mov		bl, 9						; Postavljamo poziciju sa koje pocinjemo da citamo ime
		mov		al, byte [TrenQueue]		; PocetakReda + 9*(TrenQueue-1)
		dec		al
		mul		bl
		add		si, ax
.CitajIzQueue
		mov		bl, byte [si]
		mov		byte [di], bl
		inc		si
		inc		di
		inc		cx
		cmp		cx, 9
		jne 	.CitajIzQueue

		mov		ax, ImeStampa				; Ucitavamo datoteku za stampanje u memoriju
		call	.UcitajDat

.Stampaj		
		mov		cx, bx
		mov		si, PrintBuffer				; Adresu pocetka stavljamo u SI, u CX je velicina
.prn:
		cmp 	cx, 0 						; Provera da li smo na kraju
        jz     .end                         ; Kraj 
        mov     bl, byte [si]				; pr_char stampa karakter u bl, stavljamo ga u bl
        call    .pr_char						
		inc		si							; Menjamo brojace
		dec		cx							
        jmp    .prn     
.end:
		cmp		byte [KrajDat], 1			; Provera da li smo na kraju datoteke?
		jne		.outSpooler					; Ako nismo, samo izlazimo iz spoolera
		mov		bl, 0Ch						; Na kraju stampamo form feed
		call	.pr_char
		mov		ax, ImeStampa				; Brisemo temp datoteku iz memorije	
		call 	_remove_file
		dec		byte [QueueBrojac]			
		cmp		byte [TrenQueue], MAX_QUE	; Da li smo stampali peti u redu?
		jne		.izadji						; Ako nismo, samo povecamo pokazivac u redu
		and		byte [TrenQueue], 0			; U suprotnom pokazivac stavljamo na pocetak reda
.izadji:	
		inc		byte [TrenQueue]
.outSpooler		
		dec		byte [inSpooler]
.neUlazi		
		pop		ds							; Vracamo stari DS
        popa
		popf
        ret          

; -----------------------------------
; pr_char stampa znak u bl
; -----------------------------------
.pr_char:
        push    dx
        push    cx
        mov     dx, 0378h
        mov     al, bl                      ; posalji znak
        out     dx, al	
        inc     dx
 
; Cekaj sve dok ne bude Ready (programirani U/I - upotreba polling-a) 
.wait_r:
        in      al, dx
        and     al, 080h 

; Busy je najtezi bit i invertovan je na interfejsu
        jz      .wait_r	
        inc     dx
        in      al, dx
        or      al, 01h	

; Aktiviraj Strobe (najnizi bit)
        out     dx, al

; Sacekaj malo
        mov     cx, 5000	
.delay:
        loop    .delay		

; Deaktiviraj Strobe
        and     al, 0feh	
        out     dx, al
        pop     cx			
        pop     dx
        ret
		
; ----------------------------------------------------------------
; UcitajDat ucitava sektore datoteke koja se trenutno stampa
;
; Funkcija je slicna funkciji _load_file iz disk.asm
; osim sto ne ucitava celu datoteku odjednom. 
; Funkcija u svakom slucaju pretrazuje direktorijum i cita FAT, 
; ali ako je nova datoteka funkcija ucitava atribute datoteke i 
; samo prvi sektor datoteke, dok za datoteku koja je vec delimicno
; ucitana, cita samo sledeci sektor
; ----------------------------------------------------------------
.UcitajDat:
        call    _string_uppercase
        call    PodesiIme
        mov     [.filename], ax             ; Privremeno cuvamo ime datoteke,
        call    ResetDisk                   ; U slucaju da je disketa zamenjena
        jnc    .ResetOK                     ; Da li je reset bio OK?
        mov     ax, .GreskaReseta           ; Ako nije, nesto nije u redu sa kontrolerom
        jmp     _fatal_error

.ResetOK:                                   ; Spremni smo da citamo prvi blok podataka
        mov     ax, 19                      ; Root direktorijum pocinje od logickog sektora 19
        call    CHS12
        mov     si, DiskBafer               ; ES:BX moraju da pokazuju na nas bafer
        mov     bx, si
        mov     ah, 2                       ; Parametri za INT 13h: citaj sektore
        mov     al, 14                      ; i to njih 14 (root direktorijum)
        pusha                               

.CitajDir:
        popa                                ; Resetujemo na pocetne vrednosti registara
        pusha
        stc                               
        int     13h              
        jnc    .PretraziDir    
        call    ResetDisk                   ; Problem. Resetuj kontroler i probaj ponovo.
        jnc    .CitajDir
        popa
        jmp    .RootProblem                 ; Dvostruka greska. Kontroler nije u redu.

.PretraziDir:
        popa
        mov     cx, word 224                ; Pretrazujemo sve stavke u root dirirektorijumu
        mov     bx, -32                     ; Ovo je inicijalno zbog sledece naredbe (pocinjemo od ofseta 0)

.SledecaStavka:
        add     bx, 32                      ; Idemo na sledecu stavku
        mov     di, DiskBafer               ; Pointer na sledecu stavku
        add     di, bx
        mov     al, [di]                    ; Prvi znak u imenu datoteke 
        cmp     al, 0                       ; Da li je provereno ime poslednje datoteke?
        je     .RootProblem
        cmp     al, 0E5h                    ; Da li je datoteka obrisana?
        je     .SledecaStavka               
        mov     al, [di+11]                 ; Bajt sa atributima
        cmp     al, 0Fh                     ; Windows marker?
        je     .SledecaStavka
        test    al, 10h                     ; Da li je u pitanju direktorijum?
        jnz    .SledecaStavka
        test    al, 08h                     ; Naziv volumena ?
        jnz    .SledecaStavka          
        mov byte [di+11], 0                 ; Zavrsna nula u imenu datoteke
        mov     ax, di                      ; Konvetujemo sva slova u velika slova
        call    _string_uppercase
        mov     si, [.filename]             ; DS:SI = mesto gde se vrsi ucitavanje
        call    _string_compare             ; Da li odgovara nekoj od postojecih stavki?
        jc     .NasaoDatoteku
        loop   .SledecaStavka

.RootProblem:
        mov     bx, 0                       ; Ukoliko datoteka ne postoji, ili je greska
        stc                                 ; u disk kontroleru, vrati velicinu datoteke = 0 i CF=1
        ret

.NasaoDatoteku: 
		cmp		byte [CitajNovu], 1			; Da li citamo novu datoteku?
		jne		.NeCitajPodatke				; Ako nije nova, ne citamo podatke o datoteci
        mov     ax, [di+28]                 ; Sacuvacemo velicimu datoteke
        mov word [.Velicina], ax
        cmp     ax, 0                       ; Ukoliko je velicina datoteke nula, 
        je 		near .Kraj                  ; nema potrebe ucitavati vise klastera
        mov     ax, [di+26]                 ; Ucitavamo klaster u memoriju
        mov word [.klaster], ax
.NeCitajPodatke:		
        mov     ax, 1                       ; Sektor 1 = prvi sektor prve FAT
        call    CHS12
        mov     di, DiskBafer               ; ES:BX pokazuju na nas bafer
        mov bx, di
        mov     ah, 2                       ; Parametri za INT 13h: citaj sektore
        mov     al, 9                       ; i to 9 sektora
        pusha

.CitajFAT:
        popa                                ; Za slucaj da INT 13h menja registre
        pusha
        stc
        int     13h
        jnc    .ProcitaoFAT
        call    ResetDisk
        jnc    .CitajFAT
        popa
        jmp    .RootProblem

.ProcitaoFAT:
        popa

.CitajSektor:
        mov     ax, word [.klaster]  
        add     ax, 31
        call    CHS12                       ; Konverzija u geometrijske parametre
        mov     bx, PrintBuffer
        mov     ah, 02                      ; AH = citaj sektore, AL = citaj jedan
        mov     al, 01
        stc
        int     13h
        jnc    .SledeciKlaster              ; Ukoliko nema greske ...
        call    ResetDisk                   ; U suprotnom, resetujemo disk i pokusavamo ponovo
        jnc    .CitajSektor
        mov     ax, .GreskaReseta            ; Reset neuspesan: fatalna greska
        jmp     _fatal_error

.SledeciKlaster:
        mov     ax, [.klaster]
        mov     bx, 3
        mul     bx
        mov     bx, 2
        div     bx                          ; DX = 'klaster' mod 2
        mov     si, DiskBafer               ; AX = rec u FAT koja sadri 12-bitnu stavku
        add     si, ax
        mov     ax, word [ds:si]
        or      dx, dx                      ; Ako je DX = 0, klaster je parni, ako je DX = 1 klaster je neparni
        jz     .Parni                       ; Ako je parni, odbacujemo gornja 4 bita
.Neparni:
        shr     ax, 4                       ; Ako je neparni, siftujemo udesno za 4 mesta
        jmp    .Nastavi                   
.Parni:
        and     ax, 0FFFh                   ; U svakom slucaju, gornja 4 bita nam ne tebaju

.Nastavi:
        mov word [.klaster], ax             ; Sacuvamo klaster
        cmp     ax, 0FF8h
        jae    .Kraj								
		mov		bx, 512						; Ako nije kraj datoteke, velicina sektora za stampanje je 512
		sub		word [.Velicina], 512			
        clc
		ret

.Kraj:										; Kraj datoteke
		mov		bx, [.Velicina]				; Sektor je manje velicine od 512, velicina je ostatak 
		inc		byte [KrajDat]
		clc
		ret

    .klaster        dw 0                    ; Tekuci klaster datoteke koju ucitavamo
    .filename       dw 0                    ; Ime datoteke koju ucitavamo
    .Velicina       dw 0                    ; Velicina datoteke
    .GreskaReseta    db 'Disketna jedinica ne moze da se resetuje', 0		
			
; ----------------------------------------------------------
	QueueBrojac 	db 0 					; brojac koliko ih ima u redu
	DodajQueue		db 0					; pokazivac na mesto u redu na koje dodajemo sledecu datoteku
	Queue			times 46 db 0			
	TrenQueue		db 1					; trenutna datoteka u redu koju sledecu ispisujemo
	ImeDatoteke		db 'temp .prt', 0
	ImeStampa		times 10 db 0			; ime trenutnog koji se stampa
	PrintBuffer		times 520 db 0
	brojacUlaz		dw 0					; brojac za ulaz u red za stampanje
	KrajDat			db 1					; Flag koji oznacava da li smo ucitali celu datoteku
	CitajNovu		db 1					; Flag koji oznacava da li pri citanju citamo novu datoteku
	inSpooler		db 0					; Flag koji oznacava da mi smo u spooleru
; ----------------------------------------------------------