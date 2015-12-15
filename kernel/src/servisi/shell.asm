; =============================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; =============================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Komandni interfejs (SHELL)
;
; Shell prvo proverava da li je zadata interna komanda.
; Ako nije interna, proverava se da li postoji na disku.
; Izvrsne eksterne komande su datoteke tipa .BIN, .COM i .BAT.
; Prioritet izvrsavanja je: 1) Interna, 2) BIN, 3) COM, 4) BAT.
; -----------------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.).
;
; Verzija 0.0.2 - BASIC je izdvojen iz kernela kao aplikacioni program
; (16.01.2011). Marko Petrovic, 24/06.
;
; Verzija 0.0.3 - Dodate funkcije CTRL + S za stopiranje
; i CTRL + Q za nastavljanje ispisa kod komande type/cat
; (16.01.2011). Vlado Pajic, RN16/09.
;
; Verzija 0.0.4 - Dodata interna komanda ATTRIB za setovanje/resetovanje
; atributa datoteka (16.01.2011). Darko Drdareski, 24/09.
;
; Verzija 0.1.0 - Dodate interne komande za direktorijumsko stablo:
; MD, RD, CD, PATH, kao i mogucnost eksplicitne promene tekucih disk jedinica
; A i B (27.11.2011.). Dejan Maksimovic, RN03/10.
;
; Verzija 0.1.1 - Korigovan sadrzaj i nacina ispisivanja poruka (04.12.2011.).
; Stevan Milinkovic
;
; Verzija 0.1.2 - Integracija sa ostalim modulama sistema (06.12.2011.).
; Stevan Milinkovic
; -----------------------------------------------------------------------------

%define     NULL 0
%define     DELIMIT '/'                     ; Oznaka za prompt delimiter

app_start   equ  8400h
app_seg     equ  app_start/10h              ; OBRISATI
input       equ  app_start - 256            ; Deljeni bafer za OS i aplikacije
arg1        equ  app_start - 128            ; Bafer za prvi argument komandne linije

_command_line:
    call    _clear_screen
    mov     ax, autoexec_string         ; Ucitavamo autoexec.bat
    mov     bx, 0                       ; 
    mov     cx, app_start               ; Adresa gde pocinju programi               
    call    _load_file                  ; CF = 1 ukoliko nema autoexec
    jc      Ispisi_verziju              ; Preskoci sledeci deo ako autoexec.bat ne postoji           
    mov     ax, app_start               ; Prosledjuemo interpreteru pocetak programa 
    call    _run_batch                  ; Pokrecemo BATCH Intepreter

Ispisi_verziju:       
    mov     si, pozdrav
    call    _print_string
    mov     si, verzija
    call    _print_string

Komanda:
    mov     si, prompt                  ; Glavna petlja. Prompt za unosenje komande.
    call    _print_string

    mov     ax, input                   ; Ucitati komandni string
    call    _input_string
    call    _print_newline
    mov     ax, input                   ; Ukloniti visak Space znakova
    call    _string_chomp

    mov     si, input                   ; Ponovo prompt, ako je pritisnut samo Enter
    cmp     byte [si], 0
    je      Komanda

    mov     si, input                   ; Konvertovati sve u velika slova
    call    _string_uppercase
	
	push	si
	push	di
	mov	    si, input
	mov	    di, temp_input
	call	_string_copy
	pop 	di
	pop	    si

; -------------------------
; Da li je interna komanda
; -------------------------
    mov     si, input
    mov     di, exit_string             ; stop?
    call    _string_compare
    jc near exit

    mov     di, help_string             ; help?
    call    _string_compare
    jc near print_help

    mov     di, cls_string              ; cls?
    call    _string_compare
    jc near clear_screen

    mov     di, dir_string              ; dir?
    mov	    cl, 3
    call    _string_strincmp
    jc near list_directory
    
    mov     di, ls_string               ; Unix dir?
    mov	    cl, 2
    call    _string_strincmp
    jc near list_directory

    mov     di, ver_string              ; ver?
    call    _string_compare
    jc near print_ver

    mov     di, time_string             ; time?
    call    _string_compare
    jc near print_time

    mov     di, date_string             ; date?
    call    _string_compare
    jc near print_date

    mov     di, type_string             ; type?
    mov     cl, 3
    call    _string_strincmp
    jc near cat_file

    mov     di, cat_string              ; Unix type?
    mov     cl, 3
    call    _string_strincmp
    jc near cat_file
    
    mov     di, ren_string              ; rename?
    mov     cl, 3
    call    _string_strincmp
    jc near ren_file

    mov     di, del_string              ; delete?
    mov     cl, 3
    call    _string_strincmp
    jc near del_file

    mov     di, rm_string               ; Unix delete?
    mov     cl, 2
    call    _string_strincmp
    jc near del_file

    mov     di, copy_string             ; copy?
    mov     cl, 3
    call    _string_strincmp
    jc near copy_file

    mov     di, cp_string               ; Unix copy?
    mov     cl, 2
    call    _string_strincmp
    jc near copy_file

    mov     di, attrib_string           ; attrib?
    mov 	cl,6
    call    _string_strincmp
    jc near attributes

    mov     di, pids_string             ; pids?
    mov     cl, 4
    call    _string_strincmp
    jc near pids

    mov     di, kill_string             ; kill?
    mov     cl, 4
    call    _string_strincmp
    jc near kill
 
	mov	di, md_string	                ; Make dir?
	mov	cl, 2
	call	_string_strincmp
	jc near make_dir
		
	mov	di, cd_string                   ; Change dir?
	mov	cl, 2
	call	_string_strincmp
	jc near change_dir
		
	mov	di, rd_string		            ; Remove dir?
	mov	cl, 2
	call	_string_strincmp
	jc near remove_dir
	
	mov	di, a_string		            ; A:?
	call	_string_compare
	jc near change_disc
		
	mov	di, b_string		            ; B:?
	call	_string_compare
	jc near change_disc
		
	mov	di, path_string		            ; PATH?
	mov	cl, 4
	call	_string_strincmp
	jc near path
        
; --------------------------------------------------------------------------
; Ako korisnik nije zadao nijednu od prethodnih internih komandi, potrebno 
; je proveriti da li na disku postoji izvrsna datoteka (.BIN) sa tim imenom
; --------------------------------------------------------------------------
		
ProveriIzvrsnu:
	mov	    si, temp_input
    mov     di, input                   
	call	_string_copy  
	mov	si, input                       ; Resavamo problem prenosenja parametara sa komandne linije
    call    _string_parse
    mov     si, ax
    mov     di, arg0                    ; arg0 je komanda (ime eksternog programa) 
    call    _string_copy

    cmp     bx, 0
    jne     sa_argumentom
    mov byte [arg1], 0
    jmp     bez_argumenta

sa_argumentom:     
    mov     si, bx
    mov     di, arg1                    ; arg1 je prvi argument. Ako je NULL, onda nema prvog argumenta.        
    call    _string_copy

bez_argumenta:   
    mov     si, arg0                    ; Da li zadata eksterna komada ima tacku u imenu datoteke?
    mov     al, '.'
    call    _find_char_in_string
    cmp     ax, 0
    je      Sufiks
    jmp     PunoIme                     ; Ako ima tacku, proveravamo puno ime

Sufiks: 
    mov     ax, arg0                    ; Ako nema tacku, dodajemo sufiks .BIN
    call    _string_length
    mov     si, arg0                    ; AX sada sadrzi duzinu stringa       
    add     si, ax                      ; SI pokazuje na kraj stringa         

    mov     byte [si], '.'
    mov     byte [si+1], 'B'
    mov     byte [si+2], 'I'
    mov     byte [si+3], 'N'
    mov     byte [si+4], 0	            ; String .BIN zavrsavamo nulom          

; -------------------------------------------------------------
; Proveravamo puno ime (sadrzi i ekstenziju .BIN, COM ili .BAT)
; -------------------------------------------------------------
        
PunoIme:
    mov     si, arg0                    ; Korisnik pokusava da izvrsi kernel kao aplikaciju?
    mov     di, kern_string
    call    _string_compare
    jc near kern_warning
              
    mov     ax, arg0			         
    call    _string_length                
    mov     si, arg0
    add     si, ax
    sub     si, 3                       ; Postaviti se na pravo mesto za proveru ekstenzije datoteke 

    mov     di, BinEkstenzija           ; Da li je 'BIN'?
    call    _string_compare
    jnc     ComDatoteka 

    mov     si, temp_input
    mov     di, input                   
    call    _string_copy

    mov     si, input                   ; Proveravamo da li je aplikacija pokrenuta sa background parametrom?
    call    _string_parse               ; arg1 arg2 arg3 se nalaze u bx cx dx

    mov     di, bg_string               ; da li je bx argument --bg ?
    mov     si, bx
    clc
    call    _string_compare
    jc      .bg_proces
    
    mov     di, bg_string               ; da li je cx argument --bg ?
    mov     si, cx
    clc
    call    _string_compare
    jc      .bg_proces

    mov     di, bg_string               ; da li je dx argument --bg ?
    mov     si, dx
    clc
    call    _string_compare
    jc      .bg_proces

.fg_proces:
    mov     bx, 1                       ; 1 = foreground proces
    jmp     .kreiraj_proces
.bg_proces:
    mov     bx, 0                       ; 0 = background proces

.kreiraj_proces:
    mov     ax, arg0
    clc
    call    _ubaci_proces               ; Pokusaj da kreiras proces
    jc near NijeBin                     ; Preskoci sledeci deo ako nije pronadjen trazeni program
    
 	mov		ax, (prompt+9)              ; Path pocetak
 	call	_change_folder_path
 	mov     word [tempBrojac], 0
    jmp     Komanda                     ; Po zavrsetku, ponovo se startuje shell

; --------------------------------------------------------
; Proveravamo da li je ucitana COM datoteka 
; --------------------------------------------------------        
  
ComDatoteka:
    mov     ax, input
    call    _string_length
    mov     si, input
    add     si, ax
    sub     si, 3                       ; Provera ekstenzije 

    mov     di, ComEkstenzija           ; Da li je 'COM'
    call    _string_compare
    jnc     BatDatoteka                 
        
    mov     si, temp_input
    mov     di, input                   
    call    _string_copy

    mov     si, input
    call    _string_parse
    ; na ax je ime datoteke
    ; na bx, cx, dx su argumenti, proveravamo da li je neki bg_string
    
    mov     di, bg_string
    mov     si, bx
    clc
    call    _string_compare
    jc      .bg_proces
    
    mov     di, bg_string
    mov     si, cx
    clc
    call    _string_compare
    jc      .bg_proces

    mov     di, bg_string
    mov     si, dx
    clc
    call    _string_compare
    jc      .bg_proces

.fg_proces:
    mov     bx, 1                       ; 1 = foreground proces
    jmp     .kreiraj_proces
.bg_proces:
    mov     bx, 0                       ; 0 = background proces

.kreiraj_proces:
    mov     ax, arg0
    clc
    call    _ubaci_proces               ; Pokusaj da kreiras proces
    jc near NijeCom                     ; Preskoci sledeci deo ako nije pronadjen trazeni program

	mov		ax, (prompt+9)              ; Path pocetak
	call	_change_folder_path
	mov word [tempBrojac], 0
    jmp     Komanda                     ; Po izlasku iz COM, ponovo prompt.
               
; --------------------------------------------------------
; Proveravamo da li je ucitana datoteka tekst skript
; Ukoliko jeste, potrebno je startovati BAT interpreter
; i proslediti mu ucitanu datoteku
; --------------------------------------------------------        
  
BatDatoteka:
    mov     ax, input
    call    _string_length
    mov     si, input
    add     si, ax
    sub     si, 3                       ; Provera ekstenzije 

    mov     di, BatEkstenzija           ; Da li je 'BAT'
    call    _string_compare
    jnc near ProveriPath                ; Ako nije, tada sistem ne moze da izvrsi program

    mov     si, NemaBatInterpreter
    call    _print_string
    call    _print_newline

    ;mov     ax, app_start               ; Ako jeste, pocetak programa 
    ;mov word bx, [Velicina]             ; i njegova velicina u memoriji 
    ;call    _run_batch                  ; prosledjuju se skript interpreteru
	
    mov		ax, (prompt+9)              ; Path pocetak
	call	_change_folder_path
	mov word [tempBrojac], 0
    jmp     Komanda                     ; Po izlasku, ponovo prompt.

; ----------------------------------------------------
; Zadata je datoteka bez ekstenzije, ali nije .BIN
; Ovde proveravamo da li postoji sa ekstenzijom .COM
; ----------------------------------------------------
        
NijeBin:
    mov     ax, arg0
    call    _string_length
    mov     si, arg0
    add     si, ax                      ; Idi na kraj ulaznog stringa                 
    sub     si, 4                       ; Treba oduzeti 4 znaka jer smo prethodno dodali .BIN 

    mov byte [si], '.'                  ; Dodati ekstenziju .COM ?
    mov byte [si+1], 'C'
    mov byte [si+2], 'O'
    mov byte [si+3], 'M'
    mov byte [si+4], 0		
    
    jmp ComDatoteka

; ----------------------------------------------------
; Datoteka je bez ekstenzije, ali nije ni .BIN ni .COM
; Ovde proveravamo da li postoji sa ekstenzijom .BAT
; ----------------------------------------------------
        
NijeCom:
    mov     ax, arg0
    call    _string_length
    mov     si, arg0
    add     si, ax                      ; Idi na kraj ulaznog stringa                 
    sub     si, 4                       ; Treba oduzeti 4 znaka jer smo prethodno dodali .BIN 

    mov byte [si], '.'                  ; Dodati ekstenziju .BAT ?
    mov byte [si+1], 'B'
    mov byte [si+2], 'A'
    mov byte [si+3], 'T'
    mov byte [si+4], 0		
    
    jmp BatDatoteka
    
; -----------------------------------------------------------------
; Ne postoji zadata datoteka sa ekstenzijom .BIN, .COM ili .BAT
; -----------------------------------------------------------------
ProveriPath:
	mov word ax, [tempBrojac]
	cmp		ax, 0
	jne		.JelKraj					; Ako je u tempBrojac druga vrednost osim nule
										; potrebno je proveriti da li smo na kraju putanje
	mov		si, PathSpace
	cmp byte [si], 0
	je near	NijeKomanda
.Nastavi:
	dec		si
	xor		cx, cx

.UcitajPath:
	inc		ax
	inc 	si
	cmp	byte [si], ';'
	je		.Zavrsen
	mov		di, .tempPath
	add		di, cx
	mov		bl, [si]
	mov	byte [di], bl
	inc		cx
	jmp		.UcitajPath
		
.Zavrsen:
	mov		di, .tempPath
	add		di, cx
	mov byte [di], 0
	mov	word [tempBrojac], ax
	mov		ax, .tempPath
	clc
	call	_test_path
	jc		ProveriPath
	clc
	call	_change_folder_path
	jc		ProveriPath
	jmp		ProveriIzvrsnu

.JelKraj:
	mov		si, PathSpace
	add		si, ax
	cmp byte [si], 0
	je		.Gotovo
	jmp		.Nastavi

.Gotovo:
	mov word [tempBrojac], 0
	jmp		NijeKomanda
	.tempPath times 128 db 0
	tempBrojac		dw 0

NijeKomanda:
    mov     si, NePostoji
    call    _print_string
    jmp     Komanda
	
; -----------------------------------------------------------------
; Interne komande
; -----------------------------------------------------------------

print_help:
    mov     si, HelpTekst
    call    _print_string
    jmp     Komanda

; ------------------------------------------------------------------

clear_screen:
    call    _clear_screen
    jmp     Komanda

; ------------------------------------------------------------------

print_time:
    mov     bx, tmp_string
    call    _get_time_string
    mov     si, bx
    call    _print_string
    call    _print_newline
    jmp     Komanda

; ------------------------------------------------------------------

print_date:
    mov     bx, tmp_string
    call    _get_date_string
    mov     si, bx
    call    _print_string
    call    _print_newline
    jmp     Komanda

; ------------------------------------------------------------------

print_ver:
    mov     si, verzija
    call    _print_string
    jmp     Komanda

; -----------------------------------------------------------------

list_directory:
	mov 	si, input
	call _string_parse
	
	cmp		bx, 0
	jne		.ImaPath
	
    mov		si, .Naslov
	call	_print_string
	mov		si, (prompt + 9)			; Path pocetak
	call	_print_string
	mov		si, .CrLf
	call	_print_string
		
	mov     bx, app_start               ; Bafer gde se smesta sadrzaj direktorijuma
    call    _get_dir        
    mov     si, app_start               ; Ispisi sadrzaj bafera
    call    _print_string	
    jmp     Komanda
	
.ImaPath:
	mov		ax, bx						; U AX se nalazi putanja
	push	ax
	mov		bx, app_start				; Bafer sa sadrzajem je u BX
	call	_get_dir_path
	jc near .GreskaPutanje              
    mov    si, .Naslov
	call	_print_string
		pop		ax
	call	_string_uppercase			
	mov		si, ax
	call	_print_string
	mov		si, .CrLf
	call	_print_string
	mov     si, app_start               ; Ispisi sadrzaj bafera
    call    _print_string
	jmp 	Komanda

.GreskaPutanje:
    mov     si, Err_WP
    call    _print_string
	jmp 	Komanda

    .Naslov db 13,10, ' Sadrzaj direktorijuma: ', 0
	.CrLf   db  13, 10, 10, 0
; ------------------------------------------------------------------

attributes:
    mov     si, input
    call    _string_parse
    cmp     bx, 0
    je      .GreskaArgumenta
    cmp     cx, 0
    je      .GreskaArgumenta       
    mov     ax, bx
    call    _file_exists
    jc      .NePostoji
    mov     ax, cx
    call    _string_length
    cmp     ax, 2
    jne     .GreskaArgumenta
    mov     ax, bx
    call    _change_attrib
    jc      .GreskaArgumenta
    jmp     Komanda

.NePostoji:
    mov     si, DatNePostoji            ; Datoteka ne postoji
    call    _print_string
    jmp     Komanda 
	
.GreskaArgumenta:
    mov     si, GreskaArgStr
    call    _print_string
    jmp     Komanda

; ------------------------------------------------------------------

pids:
    call    _print_pids
    jmp     Komanda
		
; ------------------------------------------------------------------

kill:
    mov     si, input
    call    _string_parse
    cmp     bx, 0
    jne     .ZadatPid
    mov     si, NemaPid
    call    _print_string
    jmp     Komanda

.ZadatPid:
    mov     si, bx
    call    _string_to_int

    cmp     ax, 0
    je      .LosPid
    cmp     ax, 28
    jg      .LosPid

    call    _kill_pid

    mov     si, UspesnoUbijenSt
    call    _print_string
    call    _print_dec
    mov     si, UspesnoUbijenEd
    call    _print_string

    jmp     .Kraj

.LosPid:
    mov     si, LosPid
    call    _print_string

.Kraj:
    jmp     Komanda
                
; ------------------------------------------------------------------

cat_file:  
	mov     si, input
    call    _string_parse
    cmp     bx, 0                       ; Da li je zadato i ime datoteke?
    jne     .ZadatoIme
    mov     si, NemaImena               ; Ako nije, ispisati poruku o gresci
    call    _print_string
    jmp     Komanda

.ZadatoIme:
    mov     ax, bx
    call    _file_exists                ; Da li postoji odredisna datoteka ?
    jc     .NePostoji
    mov cx, app_start                   ; Mozemo da ucitamo datoteku ovde, jer ne ucitavamo program
    call    _load_file
    mov word [Velicina], bx
    cmp     bx, 0                       ; Datoteka prazna (nula bajtova)?
    je      Komanda                     ; Ako jeste, nemamo sta da ispisemo. 
	
    mov     si, app_start
    mov     ah, 0Eh                     ; BIOS teletype funkcija
.Sledeci:
    lodsb                               ; Uzmi bajt iz ucitane datoteke
    cmp     al, 0Ah                     ; Idi na pocetak novog reda ukoliko je ucitani bajt 0Ah (Unix text)
    jne    .NijeNoviRed                 ; Isto uraditi i ako je OAh, 0Dh (ovaj drugi se ignorise)
    call    _get_cursor_pos
    mov     dl, 0
    call    _move_cursor
.NijeNoviRed:
    int     10h                         ; Ispisi znak
	dec     bx                          ; Racunaj velicinu datoteke
    call 	provera						; Posle ispisa karatera proverava se da li su pritisnuti CTRL + S tasteri
	cmp     bx, 0                       ; Da li je kraj datoteke?
	jne    .Sledeci
    jmp     Komanda                     ; Ovo je kraj datoteke. Idi u prompt.
	
.NePostoji:
    mov     si, DatNePostoji
    call    _print_string
    jmp     Komanda
			
; ------------------------------------------------------------------
;  	Funkcija za stopiranje ispisa komande TYPE/CAT
;   CTRL + S za stopiranje
;   CTRL + Q za nastavljanje ispisa
; ------------------------------------------------------------------
provera:
    push    ax						
    in      al, 60h	                    ; Citanje sken koda iz I/O registra tastature
    cmp     al, 1fh	                    ; Poredjenje sken koda sa sken kodom tastera S 
    jne     .kraj                       ; U koliko nije pritisnut taster S izlazimo na kraj
	
    mov     ah, 02h                     ; Provera da li je pritisnut taster CTRL pomocu prekida 16h funkcija 02h.
    int     16h                         ; U AL upisuje bajt koji predstavljaju flagove tastature (treci bit je za CTRL taster)
    or      al, 11111011b               ; Da bi proverili treci bit, radimo logicko ili po bitovima i
    cmp     al, 11111111b               ; ukoliko je rezultat 11111111 onda znamo da je pritisnut taster CTRL.
    jne     .kraj                       ; U suprotnom nije pritusnut taster CTRL i idemo na kraj.
    jmp     .cekajNaStart					
	
.kraj:
    pop     ax
    ret
                                        ; Kada su pritisnuti CTRL i S ulazi se u ovaj deo koda koji se vrti u krug
.cekajNaStart:                              ; dok se ne pritisne CTRL + Q.
    in      al, 60h					
    cmp     al, 10h                     ; Citanje sken koda, samo sto sad gledamo da li je pritisnut taster Q
    jne     .cekajNaStart               ; Ukoliko nije probaj ponovo.
	
    mov     ah, 02h                     ; Kao i gore proverava se da li je pritisnut taster CTRL
    int     16h 
    or      al, 11111011b
    cmp     al, 11111111b
    jne     .cekajNaStart               ; Ukoliko nije pritisnut probaj ponovo.
    jmp     .kraj                       ; CTRL + Q je pritisnutno i izlazimo na kraj.
	
del_file:
    mov     si, input
    call    _string_parse
    cmp     bx, 0                       ; Da li je zadato i ime datoteke?
    jne    .ZadatoIme

    mov     si, NemaImena               ; Ako nije, ispisati poruku o gresci
    call    _print_string
    jmp     Komanda

.ZadatoIme:
    mov     ax, bx
    call    _file_exists                ; Da li datoteka postoji?
    jc     .NePostoji
    call    _remove_file                ; Obrisi datoteku               
    jmp     Komanda 

.NePostoji:
    mov     si, DatNePostoji            ; Datoteka ne postoji
    call    _print_string
    jmp     Komanda    
    
; ------------------------------------------------------------------

ren_file:
    mov     si, input
    call    _string_parse
    cmp     bx, 0                       ; Da je zadato ime datoteke?
    jne    .ZadatoIme

    mov     si, NemaImena               ; Ako nije, ispisati poruku o gresci
    call    _print_string
    jmp     Komanda

.ZadatoIme:
    mov     ax, bx
    call    _file_exists                ; Da li datoteka postoji?
    jc     .NePostoji

    cmp     cx, 0                       ; Da li je zadato i ime odrdisne datoteke?
    jne    .Zadato2Ime

    mov     si, NemaImena2              ; Ako nije, ispisati poruku o gresci
    call    _print_string
    jmp     Komanda

.Zadato2Ime:
    mov     ax, cx
    call    _file_exists                ; Da li odredisna datoteka sa tim imenom vec postoji?
    jnc    .DuploIme    

    mov     ax, bx                      ; Pripremi parametre za kernel funkciju
    mov     bx, cx
    call    _rename_file                ; Preimenuj datoteku
    jc near GreskaPisanja
    jmp     Komanda              

.NePostoji:
    mov     si, DatNePostoji            ; Izvorna datoteka ne postoji
    call    _print_string
    jmp     Komanda    

.DuploIme:                                  ; Odredisna datoteka sa tim imenom vec postoji
    mov     si, VecPostoji
    call    _print_string
    jmp     Komanda    
    
; --------------------------------------------------------------------

copy_file:
    mov     si, input
    call    _string_parse 

    mov     si, bx
    mov     di, .file1
    call    _string_copy 

    mov     si, cx
    mov     di, .file2
    call    _string_copy 

    cmp     bx, 0                       ; Da li je zadato i ime datoteke? 
    jne    .ZadatoIme

    mov     si, NemaImena               ; Ako nije, ispisati poruku o gresci
    call    _print_string
    jmp     Komanda

.ZadatoIme:
    mov     ax, bx
    call    _file_exists                ; Da li postoji izvorna datoteka?
    jc     .NePostoji
    cmp     cx, 0                       ; Da li je zadato ime odredisne datoteke?
    jne    .Zadato2Ime
    mov     si, NemaImena2              ; Ako nije, ispisati poruku o gresci
    call    _print_string
    jmp     Komanda

.Zadato2Ime:
    mov     ax, cx
    call    _file_exists                ; Da li vec postoji datoteka sa tim imenom?
    jnc    .DuploIme    

    mov     ax, .file1
    mov     cx, app_start               ; Lokacija gde se ucitava datoteka
    call    _load_file 

    cmp     bx, app_start -1            ; Da li je datoteka veca od 32KB?
    jg     .SuviseVelika                ; To bi znacilo da ulazimo u memoriju rezervisanu za kernel.

    mov     cx, bx                      ; Broj bajtova  
    mov     bx, app_start               ; Lokacija pocetka bafera

    mov     ax, .file2  
    call    _write_file                 ; Upisi u odredisnu datoteku
    jc near GreskaPisanja
    jmp     Komanda              

.NePostoji:                                 ; Izvorna datoteka ne postoji
    mov     si, DatNePostoji
    call    _print_string
    jmp     Komanda    

.DuploIme:                                  ; Vec postoji odredisna datoteka sa zadatim imenom
    mov     si, VecPostoji
    call    _print_string
    jmp     Komanda    

.SuviseVelika:                              ; Datoteka veca od 3KB
    mov     si, DatPrevelika
    call    _print_string
    jmp     Komanda 

.file1    times 12 db 0
.file2    times 12 db 0  

; ------------------------------------------------------------------
make_dir:
	mov 	si, input
	call    _string_parse
	cmp		bx, 0
	jne		.ImaIme
	
	mov     si, NemaImena1               ; Ako nema, ispisati poruku o gresci
    call    _print_string
    jmp     Komanda
	
.ImaIme:
	mov		ax, bx
	call    _create_folder
	jmp     Komanda
; ------------------------------------------------------------------		
change_dir:
	mov 	si, input
	call    _string_parse
	cmp		bx, 0
	jne		.ImaIme
	mov     si, NemaImena1               ; Ako nema, ispisati poruku o gresci
    call    _print_string
    jmp     Komanda
	
.ImaIme:
	mov		ax, bx
	call 	_cd_path
	jc near path.NoPath
	mov		si, bx
	cmp byte [si+1], ':'
	je		.Apsolutna
	dec		si
    
.UkloniSlasheve:
	inc 	si
	cmp byte [si], DELIMIT
	je		.Nasao
	cmp	byte [si], 0
	je		.Nastavak
	jmp		.UkloniSlasheve
	
.Nasao:	
	mov byte [si], 0
	jmp		.UkloniSlasheve
	
.Nastavak:
	mov byte [si+1], 0
	mov		si, bx
	xor		ax, ax
	push	ax	
.Loop:
	pop		ax
	add		si, ax
	mov		ax, si
	call	_string_length
	cmp		ax, 0
	je		Komanda
	inc		ax
	push 	ax
	mov		di, .DotDot
	clc
	call 	_string_compare
	jc		.Oduzmi
.Dodaj:
	mov		ax, prompt
	mov		bx, si
	mov		cx, prompt
	call	_string_join
	mov		ax, prompt
	mov		bx, .Slash
	call	_string_join
	jmp 	.Loop
.Oduzmi:
	mov		di, prompt
	dec		di
.DoNule:
	inc		di
	cmp	byte [di], 0
	jne		.DoNule
	dec		di
.Brisi:
	dec		di
	cmp	byte [di], DELIMIT
	je	    .Loop
	mov	byte [di], 0
	jmp	    .Brisi

.Apsolutna:
	mov		di, prompt
	xor		al, al
	mov		[di+9], al
	mov		ax, di
	mov		bx, si
	mov		cx, prompt
	call	_string_join
	
	call	_string_reverse
	cmp byte [si], DELIMIT
	jne		.FaliSlash
	jmp		Komanda
.FaliSlash:
	mov		bx, .Slash
	call	_string_join
	jmp		Komanda
	
	.Slash	db DELIMIT, 0
	.DotDot db '..',0
; ------------------------------------------------------------------		
remove_dir:
	mov 	si, input
	call    _string_parse
	
	cmp		bx, 0
	jne		.ImaIme
	
	mov     si, NemaImena1                  ; Ako nije, ispisati poruku o gresci
    call    _print_string
    jmp     Komanda
	
.ImaIme:
	mov		ax, bx
	call 	_check_and_remove
	jc 		near path.NoEmpty             
	jmp 	Komanda

; ------------------------------------------------------------------		
change_disc:
	mov		si, input
	call	_change_disc
	mov		si, prompt
	mov		ax, 12
	call	_string_truncate
	mov		al, [input]
	mov	byte [si+9], al
	jmp 	Komanda
	
; ------------------------------------------------------------------		
path:
	mov 	si, input
	call    _string_parse	
	cmp		bx, 0
	jne		.ImaIme
	mov     si, PathSpace					; Ako nije zadata putanja, ispisuje sadrzaj          
    call    _print_string                   ; promenljive okruzenja PATH	
	jmp     Komanda
	
.ImaIme:
	mov		ax, bx
	mov		si, bx
	cmp	byte [si+1], ':'
	jne 	.ProveriClear					; Ako nije apsolutna putanja
	call 	_test_path
	jc 		.NoPath					        ; Ako path ne postoji        
	mov		ax, PathSpace
	mov		cx, PathSpace
	call	_string_join
	mov		bx, .tz
	call	_string_join
	jmp 	Komanda
.ProveriClear:
	mov		di, .clear
	call	_string_compare
	jnc		.NoClear                   
	mov		si, PathSpace
	mov byte [si], 0 
	jmp		Komanda

.NoPath:
    mov     si, Err_NP
    call    _print_string
    jmp     Komanda
    
.NoClear:
    mov     si, Err_NC
    call    _print_string
    jmp     Komanda

.NoEmpty:
    mov     si, Err_NE
    call    _print_string
    jmp     Komanda
    
.tz    db ';', 0
.clear db 'CLEAR', 0
; ------------------------------------------------------------------
exit:
    ; Ne zelimo da dodje do promene procesa
    cli                                 ; Zabrani prekide. 
    mov al, 080h                        ; Zabrani NMI prekide
    out 070h, al

    ret
; ------------------------------------------------------------------

kern_warning:                               ; Kernel ne moze da se izvrsava kao aplikacija
    mov     si, NeMozeKernel
    call    _print_string
    jmp     Komanda
    
; ------------------------------------------------------------------
GreskaPisanja:                              ; Zajednicko za sve operacije koje imaju upisivanje na disk
    mov		si, Greska_pisanja
	call	_print_string
    jmp     Komanda 
; ------------------------------------------------------------------

    tmp_string      times 15 db 0
    arg0            times 32 db 0
    Velicina        dw 0

    BinEkstenzija   db 'BIN', 0
    ComEkstenzija   db 'COM', 0
    BatEkstenzija   db 'BAT', 0

    prompt          db 13,10,'RAF_OS>A:/', 0
    dodatniProstor	times 256 db 0
    HelpTekst       db 'Interne komande:',13,10,
                    db 'DIR, TYPE, CLS, HELP, TIME, DATE, VER, COPY, REN, DEL, STOP, MD, RD, CD, PATH, ATTRIB, PIDS, KILL', 13, 10, 0
    NePostoji       db 'Ne postoji takva komanda ili program', 13, 10, 0
    NemaImena       db 'Nije zadato ime datoteke', 13, 10, 0
    NemaImena1      db 'Nije zadato ime direktorijuma', 13, 10, 0
    NemaImena2      db 'Nije zadato ime odredisne datoteke', 13, 10, 0
    DatNePostoji    db 'Datoteka ne postoji', 13, 10, 0
    VecPostoji      db 'Datoteka sa odredisnim imenom vec postoji', 13, 10, 0
    DatPrevelika    db 'Izvorna datoteka je suvise velika (max 32KB)', 0
    verzija         db 'RAF_OS', RAF_OS_VER, 13, 10, 0
    pozdrav         db 13,10,'Dobrodosli u Trivijalni skolski operativni sistem: ',0
    Greska_pisanja	db 'Greska upisivanja na disk', 13, 10, 0
    Err_NP          db 'Zadata putanja ne postoji', 13, 10, 0
    Err_NC          db 'Neispravan parametar za PATH', 13, 10, 0
    Err_NE          db 'Direktorijum nije prazan', 13, 10, 0
    Err_WP          db 'Neispravna putanja', 13, 10, 0
    GreskaArgStr    db 'ATTRIB: Greska u argumentima.', 13, 10, 0
    NemaBatInterpreter db 'Ne postoji implementacija Bat interpretera za RAF_OS', 13, 10, 0

    NemaPid         db 'Nije zadat pid procesa', 13, 10, 0
    LosPid          db 'Pid mora biti izmedju 1 i 28', 13, 10, 0
    UspesnoUbijenSt db 'Proces sa pid-om ', 0
    UspesnoUbijenEd db ' uspesno ubijen', 13, 10, 0

    exit_string     db 'STOP', 0
    help_string     db 'HELP', 0
    cls_string      db 'CLS', 0
    dir_string      db 'DIR', 0
    ls_string       db 'LS', 0
    time_string     db 'TIME', 0
    date_string     db 'DATE', 0
    ver_string      db 'VER', 0
    cat_string      db 'CAT', 0
    type_string     db 'TYPE', 0
    copy_string     db 'COPY', 0
    cp_string       db 'CP', 0
    ren_string      db 'REN', 0
    del_string      db 'DEL', 0
    rm_string       db 'RM', 0
    md_string  	db 'MD', 0
    cd_string	db 'CD', 0
    rd_string	db 'RD', 0
    a_string	db 'A:', 0
    b_string	db 'B:', 0
    path_string	db 'PATH', 0
    attrib_string   db 'ATTRIB', 0
    pids_string     db 'PIDS', 0
    kill_string     db 'KILL', 0
    fg_string       db '--FG', 0
    bg_string       db '--BG', 0

    autoexec_string db 'AUTOEXEC.BAT', 0		
    kern_string     db 'KERNEL.BIN', 0
    NeMozeKernel    db 'Nije moguce izvrsavati datoteku kernela!', 13, 10, 0

    PathSpace		times 256 db 0
    temp_input		times 128 db 0

  