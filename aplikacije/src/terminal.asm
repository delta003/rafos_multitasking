; ==================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ==================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
;
; Jednostavni terminalski program
; Demonstrira upotrebu propitivanja serijskog ulaza i izlaza. 
; Napomena: Nije u potpunosti implementirana ANSI kontrola ekrana!
; Testiranje:
; 1) Povezati se sa Linux racunarom upotrebom Null Modem kabla
; 2) U datoteci /etc/inittab dodati liniju
;      S0:12345:respawn:/sbin/agetty -L ttyS0 9600 vt100
; 3) Restartovati Linux racunar
; 4) Pokrenuti terminalski program
;
; ------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
; ------------------------------------------------------------------

%include "OS_API.inc"
org app_main

Start:
        call    _clear_screen
        mov     ax, 0                       ; Brzina serijskog prenosa: 9600 baud 
        call    _serial_port_enable
        mov     si, PocetnaPoruka
        call    _print_string

GlavnaPetlja:
        mov     dx, 0                       ; Komunikacija ide preko COM1
        mov     ax, 0
        mov     ah, 03h                     ; Proveravamo status porta COM1
        int     14h
        bt      ax, 8                       ; Pristigli podaci?
        jc      StigaoBajt
        mov     ax, 0                       ; Ako nisu, da li mi imamo nesto da posaljemo?
        call    _check_for_key
        cmp     ah, KEY_F8                  ; Da li je pritisnut F8?
        je      Kraj                        ; Ako jeste, zavrsavamo sa radom terminala
        cmp     al, 0                       ; Ako nije, idemo ponovo u propitivanje
        je      GlavnaPetlja

; ------------------------------------------------------------------- 
; Saljemo bajt preko COM1

        call    _send_via_serial		
        jmp     GlavnaPetlja
        
; -------------------------------------------------------------------
; Pristigao bajt preko COM1

StigaoBajt:	
        call    _get_via_serial
        cmp     al, 1Bh                     ; Da li je pristigli bajt 'Esc' (kontrolni znak)?
        je      StigaoESC
        mov     ah, 0Eh                     ; Ako nije, stampamo pristigli znak
        int     10h
        jmp     GlavnaPetlja

; -------------------------------------------------------------------
Kraj:
        call    _print_newline
        call    _print_newline
        call    _print_horiz_line
        mov     si, ZavrsnaPoruka
        call    _print_string
        call    _print_horiz_line
        call    _wait_for_key
        ret

; -------------------------------------------------------------------
StigaoESC:
        call    _get_via_serial             ; 'Esc' znaci da treba citati sledeci znak
        cmp     al, '['                     ; Da li sledeci znak oznacava kontrolu ekrana?
        jne     GlavnaPetlja
        call    _get_via_serial             ; Ako je kontrola ekrana, o cemu se radi?
        cmp     al, 'H'
        je near PocetnaPozicija
        cmp     al, 'J'
        je near BrisemoDoKraja
        cmp     al, 'K'
        je near BrisemoDoKrajaLinije
        jmp     GlavnaPetlja

PocetnaPozicija:
        mov     dx, 0                       ; Idemo na pocetnu poziciju ekrana (Home)
        call    _move_cursor
        jmp     GlavnaPetlja

BrisemoDoKraja:                             ; Brisemo sve do kraja ekrana
        call    _get_cursor_pos
        push    dx                          ; Cuvamo poziciju kursora da bismo mogli da se vratimo
        call    Brisi
        inc     dh                          ; Idemo na pocetak sledece linije
        mov     dl, 0
        call    _move_cursor
        mov     ah, 0Ah	                    ; Spremamo se za ispisivanje 80 praznih mesta ('brisanje' linije)
        mov     al, ' '
        mov     bx, 0
        mov     cx, 80
.Dalje:
        int     10h
        inc     dh                          ; Sledeca linija
        call    _move_cursor
        cmp     dh, 25                      ; Da li smo stigli do dna ekrana?
        jne    .Dalje
        pop     dx                          ; Vracamo kursor tamo gde smo ga sacuvali
        call    _move_cursor
        jmp     GlavnaPetlja

BrisemoDoKrajaLinije:
        call    Brisi
        jmp     GlavnaPetlja

Brisi:
        call    _get_cursor_pos
        push    dx                          ; Cuvamo poziciju kursora
        mov     ah, 80                      ; Racunamo koliko praznih mesta je potrebno da ispisemo
        sub     ah, dl                      ; ...
        mov     cx, 0                       ; ...
        mov     cl, ah                      ; i rezultat stavljamo u CL
        mov     ah, 0Ah	                    ; Ispisujemo prazna mesta CL broj puta
        mov     al, ' '
        mov     bx, 0
        int     10h
        pop     dx                          ; Vracamo poziciju kursora
        call    _move_cursor
        ret

    PocetnaPoruka   db 'RAF_OS terminal -- Za izlaz pritisite F8', 13, 10, 'Povezujem se brzinom 9600 baud ...', 13, 10, 13, 10, 0
    ZavrsnaPoruka   db '>> Kraj terminalskog programa. Pritisnite bilo koji taster za povratak u RAF_OS.', 0

