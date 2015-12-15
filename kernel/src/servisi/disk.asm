; ======================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ======================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Sistem datoteka FAT12 
;
; Rutine za rad sa flopi diskom
; -----------------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
;
; Verzija 0.0.2 - Dodata je mogucnost upisivanja vremenskog pecata i datuma
; prilikom upisivanja u datoteke koje pripadaju root direktorijumu (16.01.2011).
; Milan Tomic, RN02/09.
;
; Verzija 0.0.3 - Dodata je mogucnost formatiranog ispisivanja informacija
; o datotekama (16.01.2011). Robert Zuljevic, RN03/09.
;
; Verzija 0.0.4 - Dodate funkcije za realizaciju interne komande ATTRIB
; (16.01.2011). Darko Drdareski, 24/09.
; 
; Verzija 0.1.0 - Dodate disk operacije za realizaciju MD, RD, CD, PATH, 
; kao i za zamenu tekucih disk jedinica A i B (27.11.2011.). 
; Dejan Maksimovic, RN03/10.
;
; Napomena: Zbog kraceg naziva, umesto 'poddirektorijum', koristice se
;           termin 'folder'
; -----------------------------------------------------------------------------

; ----------------------------------------------------------------------
; _get_dir -- Generise listu imena datoteka iz direktorijumskih stavki
; Ulaz: BX = Bafer gde se smesta string sa listom datoteka
; ----------------------------------------------------------------------

%define     RAZMAK 20                       ; Broj praznih mesta odakle pocinje formatirano ispisivanje
%define     DATE_DELIMIT '/'                ; Oznaka za delimiter datuma

_get_dir:
        pusha
        call    UcitajCurrentFolder         ; Ucitavamo potreban broj stavki u bafer
        mov     si, DiskBafer
        mov     di, bx
        
.PocetakStavke:
        mov     al, [si+11]                 ; Provera atributa
        cmp     al, 0Fh                     ; Marker za 255 UTF-16 znakova u imenu?
        je near .Preskoci                    
        test    al, 02h                     ; Hidden attribute?  
        jnz near .Preskoci  
        test    al, 10h                     ; Direktorijumska stavka?
        jnz near .SrediDir
		mov	byte [fajl], 1
        
.Nastavak:
        test    al, 08h                     ; Naziv volumena ?
        jnz near .Preskoci                                    
        mov     al, [si]
        cmp     al, 0E5h                    ; Obrisana stavka?
        je near .Preskoci
        cmp     al, 0                       ; Prvi bajt = 0. Stavka nikada nije koriscena.
        je near .Kraj
        mov     cx, 1                       ; Brojac znakova
        mov     dx, si                      ; Cuvamo pocetak stavke

.TestirajStavku:
        inc     si
        mov     al, [si]                    ; Ispitujemo neupotrebljive znakove
        cmp     al, ' '                     ; Windows nekada stavlja 0 (UTF-8) ili 0FFh
        jl near .SledecaStavka              ; Preskoci ako je ASCII kod manji od 32
        cmp     al, '~'
        ja near .SledecaStavka              ; Preskoci ako je ASCII kod veci od 126
        inc     cx
        cmp     cx, 11                      ; Zavrsili smo sa 11 znakova za ime datoteke?
        je     .ImeDatoteke
        jmp    .TestirajStavku

.ImeDatoteke:                               
        mov     si, dx                      ; Vracamo pointer na ime datoteke     
        mov     cx, 0
        push    bx
        mov     bx, RAZMAK
        
.Ponavljaj:
        mov byte al, [si]
        cmp     al, ' '                    
        je     .PreskociPrazno
        mov byte [di], al
        dec     bx
        inc     si
        inc     di
        inc     cx
        cmp     cx, 8                       
        je     .DodajTacku
        cmp     cx, 11
        je near .Zavrseno
        jmp    .Ponavljaj

.PreskociPrazno:
        inc     si                          ; Preskacemo prazna mesta u imenu u FAT12
        inc     cx
        cmp     cx, 8
        je     .DodajTacku
        cmp     cx, 11                      ; Za slucaj da se prazna mesta nalaze i u ekstenziji, npr. PROG.C
        je near .Zavrseno
        jmp    .Ponavljaj

.DodajTacku:
		push 	ax
		mov 	ax, [fajl]
		test 	ax, 1
		pop		ax
		jz		.DirRazmak
        mov byte [di], '.'                  ; Posle 8 znakova (sa praznim mestima), dodajemo tacku
        inc     di
        jmp    .Ponavljaj
       
.DirRazmak:
		cmp     bx, 7					    ; Dodajemo prazna  mesta u string, onoliko puta koliko je
        je      .DodajDir                   ; znakova ostalo do 6 mesta kako bi ispis posle imena
		mov byte [di], ' '                  ; datoteke bio poravnan
		inc     di
		dec     bx
		jmp     .DirRazmak
        
 .DodajDir       
		mov byte [di], ' '                   
        inc     di
        dec     bx
		mov byte [di], '<'                   
        inc     di
        dec     bx
		mov byte [di], 'D'                   
        inc     di
        dec     bx
		mov byte [di], 'I'                   
        inc     di
        dec     bx
		mov byte [di], 'R'                   
        inc     di
        dec     bx
		mov byte [di], '>'                   
        inc     di
   
.Zavrseno:    
.DodajRazmak:
		cmp     bx, 0                       ; Dodajemo prazna  mesta u string, onoliko puta koliko je
        je      .DodajSat                   ; znakova ostalo do RAZMAK mesta kako bi ispis posle imena
		mov byte [di], ' '                  ; datoteke bio poravnan
		inc     di
		dec     bx
		jmp     .DodajRazmak
		
.DodajSat:
        pop     bx
		mov     cx, 1                       ; CX koristimo kao pokazivac za trenutnu operaciju
		mov     si, dx                      ; (sat, minut,...)
		add     si, 22
		xor     ax, ax
		mov     ax, [si]
		shr     ax, 11
		cmp     ax, 9
		jg      .PreskociSat                ; Ukoliko je manji od 10, dodajemo 0 na pocetak kako bi
		mov byte [di], '0'                  ; vreme bilo lepo formatirano		
		inc     di
        
.PreskociSat:
		call    _int_to_string              ; Pretvaramo dobijeni broj u string	
		push    bx
		push    ax
		mov     bx, ax
		jmp     .DodajNaString              ; Dodajemo sat poslednje promene
		
.DodajMinut:
		mov byte [di], ':'                  ; Dodajemo ':' stringu
		inc     di
 		mov     si, dx                      ; Uzimamo minut poslednje promene iz FAT tabele
		add     si, 22
		mov     cx, 2
		xor     ax, ax
		mov     ax, [si]
		shl     ax, 5                       ; Potrebni podaci su sacuvani u 2 bajta tako da moramo da
		shr     ax, 10                      ; dodjemo do njih siftovanjem
		cmp     ax, 9
		jg      .PreskociMinut              ; Ukoliko je manji od 10 dodajemo 0	na pocetak, kako bi
		mov byte [di], '0'                  ; vreme bilo lepo formatirano
		inc     di
        
.PreskociMinut:	
		call    _int_to_string              ; Pretvaramo dobijeni broj u string
		push    bx
		push    ax
		mov     bx, ax
		jmp     .DodajNaString              ; Dodajemo minut poslednje promene
		
.DodajSekund:
		mov byte [di], ':'                  ; Dodajemo ':' stringu
		inc     di
		mov     si, dx								 
		add     si, 22                      ; Uzimamo sekunde poslednje promene iz FAT tabele 
		mov     cx, 3
		xor     ax, ax
		mov     ax, [si]
		shl     ax, 11
		shr     ax, 11
		add     ax, ax
		cmp     ax, 9
		jg      .PreskociSekund             ; Ukoliko je manje od 10 dodajemo 0	na pocetak, kako bi
		mov byte [di], '0'                  ; vreme bilo lepo formatirano
		inc     di
        
.PreskociSekund:
		call    _int_to_string              ; Pretvaramo dobijeni broj u string
		push    bx
		push    ax
		mov     bx, ax
		jmp     .DodajNaString              ; Dodajemo sekunde poslednje promene
		
.DodajDan:
		mov byte [di], ' '                  ; Dodajemo dva prazna mesta radi razdvajanja vremena i datuma
		inc     di                          ; poslednje promene
		mov byte [di], ' '
		inc     di
		mov     cx, 4
		mov     si, dx 
		add     si, 24                      ; Uzimamo dan poslednje promene iz FAT tabele 
		xor     ax, ax
		mov     ax, [si]
		shl     ax, 11
		shr     ax, 11
		cmp     ax, 9
		jg      .PreskociDan                ; Ukoliko je manji od 10 dodajemo 0	na pocetak, kako bi
		mov byte [di], '0'                  ; datum bio lepo formatiran
		inc     di
        
.PreskociDan:
		call    _int_to_string              ; Pretvaramo dobijeni broj u string			
		push    bx
		push    ax
		mov     bx, ax
		jmp     .DodajNaString              ; Dodajemo dan poslednje promene

.DodajMesec:
		mov byte [di], DATE_DELIMIT         ; Dodajemo DATE_DELIMIT stringu
		inc     di
		mov     si, dx 
		add     si, 24                      ; Uzimamo mesec poslednje promene iz FAT tabele
		mov     cx, 5
		xor     ax, ax
		mov     ax, [si]
		shl     ax, 7
		shr     ax, 12
		cmp     ax, 9
		jg      .PreskociMesec              ; Ukoliko je manji od 10 dodajemo 0	na pocetak, kako bi
		mov byte [di], '0'                  ; datum bio lepo formatiran
		inc     di
        
.PreskociMesec:
		call    _int_to_string              ; Pretvaramo dobijeni broj u string
		push    bx
		push    ax
		mov     bx, ax
		jmp     .DodajNaString              ; Dodajemo mesec poslednje promene

.DodajGodina:
		mov byte [di], DATE_DELIMIT         ; Dodajemo DATE_DELIMIT stringu
		inc     di
		mov     si, dx 
		add     si, 24                      ; Uzimamo godinu poslednje promene iz FAT tabele
		mov     cx, 6
		xor     ax, ax
		mov     ax, [si]
		shr     ax, 9
		add     ax, 1980                    ; Dodajemo 1980 na vrednost godine, jer od tada pocinje
		call    _int_to_string              ; racunanje i pretvaramo u string
		
		push    bx
		push    ax
		mov     bx, ax
		jmp     .DodajNaString              ; Dodajemo godinu poslednje promene		
		
.DodajNaString:
        cmp     byte [bx], 0                ; Da li se na lokaciji na koju pokazuje 
        je      .Nastavi                    ; pointer nalazi nula (kraj stringa)?
		mov byte al, [bx]
		mov byte [di], al
		inc     di
        inc     bx                          ; i pomeri pointer na sledeci bajt.
        jmp     .DodajNaString
		
.Nastavi
		pop     bx                          ; Kada smo dodali vrednost stringu, potrebno je da dodamo
		pop     ax                          ; ostatak vremena i datuma u string
		cmp     cx, 1
		je      .DodajMinut
		cmp     cx, 2
		je      .DodajSekund
		cmp     cx, 3
		je      .DodajDan
		cmp     cx, 4
		je      .DodajMesec
		cmp     cx, 5
		je      .DodajGodina
		mov byte [di], ' '                  ; Dodajemo dva prazna mesta radi razdvajanja
		inc     di
		mov byte [di], ' '
		inc     di

.DodajVelicina
		mov     si, dx 
		add     si, 30                      ; Uzimamo vrednost velicine iz FAT tabele posto je ona
		push    dx                          ; big-endian prvo pocetak, a zatim i kraj, kako bi bio
		push    bx                          ; u pravom rasporedu
		push    ax
		xor     dx, dx
		mov     dx, [si]
		sub     si, 2
		xor     ax, ax
		mov     ax, [si]
		mov     bx, 10
		call    _long_int_to_string         ; Konvertujemo u string
        
.ProveraKraja
        cmp byte [di], 0                    ; i dodajemo ispisu
        je      .NastaviVelicina                  
		inc     di
        jmp     .ProveraKraja
		
.NastaviVelicina

		pop     dx                          ; Na kraju dodajemo " bytes"        
		pop     bx                          
		pop     ax                          ; FIX_ME. Treba da ispisuje: (S.M.)
		sub     si, 28                      ;         bajtova,  ako je zadnja cifra 0 ili veca od 4                   
		mov     dx, si                      ;         bajt      ako je zadnja cifra 1
		mov byte [di], ' '                  ;         bajta     ako je zadnja cifra 2, 3 ili 4
        inc     di
		mov byte [di], 'b'
        inc     di
		mov byte [di], 'y'
        inc     di
		mov byte [di], 't'
        inc     di
		mov byte [di], 'e'
        inc     di
		mov byte [di], 's'
        inc     di      
        mov byte [di], 13                   ; Novi red
        inc     di
        mov byte [di], 10
        inc     di
  
.SledecaStavka:
        mov     si, dx                      ; Vracamo se na pocetak direktorijumske stavke
		jmp     .Preskoci
.SrediDir:
		mov	byte [fajl], 0
		jmp     .Nastavak
.Preskoci:
        add     si, 32                      ; Pomeramo pointer na pocetak sledece stavke (32 bajta unapred)
        jmp    .PocetakStavke
.Kraj:
        mov byte [di], 0
        popa
        ret

	fajl db 0

 
;-------------------------------------------------------------
; _change_attrib -- Izmena attributa datoteke
; Atributi se setuju komandom +R/S/H aresetuju komandom -R/S/H
; npr. attrib primer1.bas +r postavlja Read Only atribut
;-------------------------------------------------------------

_change_attrib:
        call    _string_uppercase
        call    PodesiIme
        call    UcitajCurrentFolder   
        mov     di, DiskBafer               ; DI pokazuje na tekuci direktorijum								
        call    NadjiDirStavku              ; Nalazimo stavku. DI sadrzi adresu nadjene stavke
        push    di
		
        mov     al, '+'                     ; Da li je setovanje ili resetovanje atributa?
        mov     si, cx
        call    _find_char_in_string
        cmp     ax, 0
        je      .ProveraSlova
        mov byte [plus_flag], 1             ; Nadjen plus u trecem argumentu,sto znaci da je setovanje atributa
		
.ProveraSlova:
        pop     di
        mov     al, 'R'
        call    _find_char_in_string
        cmp     ax, 0
        jne     .R_Label
		
        mov     al, 'S'
        call    _find_char_in_string
        cmp     ax, 0
        jne     .S_Label
		
        mov     al, 'H'
        call    _find_char_in_string
        cmp     ax, 0
        jne     .H_Label

        mov     al, 'A'
        call    _find_char_in_string
        cmp     ax, 0
        jne     .A_Label
        jmp     .Kraj

.R_Label:
        mov     al, byte [di+11]		
        cmp byte [plus_flag], 01h
        jne     .MinusR
        or      al, 01h
        mov byte [di+11], al
        jmp     .Kraj
.MinusR:
        and     al,0FEh
        mov byte [di+11],al
        jmp     .Kraj
		
.S_Label:
        mov     al, [di+11]
        cmp byte [plus_flag], 01h
        jne     .MinusS
        or      al, 04h
        mov byte [di+11], al
        jmp     .Kraj
.MinusS:
        and     al, 0FBh
        mov byte[di+11], al
        jmp     .Kraj
		
.H_Label:
        mov     al,[di+11]
        cmp byte [plus_flag], 01h
        jne     .MinusH
        or      al, 02h
        mov byte [di+11], al
        jmp     .Kraj
.MinusH:
        and     al, 0FDh
        mov byte [di+11], al
        jmp     .Kraj

.A_Label:
        mov     al,[di+11]
        cmp byte [plus_flag], 01h
        jne     .MinusA
        or      al, 20h
        mov byte [di+11], al
        jmp     .Kraj
.MinusA:
        and     al, 0DFh
        mov byte [di+11], al

.Kraj:
        call    UpisiCurrentFolder
        mov byte [plus_flag], 0
        clc    
        ret

.Greska: 
        stc
        ret
        
; ----------------------------------------------------------------
; _load_file -- Ucitava datoteku u operativnu memoriju
; Ulaz: AX = ime datoteke, CX = adresa odakle pocinje ucitavanje
; Izlaz: BX = velicina datoteke (u bajtovima), CF=1 ako ne postoji
; ----------------------------------------------------------------

_load_file:
        call    _string_uppercase
        call    PodesiIme
        mov     [.filename], ax             ; Privremeno cuvamo ime datoteke,
        mov     [.adresa], cx               ; kao i lokaciju gde ce se ucitat.i
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
        mov     ax, [di+28]                 ; Sacuvacemo velicimu datoteke
        mov word [.Velicina], ax
        cmp     ax, 0                       ; Ukoliko je velicina datoteke nula, 
        je     .Kraj                        ; nema potrebe ucitavati vise klastera
        mov     ax, [di+26]                 ; Ucitavamo klaster u memoriju
        mov word [.klaster], ax
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
        mov     bx, [.adresa]
        mov     ah, 02                      ; AH = citaj sektore, AL = citaj jedan
        mov     al, 01
        stc
        int     13h
        jnc    .SledeciKlaster              ; Ukoliko nema greske ...
        call    ResetDisk                   ; U suprotnom, resetujemo disk i pokusavamo ponovo
        jnc    .CitajSektor
        mov     ax, .GreskaReseta           ; Reset neuspesan: fatalna greska
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
        add word [.adresa], 512
        jmp    .CitajSektor                 ; Idemo na sledeci sektor

.Kraj:
        mov     bx, [.Velicina]             ; Velicinu datoteke vracamo preko BX
        clc                                 ; CF=0, uspesno ucitavanje
        ret


    .klaster        dw 0                    ; Tekuci klaster datoteke koju ucitavamo
    .filename       dw 0                    ; Ime datoteke koju ucitavamo
    .adresa         dw 0                    ; Adresa od koje se vrsi ucitavanje
    .Velicina       dw 0                    ; Velicina datoteke
    .GreskaReseta   db 'Disketna jedinica ne moze da se resetuje', 0


; ----------------------------------------------------------------
; _load_file_current_folder -- Ucitava datoteku iz CurrentFoldera 
; u operativnu memoriju
; Ulaz: AX = ime datoteke, CX = adresa odakle pocinje ucitavanje
; Izlaz: BX = velicina datoteke (u bajtovima), CF=1 ako ne postoji
; ----------------------------------------------------------------

_load_file_current_folder:
        call    _string_uppercase
        call    PodesiIme
        mov     [.filename], ax             ; Privremeno cuvamo ime datoteke,
        mov     [.adresa], cx               ; kao i lokaciju gde ce se ucitati
        call    ResetDisk                   ; U slucaju da je disketa zamenjena
        jnc    .ResetOK                     ; Da li je reset bio OK?
        mov     ax, .GreskaReseta           ; Ako nije, nesto nije u redu sa kontrolerom
        jmp     _fatal_error

.ResetOK:                                   ; Spremni smo da citamo trenutni folder u bafer
        call	UcitajCurrentFolder
		cmp word [CurrentFolder], 0
		jne		.NijeRoot
		
.PretraziDir:
        mov     cx, word 224                ; Pretrazujemo sve stavke u root dirirektorijumu
        mov     bx, -32                     ; Ovo je inicijalno zbog sledece naredbe (pocinjemo od ofseta 0)
		jmp		.SledecaStavka
.NijeRoot:
		mov		cx, word 16
		mov		bx, -32
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
        mov     ax, [di+28]                 ; Sacuvacemo velicimu datoteke
        mov word [.Velicina], ax
        cmp     ax, 0                       ; Ukoliko je velicina datoteke nula, 
        je     .Kraj                        ; nema potrebe ucitavati vise klastera
        mov     ax, [di+26]                 ; Ucitavamo klaster u memoriju
        mov word [.klaster], ax
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
        mov     bx, [.adresa]
        mov     ah, 02                      ; AH = citaj sektore, AL = citaj jedan
        mov     al, 01
        stc
        int     13h
        jnc    .SledeciKlaster              ; Ukoliko nema greske ...
        call    ResetDisk                   ; U suprotnom, resetujemo disk i pokusavamo ponovo
        jnc    .CitajSektor
        mov     ax, .GreskaReseta           ; Reset neuspesan: fatalna greska
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
        add word [.adresa], 512
        jmp    .CitajSektor                 ; Idemo na sledeci sektor

.Kraj:
        mov     bx, [.Velicina]             ; Velicinu datoteke vracamo preko BX
        clc                                 ; CF=0, uspesno ucitavanje
        ret


    .klaster        dw 0                    ; Tekuci klaster datoteke koju ucitavamo
    .filename       dw 0                    ; Ime datoteke koju ucitavamo
    .adresa         dw 0                    ; Adresa od koje se vrsi ucitavanje
    .Velicina       dw 0                    ; Velicina datoteke
    .GreskaReseta   db 'Disketna jedinica ne moze da se resetuje', 0
    
    
; -----------------------------------------------------------------
; _write_file -- Snima datoteku (maksimalne velicine 64K) na disk
; Ulaz: AX = ime datoteke, BX = adresa podataka, CX = broj bajtova
; Izlaz: Ukoliko ima geske, CF = 1. 
; -----------------------------------------------------------------

_write_file:
        pusha
        mov     si, ax
        call    _string_length
        cmp     ax, 0
        je near .Greska
        mov     ax, si
        call    _string_uppercase
        call    PodesiIme                   ; Podesiti pozicije znakova u imenu datoteke
        jc near .Greska
        mov word [.velicina], cx
        mov word [.podaci], bx
        mov word [.filename], ax
        call    _file_exists                ; Da li datoteka postoji?
        jnc near .Greska

; Prvo anuliramo sve slobodne klastere (sve clanove liste .SlobodniKlasteri)
        pusha
        mov     di, .SlobodniKlasteri
        mov     cx, 127
        
.AnulirajSlobodne:
        mov     byte [di], 0
        inc     di
        loop   .AnulirajSlobodne
        popa

; Sledece, racunamo koliko nam je potrebno 512-bajtnih klastera
        mov     ax, cx
        mov     dx, 0
        mov     bx, 512                     ; Delimo broj bajtova sa 512 da dobijemo broj potrebnih klastera
        div     bx
        cmp     dx, 0
        jg     .JosJedan                    ; Ako ima ostatka, dodati jos jedan klaster
        jmp    .Nastavi
.JosJedan:
        add     ax, 1
.Nastavi:
        mov word [.PotrebnoKlastera], ax
        mov word ax, [.filename]            ; Vracamo ime datoteke
        call    _create_file                ; Kreiramo praznu direktorijumsku stavku za ovu datoteku
        jc near .Greska                     ; Greska ukoliko ne mozemo da upisujemo na medijum
        mov word bx, [.velicina]
        cmp     bx, 0                       ; Ukoliko je datoteka nova (prazna), zavrsavamo
        je near .Zavrseno
        call    UcitajFAT                   ; Ucitavamo FAT u memoriju
        mov     si, DiskBafer + 3           ; Preskacemo prva dva klastra 
        mov     bx, 2                       ; Pocetni redni broj klastera
        mov word cx, [.PotrebnoKlastera]
        mov     dx, 0                       ; Ofset u listi slobodnih klastera

.NadjiSlobodni:
        lodsw                               ; Ucitavamo rec od koje nam treba samo 12 bitova
        and     ax, 0FFFh                   ; Maska za parne klastere 
        jz     .NasaoParni                  ; Slobodan klaster?

.JosNeparnih:
        inc     bx	
        dec     si                          ; LODSW naredba je ucitala dva bajta. Nama treba jedan.
        lodsw                               ; Ucitati sledeu rec
        shr     ax, 4                       ; Izvajamo deo kod neparnog klastera
        or      ax, ax                      ; Da li je slobodan?
        jz     .NasaoNeparni

.JosParnih:
        inc     bx                          ; Ako nije, trazimo dalje
        jmp    .NadjiSlobodni

.NasaoParni:
        push    si
        mov     si, .SlobodniKlasteri       ; Sacuvamo klaster
        add     si, dx
        mov word [si], bx
        pop     si
        dec     cx                          ; Obezbedili smo potreban broj klastera?
        cmp     cx, 0
        je     .ZavrsenaLista
        inc     dx                          ; Sledeca rec u listi
        inc     dx
        jmp    .JosNeparnih

.NasaoNeparni:
        push    si
        mov     si, .SlobodniKlasteri       ; Sacuvati klaster
        add     si, dx
        mov word [si], bx
        pop     si
        dec     cx
        cmp     cx, 0
        je     .ZavrsenaLista
        inc     dx                          ; Sledeca rec u listi
        inc     dx
        jmp    .JosParnih

; Tabela .SlobodniKlasteri sadrzi niz brojeva (reci) koje odgovaraju slobodnim klasterima na disku
; Sada pravimo lanac klastera u FAT za nasu datoteku      
        
.ZavrsenaLista:
        mov     cx, 0                       ; Ofset u tabeli slobodnih klastera
        mov word [.BrojacKlastera], 1       ; Brojac klastera

.Ulancavanje:
        mov word ax, [.BrojacKlastera]      ; Da li je ovo poslednji potrebni klaster?
        cmp word ax, [.PotrebnoKlastera]
        je     .PoslednjiKlaster
        mov     di, .SlobodniKlasteri
        add     di, cx
        mov word bx, [di]                   ; Uzmi klaster iz tabele
        mov     ax, bx                      ; Da li je ovo neparni ili parni klaster?
        mov     dx, 0
        mov     bx, 3
        mul     bx
        mov     bx, 2
        div     bx                          ; DX = 'klaster' mod 2
        mov     si, DiskBafer
        add     si, ax                      ; AX = rec u FAT za 12-bitnu stavku
        mov     ax, word [ds:si]
        or      dx, dx                      ; Ako je DX = 0, klaster je parni. Za DX = 1 je neparni.
        jz     .Parni

.Neparni:
        and     ax, 000Fh                   ; Anuliramo bitove koje cemo da koristimo
        mov     di, .SlobodniKlasteri
        add     di, cx                      ; Ofset u tabeli .SlobodniKlasteri
        mov word bx, [di+2]                 ; Broj sledeceg klastera
        shl     bx, 4                       ; Konvertujemo u odgovarajuci format FAT12
        add     ax, bx
        mov word [ds:si], ax                ; Cuvamo dobijenu vrednost u kopiji FAT-a u memoriji
        inc word [.BrojacKlastera]
        inc     cx                          ; Sledeca rec u tabeli .SlobodniKlasteri
        inc     cx
        jmp    .Ulancavanje

.Parni:
        and     ax, 0F000h                  ; Anuliramo bitove koje cemo da koristimo
        mov     di, .SlobodniKlasteri
        add     di, cx                      ; Ofset u tabeli .SlobodniKlasteri
        mov     word bx, [di+2]             ; Broj sledeceg klastera
        add     ax, bx
        mov word [ds:si], ax                ; Cuvamo dobijenu vrednost u kopiji FAT-a u memoriji
        inc word [.BrojacKlastera]
        inc     cx                          ; Sledeca rec u tabeli .SlobodniKlasteri
        inc     cx
        jmp    .Ulancavanje

.PoslednjiKlaster:                          ; Provera parnosti poslednjeg klastera
        mov     di, .SlobodniKlasteri
        add     di, cx
        mov word bx, [di]		
        mov     ax, bx
        mov     dx, 0
        mov     bx, 3
        mul     bx
        mov     bx, 2
        div     bx
        mov     si, DiskBafer
        add     si, ax
        mov     ax, word [ds:si]
        or      dx, dx
        jz     .PoslednjiParni

.PoslednjiNeparni:
        and     ax, 000Fh                   ; Klaster sadrzi EOC
        add     ax, 0FF80h
        jmp    .SnimiFAT

.PoslednjiParni:
        and     ax, 0F000h                  ; Isto kao predthodni, samo za parni klaster
        add     ax, 0FF8h

.SnimiFAT:
        mov word [ds:si], ax
        call    UpisiFAT                    ; Snimamo FAT iz memorije na disk

; Sada cemo snimiti sektore nase datoteke na disk
        mov     cx, 0

.SnimiSektore:
        mov     di, .SlobodniKlasteri
        add     di, cx
        mov     word ax, [di]
        cmp     ax, 0
        je near .SnimiDirStavku
        pusha
        add     ax, 31
        call    CHS12
        mov word bx, [.podaci]
        mov     ah, 3
        mov     al, 1
        stc
        int     13h
        popa
        add word [.podaci], 512
        inc     cx
        inc     cx
        jmp    .SnimiSektore

; Vracamo se na root direktorijum, pronalazimo nasu stavku
; i upisujemo nove vrednosti pocetnog klastera, velicinu datoteke
; kao i vremski/datumski pecat        
        
.SnimiDirStavku:
        call    UcitajRootDir
        mov word ax, [.filename]
        call    NadjiDirStavku
        mov word ax, [.SlobodniKlasteri]    ; Prvi klaster
		call    SetFileTimeStamp            ; Funkcija za setovanje trenutnog vremena
		call    SetFileDateStamp            ; Funkcija za setovanje trenutnog datuma
		mov word cx, [FileTimeStamp]        ; Trenutno vreme stavljamo u CX
		mov	byte [di+22], cl                ; Vreme poslednjeg upisa
		mov byte [di+23], ch
		mov word cx, [FileDateStamp]        ; Trenutni datum stavljamo u CX
		mov byte [di+24], cl                ; Datum poslednjeg upisa
		mov byte [di+25], ch
        mov word [di+26], ax                ; Broj prvog klastera ide u drektorijumsku stavku
        mov word cx, [.velicina]
        mov word [di+28], cx
        mov byte [di+30], 0                 ; Velicina datoteke
        mov byte [di+31], 0    
        call    UpisiRootDir

.Zavrseno:
        popa
        clc
        ret

.Greska:
  ;     mov     si, Greska_pisanja
  ;	    call    _print_string
        popa
        stc                                 ; Greska u pisanju
        ret

    .velicina         dw 0
    .klaster          dw 0
    .BrojacKlastera   dw 0
    .podaci           dw 0
    .PotrebnoKlastera dw 0
    .filename         dw 0
    
	.atributi					dw 0
    .SlobodniKlasteri times 128 dw 0

; -------------------------------------------------------------------
; _file_exists -- Poveriti da li postoji datoteka sa zadatim imenom
; Ulaz: AX = ime datoteke; Izlaz: CF=0, ako postoji
; -------------------------------------------------------------------

_file_exists:

        call    _string_uppercase
        call    PodesiIme	
        push    ax
        call    _string_length
        cmp     ax, 0
        je     .Greska
        pop     ax
        push    ax
        call    UcitajRootDir
        pop     ax				
        mov     di, DiskBafer
        call    NadjiDirStavku	
        ret
.Greska:
        pop     ax
        stc                                 ; CF=1 ako je greska (ali i ako ne postoji - moze da pravi problem)
        ret
		
; -------------------------------------------------------------------
; _folder_exists -- Poveriti da li postoji folder sa zadatim imenom
; Ulaz: AX = ime foldera; Izlaz: CF=0, ako postoji
; -------------------------------------------------------------------

_folder_exists:
        call    _string_uppercase	
        push    ax
        call    _string_length
        cmp     ax, 0
        je     .Greska
        pop     ax
        push    ax
        call    UcitajCurrentFolder
        pop     ax				
        mov     di, DiskBafer
        call    NadjiUCurrentFolderu
        ret
.Greska:
        pop     ax
        stc                                 ; CF=1 ako je greska (ali i ako ne postoji - moze da pravi problem)
        ret

; ------------------------------------------------------------------
; _create_file -- Kreira novu praznu datoteku
; Ulaz: AX = ime datoteke; Izlaz: CF=1 ako je greska
; ------------------------------------------------------------------

_create_file:
        clc
        call    _string_uppercase
        call    PodesiIme	
        pusha
        push    ax                          ; Privremeno cuvamo ime datoteke		
        call    _file_exists                ; Da i vec postoji datoteka sa zadatim imenom?
        jnc    .DatotekaPostoji             ; Ako postoji, javi gresku.

; Root direktorijum je vec u baferu (ucitala ga je rutina _file_exists)
        mov     di, DiskBafer               ; Resetujemo DI da pokazuje na root direktorijum
        mov     cx, 224                     ; Ispitujemo sve stavke direktorijuma
        
.SledecaStavka:
        mov byte al, [di]
        cmp     al, 0                       ; Da li je stavka slobodna?
        je     .PronasaoSlobodnu
        cmp     al, 0E5h                    ; Da li je stavka obrisna (sto znaci slobodna)?
        je     .PronasaoSlobodnu
        add     di, 32                      ; Ukoliko nije, ispitujemo sledecu stavku
        loop   .SledecaStavka

.DatotekaPostoji:                           ; Datoteka postoji ili je direktorijum pun (nema slobodnih stavki)
        pop     ax                          ; Oslobadjamo stek (sacuvano ime datoteke)            
        jmp    .Greska

.PronasaoSlobodnu:
        pop     si                          ; Vracamo ime datoteke
        mov     cx, 11
        rep     movsb                       ; Kopiramo ga u direktorijum u baferu (na mesto na koje pokazuje DI)
        sub     di, 11                      ; Vracamo se na pocetak tekuce direktorijumske stavke

        mov byte [di+11], 20h               ; Atributi
        mov byte [di+12], 0                 ; Rezervisano
        mov byte [di+13], 0                 ; Rezervisano
        mov byte [di+14], 0C6h              ; Vreme kreiranja
        mov byte [di+15], 0A4h              ; Vreme kreiranja
        mov byte [di+16], 0Ch               ; Datum kreiranja
        mov byte [di+17], 3Dh	            ; Datum kreiranja
        mov byte [di+18], 0Eh               ; Datum poslednjeg pristupa
        mov byte [di+19], 3Dh               ; Datum poslednjeg pristupa
        mov byte [di+20], 0                 ; Zanemariti u FAT12
        mov byte [di+21], 0                 ; Zanemariti u FAT12
        mov byte [di+22], 27h               ; Vreme poslednjeg upisa
        mov byte [di+23], 0B2h              ; Vreme poslednjeg upisa
        mov byte [di+24], 0Eh               ; Datum poslednjeg upisa
        mov byte [di+25], 3Dh               ; Datum poslednjeg upisa
        mov byte [di+26], 0                 ; Prvi logicki klaster
        mov byte [di+27], 0                 ; Prvi logicki klaster
        mov byte [di+28], 0                 ; Velicina datoteke
        mov byte [di+29], 0                 ; Velicina datoteke
        mov byte [di+30], 0                 ; Velicina datoteke
        mov byte [di+31], 0                 ; Velicina datoteke
		
        call    UpisiRootDir
        jc     .Greska
        popa
        clc                                 ; Zavrsetak bez greske, CF=0
        ret

.Greska:
        jmp     _write_file.Greska          ; Zavrsetak sa greskom, CF=1
 ;      popa
 ;      stc                                 
 ;      ret
		
; ------------------------------------------------------------------
; _create_folder -- Kreira novi prazan folder
; Ulaz: AX = ime datoteke; Izlaz: CF=1 ako je greska
; ------------------------------------------------------------------

_create_folder:
		pusha
        clc
        call    _string_uppercase
		
        call    PodesiImeFoldera
		jc near .Greska
        push    ax                          ; Privremeno cuvamo ime foldera
		mov		word [.filename], ax
        call    _folder_exists              ; Da i vec postoji folder sa zadatim imenom?
        jnc    .FolderPostoji             	; Ako postoji, javi gresku.

; Root direktorijum je vec u baferu (ucitala ga je rutina _file_exists)
        mov     di, DiskBafer               ; Resetujemo DI da pokazuje na root direktorijum
		cmp	word [CurrentFolder], 0
		jne		.NijeRoot
        mov     cx, 224                     ; Ispitujemo sve stavke direktorijuma
        jmp		.SledecaStavka
.NijeRoot:
		mov		cx, 16                      ; Njih 16, ako nije root dir        FIX_ME. Mora da bude proizvoljan broj. (S.M.)
.SledecaStavka:
        mov byte al, [di]
        cmp     al, 0                       ; Da li je stavka slobodna?
        je     .PronasaoSlobodnu
        cmp     al, 0E5h                    ; Da li je stavka obrisna (sto znaci slobodna)?
        je     .PronasaoSlobodnu
        add     di, 32                      ; Ukoliko nije, ispitujemo sledecu stavku
        loop   .SledecaStavka
		
		jmp		.Greska
.FolderPostoji:                             ; Datoteka postoji ili je direktorijum pun (nema slobodnih stavki)
		push 	si
		mov		si, PostojiFolder
		call	_print_string
		pop		si
        pop     ax                          ; Oslobadjamo stek (sacuvano ime datoteke)            
        jmp    .Greska

.PronasaoSlobodnu:
        pop     si                          ; Vracamo ime datoteke
        mov     cx, 11
        rep     movsb                       ; Kopiramo ga u direktorijum u baferu (na mesto na koje pokazuje DI)
        sub     di, 11                      ; Vracamo se na pocetak tekuce direktorijumske stavke

        mov byte [di+11], 10h               ; Atributi
        mov byte [di+12], 0                 ; Rezervisano
        mov byte [di+13], 0                 ; Rezervisano
        mov byte [di+14], 0C6h              ; Vreme kreiranja
        mov byte [di+15], 0A4h              ; Vreme kreiranja
        mov byte [di+16], 0Ch               ; Datum kreiranja
        mov byte [di+17], 3Dh	            ; Datum kreiranja
        mov byte [di+18], 0Eh               ; Datum poslednjeg pristupa
        mov byte [di+19], 3Dh               ; Datum poslednjeg pristupa
        mov byte [di+20], 0                 ; Zanemariti u FAT12
        mov byte [di+21], 0                 ; Zanemariti u FAT12
        mov byte [di+22], 27h               ; Vreme poslednjeg upisa
        mov byte [di+23], 0B2h              ; Vreme poslednjeg upisa
        mov byte [di+24], 0Eh               ; Datum poslednjeg upisa
        mov byte [di+25], 3Dh               ; Datum poslednjeg upisa
        mov byte [di+26], 0                 ; Prvi logicki klaster
        mov byte [di+27], 0                 ; Prvi logicki klaster
        mov byte [di+28], 0                 ; Velicina datoteke
        mov byte [di+29], 0                 ; Velicina datoteke
        mov byte [di+30], 0                 ; Velicina datoteke
        mov byte [di+31], 0                 ; Velicina datoteke
		
		mov [.DiSave], di
		
		call    UpisiCurrentFolder
        jc near .Greska
		
		mov		ax, 1
		call	FindEmptyClusters
		mov	word [.SlobodniKlaster], ax
		
		mov 	bx, ax
        mov     dx, 0
        mov     bx, 3
        mul     bx
        mov     bx, 2
        div     bx
        mov     si, DiskBafer
        add     si, ax
        mov     ax, word [ds:si]
        or      dx, dx
        jz     .PoslednjiParni
		
.PoslednjiNeparni:
        and     ax, 000Fh                   ; Klaster sadrzi EOC
        add     ax, 0FF80h
        jmp    .SnimiFAT

.PoslednjiParni:
        and     ax, 0F000h                  ; Isto kao predthodni, samo za parni klaster
        add     ax, 0FF8h
		
.SnimiFAT:
        mov word [ds:si], ax
        call    UpisiFAT                    ; Snimamo FAT iz memorije na disk

.SnimiSektore:	
        mov     di, .SlobodniKlaster
        mov     word ax, [di]

        pusha
        add     ax, 31
        call    CHS12
		
		push 	di
		mov	word di, .podaci                ; Upisujemo odgovarajuce pocetne klastere
		mov	word ax, [.SlobodniKlaster]     ; u dot i dotdot stavku na .podaci
		mov word [di+26], ax                ; Dot je pointer na sam folder
		add		di, 32
		mov	word ax, [CurrentFolder]        ; A dotdot je trenutni folder, odnosno parent
		mov	word [di+26], ax
		pop 	di
		mov 	bx, .podaci
        mov     ah, 03h
        mov     al, 1
        stc
        int     13h
        popa
		
		call	UcitajCurrentFolder
		mov	word di, [.DiSave]
		
		mov	word ax, [.SlobodniKlaster]
		mov word [di+26], ax
		
		call	UpisiCurrentFolder
		jc		.Greska
		
        popa
        clc                                 ; Zavrsetak bez greske, CF=0
        ret

.Greska:                                    ; Zavrsetak sa greskom, CF=1
        jmp     _write_file.Greska
;       popa
;       stc                                 
;       ret
        
	.DiSave			  dw 0
	.podaci           db 2Eh, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 10h, 0, 20h, 0C6h, 0A4h, 0Ch, 3Dh, 0Eh, 3Dh, 0, 0, 27h, 0B2h, 0Eh, 3Dh, 0, 0, 0, 0, 0, 0 
	.bla			  db 2Eh, 2Eh, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 20h, 10h, 0, 20h, 0C6h, 0A4h, 0Ch, 3Dh, 0Eh, 3Dh, 0, 0, 27h, 0B2h, 0Eh, 3Dh, 0,
	.blab			  times 453 db 0
	.filename         dw 0
    .SlobodniKlaster  dw 0
	PostojiFolder	  db 'Postoji folder', 13, 10, 0
    
; ---------------------------------------------------------------------
; _remove_file -- Brise datoteku sa zadatim imenom
; Ulaz: AX = ime datoteke
; Ovo je genericka rutina za FAT12 (ukljuceni su svi potrebni segmenti)
; ---------------------------------------------------------------------

_remove_file:
        call    _string_uppercase
        call    PodesiIme
        push    ax                          ; Sacuvati podeseno ime
        clc
        call    UcitajRootDir
        mov     di, DiskBafer               ; DI pokazuje na root direktorijum
        pop     ax                          ; Vracamo sacuvao ime datoteke
        call    NadjiDirStavku              ; Nalazimo stavku. DI sadrzi adresu nadjene stavke
        jc     .Greska                      ; ili je grseka, ako ne mozemo da je nadjemo.
        mov     ax, word [es:di+26]         ; Uzimamo broj prvog klastera zadate datoteke
        mov word [.klaster], ax             ; i privremeno ga sacuvamo. 
        mov byte [di], 0E5h                 ; Oznaciti direktorijumski stavku (prvi bajt imena) kao obrisanu
        inc     di
        mov     cx, 0
        
.Anuliraj:
        mov     byte [di], 0                ; Anuliraj ostala polja direktorijumske stavke 
        inc     di
        inc     cx
        cmp     cx, 31                      ; 32 bajta, minus prethodni bajt (0E5h)
        jl     .Anuliraj
        call    UpisiRootDir                ; Upisujemo direktorijum na disk
        call    UcitajFAT                   ; Ucitavamo FAT
        mov     di, DiskBafer               ; Resetujemo DI na pocetak FAT

.SledeciKlaster:
        mov word ax, [.klaster]             ; Uzimamo broj klastera
        cmp     ax, 0                       ; Ukoliko je nula, u pitanju je prazna datoteka
        je     .Zavrsi
        mov     bx, 3                       ; Da li je klaster parni ili neprani
        mul     bx
        mov     bx, 2
        div     bx                          ; DX = 'klaster' mod 2 
        mov     si, DiskBafer             
        add     si, ax
        mov     ax, word [ds:si]
        or      dx, dx                      ; Ako je DX = 0, klaster je parni, ako je DX = 1, klaster je neparni
        jz     .Parni                       ; Ako je parni, odbacujemo gornji nibl

.Neparni:
        push    ax
        and     ax, 000Fh                   ; Postavljamo sadrzaj u FAT (gornjih 12 bitova) na nula
        mov word [ds:si], ax
        pop     ax
        shr     ax, 4                       ; Postavljamo bitove na pravo mesto (gornja 4 bita su sada nula)
        jmp    .Nastavi	                   

.Parni:
        push    ax
        and     ax, 0F000h                  ; Postavljamo sadrzaj u FAT (donjih 12 bitova) na nula
        mov word [ds:si], ax
        pop     ax
        and     ax, 0FFFh                   ; Maskiramo gornja 4 bita

.Nastavi:
        mov word [.klaster], ax         
        cmp     ax, 0FF8h                   ; Da li je sadrzaj = EOC (poslednji klaster)?
        jae    .Kraj
        jmp    .SledeciKlaster              ; Ako nije, obradi sledeci klaster

.Kraj:
        call    UpisiFAT
        jc     .Greska

.Zavrsi:
        ret

.Greska:
        stc
        ret

    .klaster dw 0

; --------------------------------------------------------------------------
; _rename_file -- Preimenuje datoteku
; Ulaz: AX = originalno ime datoteke, BX = Novo ime datoteke
; Izlaz: CF=1 ukoliko nastane greska
; --------------------------------------------------------------------------

_rename_file:
        push    bx                          ; Sacuvaj (pointer na) novo ime datoteke
        push    ax                          ; Sacuvaj (pointer na) staro ime datoteke
        clc
        call    UcitajRootDir
        mov     di, DiskBafer               ; DI je pointer na pocetak direktorijuma
        pop     ax                          ; Vracamo sacuvano staro ime datoteke
        call    _string_uppercase
        call    PodesiIme
        call    NadjiDirStavku              ; Nalazimo trazenu stavku u direktorijumi (DI pokazuje na nju)
        jc     .GreskaCitanja               ; Greska ukoliko datoteka ne postoji.
        pop     bx                          ; Vracamo novo ime datoteke
        mov     ax, bx
        call    _string_uppercase
        call    PodesiIme
        mov     si, ax
        mov     cx, 11                      ; Snimamo novo ime u root direktorijum u baferu
        rep     movsb
        call    UpisiRootDir                ; Snimamo root direktorijum na disk
        jc     .GreskaPisanja
        ret

.GreskaCitanja:
        pop     ax
        stc
        ret

.GreskaPisanja:
        stc
        ret

; --------------------------------------------------------------------------
; _get_file_size -- Vraca informaciju o velicini datoteke
; Ulaz: AX = datoteka; Izlaz: BX = velicina u bajtovima (do 64KB),
; CF=1 ukoliko nema trazene datoteke
; --------------------------------------------------------------------------

_get_file_size:
        pusha
        call    _string_uppercase
        call    PodesiIme
        clc
        push    ax
        call    UcitajRootDir
        jc     .Greska
        pop     ax
        mov     di, DiskBafer
        call    NadjiDirStavku
        jc     .Greska
        mov word bx, [di+28]                ; Velicina datoteke do 64 KB je na ofsetu 28 i 29 (word)
        mov word [.tmp], bx                 ; direktorijumske stavke
        popa
        mov word bx, [.tmp]
        ret

.Greska:
        popa
        stc
        ret

       .tmp dw 0

; ==========================================
; Lokalne rutine. Nisu dostupne preko OS API
; ==========================================
; -------------------------------------------------------------------
; PodesiIme -- Menja npr. 'FILE.BIN' u 'FILE    BIN' po zahtevu FAT12
; Ulaz:  AX = Zadato ime datoteke
; Izlaz: AX = Konvertovano ime datoteke; CF=1 ukoliko je nevazece
; -------------------------------------------------------------------

PodesiIme:
        pusha
        mov     si, ax
        call    _string_length
        cmp     ax, 13                      ; Da li je ime datoteke predugacko?
        jg     .Greska                      ; Maksimalno je 8(ime) + 3(ext) +1(tacka) + nula = 13
        cmp     ax, 0
        je     .Greska                      ; Greska ukoliko je ime prazan string
        mov     dx, ax                      ; Sacuvati duzimu stringa imena datoteke
        mov     di, .NoviString
        mov     cx, 0
.Sledeci:
        lodsb
        cmp     al, '.'                     ; Trazimo tacku
        je     .NasaoExt
        stosb
        inc     cx
        cmp     cx, dx
        jg     .Greska                      ; Greska ukoliko nema ekstenziju
        jmp    .Sledeci

.NasaoExt:
        cmp     cx, 0
        je     .Greska                      ; Greska ukoliko je prvi znak tacka
        cmp     cx, 8                       ; Preskoci dodavanje praznih mesta
        je     .Ekstenzija                  ; ako je prvi deo duzine 8 snakova

; Prvi deo imena popunjavamo praznim mestima do 8 znakova
.DodajPrazno:
        mov byte [di], ' '
        inc     di
        inc     cx
        cmp     cx, 8
        jl     .DodajPrazno

; Na kraju, kopiramo ekstenziju
.Ekstenzija:
        lodsb                               ; 3 znaka za ekstenziju
        cmp     al, 0
        je     .Greska
        stosb
        lodsb
        cmp     al, 0
        je     .Greska
        stosb
        lodsb
        cmp     al, 0
        je     .Greska
        stosb
        mov byte [di], 0                    ; Zavrsi nulom ime datoteke
        popa
        mov     ax, .NoviString
        clc                                 ; Zavrsetak bez greske, CF=0
        ret

.Greska:
        popa
        stc                                 ; Zavrsetak sa greskom, CF=1     
        ret

 .NoviString	times 13 db 0
	
; -------------------------------------------------------------------
; PodesiImeFoldera
; Ulaz:  AX = Zadato ime foldera
; Izlaz: AX = Konvertovano ime foldera; CF=1 ukoliko je nevazece
; -------------------------------------------------------------------

PodesiImeFoldera:
        pusha
		push    cx
		push    di
		mov		cx, 13
		mov		di, .NoviString
.Brisi: 
		mov	byte[di], 0
		inc		di
		dec		cx
		jnz		.Brisi
		pop	    di
		pop     cx
		
        mov     si, ax
        call    _string_length
        cmp     ax, 13                      ; Da li je ime predugacko?
        jg     .Greska                      ; Maksimalno je 8(ime) + 3(ext) +1(tacka)=13
        cmp     ax, 0
        je     .Greska                      ; Greska ukoliko je ime prazan string
        mov		dx, 0                       ; U DX brojimo tacke
        mov     di, .NoviString
        mov     cx, 0
.Sledeci:
        lodsb
		cmp		al, DELIMIT
		je		.Greska
		cmp		al, ':'
		je		.Greska
		cmp		al, '.'
		je		.Sledeci
		cmp		al, ';'
		je		.Sledeci
		cmp 	al, 0
		jne		.Vozi
		jmp		.PopuniSpejsovima
.Vozi:
		stosb
        inc     cx
        cmp     cx, 10
        jg     .Nastavi4                    
        jmp    .Sledeci
		
.PopuniSpejsovima:
		mov		al, ' '
		stosb
		inc 	cx
		cmp		cx, 10
		jg		.Nastavi4
		jmp		.PopuniSpejsovima
		
		
.Nastavi4:
        mov byte [di], 0                    ; Zavrsi nulom ime datoteke
        popa
        mov     ax, .NoviString
        clc                                 ; Zavrsetak bez greske, CF=0
        ret

.Greska:
        popa
        stc                                 ; Zavrsetak sa greskom, CF=1
        ret

    .NoviString	times 13 db 0

; --------------------------------------------------------------------------
; NadjiDirStavku -- Vraca lokaciju trazene stavke direktorijuma
; Ulaz: AX = datoteka; Izlaz: DI = lokacija u disk baferu ili CF=1 ako je nema
; --------------------------------------------------------------------------

NadjiDirStavku:
        pusha
        mov word [.filename], ax            ; Sacuvaj ime datoteke
        mov     cx, 224	                    ; Pretrazuje se svih 224 stavki FAT12 direktorijuma
        mov     ax, 0                       ; Pocinjemo sa ofsetom 0 (ime datoteke)

.SledecaStavka:
        xchg    cx, dx	                    ; Sacuvaj CX
        mov word si, [.filename]            ; Trazimo zadato ime
        mov     cx, 11                      ; u obliku filename.ext
        rep     cmpsb
        je     .NasaoStavku                 ; Pointer DI ce biti na ofsetu 11 (poslednji znak nadjenog imena)
        add     ax, 32                      ; Sledeca stavka (svaka ima 32 bajta)
        mov     di, DiskBafer		
        add     di, ax
        xchg    dx, cx                      ; Vrati sacuvani CX
        loop   .SledecaStavka
        popa
        stc                                 ; CF=1 jer nismo nasli stavku
        ret

.NasaoStavku:
        sub     di, 11                      ; Vracamo se na prvi znak nadjenog imena
        mov word [.tmp], di                 ; Vracamo sve registre
        popa
        mov word di, [.tmp]                 ; DI sadrzi pocetak stavke sa trazenim imenom
        clc
        ret

    .filename   dw 0
    .tmp        dw 0
    
; ---------------------------------------------------------------------
; UcitajFAT -- Ucitava sadrzaj prve FAT tabele u disk bafer
; Ulaz: - ; Izlaz: CF=1 ukoliko je nastala je greska u citanju
; Ovo je genericka rutina za FAT12 (ukljuceni su svi potrebni segmenti)
; ---------------------------------------------------------------------

UcitajFAT:
        pusha
        mov     ax, 1                       ; Prva kopija FAT pocinje od LBA=1 (odmah iza boot sektora)
        call    CHS12
        mov     si, DiskBafer	            ; Postavi ES:BX da pokazuju na bafer
        mov     bx, 2000h
        mov     es, bx
        mov     bx, si
        mov     ah, 2                       ; Parametar za INT 13h: ucitaj sektore
        mov     al, 9                       ; i to njih 9 (za prvi FAT), pocev od prvog sektora
        pusha	

.CitajDalje:
        popa
        pusha
        stc		
        int     13h	
        jnc    .Uspesno
        call    ResetDisk                   ; Resetuj disk kontroler u slucaju greske i pokusaj ponovo
        jnc    .CitajDalje                  ; Da li je reset bio uspesan?
        popa
        jmp    .Greska                      ; Ako je i reset bio bezuspesan, nesto nije u redu sa disk jedinicom

.Uspesno:
        popa                                ; Registri iz prethodne petlje,
        popa                                ; a zatim registri sacuvani na pocetku ove rutine
        clc                                 ; Zavrsetak bez greske, CF=0
        ret

.Greska:
        popa
        stc                                 ; Zavrsetak sa greskom, CF=1
        ret
        
; ---------------------------------------------------------------------
; UpisiFAT -- Upisuje sadrzaj FAT tabele iz disk bafera na disk
; Ulaz: FAT u disk baferu; Izlaz: CF=1 ako je greska u pisanju
; Ovo je genericka rutina za FAT12 (ukljuceni su svi potrebni segmenti)
; ---------------------------------------------------------------------

UpisiFAT:
        pusha
        mov     ax, 1                       ; Prva kopija FAT pocinje od LBA=1 (odmah iza boot sektora)
        call    CHS12
        mov     si, DiskBafer               ; Postavi ES:BX da pokazuju na bafer
        mov     bx, ds
        mov     es, bx
        mov     bx, si
        mov     ah, 3                       ; Parametar za INT 13h: upisi sektore
        mov     al, 9                       ; i to njih 9 (za prvi FAT), pocev od prvog sektora
        stc	
        int     13h	
        jc     .GreskaPisanja
        popa
        clc                                 ; Zavrsetak bez greske, CF=0
        ret

.GreskaPisanja:
        popa
        stc                                 ; Zavrsetak sa greskom, CF=1
        ret

; --------------------------------------------------------------------------
; UcitajRootDir -- Ucitava kompletan sadrzaj root direktoriuma u disk bafer
; Ulaz: - ; Izlaz: CF = 1 ukoliko je nastala je greska u citanju
; Ovo je genericka rutina za FAT12 (ukljuceni su svi potrebni segmenti)
; --------------------------------------------------------------------------

UcitajRootDir:
        pusha
        mov     ax, 19                      ; Root direktorijum za FAT 12 pocinje od LBA 19
        call    CHS12
        mov     si, DiskBafer               ; Postavi ES:BX da pokazuju na bafer
        mov     bx, ds
        mov     es, bx
        mov     bx, si
        mov     ah, 2                       ; Parametar za INT 13h: ucitaj sektore
        mov     al, 14                      ; i to njih 14 (224 stavke), pocev od 19-tog sektora
        pusha				

.CitajDalje:
        popa                                ; Resetuj sadrzaj registara na gornje vrednosti
        pusha
        stc	
        int     13h		
        jnc    .Uspesno
        call    ResetDisk                   ; Resetuj disk kontroler u slucaju greske i pokusaj ponovo
        jnc    .CitajDalje                  ; Da li je reset bio uspesan?
        popa
        jmp    .Greska                      ; Ako je i reset bio bezuspesan, nesto nije u redu sa disk jedinicom

.Uspesno:
        popa                                ; Registri iz prethodne petlje,
        popa                                ; a zatim registri sacuvani na pocetku ove rutine
        clc                                 ; Zavrsetak bez greske, CF=0
        ret

.Greska:
        popa
        stc                                 ; Zavrsetak sa greskom, CF=1
        ret

; --------------------------------------------------------------------------
; UpisiRootDir -- Upisuje sadrzaj root dirktorijuma iz DiskBafera na disk
; Ulaz: Sadrzaj DiskBafera; Izlaz: CF=1 ako je greska u pisanju.
; Ovo je genericka rutina za FAT12 (ukljuceni su svi potrebni segmenti)
; --------------------------------------------------------------------------

UpisiRootDir:
        pusha
        mov     ax, 19                      ; Root direktorijum za FAT 12 pocinje od LBA 19
        call    CHS12
        mov     si, DiskBafer               ; Postavi ES:BX da pokazuju na bafer
        mov     bx, ds              
        mov     es, bx              
        mov     bx, si
        mov     ah, 3                       ; Parametar za INT 13h: upisi sektore
        mov     al, 14                      ; i to njih 14 (224 stavke), pocev od 19-tog sektora
        stc	     
        int     13h	
        jc     .GreskaPisanja
        popa				
        clc
        ret

.GreskaPisanja:
        popa
        stc                                 ; CF=1 kada je greska
        ret

; ------------------------------
; Resetuje flopi disk kontroler
; ------------------------------

ResetDisk:                                  ; U slucaju greske, postavlja se CF (Carry)
        push    ax
        push    dx
        mov     ax, 0
        mov     dl, byte [bsDriveNumber]
        stc
        int     13h
        pop     dx
        pop     ax
        ret
        
; ------------------------------------------
; Racuna cilindar, glavu i sektor iz LBA  
; Ulaz: LBA u AX
; Izlaz: Odgovarajuci registri za INT 13h, fn2  
; ------------------------------------------

CHS12:				
        push    bx
        push    ax
        mov     bx, ax                      ; Sacuvati logicki sektor
        mov     dx, 0                           
        div     word [bpbSectorsPerTrack]
        add     dl, 01h                     ; Fizicki sektor pocinje od 1
        mov     cl, dl                      ; Sektori se prosledjuju preko CL 
        mov     ax, bx
        mov     dx, 0                       ; Racunati glavu
        div     word [bpbSectorsPerTrack]
        mov     dx, 0
        div     word [bpbHeadsPerCylinder]
        mov     dh, dl                      ; Glava
        mov     ch, al                      ; Cilindar
        pop     ax
        pop     bx
        mov     dl, byte [bsDriveNumber]		
        ret

; --------------------------------------------------------------
; FindEmptyClusters -- Nalazi slobodne klastere ciji broj zavisi
; od vrednosti u AX
; Ulaz: AX : broj potrebnih klastera
; Izlaz: AX : lista klastera; CF = 1 ako je greska
; --------------------------------------------------------------

FindEmptyClusters:
        pusha	
        
; Prvo anuliramo sve slobodne klastere (sve clanove liste .SlobodniKlasteri)
        pusha
        mov     di, .SlobodniKlasteri
        mov     cx, 127
        
.AnulirajSlobodne:
        mov     byte [di], 0
        inc     di
        loop   .AnulirajSlobodne
        popa

.Nastavi:
        mov word [.PotrebnoKlastera], ax
        call    UcitajFAT                   ; Ucitavamo FAT u memoriju
        mov     si, DiskBafer + 3           ; Preskacemo prva dva klastra 
        mov     bx, 2                       ; Pocetni redni broj klastera
        mov word cx, [.PotrebnoKlastera]
        mov     dx, 0                       ; Ofset u listi slobodnih klastera

.NadjiSlobodni:
        lodsw                               ; Ucitavamo rec od koje nam treba samo 12 bitova
        and     ax, 0FFFh                   ; Maska za parne klastere 
        jz     .NasaoParni                  ; Slobodan klaster?

.JosNeparnih:
        inc     bx	
        dec     si                          ; LODSW naredba je ucitala dva bajta. Nama treba jedan.
        lodsw                               ; Ucitati sledeu rec
        shr     ax, 4                       ; Izvajamo deo kod neparnog klastera
        or      ax, ax                      ; Da li je slobodan?
        jz     .NasaoNeparni

.JosParnih:
        inc     bx                          ; Ako nije, trazimo dalje
        jmp    .NadjiSlobodni

.NasaoParni:
        push    si
        mov     si, .SlobodniKlasteri       ; Sacuvamo klaster
        add     si, dx
        mov word [si], bx
        pop     si
        dec     cx                          ; Obezbedili smo potreban broj klastera?
        cmp     cx, 0
        je     .Kraj
        inc     dx                          ; Sledeca rec u listi
        inc     dx
        jmp    .JosNeparnih

.NasaoNeparni:
        push    si
        mov     si, .SlobodniKlasteri       ; Sacuvati klaster
        add     si, dx
        mov word [si], bx
        pop     si
        dec     cx
        cmp     cx, 0
        je     .Kraj
        inc     dx                          ; Sledeca rec u listi
        inc     dx
        jmp    .JosParnih
		
.Kraj:
		popa
		mov word ax, [.SlobodniKlasteri]
		ret
        
.Greska:
		popa
		stc
		ret

    .klaster          dw 0
    .PotrebnoKlastera dw 0
    .SlobodniKlasteri times 128 dw 0
; Tabela .SlobodniKlasteri sadrzi niz brojeva (reci) koje odgovaraju slobodnim klasterima na disku
	
; --------------------------------------------------------------------------
; _get_first_sector -- Vraca informaciju o prvom sektoru foldera
; Ulaz: AX = ime foldera; Izlaz: BX = prvi sektor,
; CF=1 ukoliko nema trazenog foldera
; --------------------------------------------------------------------------

_get_first_sector:
        pusha
        clc
        push    ax
        call    UcitajCurrentFolder
        jc     .Greska
        pop     ax
        mov     di, DiskBafer
        call    NadjiUCurrentFolderu
        jc     .Greska
        mov word bx, [di+26]                ; prvi sektor je na ofsetu 26 i 27
        mov word [.tmp], bx                 ; direktorijumske stavke
        popa
        mov word bx, [.tmp]
        ret

.Greska:
        popa
        stc
        ret

       .tmp dw 0

; --------------------------------------------------------------------------
; NadjiUCurrentFolderu -- Vraca lokaciju trazene stavke u trenutnom folderu
; Ulaz: AX = datoteka; Izlaz: DI = lokacija u disk baferu ili CF=1 ako je nema
; --------------------------------------------------------------------------

NadjiUCurrentFolderu:
        pusha
        mov word [.filename], ax            ; Sacuvaj ime datoteke
		cmp	word [CurrentFolder], 0
		jne		.NijeRoot
        mov     cx, 224	                    ; Pretrazuje se svih 224 stavki FAT12 direktorijuma
        mov     ax, 0                       ; Pocinjemo sa ofsetom 0 (ime datoteke)
		jmp 	.SledecaStavka
		
.NijeRoot:
		mov		cx, 16                      ; Ukoliko nije root, pretrazujemo 16 stavki trenutnog foldera   FIX_ME. treba neogranicen broj. (S.M.)
		mov		ax, 0
		
.SledecaStavka:
        xchg    cx, dx	                    ; Sacuvaj CX
        mov word si, [.filename]            ; Trazimo zadato ime
        mov     cx, 11                      ; u obliku filename.ext
        rep     cmpsb
        je     .NasaoStavku                 ; Pointer DI ce biti na ofsetu 11 (poslednji znak nadjenog imena)
        add     ax, 32                      ; Sledeca stavka (svaka ima 32 bajta)
        mov     di, DiskBafer		
        add     di, ax
        xchg    dx, cx                      ; Vrati sacuvani CX
        loop   .SledecaStavka
        popa
        stc                                 ; CF=1 jer nismo nasli stavku
        ret

.NasaoStavku:
        sub     di, 11                      ; Vracamo se na prvi znak nadjenog imena
        mov word [.tmp], di                 ; Vracamo sve registre
        popa
        mov word di, [.tmp]                 ; DI sadrzi pocetak stavke sa trazenim imenom
        clc
        ret

    .filename   dw 0
    .tmp        dw 0
    
; -----------------------------------------------------------------------------
; UcitajCurrentFolder -- Ucitava kompletan sadrzaj trenutnog foldera u disk bafer
; Ulaz: - ; Izlaz: CF = 1 ukoliko je nastala je greska u citanju
; -----------------------------------------------------------------------------

UcitajCurrentFolder:
        pusha
		mov		dx, [CurrentFolder]
		cmp		dx, 0
		jne		.NijeRoot
		
        mov     ax, 19                      ; Root direktorijum za FAT 12 pocinje od LBA 19
        call    CHS12
        mov     si, DiskBafer               ; Postavi ES:BX da pokazuju na bafer
        mov     bx, ds
        mov     es, bx
        mov     bx, si
        mov     ah, 2                       ; Parametar za INT 13h: ucitaj sektore
        mov     al, 14                      ; i to njih 14 (224 stavke), pocev od 19-tog sektora
        pusha
		jmp		.CitajDalje

        
.NijeRoot:
		mov     ax, [CurrentFolder]         ; Postavljamo ax na odgovarajucu vrednost sektora
		add		ax, 31                      ; dodajuci 31 na trenutni CurrentFolder klaster
        call    CHS12
        mov     si, DiskBafer               ; Postavi ES:BX da pokazuju na bafer
        mov     bx, ds
        mov     es, bx
        mov     bx, si
        mov     ah, 2                       ; Parametar za INT 13h: ucitaj sektore
        mov     al, 1                     	; i to jedan na mjestu CurrentFoldera
		pusha
	
.CitajDalje:
        popa                                ; Resetuj sadrzaj registara na gornje vrednosti
        pusha
        stc	
        int     13h		
        jnc    .Uspesno
        call    ResetDisk                   ; Resetuj disk kontroler u slucaju greske i pokusaj ponovo
        jnc    .CitajDalje                  ; Da li je reset bio uspesan?
        popa
        jmp    .Greska                      ; Ako je i reset bio bezuspesan, nesto nije u redu sa disk jedinicom

.Uspesno:
        popa                                ; Registri iz prethodne petlje,
        popa                                ; a zatim registri sacuvani na pocetku ove rutine
        clc                                 ; Zavrsetak bez greske, CF=0
        ret

.Greska:
        popa
        stc                                 ; Zavrsetak sa greskom, CF=1
        ret
        
; --------------------------------------------------------------------------
; _change_folder -- menja CurrentFolder na prvi sektor zadanog foldera
; Ulaz: AX = ime foldera
; CF=1 ukoliko nema trazenog foldera
; --------------------------------------------------------------------------

_change_folder:
        pusha
		mov		si, ax
		mov		di, .DotDotCmp
		call	_string_compare
		jc		.GetParent
		
		call    _string_uppercase
        call    PodesiImeFoldera
		jc		.Greska
		jmp		.Nastavak

.GetParent:
		mov		ax, .DotDotFilename
		
.Nastavak:		
		call	_get_first_sector
		jc 	    .Greska
		
		mov	word [CurrentFolder], bx
		
		popa
		clc
		ret
		
.Greska:
        popa
        stc
        ret

       .DotDotCmp db '..',0
	   .DotDotFilename db '..         ', 0
       
; --------------------------------------------------------------------------
; UpisiCurrentFolder -- Upisuje sadrzaj trenutnog dirktorijuma iz DiskBafera na disk
; Ulaz: Sadrzaj DiskBafera; Izlaz: CF=1 ako je greska u pisanju.
; --------------------------------------------------------------------------

UpisiCurrentFolder:
        pusha
		cmp word [CurrentFolder], 0
		jne		.NijeRoot
											; Ako je root
		mov     ax, 19  					; Root direktorijum za FAT 12 pocinje od LBA 19
		call    CHS12
        mov     si, DiskBafer               ; Postavi ES:BX da pokazuju na bafer
        mov     bx, ds              
        mov     es, bx              
        mov     bx, si
        mov     ah, 3                       ; Parametar za INT 13h: upisi sektore
        mov     al, 14                      ; i to njih 14 (224 stavke), pocev od 19-tog sektora
		jmp		.Nastavak
		
.NijeRoot:
		mov     ax, [CurrentFolder]  		; Uzimamo vrednost CurrentFoldera
		add		ax, 31						; Dodajemo 31 za dobijanje odgovarajuceg klastera
		call    CHS12
        mov     si, DiskBafer               ; Postavi ES:BX da pokazuju na bafer
        mov     bx, ds              
        mov     es, bx              
        mov     bx, si
        mov     ah, 3                       ; Parametar za INT 13h: upisi sektore
        mov     al, 1                       ; i to jedan, to jeste onaj iz CurrentFoldera
		
.Nastavak:
        stc	     
        int     13h	
        jc     .GreskaPisanja
        popa				
        clc
        ret

.GreskaPisanja:
        popa
        stc                                 ; CF=1 kada je greska
        ret
		
		
; ---------------------------------------------------------------------
; _check_and_remove -- Brise folder sa zadatim imenom, ali se prvo
; ide provera da li je prazan
; Ulaz: AX = ime foldera; Izlaz: CF=1 ako je greska u pisanju.
; ---------------------------------------------------------------------

_check_and_remove:
        pusha
        push 	ax
	
        call 	_change_folder                  ; Menjamo trenutni folder na trazeni
        jc 	 	.Greska
	
        call 	UcitajCurrentFolder	            ; Ucitavamo trazeni folder u DiskBafer
        mov  	di, DiskBafer                   ; Sada pretrazujemo folder stavku po stavku
        add		di, 32                          ; Preskocicemo prve dve stavke, drugu kasnije preskacemo
        mov		cx, 15                          ; kako bismo nasli jednu koja nije prazna ili obrisana
        
.Sledeca:
        add		di, 32
        dec		cx
        jz		.Kraj
        mov byte al, [di] 						
        cmp 	al, 0E5h                        ; Da li je obrisana?
        je		.Sledeca
        cmp		al, 0                           ; Da li je prazna
        je		.Sledeca
        jmp		.Greska                         ; ako nije ni prazna ni obrisana, onda ima nesto u folderu
                                                ; i ne smemo ga obrisati
.Kraj: 
        mov		ax, .DotDot
        call	_change_folder                  ; Vracamo se na parent trazenog foldera
        pop 	ax
        call	_remove_folder
        popa
        clc
        ret
    
.Greska:
        mov		ax, .DotDot
        call	_change_folder                  ; Vracamo se na parent trazenog foldera
        pop 	ax
        stc
        popa
        ret
        
.DotDot db '..',0

; ---------------------------------------------------------------------
; _remove_folder -- Brise folder sa zadatim imenom
; Ulaz: AX = ime foldera; Izlaz: CF=1 ako je greska u pisanju.
; ---------------------------------------------------------------------

_remove_folder:
		pusha
		clc
        call    _string_uppercase
        call    PodesiImeFoldera
		jc		.Greska
        push    ax                          ; Sacuvati podeseno ime
        call    UcitajCurrentFolder
        mov     di, DiskBafer               ; DI pokazuje na trazeni folder
        pop     ax                          ; Vracamo sacuvao ime foldera
        call    NadjiUCurrentFolderu        ; Nalazimo stavku. DI sadrzi adresu nadjene stavke
        jc     .Greska                      ; ili je grseka, ako ne mozemo da je nadjemo.
        mov     ax, word [es:di+26]         ; Uzimamo broj prvog klastera zadatog foldera
        mov word [.klaster], ax             ; i privremeno ga sacuvamo. 
        mov byte [di], 0E5h                 ; Oznaciti direktorijumski stavku (prvi bajt imena) kao obrisanu
        inc     di
        mov     cx, 0
        
.Anuliraj:
        mov     byte [di], 0                ; Anuliraj ostala polja direktorijumske stavke 
        inc     di
        inc     cx
        cmp     cx, 31                      ; 32 bajta, minus prethodni bajt (0E5h)
        jl     .Anuliraj
        call    UpisiCurrentFolder          ; Upisujemo direktorijum na disk
        call    UcitajFAT                   ; Ucitavamo FAT
        mov     di, DiskBafer               ; Resetujemo DI na pocetak FAT

.SledeciKlaster:
        mov word ax, [.klaster]             ; Uzimamo broj klastera
        cmp     ax, 0                       ; Ukoliko je nula, u pitanju je prazna datoteka
        je     .Zavrsi
        mov     bx, 3                       ; Da li je klaster parni ili neprani
        mul     bx
        mov     bx, 2
        div     bx                          ; DX = 'klaster' mod 2 
        mov     si, DiskBafer             
        add     si, ax
        mov     ax, word [ds:si]
        or      dx, dx                      ; Ako je DX = 0, klaster je parni, ako je DX = 1, klaster je neparni
        jz     .Parni                       ; Ako je parni, odbacujemo gornji nibl

.Neparni:
        push    ax
        and     ax, 000Fh                   ; Postavljamo sadrzaj u FAT (gornjih 12 bitova) na nula
        mov word [ds:si], ax
        pop     ax
        shr     ax, 4                       ; Postavljamo bitove na pravo mesto (gornja 4 bita su sada nula)
        jmp    .Nastavi	                   

.Parni:
        push    ax
        and     ax, 0F000h                  ; Postavljamo sadrzaj u FAT (donjih 12 bitova) na nula
        mov word [ds:si], ax
        pop     ax
        and     ax, 0FFFh                   ; Maskiramo gornja 4 bita

.Nastavi:
        mov word [.klaster], ax         
        cmp     ax, 0FF8h                   ; Da li je sadrzaj = EOC (poslednji klaster)?
        jae    .Kraj
        jmp    .SledeciKlaster              ; Ako nije, obradi sledeci klaster

.Kraj:
        call    UpisiFAT
        jc     .Greska

.Zavrsi:
		popa
        ret

.Greska:
        stc
		popa
        ret

    .klaster dw 0
    
; ---------------------------------------------------------------------
; _change_disc -- menja trenutni disk. Ako se ne razlikuje od trenutnog
; postalja trenutni folder na root
; Ulaz: SI = zeljeni disk; Izlaz: -
; ---------------------------------------------------------------------

_change_disc:
		pusha
		cmp	byte [si], 'A'
		je	.A
.B:
		mov	byte [bsDriveNumber], 1         ; Zamena diska resetuje trenutni folder na root
		mov	word [CurrentFolder], 0
		jmp .Kraj
.A:
		mov byte [bsDriveNumber], 0
		mov word [CurrentFolder], 0
.Kraj:
		popa
		ret
        
; ---------------------------------------------------------------------
; _get_dir_path -- Nalazi direktorijum po apsolutnoj ili relativnoj
; putanji i upisuje ga u bafer za listanje
; Ulaz: AX = putanja do direktorijuma, BX = bafer gdje se smesta 
; string sa listom fajlova; Izlaz: CF = 1 ako je greska
; ---------------------------------------------------------------------

_get_dir_path:
		pusha
		clc
		push 	ax
		mov		ax, [CurrentFolder]	        ; Cuvamo trenutni folder kako bismo se mogli
		mov		[.StariCurrentFolder], ax   ; vratiti u njega kad zavrsimo izlistavanje
		mov	byte al, [bsDriveNumber]        ; Isto radimo i sa trenutnom disketom
		mov	byte [.StariDriveNumber], al
		pop		ax
		
		call	_change_folder_path         ; Nalazimo trazenu putanju
		jc		.Greska	                    ; Ako je CF = 1, nema putanje
		call	_get_dir                    ; U BX se upisuje trazeni sadrzaj
		
		mov		ax, [.StariCurrentFolder]   ; Vracamo sve na staro
		mov	    [CurrentFolder], ax
		mov	byte al, [.StariDriveNumber]
		mov	byte [bsDriveNumber], al
		
		call	_change_folder
.Kraj:
		popa
		clc
		ret

.Greska:
		mov		ax, [.StariCurrentFolder]   ; Vracamo sve na staro i ispisujemo gresku
		mov		[CurrentFolder], ax
		mov	byte al, [.StariDriveNumber]
		mov	byte [bsDriveNumber], al
		call	_change_folder
		popa
		stc
		ret
	
	.StariCurrentFolder 	dw 0
	.StariDriveNumber		db 0
    
; ---------------------------------------------------------------------
; _change_folder_path -- Nalazi folder po apsolutnoj ili relativnoj
; putanji i menja CurrentFolder na prvi klaster tog foldera
; Ulaz: AX = putanja do direktorijuma; Izlaz: CF = 1 ako nema putanje
; ---------------------------------------------------------------------

_change_folder_path:
		pusha
		clc
		mov		si, ax
		dec		si							; Mali hak za coveka, ali veliki za ovu funkciju
		cmp byte [si+2], ':'                ; Ako drugi karakter AX nije ':'
		jne 	.Relativna                  ; rec je o relativnoj putanji 
                                            ; Kredit za Dejana Maksimovica (S.M.) :)
.Apsolutna:
		mov		si, ax                      ; Ako je rec o apsolutnoj putanji, mozemo se
		call	_change_disc                ; na odgovarajuci disk prebaciti koristeci _change_disc
                                            ; i to sto je u AX prvo slovo slovo drajva
		add		si, 3                       ; Dodavanjem 3 na SI pravimo relativnu putanju
                                            ; i nadalje radimo kao da je rec o relativnoj
		cmp	byte [si], 0                    ; Ako je zadana samo putanja na root diska, zavrsiti odmah
		je 		.Gotovo
		dec		si
		xor		cx, cx
.Relativna:
		inc		si
		cmp	byte [si], 0                    ; Ako je na SI vrednost nula, zavrsili smo razresavanje putanje
		je		.Kraj                       ; i u zeljenom smo folderu
		cmp	byte [si], DELIMIT              ; Ako se na SI nalazi DELIMIT, moramo se prebaciti na novi folder
		je		.Menjaj
		mov		di, .tmp
		add		di, cx
		mov	byte al, [si]
		mov byte [di], al                   ; Ukoliko nije nista od prethodnog, stavljamo trenutni znak
		inc		cx                          ; u .tmp i povecavamo CX
		jmp		.Relativna
				
.Menjaj:
		mov		di, .tmp
		add		di, cx
		xor		al, al
		mov		[di], al                    ; Postavljamo posljednji znak .tmp na 0
		xor		cx, cx
		mov		ax, .tmp                    ; U .tmp je ime novog foldera na koji se treba prebaciti
		
		call	_change_folder				
		jc		.Greska                     ; Ako nema bilo kog foldera iz putanje, javljamo gresku
		jmp		.Relativna                  ; U suprotnom trazimo sledeci folder

.Kraj:                                      ; Ostao je jos jedan folder za kraj
		mov		di, .tmp
		add		di, cx
		xor		al, al
		mov		[di], al				
		xor		cx, cx
		mov		ax, .tmp

		call	_change_folder				
		jc		.Greska				
.Gotovo:
		popa
		clc
		ret

.Greska:
		popa
		stc
		ret
		
.tmp	times 14 db 0

; ---------------------------------------------------------------------
; _cd_path -- Nalazi folder po apsolutnoj ili relativnoj
; putanji i prebacuje se na njega, ako nema putanje vraca sve na staro
; Ulaz: AX = putanja do foldera
; Izlaz: CF = 1 ako je greska
; ---------------------------------------------------------------------

_cd_path:
		pusha
		clc
		push 	ax
		mov		ax, [CurrentFolder]	            ; Cuvamo trenutni folder kako bismo se mogli
		mov		[.StariCurrentFolder], ax       ; vratiti u njega kad zavrsimo 
		mov	byte al, [bsDriveNumber]            ; Isto radimo i sa trenutnim diskom
		mov	byte [.StariDriveNumber], al
		pop		ax
		
		call	_change_folder_path	            ; Nalazimo trazenu putanju
		jc		.Greska	                        ; Ako je CF = 1, nema putanje
		
.Kraj:
		popa
		clc
		ret

.Greska:
		mov		ax, [.StariCurrentFolder]       ; Vracamo sve na staro i ispisujemo gresku
		mov		[CurrentFolder], ax
		mov	byte al, [.StariDriveNumber]
		mov	byte [bsDriveNumber], al
		call	_change_folder
		popa
		stc
		ret
	
.StariCurrentFolder 	dw 0
.StariDriveNumber		db 0

; ---------------------------------------------------------------------
; _test_path -- Nalazi folder po apsolutnoj ili relativnoj
; putanji, ako postoji, ne menjajuci tekuci folder
; Ulaz: AX = putanja do foldera
; Izlaz: CF = 1 ako ne postoji, 0 ako postoji
; ---------------------------------------------------------------------

_test_path:
		pusha
		clc
		push 	ax
		mov		ax, [CurrentFolder]             ; Cuvamo trenutni folder kako bismo se mogli
		mov		[.StariCurrentFolder], ax       ; vratiti u njega kad zavrsimo 
		mov	byte al, [bsDriveNumber]            ; Isto radimo i sa trenutnom disketom
		mov	byte [.StariDriveNumber], al
		pop		ax
		call	_change_folder_path             ; Nalazimo trazenu putanju
		jc		.Greska	                        ; Ako je CF = 1, nema putanje
		mov		ax, [.StariCurrentFolder]       ; Vracamo sve na staro
		mov		[CurrentFolder], ax
		mov	byte al, [.StariDriveNumber]
		mov	byte [bsDriveNumber], al
		call	_change_folder
		
.Kraj:
		popa
		clc
		ret

.Greska:
		mov		ax, [.StariCurrentFolder]       ; Vracamo sve na staro i ispisujemo gresku
		mov		[CurrentFolder], ax
		mov	byte al, [.StariDriveNumber]
		mov	byte [bsDriveNumber], al
		call	_change_folder
		popa
		stc
		ret
	
.StariCurrentFolder 	dw 0
.StariDriveNumber		db 0

 ; Informacije koje se nalaze u boot sektoru:       
bpbSectorsPerTrack      dw 18
bpbHeadsPerCylinder     dw 2
bsDriveNumber           db 0
	
; Globalna varijabla na nivou diska sa putanjom
CurrentFolder	 dw 0
    
 ; ----------------------------------------------------
; Upisuje trenutno vreme u FileTimeStamp u DOS formatu
; ----------------------------------------------------
SetFileTimeStamp:                           
        pusha
        clc                                 ; Za svaku sigurnost
        mov     ah, 2                       ; Uzimamo BIOS vreme u BCD obliku
        int     1Ah                         ; BIOS vraca vreme u obliku CH: sati, CL: minuti, DH: sekunde 
        jnc near .CitajT
        clc
        mov     ah, 2                       ; BIOS je vrsio osvezavanje, probati ponovo
        int     1Ah
        
.CitajT:                                    ; _bcd_to_int ulaz: AL BCD; izlaz AX ceo broj
        mov     al, ch                      ; Sati
		call    _bcd_to_int                 ; U AX je sada ceo broj sati (0-23)
		mov     [.sat], ax
        mov     al, cl                      ; Minuti
		call    _bcd_to_int                 ; U AX je sada ceo broj minuta (0-59)
        mov		[.minut], ax
        mov     al, dh                      ; Sekunde
		call    _bcd_to_int                 ; U AX je sada ceo broj sekundi (0-59)
		mov     [.sekund], ax

; ------------------------------------------------------------
; Formiranje FileTimeStamp
;
;    format FileTimeStamp:
;        FEDCBA9876543210
;        hhhhhmmmmmmsssss
;    hhhhh - 5 bitova, broj sati 0-23; 
;    mmmmmm - 6 bitova, broj minuta 0-59 
;    sssss - 5 bitova, broj sekundi 0-29 (mora da se deli sa 2)
;    formiranje u AX glavnog stringa, BX - podesavanje minuta, 
;    CX - podesavanje sekundi
; -------------------------------------------------------------

        xor     ax, ax                      ; Anuliranje AX
        mov     ax, word [.sat]             ; Broj sati je sigurno 0-23
        shl     ax, 11                      ; 5432100000000000 -> sat pomeren na pocetak
        mov     bx, word [.minut]           ; Broj minuta je sigurno 0-59;
		shl     bx, 5                       ; xxxxx65432100000 -> minut pomeren u sredinu
        or      ax, bx                      ; Bitovi minuta pridruzeni
        mov     bx, word [.sekund]          ; Broj sekundi je sigurno 0-59, mora da se podeli sa 2 
        shr     bx, 1                       ; Deli sa 2
        or      ax, bx                      ; Sekunde su na poslednjem mestu
        mov     [FileTimeStamp], ax         ; Formiran je string sa vremenom.
        popa
        ret

.sat:           dw 0
.minut:         dw 0
.sekund:        dw 0
FileTimeStamp:  dw 0

; --------------------------------------------------------
; Upisuje trenutni datum u FileDateStamp u dos formatu
; --------------------------------------------------------
SetFileDateStamp:                           		
        pusha
        clc                                 ; Za svaku sigurnost
        mov     ah, 4                       ; Uzimamo BIOS datum u BCD obliku
        int     1Ah                         ; BIOS vraca datum u obliku CH: vek, CL: godina (dvocifreno),
        jnc near .CitajD                    ; DH: mesec, DL: dan
        clc
        mov     ah, 4                       ; BIOS je vrsio osvezavanje, probati ponovo
        int     1Ah
        
.CitajD:
        mov     al, dl                      ; Dan
        call    _bcd_to_int                 ; U AX je sada ceo broj dana (1-31)
        mov     [.dan], ax
        mov     al, dh                      ; Mesec
        call    _bcd_to_int                 ; U AX je sada ceo broj meseca (1-12)
        mov     [.mesec], ax
        mov     al, ch                      ; Vek
        call    _bcd_to_int                 ; U AX je sada ceo broj veka
        mov     [.vek], ax
        mov     al, cl                      ; Godina
        call    _bcd_to_int                 ; U AX je sada ceo broj godine
        mov     [.godina], ax

; -----------------------------------------------------------------------
; Formiranje FileDateStamp
;
;   format FileDateStamp:
;       FEDCBA9876543210
;       gggggggmmmmddddd
;   ddddd - 5 bitova, broj dana (1-31); mmmm - 4 bita, broj meseca (1-12);
;   gggggg - 7 bitova, broj godine (0-127 = 1980-2107)
; ------------------------------------------------------------------------

        xor     cx, cx                      ; Ciscenje CX, u njemu se formira string
        mov     cx, word [.dan]             ; Broj dana je sigurno 1-31
        mov     bx, word [.mesec]           ; Broj meseca je sigurno 1-12
        shl     bx, 5                       ; xxxxxxx432100000 -> mesec pomeren na sredinu
        or      cx, bx                      ; Bitovi meseca pridodati bitovima dana
        mov     ax, word [.vek]             ; Racunarski vek je za 1 manji od istorijskog (tj. 20. vek na racunaru traje 2000-2099)
        mov     bl, 100
        mul     bl                          ; U AX je sada broj veka pomnozen sa 100
        add     ax, word [.godina]          ; Sada je cela godina, treba je umanjiti za 1980
        sub     ax, word 1980               ; Umanjenu godinu dodajemo na CX
        shl     ax, 9                       ; 7654321000000000
        or      cx, ax                      ; To su najnizi bitovi
        mov     [FileDateStamp], cx         ; Formiran je FileDateStamp
        popa
        ret
        
; --------------------------------------------        
; Dodatne informacije za upisivanje vremena
; --------------------------------------------
.vek            dw 0
.godina         dw 0
.mesec          dw 0
.dan            dw 0
FileDateStamp   dw 0

; --------------------------------------------        
; Indikator potreban za rad sa atributima
; --------------------------------------------
plus_flag       db 0