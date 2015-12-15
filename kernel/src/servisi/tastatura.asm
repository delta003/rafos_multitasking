; ==================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ==================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Rutine za rad sa tastaturom 
;
; ------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
; ------------------------------------------------------------------

; ------------------------------------------------------------------
; _wait_for_key -- Ceka da se pritisne taster 
; Ulaz: -
; Izlaz: AX = pritisnuti taster
; ------------------------------------------------------------------

_wait_for_key:
        pusha   
        mov     ax, 0
        mov     ah, 10h                     ; BIOS poziv za cekanje pritisnutog tastera
        int     16h
        mov     [.tmp_buf], ax              ; Sacuvati rezultat
        popa                                ; Vratiti sve registre
        mov     ax, [.tmp_buf]              ; Vratiti rezultat preko AX
        ret

       .tmp_buf dw 0

; ------------------------------------------------------------------
; _check_for_key -- Propituje tastaturu za ulaz, ali ne ceka
; Ulaz: -
; Izlaz: AX = 0 ako nije pritisnut taster. Ako jeste, sadrzi scan_code
; ------------------------------------------------------------------

_check_for_key:
        pusha
        mov     ax, 0
        mov     ah, 1                       ; BIOS poziv (da li je pritisnut neki taster)
        int     16h
        jz     .NijePritisnut               ; Ako nije, idi na kraj
        mov     ax, 0                       ; Ako jeste, uzmi ga iz bafera
        int     16h
        mov     [.tmp_buf], ax              ; Sacuvati rezultat
        popa				         
        mov     ax, [.tmp_buf]              ; Vratiti rezultat preko AX
        ret
        
.NijePritisnut:
        popa
        mov     al, 0                       ; Nula, ako taster nije pritisnut
        ret

       .tmp_buf dw 0

