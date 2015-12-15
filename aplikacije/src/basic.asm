; ==================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ==================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; BAS Interpreter
;
; ------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
; ------------------------------------------------------------------

	%include "OS_API.inc"
	org app_main
	bas_start equ app_main + 2000h

; ------------------------------------------------------    
; Ime datoteke mora da se zada preko komandne linije.
; ------------------------------------------------------

Start:
	    cmp     byte [arg1], 0              ; Da li je zadato ime datoteke?
        jne     .ZadatoIme
        mov     si, NijeZadatoIme           ; Ako nije, ispisati poruku o gresci
        call    _print_string
        ret
		
.ZadatoIme:
		mov     si, arg1                    ; Da li zadata eksterna komada ima tacku u imenu datoteke?
        mov     al, '.'
        call    _find_char_in_string
        cmp     ax, 0
        je      .Sufiks
        jmp     .PunoIme                     ; Ako ima tacku, proveravamo puno ime
		
.Sufiks:
		mov     ax, arg1                    ; Ako nema tacku, dodajemo sufiks .BAS
        call    _string_length
        mov     si, arg1                    ; AX sada sadrzi duzinu stringa       
        add     si, ax                      ; SI pokazuje na kraj stringa         

        mov     byte [si], '.'
        mov     byte [si+1], 'B'
        mov     byte [si+2], 'A'
        mov     byte [si+3], 'S'
        mov     byte [si+4], 0	            ; String . BAS zavrsavamo nulom  
		
.PunoIme:
		mov     ax, arg1
        call    _string_length
        mov     si, arg1
        add     si, ax
        sub     si, 3                       ; Provera ekstenzije 

        mov     di, BasEkstenzija           ; Da li je 'BAS'
        call    _string_compare
        jc		.DaLiPostoji                ; Ako nije, tada sistem ne moze da izvrsi program
		mov     si, NijeBasDatoteka           ; Ako nije, ispisati poruku o gresci
        call    _print_string
        ret
		
.DaLiPostoji:
		mov     ax, arg1                    ; Ucitavamo datoteku
        mov     bx, 0                       ; arg1 je ime .bas datoteke koje treba ucitati
        mov     cx, bas_start               ; Adresa gde pocinje datoteka                
        call    _load_file                  ; CF = 1 ukoliko nema trazene datoteke
	    mov     ax, bas_start               
		jnc 	run_bas
		mov		si, DatotekaNePostoji
		call	_print_string
		ret
		
	
	
	
; ------------------------------------------------------------------
; Vrste tokena

%define PROMENLJIVA 1
%define STRING_PROM 2
%define BROJ 3
%define STRING 4
%define NAVODNIK 5
%define ZNAK 6
%define NEPOZNAT 7
%define LABELA 8


; --------------------------------------------
; Ovde pocinje izvrsavanje BASIC intepretera
; --------------------------------------------

run_bas:
		mov     ax, bas_start  
        mov word [OrigStek], sp             ; Cuvamo originalni stek pointer, za neki neplanirani slucaj 
        mov word [PocTeksta], ax            ; AX sadrzi pocetak BASIC teksta
        mov word [Linija], ax               ; Linija je brojac tekucih BASIC linija
        add     bx, ax                      ; Velicina .BAS datoteke
        dec     bx
        dec     bx
        mov word [KrajTeksta], bx           ; Zadnji bajt u BASIC programu
        call    BrisiRAM                    ; Anuliramo memoriju (eventualni ostatak prethodnog izvrsavanja)

GlavnaPetlja:
        call    UzmiToken                   ; Uzimamo token sa pocetka linije
        cmp     ax, STRING                  ; Da li je u pitanju string ili znak?
        je     .KljucnaRec                  ; Ako jeste, proveravamo da li je u pitanju kljucna rec.
        cmp     ax, PROMENLJIVA             ; Ako je to promenljiva, da li je u pitanju dodela
        je near Dodela                      ; vrednosti (npr. "X = Y + 5")
        cmp     ax, STRING_PROM             ; Isto to za string promenljivu (npr. $1)
        je near Dodela
        cmp     ax, LABELA                  ; Ako je labela, onda preskoci
        je      GlavnaPetlja
        mov     si, Sintaksa                ; Ako nije nista od navedenog, ispisi poruku o gresci
        jmp     Greska

.KljucnaRec:
        mov     si, Token                   ; Da li je neka od naredbi (kljucnih reci)
        mov     di, alert_cmd
        call    _string_compare
        jc near do_alert

        mov     di, call_cmd
        call    _string_compare
        jc near do_call

        mov     di, cls_cmd
        call    _string_compare
        jc near do_cls

        mov     di, cursor_cmd
        call    _string_compare
        jc near do_cursor

        mov     di, curschar_cmd
        call    _string_compare
        jc near do_curschar

        mov     di, end_cmd
        call    _string_compare
        jc near do_end

        mov     di, for_cmd
        call    _string_compare
        jc near do_for

        mov     di, getkey_cmd
        call    _string_compare
        jc near do_getkey

        mov     di, gosub_cmd
        call    _string_compare
        jc near do_gosub

        mov     di, goto_cmd
        call    _string_compare
        jc near do_goto

        mov     di, input_cmd
        call    _string_compare
        jc near do_input

        mov     di, if_cmd
        call    _string_compare
        jc near do_if

        mov     di, load_cmd
        call    _string_compare
        jc near do_load

        mov     di, move_cmd
        call    _string_compare
        jc near do_move

        mov     di, next_cmd
        call    _string_compare
        jc near do_next

        mov     di, pause_cmd
        call    _string_compare
        jc near do_pause

        mov     di, peek_cmd
        call    _string_compare
        jc near do_peek

        mov     di, poke_cmd
        call    _string_compare
        jc near do_poke

        mov     di, port_cmd
        call    _string_compare
        jc near do_port

        mov     di, print_cmd
        call    _string_compare
        jc near do_print

        mov     di, rand_cmd
        call    _string_compare
        jc near do_rand

        mov     di, rem_cmd
        call    _string_compare
        jc near do_rem

        mov     di, return_cmd
        call    _string_compare
        jc near do_return

        mov     di, save_cmd
        call    _string_compare
        jc near do_save

        mov     di, serial_cmd
        call    _string_compare
        jc near do_serial

        mov     di, sound_cmd
        call    _string_compare
        jc near do_sound

        mov     di, waitkey_cmd
        call    _string_compare
        jc near do_waitkey

        mov     si, NemaNaredbe             ; Naredba ne postoji
        jmp     Greska

; ----------------------------------------------------------------
; Brisemo (anuliramo) memoriju koji koristi BASIC
; Zbog toga ce sve promenljive biti inicijalizovane na vrednost 0 
; ----------------------------------------------------------------

BrisiRAM:
        mov     al, 0
        mov     di, Promenljive
        mov     cx, 52
    rep stosb
    
        mov     di, ForPromenljive
        mov     cx, 52
    rep stosb
    
        mov     di, ForBroj
        mov     cx, 52
	rep stosb
    
        mov byte [Dubina], 0              
        mov     di, GosubBroj
        mov     cx, 20
	rep stosb
    
        mov     di, StringProm
        mov     cx, 1024
	rep stosb
    
        ret

; -----------------------
; Dodeljivanje vrednosti
; -----------------------

Dodela:
        cmp     ax, PROMENLJIVA             ; Da li pocinjemo sa brojnom promenljivom?
        je     .Brojna
        mov     di, StringProm              ; Ako ne, onda je to string promenljiva
        mov     ax, 128
        mul     bx                          ; (BX = broj stringa koji je dobijen od UzmiToken)
        add     di, ax
        push    di
        call    UzmiToken
        mov byte al, [Token]
        cmp     al, '='
        jne near .Greska
        call    UzmiToken
        cmp     ax, NAVODNIK
        je     .DrugiJeNavodnik
        cmp     ax, STRING_PROM
        jne near .Greska
        mov     si, StringProm	           
        mov     ax, 128
        mul     bx                         
        add     si, ax
        pop     di
        call    _string_copy
        jmp     GlavnaPetlja

.DrugiJeNavodnik:
        mov     si, Token
        pop     di
        call    _string_copy
        jmp     GlavnaPetlja

.Brojna:
        mov     ax, 0
        mov byte al, [Token]
        mov byte [.tmp], al
        call    UzmiToken
        mov byte al, [Token]
        cmp     al, '='
        jne near .Greska
        call    UzmiToken
        cmp     ax, BROJ
        je     .DrugiJeBroj
        cmp     ax, PROMENLJIVA
        je     .DrugiJeProm
        cmp     ax, STRING
        je near .DrugiJeString
        cmp     ax, NEPOZNAT
        jne near .Greska
        mov byte al, [Token]                ; Adresa string promenljive?
        cmp     al, '&'
        jne near .Greska
        call    UzmiToken                   ; Da li postoji string promenljiva
        cmp     ax, STRING_PROM
        jne near .Greska
        mov     di, StringProm
        mov     ax, 128
        mul     bx
        add     di, ax
        mov     bx, di
        mov byte al, [.tmp]
        call    Postavi
        jmp     GlavnaPetlja

.DrugiJeProm:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        mov     bx, ax
        mov byte al, [.tmp]
        call    Postavi
        jmp    .DaLiImaJos

.DrugiJeBroj:
        mov     si, Token
        call    _string_to_int
        mov     bx, ax                      ; Broj koji treba ubaciti u tabelu promenljivih
        mov     ax, 0
        mov byte al, [.tmp]
        call    Postavi

; -----------------------------------------------------------------
; Dodeljivanje moze da bude jednostavno, kao npr. "A = 3", itd. 
; Medjutim, moze da bude komplikovanije, kao npr. "A = B + 3".
; Ovde proveravamo da li postoji delimiter (aritmeticka operacija).
; -----------------------------------------------------------------

.DaLiImaJos:
        mov word ax, [Linija]               ; Sacuvati lokaciju BASIC koda, za slucaj da nema delimitera
        mov word [.Privremeno], ax
        call    UzmiToken                   ; Da li ima jos stavki za ovu dodelu?
        mov byte al, [Token]
        cmp     al, '+'
        je     .ImaJos
        cmp     al, '-'
        je     .ImaJos
        cmp     al, '*'
        je     .ImaJos
        cmp     al, '/'
        je     .ImaJos
        cmp     al, '%'
        je     .ImaJos
        mov word ax, [.Privremeno]          ; Nije delimiter. Vracamo se nazad jedan korak ispred tokena.
        mov word [Linija], ax                
        jmp     GlavnaPetlja                 

.ImaJos:
        mov byte [.Delimiter], al
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        je     .Prom
        mov     si, Token
        call    _string_to_int
        mov     bx, ax
        mov     ax, 0
        mov byte al, [.tmp]
        call    Vrednost                    
        cmp byte [.Delimiter], '+'
        jne    .NijePlus
        add     ax, bx
        jmp    .Zavrsi

.NijePlus:
        cmp byte [.Delimiter], '-'
        jne    .NijeMinus
        sub     ax, bx
        jmp    .Zavrsi

.NijeMinus:
        cmp byte [.Delimiter], '*'
        jne    .NijePuta
        mul     bx
        jmp    .Zavrsi

.NijePuta:
        cmp byte [.Delimiter], '/'
        jne    .NijePodeljeno
        mov     dx, 0
        div     bx
        jmp    .Zavrsi

.NijePodeljeno:
        mov     dx, 0
        div     bx
        mov     ax, dx                      ; MOD. DX sadrzi ostatak

.Zavrsi:
        mov     bx, ax
        mov byte al, [.tmp]
        call    Postavi
        jmp    .DaLiImaJos

.Prom:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        mov     bx, ax
        mov     ax, 0
        mov byte al, [.tmp]
        call    Vrednost
        cmp byte [.Delimiter], '+'
        jne    .PromNijePlus
        add     ax, bx
        jmp    .PromZavrsi

.PromNijePlus:
        cmp byte [.Delimiter], '-'
        jne    .PromNijeMinus
        sub     ax, bx
        jmp    .PromZavrsi

.PromNijeMinus:
        cmp byte [.Delimiter], '*'
        jne    .PromNijePuta
        mul     bx
        jmp    .PromZavrsi

.PromNijePuta:
        cmp byte [.Delimiter], '/'
        jne    .PromNijePod
        mov     dx, 0
        div     bx
        jmp    .Zavrsi

.PromNijePod:
        mov     dx, 0
        div     bx
        mov     ax, dx                      ; DX sadrzi ostatak

.PromZavrsi:
        mov     bx, ax
        mov byte al, [.tmp]
        call    Postavi
        jmp    .DaLiImaJos

.DrugiJeString:
        mov     di, Token
        mov     si, progstart_keyword
        call    _string_compare
        je     .DaLiJeStart
        mov     si, ramstart_keyword
        call    _string_compare
        je     .DaLiJeRAM
        jmp    .Greska

.DaLiJeStart:
        mov     ax, 0
        mov byte al, [.tmp]
        mov word bx, [PocTeksta]
        call    Postavi
        jmp     GlavnaPetlja

.DaLiJeRAM:
        mov     ax, 0
        mov byte al, [.tmp]
        mov word bx, [KrajTeksta]
        inc     bx
        inc     bx
        inc     bx
        call    Postavi
        jmp     GlavnaPetlja

.Greska:
        mov     si, Sintaksa
        jmp     Greska

    .tmp            db 0
    .Privremeno     dw 0
    .Delimiter      db 0


; =====================================
; BASIC instrukcije (po abecednom redu)
; =====================================
; ------------
; ALERT
; ------------

do_alert:
        call    UzmiToken
        cmp     ax, NAVODNIK
        je     .Jeste
        mov     si, Sintaksa
        jmp     Greska

.Jeste:
        mov     ax, Token                   ; Prvi string u dialog boksu
        mov     bx, 0                       ; Ostali se ne koriste
        mov     cx, 0            
        call    _dialog_box
        call    _clear_screen
        jmp     GlavnaPetlja

; ------------
; CALL
; ------------

do_call:
        call    UzmiToken
        cmp     ax, BROJ
        je     .Broj
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        jmp    .IzvrsiPoziv

.Broj:
        mov     si, Token
        call    _string_to_int

.IzvrsiPoziv:
        mov     bx, 0
        mov     cx, 0
        mov     dx, 0
        mov     di, 0
        mov     si, 0
        call    ax
        jmp     GlavnaPetlja

; ------------
; CLS
; ------------

do_cls:
        call    _clear_screen
        jmp     GlavnaPetlja

; ------------
; CURSOR
; ------------

do_cursor:
        call    UzmiToken
        mov     si, Token
        mov     di, .DaString
        call    _string_compare
        jc     .Ukljuci
        mov     si, Token
        mov     di, .NeString
        call    _string_compare
        jc     .Iskljuci
        mov     si, Sintaksa
        jmp     Greska

.Ukljuci:
        call    _show_cursor
        jmp     GlavnaPetlja

.Iskljuci:
        call    _hide_cursor
        jmp     GlavnaPetlja

    .DaString    db "ON", 0
    .NeString    db "OFF", 0

; ------------
; CURSCHAR
; ------------

do_curschar:
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        je     .JesteProm
        mov     si, Sintaksa
        jmp     Greska

.JesteProm:
        mov     ax, 0
        mov byte al, [Token]
        push    ax                          ; Sacuvacemo promenljivu koju cemo da koristimo
        mov     ah, 08h
        mov     bx, 0
        int     10h                         ; Koji je znak na trenutnoj poziciji kursora
        mov     bx, 0                       ; Interesuje nas samo nizi bajt (znak, a ne i atribut)
        mov     bl, al
        pop     ax                          ; Vracamo nazad promenljivu
        call    Postavi                     ; i cuvamo vrednost
        jmp     GlavnaPetlja

; ------------
; END
; ------------

do_end:
        mov word sp, [OrigStek]
        ret

; ------------
; FOR
; ------------

do_for:
        call    UzmiToken                   ; Promenljiva koju koristimo u ovoj petlji
        cmp     ax, PROMENLJIVA
        jne near .Greska
        mov     ax, 0
        mov byte al, [Token]
        mov byte [.Privremeno], al          ; Privremeno je cuvamo
        call    UzmiToken
        mov     ax, 0                       ; Da li se iza nje nalazi znak '=' ?
        mov byte al, [Token]
        cmp     al, '='
        jne    .Greska
        call    UzmiToken                   ; Sledece sto nam treba je broj
        cmp     ax, BROJ
        jne    .Greska
        mov     si, Token                   ; Konvertujemo string u trazeni broj
        call    _string_to_int

; --------------------------------------------------------
; U ovom trenutku procitali smo nesto kao npr. "FOR X = 1"
; Sacuvajmo taj broj (ovde je to 1) u tabeli promenljivih
; ---------------------------------------------------------

        mov     bx, ax
        mov     ax, 0
        mov byte al, [.Privremeno]
        call    Postavi
        call    UzmiToken                   ; Trazimo sada frazu "TO"
        cmp     ax, STRING
        jne    .Greska
        mov     ax, Token
        call    _string_uppercase
        mov     si, Token
        mov     di, .StringTO
        call    _string_compare
        jnc    .Greska

; --------------------------------------
; Znaci, sada smo na npr. "FOR X = 1 TO"
; --------------------------------------
	
        call    UzmiToken
        cmp     ax, BROJ
        jne    .Greska
        mov     si, Token                   ; Uzimamo krajnji broj
        call    _string_to_int
        mov     bx, ax
        mov     ax, 0
        mov byte al, [.Privremeno]
        sub     al, 65                      ; Snimamo krajnji broj u tabelu
        mov     di, ForPromenljive
        add     di, ax
        add     di, ax
        mov     ax, bx
        stosw

; ------------------------------------------------------------------------
; Do sada smo ucitali promenljivu, dodelili joj pocetni broj i stavili u 
; tabelu broj do kojeg moze da ide. Medjutim, moramo da sacuvamo i
; mesto u kodu iza FOR linije gde cemo da se vratimo ako NEXT X nije
; zavrsio petlju...
; ------------------------------------------------------------------------

        mov     ax, 0
        mov byte al, [.Privremeno]
        sub     al, 65                      ; Cuvamo u tabeli poziciju u kodu gde cemo da se vratimo
        mov     di, ForBroj
        add     di, ax
        add     di, ax
        mov word ax, [Linija]
        stosw
        jmp     GlavnaPetlja

.Greska:
        mov     si, Sintaksa
        jmp     Greska

    .Privremeno    db 0
    .StringTO      db 'TO', 0

; ------------
; GETKEY
; ------------

do_getkey:
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        je     .JesteProm
        mov     si, Sintaksa
        jmp     Greska

.JesteProm:
        mov     ax, 0
        mov byte al, [Token]
        push    ax
        call    _check_for_key
        mov     bx, 0
        mov     bl, al
        pop     ax
        call    Postavi
        jmp     GlavnaPetlja

; ------------
; GOSUB
; ------------

do_gosub:
        call    UzmiToken                   ; Uzimamo broj linije (labelu)
        cmp     ax, STRING
        je     .JesteString
        mov     si, NemaLabele
        jmp     Greska

.JesteString:
        mov     si, Token                   ; Vracamo se na ovu labelu
        mov     di, .PrivemeniToken
        call    _string_copy
        mov     ax, .PrivemeniToken
        call    _string_length

        mov     di, .PrivemeniToken         ; Dodajemo znak ':' na kraj pre pretrazivanja
        add     di, ax
        mov     al, ':'
        stosb
        mov     al, 0
        stosb	

        inc byte [Dubina]
        mov     ax, 0
        mov byte al, [Dubina]               ; Koji je GOSUB nivo (ugnjezdenja) u pitanju
        cmp     al, 9
        jle    .UGranicama
        mov     si, MaksDubina
        jmp     Greska

.UGranicama:
        mov     di, GosubBroj               ; Idemo u nasu tabelu pointera
        add     di, ax                      ; Tabela je od reci (ne od bajtova)
        add     di, ax
        mov word ax, [Linija]
        stosw                               ; Sacuvati tekucu lokaciju 

        mov word ax, [PocTeksta]
        mov word [Linija], ax	            ; Vracamo sa na pocetak na bismo nasli labelu

.Dalje:
        call    UzmiToken
        cmp     ax, LABELA
        jne    .LinijskaPetlja
        mov     si, Token
        mov     di, .PrivemeniToken
        call    _string_compare
        jc      GlavnaPetlja

.LinijskaPetlja:                            ; Idemo na kraj linije
        mov word si, [Linija]
        mov byte al, [si]
        inc word [Linija]
        cmp     al, 10
        jne    .LinijskaPetlja
        mov word ax, [Linija]
        mov word bx, [KrajTeksta]
        cmp     ax, bx
        jg     .ProsaoKraj
        jmp    .Dalje

.ProsaoKraj:
        mov     si, LabNePostoji
        jmp     Greska

    .PrivemeniToken  times 30 db 0

; ------------
; GOTO     
; ------------

do_goto:
	call UzmiToken                          ; Sledeci token

	cmp ax, STRING
	je .JesteString

	mov si, NemaLabele
	jmp Greska

.JesteString:
	mov si, Token                           ; Sacuvati labelu
	mov di, .PrivemeniToken
	call _string_copy

	mov ax, .PrivemeniToken
	call _string_length

	mov di, .PrivemeniToken                 ; Dodati snak ':' na kraj radi pretrage
	add di, ax
	mov al, ':'
	stosb
	mov al, 0
	stosb	

	mov word ax, [PocTeksta]
	mov word [Linija], ax                   ; Vracamo sa na pocetak na bismo nasli labelu

.Dalje:
	call UzmiToken

	cmp ax, LABELA
	jne .LinijskaPetlja

	mov si, Token
	mov di, .PrivemeniToken
	call _string_compare
	jc GlavnaPetlja

.LinijskaPetlja: 
	mov word si, [Linija]                   ; Idemo na kraj linije
	mov byte al, [si]
	inc word [Linija]

	cmp al, 10
	jne .LinijskaPetlja

	mov word ax, [Linija]
	mov word bx, [KrajTeksta]
	cmp ax, bx
	jg .ProsaoKraj

	jmp .Dalje

.ProsaoKraj:
	mov si, LabNePostoji
	jmp Greska

   .PrivemeniToken times 30 db 0


; ------------
; IF
; ------------

do_if:
        call    UzmiToken
        cmp     ax, PROMENLJIVA             ; Iza IF moze da bude samo promenljiva
        je     .BrojnaProm
        cmp     ax, STRING_PROM
        je near .StringProm
        mov     si, Sintaksa
        jmp     Greska

.BrojnaProm:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        mov     dx, ax                      ; Cuvamo vrednost prvog dela poredjenja
        call    UzmiToken                   ; Uzimamo delimiter
        mov byte al, [Token]
        cmp     al, '='
        je     .Jednako
        cmp     al, '>'
        je     .Vece
        cmp     al, '<'
        je     .Manje
        mov     si, Sintaksa                ; Ako nije nijedan od navedenih, Greska 
        jmp     Greska

.Jednako:
        call    UzmiToken                   ; Da li je ovo tipa 'X = Y' (jednako drugoj promenljivoj?)
        cmp     ax, ZNAK
        je     .ZnakJednako
        mov byte al, [Token]
        call    Slovo
        jc     .PromJednako
        mov     si, Token                   ; Ako ne, onda je to tipa 'X = 1' (znaci broj)
        call    _string_to_int
        cmp     ax, dx                      ; Tazimo kljucnu rec THEN ukoliko je 'X = broj' tacan izraz
        je near .TrazimoTHEN
        jmp    .KrajLinije                  ; U suprotnom preskacemo ostatak linije

.ZnakJednako:
        mov     ax, 0
        mov byte al, [Token]
        cmp     ax, dx
        je near .TrazimoTHEN
        jmp    .KrajLinije

.PromJednako:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        cmp     ax, dx                      ; Da li su vrednosti promenljivih jednake?
        je near .TrazimoTHEN                ; Ako jesu, tazimo kljucnu rec THEN 
        jmp    .KrajLinije                  ; U suprotnom preskacemo ostatak linije

.Vece:
        call    UzmiToken                   ; Da li je vrednost veca od broja ili vrednosti promenljive?
        mov byte al, [Token]
        call    Slovo
        jc     .PromVece
        mov     si, Token                   ; Ovde mora da bude broj ...
        call    _string_to_int
        cmp     ax, dx
        jl near .TrazimoTHEN
        jmp    .KrajLinije

.PromVece:                                  ; Ovde je u pitanju promenljiva
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        cmp     ax, dx                      ; Ovde vrsimo poredjenje
        jl     .TrazimoTHEN                 ; Ako je izraz tacan, tazimo kljucnu rec THEN 
        jmp    .KrajLinije

.Manje:                                     ; Isto vazi i za opraciju "manje"
        call    UzmiToken
        mov byte al, [Token]
        call    Slovo
        jc     .PromManje
        mov     si, Token
        call    _string_to_int
        cmp     ax, dx
        jg     .TrazimoTHEN
        jmp    .KrajLinije

.PromManje:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        cmp     ax, dx
        jg     .TrazimoTHEN
        jmp    .KrajLinije

.StringProm:
        mov byte [.Privremeno], bl
        call    UzmiToken
        mov byte al, [Token]
        cmp     al, '='
        jne    .Greska
        call    UzmiToken
        cmp     ax, STRING_PROM
        je     .DrugiJeStringProm
        cmp     ax, NAVODNIK
        jne    .Greska
	
        mov     si, StringProm
        mov     ax, 128
        mul     bx
        add     si, ax
        mov     di, Token
        call    _string_compare
        je     .TrazimoTHEN
        jmp    .KrajLinije

.DrugiJeStringProm:
        mov     si, StringProm
        mov     ax, 128
        mul     bx
        add     si, ax
        mov     di, StringProm
        mov     bx, 0
        mov byte bl, [.Privremeno]
        mov     ax, 128
        mul     bx
        add     di, ax
        call    _string_compare
        jc     .TrazimoTHEN
        jmp    .KrajLinije

.TrazimoTHEN:
        call    UzmiToken
        mov     si, Token
        mov     di, then_keyword
        call    _string_compare
        jc     .PostojiTHEN
        mov     si, Sintaksa
        jmp     Greska

.PostojiTHEN:                               ; Nastavljamo kao i kodsvake druge naredbe
        jmp     GlavnaPetlja

.KrajLinije:                                ; IF nije ispunjen, zato preskacemo ostatak linije
        mov word si, [Linija]
        mov byte al, [si]
        inc word [Linija]
        cmp     al, 10
        jne    .KrajLinije
        jmp     GlavnaPetlja

.Greska:
        mov     si, Sintaksa
        jmp     Greska

    .Privremeno db 0

; ------------
; INPUT
; ------------

do_input:
        mov     al, 0                       ; Brisemo string zbog prethodne upotrebe
        mov     di, .Privremeno
        mov     cx, 128
    rep stosb
        call    UzmiToken
        cmp     ax, PROMENLJIVA             ; INPUT moze samo u promenljivu
        je     .BrojnaProm
        cmp     ax, STRING_PROM
        je     .StringProm
        mov     si, Sintaksa
        jmp     Greska

.BrojnaProm:
        mov     ax, .Privremeno              ; Ulaz od korisnika
        call    _input_string
        mov     ax, .Privremeno
        call    _string_length
        cmp     ax, 0
        jne    .UnetJeZnak
        mov byte [.Privremeno], '0'          ; Ukoliko je pritisnut Enter, promenljiva je 0
        mov byte [.Privremeno + 1], 0

.UnetJeZnak:
        mov     si, .Privremeno              ; Konvertujemo u celobrjnu vrednost
        call    _string_to_int
        mov     bx, ax
        mov     ax, 0
        mov byte al, [Token]                 ; Adresa promenljive
        call    Postavi                      ; i postavljanje promenljive na unetu vrednost
        call    _print_newline
        jmp     GlavnaPetlja

.StringProm:
        push    bx
        mov     ax, .Privremeno
        call    _input_string
        mov     si, .Privremeno
        mov     di, StringProm
        pop     bx
        mov     ax, 128
        mul     bx
        add     di, ax
        call    _string_copy
        call    _print_newline
        jmp     GlavnaPetlja

    .Privremeno  times 128 db 0

; ------------
; LOAD
; ------------

do_load:
        call    UzmiToken
        cmp     ax, NAVODNIK
        je     .Jeste
        cmp     ax, STRING_PROM
        jne    .Greska
        mov     si, StringProm
        mov     ax, 128
        mul     bx
        add     si, ax
        jmp    .Lokacija

.Jeste:
        mov     si, Token

.Lokacija:
        mov     ax, si
        call    _file_exists
        jc     .NePostoji
        mov     dx, ax                      
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        je     .DrugiJeProm
        cmp     ax, BROJ
        jne    .Greska
        mov     si, Token
        call    _string_to_int

.UcitajDeo:
        mov     cx, ax
        mov     ax, dx
        call    _load_file
        mov     ax, 0
        mov     byte al, 'S'
        call    Postavi
        mov     ax, 0
        mov     byte al, 'R'
        mov     bx, 0
        call    Postavi
        jmp     GlavnaPetlja

.DrugiJeProm:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        jmp    .UcitajDeo

.NePostoji:
        mov     ax, 0
        mov byte al, 'R'
        mov     bx, 1
        call    Postavi
        call    UzmiToken               
        jmp     GlavnaPetlja

.Greska:
        mov     si, Sintaksa
        jmp     Greska

; ------------
; MOVE
; ------------

do_move:
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        je     .PrviJeProm
        mov     si, Token
        call    _string_to_int
        mov     dl, al
        jmp    .Drugi

.PrviJeProm:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        mov     dl, al

.Drugi:
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        je     .DrugiJeProm
        mov     si, Token
        call    _string_to_int
        mov     dh, al
        jmp    .Zavrsi

.DrugiJeProm:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        mov     dh, al

.Zavrsi:
        call    _move_cursor
        jmp     GlavnaPetlja

; ------------
; NEXT
; ------------

do_next:
        call    UzmiToken
        cmp     ax, PROMENLJIVA             ; Iza NEXT mora da se nalazi promenljiva
        jne    .Greska
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        inc     ax                          ; NEXT inkrementira promenljivu
        mov     bx, ax
        mov     ax, 0
        mov byte al, [Token]
        sub     al, 65
        mov     si, ForPromenljive
        add     si, ax
        add     si, ax
        lodsw                               ; Konacni broj ponavljanja iz tabele
        inc     ax                          ; Petlja ukljucije i ovaj broj
        cmp     ax, bx                      ; Da li se vrednosti promenljive i konacnog broja poklapaju
        je     .Kraj
        mov     ax, 0                       ; Ako ne, sacuvaj inkrementiranu vrednost promenljive
        mov byte al, [Token]
        call    Postavi
        mov     ax, 0                       ; Vrati se na izvrsenje linije koja sadrzi FOR petlju
        mov byte al, [Token]
        sub     al, 65
        mov     si, ForBroj
        add     si, ax
        add     si, ax
        lodsw
        mov word [Linija], ax
        jmp     GlavnaPetlja

.Kraj:
        jmp     GlavnaPetlja

.Greska:
        mov     si, Sintaksa
        jmp     Greska

; ------------
; PAUSE
; ------------

do_pause:
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        je     .Prom
        mov     si, Token
        call    _string_to_int
        jmp    .Zavrsi

.Prom:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost

.Zavrsi:
        call    _pause
        jmp     GlavnaPetlja

; ------------
; PEEK
; ------------

do_peek:
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        jne    .Greska
        mov     ax, 0
        mov byte al, [Token]
        mov byte [.Privremeno], al
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        je     .Adresiraj
        cmp     ax, BROJ
        jne    .Greska
        mov     si, Token
        call    _string_to_int

.Sacuvaj:
        mov     si, ax
        mov     bx, 0
        mov byte bl, [si]
        mov     ax, 0
        mov byte al, [.Privremeno]
        call    Postavi
        jmp     GlavnaPetlja

.Adresiraj:
        mov byte al, [Token]
        call    Vrednost
        jmp    .Sacuvaj

.Greska:
        mov     si, Sintaksa
        jmp     Greska

    .Privremeno    db 0

; ------------
; POKE
; ------------

do_poke:
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        je     .PrviJeProm
        cmp     ax, BROJ
        jne    .Greska
        mov     si, Token
        call    _string_to_int
        cmp     ax, 255
        jg     .Greska
        mov byte [.PrvaVrednost], al
        jmp    .Drugi

.PrviJeProm:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        mov byte [.PrvaVrednost], al

.Drugi:
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        je     .DrugiJeProm
        cmp     ax, BROJ
        jne    .Greska
        mov     si, Token
        call    _string_to_int

.ImamVrednsot:
        mov     di, ax
        mov     ax, 0
        mov byte al, [.PrvaVrednost]
        mov byte [di], al
        jmp     GlavnaPetlja

.DrugiJeProm:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        jmp    .ImamVrednsot

.Greska:
        mov     si, Sintaksa
        jmp     Greska

    .PrvaVrednost    db 0

; ------------
; PORT
; ------------

do_port:
        call    UzmiToken
        mov     si, Token
        mov     di, .KomandaOut
        call    _string_compare
        jc     .Izlaz
        mov     di, .KomandaIn
        call    _string_compare
        jc     .Ulaz
        jmp    .Greska

.Izlaz:
        call    UzmiToken
        cmp     ax, BROJ
        jne    .Greska
        mov     si, Token
        call    _string_to_int            ; Sada je AX = broj porta
        mov     dx, ax
        call    UzmiToken
        cmp     ax, BROJ
        je     .IzlazBroj
        cmp     ax, PROMENLJIVA
        je     .IzlazProm
        jmp    .Greska

.IzlazBroj:
        mov     si, Token
        call    _string_to_int
        call    _port_byte_out
        jmp     GlavnaPetlja

.IzlazProm:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        call    _port_byte_out
        jmp     GlavnaPetlja

.Ulaz:
        call    UzmiToken
        cmp     ax, BROJ
        jne    .Greska
        mov     si, Token
        call    _string_to_int
        mov     dx, ax
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        jne    .Greska
        mov byte cl, [Token]
        call    _port_byte_in
        mov     bx, 0
        mov     bl, al
        mov     al, cl
        call    Postavi
        jmp     GlavnaPetlja

.Greska:
        mov     si, Sintaksa
        jmp     Greska

    .KomandaOut    db "OUT", 0
    .KomandaIn	   db "IN", 0

; ------------
; PRINT
; ------------

do_print:
        call    UzmiToken                   ; Deo koji se navodi iza PRINT
        cmp     ax, NAVODNIK                ; Koja vrsta tokena je u pitanju?
        je     .IspisiTekst
        cmp     ax, PROMENLJIVA             ; Brojna promenljiva (npr. X)
        je     .IspisiProm
        cmp     ax, STRING_PROM             ; String promenljiva (npr. $1)
        je     .IspisiStringProm
        cmp     ax, STRING                  ; Specijalna kljucna rec (npr. CHR ili HEX)
        je     .IspisiKlucnuRec
        mov     si, GreskaPrint             ; Ispisuju se samo promenljive i tekst pod navodnicima
        jmp     Greska

.IspisiProm:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost                     ; Uzimamo vrednost promenljive i
        call    _int_to_string               ; kovertujemo je u string
        mov     si, ax
        call    _print_string
        jmp    .NovaLinija

.IspisiTekst:                                ; Ukoliko je tekst pod navodnicima, jednostavno ga ispisujemo 
        mov     si, Token
        call    _print_string
        jmp    .NovaLinija

.IspisiStringProm:
        mov     si, StringProm
        mov     ax, 128
        mul     bx
        add     si, ax
        call    _print_string
        jmp    .NovaLinija

.IspisiKlucnuRec:
        mov     si, Token
        mov     di, chr_keyword
        call    _string_compare
        jc     .Znak
        mov     di, hex_keyword
        call    _string_compare
        jc     .Hex
        mov     si, Sintaksa
        jmp     Greska

.Znak:
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        jne    .Greska
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        mov     ah, 0Eh
        int     10h
        jmp    .NovaLinija

.Hex:
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        jne    .Greska
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        call    _print_2hex
        jmp    .NovaLinija

.Greska:
        mov     si, Sintaksa
        jmp     Greska

.NovaLinija:
        mov word ax, [Linija]               ; Gledamo da li se linija zavrsava sa  ';'
        mov word [.Privremeno], ax          ; sto znaci da iza toga ne treba ispisivati novu liniju
        call    UzmiToken
        cmp     ax, NEPOZNAT
        jne    .IpakNovaLinija
        mov     ax, 0
        mov     al, [Token]
        cmp     al, ';'
        jne    .IpakNovaLinija
        jmp     GlavnaPetlja                ; Ne ispisujemo novu liniju vec nastavljamo sa izvrsavanjem BASIC programa

.IpakNovaLinija:
        call    _print_newline
        mov word ax, [.Privremeno]
        mov word [Linija], ax
        jmp     GlavnaPetlja

    .Privremeno    dw 0

; ------------
; RAND
; ------------

do_rand:
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        jne    .Greska
        mov byte al, [Token]
        mov byte [.tmp], al
        call    UzmiToken
        cmp     ax, BROJ
        jne    .Greska
        mov     si, Token
        call    _string_to_int
        mov word [.Broj1], ax
        call    UzmiToken
        cmp     ax, BROJ
        jne    .Greska
        mov     si, Token
        call    _string_to_int
        mov word [.Broj2], ax
        mov word ax, [.Broj1]
        mov word bx, [.Broj2]
        call    _get_random
        mov     bx, cx
        mov     ax, 0
        mov byte al, [.tmp]
        call    Postavi
        jmp     GlavnaPetlja

    .tmp     db 0
    .Broj1   dw 0
    .Broj2   dw 0

.Greska:
        mov     si, Sintaksa
        jmp     Greska

; ------------
; REM
; ------------

do_rem:
        mov word si, [Linija]
        mov byte al, [si]
        inc word [Linija]
        cmp     al, 10                      ; Trazimo kraj linije nakon sto smo naisli na REM
        jne     do_rem
        jmp     GlavnaPetlja


; ------------
; RETURN
; ------------

do_return:
        mov     ax, 0
        mov byte al, [Dubina]
        cmp     al, 0
        jne    .OK
        mov     si, BezGosub
        jmp     Greska

.OK:    mov     si, GosubBroj
        add     si, ax                      ; Tabela se sastoji od reci (po dva bajta)
        add     si, ax
        lodsw
        mov word [Linija], ax
        dec byte [Dubina]
        jmp     GlavnaPetlja	

; ------------
; SAVE
; ------------

do_save:
        call    UzmiToken
        cmp     ax, NAVODNIK
        je     .Jeste
        cmp     ax, STRING_PROM
        jne near .Greska
        mov     si, StringProm
        mov     ax, 128
        mul     bx
        add     si, ax
        jmp    .Lokacija

.Jeste:
        mov     si, Token

.Lokacija:
        mov     di, .ImeDatoteke
        call    _string_copy
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        je     .DrugiJeProm
        cmp     ax, BROJ
        jne    .Greska
        mov     si, Token
        call    _string_to_int

.PostaviAdresu:
        mov word [.AdresaPodataka], ax
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        je     .TreciJeProm
        cmp     ax, BROJ
        jne    .Greska
        mov     si, Token
        call    _string_to_int

.PostaviVelicinu:
        mov word [.VelicinaPodataka], ax
        mov word ax, .ImeDatoteke
        mov word bx, [.AdresaPodataka]
        mov word cx, [.VelicinaPodataka]
        call    _write_file
        jc     .GreskaSnimanja
        mov     ax, 0
        mov byte al, 'R'
        mov     bx, 0
        call    Postavi
        jmp     GlavnaPetlja

.DrugiJeProm:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        jmp    .PostaviAdresu

.TreciJeProm:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        jmp    .PostaviVelicinu

.GreskaSnimanja:
        mov     ax, 0
        mov byte al, 'R'
        mov     bx, 1
        call    Postavi
        jmp     GlavnaPetlja

.Greska:
        mov     si, Sintaksa
        jmp     Greska

    .AdresaPodataka        dw 0
    .VelicinaPodataka      dw 0
    .ImeDatoteke           times 15 db 0

; ------------
; SERIAL
; ------------

do_serial:
        call    UzmiToken
        mov     si, Token
        mov     di, .KomandaON
        call    _string_compare
        jc     .Parametri
        mov     di, .KomandaSEND
        call    _string_compare
        jc     .Salji
        mov     di, .KomandaREC
        call    _string_compare
        jc     .Primaj
        jmp    .Greska

.Parametri:
        call    UzmiToken
        cmp     ax, BROJ
        je     .OK
        jmp    .Greska

.OK:    mov     si, Token
        call    _string_to_int
        cmp     ax, 1200
        je     .Sporo
        cmp     ax, 9600
        je     .Brzo
        jmp    .Greska

.Brzo:
        mov     ax, 0
        call    _serial_port_enable
        jmp     GlavnaPetlja

.Sporo:
        mov     ax, 1
        call    _serial_port_enable
        jmp     GlavnaPetlja

.Salji:
        call    UzmiToken
        cmp     ax, BROJ
        je     .SaljiBroj
        cmp     ax, PROMENLJIVA
        je     .SaljiProm
        jmp    .Greska

.SaljiBroj:
        mov     si, Token
        call    _string_to_int
        call    _send_via_serial
        jmp     GlavnaPetlja

.SaljiProm:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        call    _send_via_serial
        jmp     GlavnaPetlja

.Primaj:
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        jne    .Greska
        mov byte al, [Token]
        mov     cx, 0
        mov     cl, al
        call    _get_via_serial
        mov     bx, 0
        mov     bl, al
        mov     al, cl
        call    Postavi
        jmp     GlavnaPetlja

.Greska:
        mov     si, Sintaksa
        jmp     Greska

    .KomandaON     db "ON", 0
    .KomandaSEND   db "SEND", 0
    .KomandaREC    db "REC", 0

; ------------
; SOUND
; ------------

do_sound:
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        je     .PrviJeProm
        mov     si, Token
        call    _string_to_int
        jmp    .OK

.PrviJeProm:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost
        
.OK:    call    _speaker_tone
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        je     .DrugiJeProm
        mov     si, Token
        call    _string_to_int
        jmp    .Zavrsi

.DrugiJeProm:
        mov     ax, 0
        mov byte al, [Token]
        call    Vrednost

.Zavrsi:
        call    _pause
        call    _speaker_off
        jmp     GlavnaPetlja

; ------------
; WAITKEY
; ------------

do_waitkey:
        call    UzmiToken
        cmp     ax, PROMENLJIVA
        je     .JesteProm
        mov     si, Sintaksa
        jmp     Greska

.JesteProm:
        mov     ax, 0
        mov byte al, [Token]
        push    ax
        call    _wait_for_key
        cmp     ax, 48E0h
        je     .PritisnutUP
        cmp     ax, 50E0h
        je     .PritisnutDN
        cmp     ax, 4BE0h
        je     .PritisnutLevi
        cmp     ax, 4DE0h
        je     .PritisnutDesni

.Sacuvaj:
        mov     bx, 0
        mov     bl, al
        pop     ax
        call    Postavi
        jmp     GlavnaPetlja

.PritisnutUP:
        mov     ax, 1
        jmp    .Sacuvaj

.PritisnutDN:
        mov     ax, 2
        jmp    .Sacuvaj

.PritisnutLevi:
        mov     ax, 3
        jmp    .Sacuvaj

.PritisnutDesni:
        mov     ax, 4
        jmp    .Sacuvaj

; =========================================================
; Interne rutine interpretera
; =========================================================

; ---------------------------------------------------------
; Vrednost promenljive zadate u AL (npr. 'A')
; ---------------------------------------------------------

Vrednost:
        sub     al, 65
        mov     si, Promenljive
        add     si, ax
        add     si, ax
        lodsw
        ret

; ---------------------------------------------------------
; Postavljenje promeljive zadate u AL (npr. 'A')
; na vrednost zadatu u BX
; ---------------------------------------------------------

Postavi:
        mov     ah, 0
        sub     al, 65                      ; Ukloniti ASCII kodove pre 'A'
        mov     di, Promenljive             ; Nalazimo poziciju u tabeli (reci)
        add     di, ax
        add     di, ax
        mov     ax, bx
        stosw
        ret

; ---------------------------------------------------------
; Token sa tekuce pozicije u programu
; ---------------------------------------------------------

UzmiToken:
        mov word si, [Linija]
        lodsb
        cmp     al, 10
        je     .NoviRed
        cmp     al, ' '
        je     .NoviRed                    
        call    Broj
        jc      UzmiBroj
        cmp     al, '"'
        je      UzmiNavodnik
        cmp     al, 39                      ; Navodnik (') zbog asemblera, jer ne mozemo da napisemo '''
        je      UzmiZnak
        cmp     al, '$'
        je near UzmiStringProm
        jmp     UzmiString

.NoviRed:
        inc word [Linija]
        jmp     UzmiToken

UzmiBroj:
        mov word si, [Linija]
        mov     di, Token
.Dalje:
        lodsb
        cmp     al, 10
        je     .Kraj
        cmp     al, ' '
        je     .Kraj                      
        call    Broj
        jc     .Uredu
        mov     si, NeocekivaniZnak
        jmp     Greska

.Uredu:
        stosb
        inc word [Linija]
        jmp    .Dalje

.Kraj:
        mov     al, 0                       ; Token zavrsiti nulom 
        stosb
        mov     ax, BROJ                    ; Oznaciti vstu tokena
        ret

UzmiZnak:
        inc word [Linija]                   ; Prolazimo prvi navodnik (')
        mov word si, [Linija]
        lodsb
        mov byte [Token], al
        lodsb
        cmp     al, 39                      ; Mora da se zavrsi sa drugim navodnikom
        je     .OK
        mov     si, NemaNavodnika
        jmp     Greska

.OK:
        inc word [Linija]
        inc word [Linija]
        mov     ax, ZNAK
        ret

UzmiNavodnik:
        inc word [Linija]                   ; Prolazimo prve navodnike (") 
        mov word si, [Linija]
        mov     di, Token
.Dalje:
        lodsb
        cmp     al, '"'
        je     .Kraj
        cmp     al, 10
        je     .Greska
        stosb
        inc word [Linija]
        jmp    .Dalje

.Kraj:
        mov     al, 0                       ; Token zavrsiti nulom 
        stosb
        inc word [Linija]                   ; Prolazimo pored zatvorenih navodnika
        mov     ax, NAVODNIK                ; Oznaciti vstu tokena
        ret

.Greska:
        mov     si, NemaNavodnika
        jmp     Greska

UzmiStringProm:
        lodsb
        mov     bx, 0                       ; Ukoliko je u pitanju string promenljiva, stavi njen broj u BX
        mov     bl, al
        sub     bl, 49
        inc word [Linija]
        inc word [Linija]
        mov     ax, STRING_PROM
        ret
	
UzmiString:
        mov word si, [Linija]
        mov     di, Token
.Dalje:
        lodsb
        cmp     al, 10
        je     .Kraj
        cmp     al, ' '
        je     .Kraj
        stosb
        inc word [Linija]
        jmp    .Dalje
.Kraj:
        mov     al, 0                       ; Token zavrsiti nulom 
        stosb
        mov     ax, Token
        call    _string_uppercase
        mov     ax, Token
        call    _string_length              ; Kolko je dugacak token?
        cmp     ax, 1                       ; Akoje duzine jednog znaka, onda je to promenljiva ili delimiter
        je     .NijeString
        mov     si, Token                   ; Ako se token zavrsava sa ':', to je labela
        add     si, ax
        dec     si
        lodsb
        cmp     al, ':'
        je     .Labela
        mov     ax, STRING                  ; Ako nije nista od prethodnog, onda je u pitanju string 
	ret

.Labela:
        mov     ax, LABELA
        ret

.NijeString:
        mov byte al, [Token]
        call    Slovo
        jc     .Promenljiva
        mov     ax, NEPOZNAT
        ret

.Promenljiva:
        mov     ax, PROMENLJIVA             ; U supotnom je promenljiva
        ret

; ---------------------------------------------------------
; Postavi CF (Carry Flag) ukoliko AL sadrzi ASCII broj
; ---------------------------------------------------------

Broj:
        cmp     al, 48
        jl     .NijeBroj
        cmp     al, 57
        jg     .NijeBroj
        stc
        ret
        
.NijeBroj:
        clc
        ret

; ---------------------------------------------------------
; Postavi CF (Carry Flag) ukoliko AL sadrzi ASCII znak
; ---------------------------------------------------------

Slovo:
        cmp     al, 65
        jl     .NijeSlovo
        cmp     al, 90
        jg     .NijeSlovo
        stc
        ret

.NijeSlovo:
        clc
        ret

; ---------------------------------------------------------
; Ispisivanje poruka o gresci i zavrsavanje sa radom
; ---------------------------------------------------------

Greska:
        call    _print_newline
        call    _print_string             ; Ispisujemo poruku
        call    _print_newline
        mov word sp, [OrigStek]           ; Vracamo stek, kao sto je bio pre startovanja BASICa
        ret                                 

; Tekstovi poruka ...

    NeocekivaniZnak     db "Greska: Neocekivani znak unutar broja", 0
    NemaNavodnika       db "Greska: Navodnici nisu na oba kaja", 0
    GreskaPrint         db "Greska: Iza PRINT ne nalazi se string ili promeljiva", 0
    NemaNaredbe         db "Greska: Nepostojeca naredba", 0
    NemaLabele          db "Greska: GOTO ili GOSUB nemaju labelu na koju skacu", 0
    LabNePostoji        db "Greska: Ne postoji labela navedena u GOTO ili GOSUB", 0
    BezGosub            db "Greska: RETURN bez odgovarajuceg GOSUB", 0
    MaksDubina          db "Greska: Dostignut maksimum ugnjezdavanja FOR ili GOSUB", 0
    Sintaksa            db "Greska u sintaksi", 0
	NijeZadatoIme   	db 10, 13, '[BASIC] Greska: nije zadato ime datoteke.', 13, 10, 0
	NijeBasDatoteka		db 10, 13, '[BASIC] Greska: datoteka nije .BAS', 13, 10, 0
	DatotekaNePostoji	db 10, 13, '[BASIC] Greska: datoteka ne postoji', 13, 10, 0
    
 ; Stringovi naredbi ...
 
    alert_cmd           db "ALERT", 0          
    call_cmd            db "CALL", 0
    cls_cmd             db "CLS", 0
    cursor_cmd          db "CURSOR", 0
    curschar_cmd        db "CURSCHAR", 0
    end_cmd             db "END", 0
    for_cmd             db "FOR", 0
    gosub_cmd           db "GOSUB", 0
    goto_cmd            db "GOTO", 0
    getkey_cmd          db "GETKEY", 0
    if_cmd              db "IF", 0
    input_cmd           db "INPUT", 0
    load_cmd            db "LOAD", 0
    move_cmd            db "MOVE", 0
    next_cmd            db "NEXT", 0
    pause_cmd           db "PAUSE", 0
    peek_cmd            db "PEEK", 0
    poke_cmd            db "POKE", 0
    port_cmd            db "PORT", 0
    print_cmd           db "PRINT", 0
    rem_cmd             db "REM", 0
    rand_cmd            db "RAND", 0
    return_cmd          db "RETURN", 0
    save_cmd            db "SAVE", 0
    serial_cmd          db "SERIAL", 0
    sound_cmd           db "SOUND", 0
    waitkey_cmd         db "WAITKEY", 0
    
    then_keyword        db "THEN", 0
    chr_keyword         db "CHR", 0
    hex_keyword         db "HEX", 0
    progstart_keyword   db "PROGSTART", 0
    ramstart_keyword    db "RAMSTART", 0
	BasEkstenzija  		db 'BAS', 0

    OrigStek            dw 0                ; Originalni stek i trenutku startovanja BASICa
    Linija              dw 0                ; Brojac tekucih linija BASIC teksta
    KrajTeksta          dw 0                ; Pointer na zavrsni bajt BASIC teksta
    PocTeksta           dw 0                ; Pocetak BASIC teksta
    token_type          db 0                ; Vrsta poslednjeg ucitanog tokena (npr. BROJ, PROMENLJIVA)
    Dubina              db 0                ; Trenutni nivo ugnjezdenja potprograma
    Token               times 255 db 0      ; Prostor za smestanje tokena
    Promenljive         times 26 dw 0       ; Prostor za promenljive A do Z
    ForPromenljive      times 26 dw 0       ; Prostor za promenljive FOR petlje
    ForBroj             times 26 dw 0       ; Prostor gde se smesta pocetak FOR petlji
    GosubBroj           times 10 dw 0       ; Mesto na koje se vraca nakon naredbe RETURN
    StringProm          times 1024 db 0     ; 8 stringova po 128 bajtova
