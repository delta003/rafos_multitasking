; ==================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ==================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Rutine za rad sa zvukom 
;
; ------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
; ------------------------------------------------------------------

; ------------------------------------------------------------------
; _speaker_tone -- Generise zvuk na ugradjenom zvucniku
; Ulaz AX = visina tona
; Izlaz: -
; ------------------------------------------------------------------

_speaker_tone:
        pusha
        mov     cx, ax                      ; Sacuvati visinu tona
        mov     al, 182
        out     43h, al
        mov     ax, cx                      ; Podesiti frekvenciju
        out     42h, al
        mov     al, ah
        out     42h, al
        in      al, 61h                     ; Ukljuciti zvucnik
        or      al, 03h
        out     61h, al
        popa
        ret

; ------------------------------------------------------------------
; _speaker_off -- Iskljucuje zvucnik
; Ulaz/Izlaz: -
; ------------------------------------------------------------------

_speaker_off:
        push    ax
        in      al, 61h
        and     al, 0FCh
        out     61h, al
        pop     ax
        ret
