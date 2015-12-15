; ==================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ==================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Interpreter batch skriptova
;
; ------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 06.12.2011.)
; ------------------------------------------------------------------

; --------------------------------------------
; Ovde pocinje izvrsavanje BAT intepretera
; --------------------------------------------

_run_batch:
    
    mov     si, .BatPozdrav
    call    _print_string
    ret
    
 .BatPozdrav   db 'Batch interpreter V.0.0.1',10,13,0   