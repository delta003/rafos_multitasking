; ==================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ==================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Rutine za rad sa tekst ekranom 80x25 znakova 
;
; ------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
; ------------------------------------------------------------------

; ----------------------------------------------------
; _print_string -- Ispisuje tekst upotrebom BIOS-a
; Ulaz: SI = pointer na pocetak stringa
; String mora da se zavrsi nulom.
; ----------------------------------------------------

_print_string:
        pusha
        mov     ah, 0Eh                     ; BIOS INT 10h teletype (TTY) funcija

.Ponavljaj:
        lodsb                               ; Uzmi jedan znak iz stringa
        cmp     al, 0
        je     .Kraj                        ; Ako je znak nula, to je kraj stringa.
        int     10h                         ; Ako nije kraj, pozovi BIOS za ispisivanje
        jmp    .Ponavljaj                   ; i idi na sledeci znak.
.Kraj:
        popa
        ret
  
; ----------------------------------------------------
; _clear_screen -- Brise ekran (u boju pozadine)
; Ulaz/Izlaz: -
; ----------------------------------------------------

_clear_screen:
        pusha
        mov     dx, 0                       ; Kursor na pocetnu poziciju (gore levo)
        call    _move_cursor
        mov     ah, 6                       ; Funkcija za skrol ekrana na gore
        mov     al, 0                       ; Ceo ekran
        mov     bh, 7                       ; Bela slova na crnoj pozadini (bice obrisano u crno)
        mov     cx, 0                       ; Oblast za brisanje: Gore levo (CH=CL=0)
        mov     dh, 24                      ; Dole desno (DH=24, DL=79)
        mov     dl, 79
        int     10h
        popa
        ret

; ----------------------------------------------------
; _move_cursor -- Pomera kursor
; Ulaz: DH = linija, DL = kolona
; ----------------------------------------------------

_move_cursor:
        pusha
        mov     bh, 0                       ; Normalna stranica (0)
        mov     ah, 2                       ; BIOS funkcija za pomeranje kursora
        int     10h				
        popa
        ret

; -----------------------------------------------------
; _get_cursor_pos -- Polozaj kursora
; Izlaz: DH = linija, DL = kolona
; -----------------------------------------------------

_get_cursor_pos:
        pusha
        mov     bh, 0                       ; Normalna stranica (0)
        mov     ah, 3                       ; BIOS funkcija za polozaj kursora
        int     10h				
        mov     [.tmp], dx                  ; Sacuvati privremeno, zbog 'popa'
        popa
        mov     dx, [.tmp]                  
        ret

       .tmp dw 0

; ------------------------------------------------------
; _print_horiz_line -- Crta horizontalnu liniju
; Ulaz: AX = vrsta linije (1 za dvostruku (=), 
; ostale vrednosti za jednostruku (-))
; ------------------------------------------------------

%define JEDNA   196
%define DVE     205

_print_horiz_line:
        pusha
        mov     cx, ax                      ; Vrsta linije
        mov     al, JEDNA                   ; Standardno je jednostruka linija
        cmp     cx, 1                       ; Da li je zadata dvostruka linija?
        jne    .Spreman
        mov     al, DVE                     ; Znak za dvostruku liniju
.Spreman:
        mov     cx, 0                       ; Brojac znakova
        mov     ah, 0Eh                     ; BIOS TTY
.Ponovo:
        int     10h
        inc     cx
        cmp     cx, 80                      ; Da li je narctano svih 80 znakova?
        je     .Kraj
        jmp    .Ponovo
.Kraj:
        popa
        ret

; ------------------------------------------------------
; _show_cursor -- Pikazi kursor
; Ulaz/Izlaz: -
; ------------------------------------------------------

_show_cursor:
        pusha
        mov     ch, 6                       ; Standardni CGA kursor
        mov     cl, 7
        mov     ah, 1                       ; BIOS funkcija za oblik kursora
        mov     al, 3                       ; Ovo znaci 80x25 16 boja, za INT 10,AH=0
        int     10h                         ; Ovde je za svaku sigurnost
        popa
        ret

; ------------------------------------------------------
; _hide_cursor -- Sakrij kursor
; Ulaz/Izlaz: -
; ------------------------------------------------------

_hide_cursor:
        pusha
        mov     ch, 32
        mov     ah, 1                       ; BIOS funkcija za oblik kursora
        mov     al, 3                       ; Ovo znaci 80x25 16 boja, za INT 10,AH=0
        int     10h                         ; Ovde je za svaku sigurnost
        popa
        ret  
    
; ----------------------------------------------------------
; _print_newline -- Postavlja kursor na pocetak novog reda
; Ulaz/Izlaz: -
; ----------------------------------------------------------

_print_newline:
        pusha
        mov     ah, 0Eh			
        mov     al, 13                      ; Pocetak reda (CR)
        int     10h
        mov     al, 10                      ; Novi red (LF)
        int     10h
        popa
        ret

; ------------------------------------------------------------------
; _dump_registers -- Ispisuje sadrzaj registara u hex formatu
; Ulaz/Izlaz: AX/BX/CX/DX/SI/DI = registri ciji se sadrzaj ispisuje
; ------------------------------------------------------------------

_dump_registers:
        pusha
        call    _print_newline
        push    di
        push    si
        push    dx
        push    cx
        push    bx
        
        mov     si, .ax_string
        call    _print_string
        call    _print_4hex
	
        pop     ax
        mov     si, .bx_string
        call    _print_string
        call    _print_4hex

        pop     ax
        mov     si, .cx_string
        call    _print_string
        call    _print_4hex

        pop     ax
        mov     si, .dx_string
        call    _print_string
        call    _print_4hex

        pop     ax
        mov     si, .si_string
        call    _print_string
        call    _print_4hex

        pop     ax
        mov     si, .di_string
        call    _print_string
        call    _print_4hex

        call    _print_newline
        popa
        ret

       .ax_string     db ' AX:', 0
       .bx_string     db ' BX:', 0
       .cx_string     db ' CX:', 0
       .dx_string     db ' DX:', 0
       .si_string     db ' SI:', 0
       .di_string     db ' DI:', 0
   
; --------------------------------------------------------
; _print_space -- Ispisuje znak za prazno mesto (Space)
; Ulaz/Izlaz: -
; --------------------------------------------------------

_print_space:
        pusha
        mov     ah, 0Eh			
        mov     al, 20h                     ; ASCII kod za Space
        int     10h
        popa
        ret

; ------------------------------------------------------------------
; _dump_string -- Ispisuje string kao niz hex bajtova i znakova
; Ulaz: SI = pointer na pocetak stringa
; ------------------------------------------------------------------

_dump_string:                                                      
        pusha
        mov     bx, si                    
.Linija:
        mov     di, si                    
        mov     cx, 0                       ; Brojac bajtova
.JosHexa:
        lodsb
        cmp     al, 0
        je     .StampajZnak
        call    _print_2hex
        call    _print_space                ; Prazno mesto izmedju bajtova
        inc     cx
        cmp     cx, 8                       ; Da li je sredina (od 16 bajtova)?
        jne    .SledecaLinija
        call    _print_space                ; Sredina linije, dvostruko prazno mesto
        jmp    .JosHexa
.SledecaLinija:
        cmp     cx, 16
        jne    .JosHexa
.StampajZnak:
        call    _print_space
        mov     ah, 0Eh                     ; BIOS TTY
        mov     al, '|'                     ; Delimiter izmedju hex ispisa i ASCII znakova
        int     10h
        call    _print_space
        mov     si, di                      ; Idi na pocetak ove linije
        mov     cx, 0
.JosZnakova:
        lodsb
        cmp     al, 0
        je     .Kraj
        cmp     al, ' '                     ; Provera donje ASCII granice
        jae    .Provera
        jmp short .NeMoze
.Provera:
        cmp     al, '~'                     ; Provera gornje ASCII granice
        jbe    .Izlaz
.NeMoze:
        mov     al, '.'                     ; Ako je van granica, unseto ASCII ispisi '.'
.Izlaz:
        mov     ah, 0Eh                     ; Ispisi jednu liniju
        int     10h
        inc     cx
        cmp     cx, 16                      ; U jednoj liniji ispisuje se 16 bajtova
        jl     .JosZnakova
        call    _print_newline              ; Sledeca linija
        jmp    .Linija
.Kraj:
        call    _print_newline        
        popa
        ret

; --------------------------------------------------------------
; _print_digit -- Ispisuje sadrzaj AX kao cifru 
; Radi sa osnovama do 36, tj. ciframa  0-Z
; Ulaz: AX = "cifra" koji treba formatirati i ispisati
; --------------------------------------------------------------

_print_digit:
        pusha
        cmp     ax, 9                       ; Preskociti znakove interpunkcije u ASCII tabeli
        jle    .FormatBroja
        add     ax, 'A'-'9'-1		
.FormatBroja:
        add     ax, '0'                     ; Ofset u ASCII tabeli (0 ce se ispisati kao '0', itd).	
        mov     ah, 0Eh			
        int     10h
        popa
        ret

; -------------------------------------------------------
; _print_1hex -- Ispisuje donji nibl AL u hex formatu
; Ulaz: AL = broj koji je potrebno ispisati
; -------------------------------------------------------

_print_1hex:
        pusha
        and     ax, 0Fh                     ; Maska za donji nibl
        call    _print_digit
        popa
        ret

; -------------------------------------------------------
; _print_2hex -- Ispisuje AL u hex formatu
; Ulaz: AL = broj koji je potrebno ispisati
; -------------------------------------------------------

_print_2hex:
        pusha
        push    ax                          ; Gornji nibl prebaciti u donji
        shr     ax, 4
        call    _print_1hex                 ; Ispisati gornji nibl
        pop     ax
        call    _print_1hex                 ; Ispisati donji nibl
        popa
        ret

; -------------------------------------------------------
; _print_4hex -- Ispisuje AX u hex formatu
; Ulaz: AX = broj koji je potrebno ispisati
; -------------------------------------------------------

_print_4hex:
        pusha
        push    ax                          ; Ispisati gornji bajt
        mov     al, ah
        call    _print_2hex
        pop     ax                          ; Ispisati donji bajt
        call    _print_2hex
        popa
        ret

; -------------------------------------------------------
; _print_dec -- Ispisuje AX u dekadnom formatu
; Ulaz: AX = broj koji je potrebno ispisati
; -------------------------------------------------------

_print_dec:
        pusha
        xor cx, cx
        mov bx, 10
    .petlja:
        xor dx, dx
        div bx
        push dx
        inc cx
        cmp ax, 0
        jg .petlja
    .petlja2:
        pop ax
        call _print_digit
        loop .petlja2
        popa
        ret

; --------------------------------------------------------------------
; _input_string -- Ucitava string sa tastature
; Ulaz/Izlaz: AX = pointer na pocetak stringa
; Maksimalna velicina unetog stinga je 255, ukljucujuci i zavrsnu nulu
; --------------------------------------------------------------------

_input_string:
        pusha
        mov     di, ax                      ; DI pokazuje na bafer (lokaciju gde se smesta string)
        mov     cx, 0                       ; Backspace brojac
.ImaJos:                                      
        call    _wait_for_key
        cmp     al, 13                      ; Zavrsi unosenje ako je pritisnut Enter
        je     .Kraj
        cmp     al, 8                       ; Pritisnut Backspace?
        je     .BackSpace                   
        cmp     al, ' '                     ; Da li je znak u ASCII opsegu od 32 do 126?
        jb     .ImaJos                        
        cmp     al, '~'
        ja     .ImaJos
        jmp    .NijeBackSpace

.BackSpace:
        cmp     cx, 0                       ; Backspace na pocetku stringa?
        je     .ImaJos                      ; Ako jeste, ignorisi
        call    _get_cursor_pos             ; Backspace na pocetku ekranske linije?
        cmp     dl, 0
        je     .BkSpPocetakLinije
        pusha
        mov     ah, 0Eh                     ; Ukoliko nije, upisi Space i pomeri kursor unazad
        mov     al, 8
        int     10h                         ; Za brisanje praznog mesta, dva puta Backspace
        mov     al, 32
        int     10h
        mov     al, 8
        int     10h
        popa                               
        dec     di                          ; Znak ce biti prepisan drugim znakom ili zavrsnom nulom
        dec     cx                      
        jmp    .ImaJos

.BkSpPocetakLinije:
        dec     dh                          ; Skoci na kraj prethodne linije
        mov     dl, 79
        call    _move_cursor
        mov     al, ' '                     ; Ispisi Space
        mov     ah, 0Eh
        int     10h

        mov     dl, 79                      ; Pomeri se unazad pre Space
        call    _move_cursor
        dec     di                          ; Pomeri unazad pointer stringa
        dec     cx                          ; Pomeri unazad brojac
        jmp    .ImaJos

.NijeBackSpace:
        pusha
        mov     ah, 0Eh                     ; Printabilni znak
        int     10h
        popa

        stosb                               ; Sacuvati znak u baferu
        inc     cx                          ; Uvecati brojaz znakova
        cmp     cx, 254                     ; Da li smo dosli do kraja bafera?
        jae near .Kraj
        jmp near .ImaJos                    ; Jos uvek ima mesta

.Kraj:
        mov     ax, 0                       ; Zavrsetak stringa
        stosb
        popa
        ret

; --------------------------------------------------------------------------------
; _draw_block -- Crta blok u zadatoj boji (boja se nalazi u BL)
; Ulaz: 
; Pocetak bloka: DH = linija, DL = kolona
; Sirina bloka: SI 
; Poslenja linija bloka: DI
; ---------------------------------------------------------------------------------

_draw_block:          
        pusha
.ImaJos:
        call    _move_cursor                ; Postavljamo se na pocetak crtanja bloka
        mov     ah, 09h                     ; Crtamo blok pomocu praznom mesta odredjene boje
        mov     bh, 0
        mov     cx, si
        mov     al, ' '
        int     10h
        inc     dh                          ; Sledeca linija
        mov     ax, 0
        mov     al, dh                      ; Tekuca Y pozicija u DL
        cmp     ax, di                      ; Da li smo stigli do krajnje tacke (DI)?
        jne    .ImaJos                      ; Ako nismo, nastavljamo crtanje
        popa
        ret

; -------------------------------------------------------------------
; _draw_background -- Brise ekran i iscrtava gore i dole bele trake,
; odgovarajuci tekst i obojenu radnu povrsinu.
; Ulaz: AX = gornji string, BX = donji string, CX = boja                           
; -------------------------------------------------------------------

%define CRNO_NA_BELOM   01110000b           ; Bela boja pozadine (nije sjajna - sivkasta), crna slova

_draw_background:
        pusha
        push    ax                          ; Parametri koji ce nam biti potrebni kasnije
        push    bx
        push    cx
        mov     dl, 0                       ; Postavljamo kursor u gornji levi ugao
        mov     dh, 0
        call    _move_cursor

        mov     ah, 09h                     ; Iscrtavamo gornju traku
        mov     bh, 0
        mov     cx, 80
        mov     bl, CRNO_NA_BELOM           ; Bela boja pozadine, crna slova
        mov     al, ' '
        int     10h

        mov     dh, 1                       ; Postavljamo kursor na pocetak drugog reda
        mov     dl, 0
        call    _move_cursor

        mov     ah, 09h                     ; Iscrtavamo obojenu radnu povrsinu
        mov     cx, 1840                    ; 23 linija x 80 kolona 
        pop     bx                          ; Boja koja je na pocetku zadata preko CX
        mov     bh, 0
        mov     al, ' '
        int     10h

        mov     dh, 24                      ; Postavljamo kursor na pocetak poslednjeg reda
        mov     dl, 0
        call    _move_cursor

        mov     ah, 09h                     ; Iscrtavamo donju traku
        mov     bh, 0
        mov     cx, 80
        mov     bl, CRNO_NA_BELOM           ; Bela boja pozadine, crna slova
        mov     al, ' '
        int     10h

        mov     dh, 24                      ; Postavljamo kursor na prvu poziciju u donjoj traci
        mov     dl, 1
        call    _move_cursor
        pop     bx                          ; Ispisujemo donji string
        mov     si, bx
        call    _print_string

        mov     dh, 0                       ; Postavljamo kursor na prvu poziciju u gornjoj traci
        mov     dl, 1
        call    _move_cursor
        pop     ax                          ; Ispisujemo gornji string
        mov     si, ax
        call    _print_string

        mov     dh, 1                       ; Postavljamo kursor na prvu poziciju radne povrsine
        mov     dl, 0
        call    _move_cursor

        popa
        ret

; ------------------------------------------------------------------
; _dialog_box -- Iscrtava dialog boks sa dugmetom 'OK'
; Ulaz: AX, BX, CX = pointeri na pocetak stringova 
; Svaki string je maksimalne duzine 40 znakova
; ------------------------------------------------------------------

%define BELO_NA_SIVOM   10001111b  
%define CRNO_NA_BELOM_S 11110000b
 
_dialog_box:
        pusha
        call    _hide_cursor
        mov     dh, 9                       ; Iscrtavamo pozadinu dialog boksa 
        mov     dl, 19                      ; Gornji levi ugao je 9-ta linija 19-ta kolona 
.CrtajBoks:
        call    _move_cursor
        pusha
        mov     ah, 09h
        mov     bh, 0
        mov     cx, 42                      ; Sirina dilaog boksa je 42 (sa svake strane ostaje po 19)
        mov     bl, BELO_NA_SIVOM           ; Bela slova, siva pozadina   
        mov     al, ' '
        int     10h
        popa
        inc     dh
        cmp     dh, 16                      ; Da li smo iscrtali 16-9=7 linija?
        je     .BoksOK                      ; Iscrtali smo pozadinu dialog boksa
        jmp    .CrtajBoks

.BoksOK:                                    ; Ispisujemo tekst unutar dialog boksa
        cmp     ax, 0                       ; Preskoci ako je parametar nula
        je     .NijePrvi                    ; Ucitati string za prvi red dialog boksa
        mov     dl, 20
        mov     dh, 10                      ; Postaviti kursor na pocetak prvog reda dialog boksa
        call    _move_cursor
        mov     si, ax                      ; Ispisati prvi string
        call    _print_string

.NijePrvi:
        cmp     bx, 0                       ; Preskoci ako je parametar nula
        je     .NijeDrugi                   ; Ucitati string za drugi red dialog boksa
        mov     dl, 20
        mov     dh, 11                      ; Postaviti kursor na pocetak drugog reda dialog boksa
        call    _move_cursor
        mov     si, bx                      ; Ispisati drugi string	
        call    _print_string

.NijeDrugi:
        cmp     cx, 0                       ; Preskoci ako je parametar nula
        je     .NijeTreci                   ; Ucitati string za treci red dialog boksa
        mov     dl, 20
        mov     dh, 12                      ; Postaviti kursor na pocetak treceg reda dialog boksa
        call    _move_cursor
        mov     si, cx                      ; Ispisati treci string	
        call    _print_string

.NijeTreci:
        mov     bl, CRNO_NA_BELOM_S         ; Sjajna bela boja pozadine, crna slova 
        mov     dh, 14                      ; Iscrtava dugme u dnu
        mov     dl, 35                      ; i na sredini  dalog boksa
        mov     si, 8                       ; dimenzije 8x1 znakova
        mov     di, 15
        call    _draw_block
        mov     dl, 38                      ; Ispisuje OK na sredini dugmeta
        mov     dh, 14
        call    _move_cursor
        mov     si, .ok_string
        call    _print_string
        call    _wait_for_key               ; Cekaj da korisnik pritisne taster Enter
        cmp     al, 13			
        jne    .NijeTreci
        call    _show_cursor
        popa
        ret

       .ok_string    db 'OK', 0


