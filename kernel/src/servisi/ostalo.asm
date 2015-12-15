; ==================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ==================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Razlicite rutine  
;
; ------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
; ------------------------------------------------------------------
;
; ------------------------------------------------------------------
; _get_api_version -- Vraca trenutni verziju RAF_OS API
; Ulaz: -
; Izlaz: AL = API verzija
; ------------------------------------------------------------------

_get_api_version:
        mov     al, RAF_OS_API_VER
        ret

; ------------------------------------------------------------------
; _pause -- Cekanje odredjeno vreme
; Ulaz: AX = broj desetinki koje treba cekati (znaci 10 = 1 sekunda)
; ------------------------------------------------------------------
_pause:
        pusha
        mov     bx, ax
        mov     cx, 1h
        mov     dx, 86A0h
        mov     ax, 0
        mov     ah, 86h
.Cekaj:
        int     15h
        dec     bx
        jne    .Cekaj
        popa
        ret

; -------------------------------------------------------------------
; _fatal_error -- Ispisi poruku o fatalnoj gresci i zaustavi sistem
; Ulaz: AX = Ponter na pocetak poruke o gresci
; -------------------------------------------------------------------

_fatal_error:
        mov     bx, ax                      ; Sacuvati privremeno adresu poruke
        mov     dh, 0
        mov     dl, 0
        call    _move_cursor
        pusha
        mov     ah, 09h                     ; Nacrtati crvenu traku na vrhu
        mov     bh, 0
        mov     cx, 240
        mov     bl, 01001111b
        mov     al, ' '
        int     10h
        popa

        mov     dh, 0
        mov     dl, 0
        call    _move_cursor

        mov     si, .FatalnaGreska          ; Ispisi poruku o grsci
        call    _print_string
        mov     si, bx                      ; Objasnjenje greske koje prosledjuje program
        call    _print_string
        cli                                 ; Zaustaviti rad procesora
        hlt
	
       .FatalnaGreska      db '>>> FATALNA GRESKA OPERATIVNOG SISTEMA <<<', 13, 10, 0


