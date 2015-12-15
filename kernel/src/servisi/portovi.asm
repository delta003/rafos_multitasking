; ==================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ==================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Rutine za rad sa portovima
;
; ------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
; ------------------------------------------------------------------

; ------------------------------------------------------------------
; _port_byte_out -- Posalji bajt na odgovarajuci port
; Ulaz: DX = adresa porta, AL = bajt kojeg treba poslati
; ------------------------------------------------------------------

_port_byte_out:
        pusha
        out     dx, al
        popa
        ret

; ------------------------------------------------------------------
; _port_byte_in -- Ucitati bajt sa porta
; Ulaz:  DX = adresa porta
; Izlaz: AL = bajt ucitan sa porta
; ------------------------------------------------------------------

_port_byte_in:
        pusha
        in      al, dx
        mov word [.tmp], ax
        popa
        mov     ax, [.tmp]
        ret

       .tmp     dw 0

; ------------------------------------------------------------------
; _serial_port_enable -- Podesavanje serijskog porta
; Ulaz: AX = 0 za 9600 baud ili 1 za 1200 baud (oba N,8,1)
; ------------------------------------------------------------------

_serial_port_enable:
        pusha
        mov     dx, 0                       ; Konfigurisanje serijskog porta 1
        cmp     ax, 1
        je     .SporiPrenos
        mov     ah, 0
        mov     al, 11100011b               ; 9600 baud, no parity, 8 data bits, 1 stop bit
        jmp    .Kraj
        
.SporiPrenos:
        mov     ah, 0
        mov     al, 10000011b               ; 1200 baud, no parity, 8 data bits, 1 stop bit	
.Kraj:
        int     14h
        popa
        ret

; ------------------------------------------------------------------
; _send_via_serial -- Posalji bajt preko serijskg porta
; Ulaz:  AL = bajt kojeg treba poslati
; Izlaz: AH bit 7 = 0 ukoliko je OK
; ------------------------------------------------------------------

_send_via_serial:
        pusha
        mov     ah, 01h
        mov     dx, 0                       ; COM1
        int     14h
        mov     [.tmp], ax
        popa
        mov     ax, [.tmp]
        ret

       .tmp     dw 0

; ------------------------------------------------------------------
; _get_via_serial -- Ucitati bajt preko serijskog porta
; Izlaz: AL = primljeni bajt; AH bit 7 = 0, ukoliko je OK
; ------------------------------------------------------------------

_get_via_serial:
        pusha
        mov     ah, 02h
        mov     dx, 0                       ; COM1
        int     14h
        mov     [.tmp], ax
        popa
        mov     ax, [.tmp]
        ret

       .tmp     dw 0
