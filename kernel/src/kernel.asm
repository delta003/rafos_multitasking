; ==========================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ==========================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; KERNEL 
;
; Ucitava se direktno upotrebom programa sa boot sektora.
; Za kernel je predvidjena memorija velicine 6000h (24 KB).
; Odmah iza toga nalazi se bafer za disk operacije, velicine 2000h (8KB). 
; Neposredno iza bafera (lokacija 8000h) ucitavaju se svi programi.
; ---------------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
; ---------------------------------------------------------------------------

    %define RAF_OS_VER ' ver. 0.1.2'        ; Verzija operativnog sistema
    %define RAF_OS_API_VER 1                ; API verzija (proveravaju je aplikacije)
    
     DiskBafer equ 6000h
     sys       equ 2000h                    ; Segment u kome radi kernel
    
    %include "vektor.inc"

_main:
    mov     ax, 0           
    mov     ss, ax                      ; Segment koji koristi BIOS
    mov     sp, 08FFFh                  ; Inicijalizacija stek pointera na vrh steka
    cld                                 ; Pravac operacija sa stringovima (ka rastucim adresama)

    mov     ax, cs                      ; Podesavanje svih segmenata na segment gde se ucitava kernel.
    mov     ds, ax                      ; Nakon ovoga, vise nema potrebe voditi racuna o segmentima
    mov     es, ax                      ; jer ce se sve (osim stek operacija) odvijati unutar nasih 64K.
    mov     fs, ax
    mov     gs, ax

    mov     ax, 1003h                   ; Sjajan tekst bez treptanja
    mov     bx, 0
    int     10h
    call    _seed_random                ; Seed za generator slucajnih brojeva 

    call    _clear_screen               ; Startovati komandni interpreter 
    call    _init_scheduler
    call 	set_interrupts
    call 	_command_line

stop:
    call    _clear_screen
    mov     si, stop_msg                ; Kada se izadje iz CLI, sistem se zaustavlja.
    call    _print_string
    hlt

stop_msg   db 13,10, '   >>> Sistem zaustavljen. Mozete iskljuciti racunar.', 0

        
; ---------------------------------
; Sistemski servisi 
; ---------------------------------
    %include "servisi/shell.asm"
    %include "servisi/scheduler.asm"
    %include "servisi/batch.asm"
    %include "servisi/disk.asm"
    %include "servisi/tastatura.asm"
    %include "servisi/matemat.asm"
    %include "servisi/ostalo.asm"
    %include "servisi/portovi.asm"
    %include "servisi/ekran.asm"
    %include "servisi/zvuk.asm"
    %include "servisi/string.asm"
    %include "servisi/printer.asm"
	%include "servisi/prekidi.asm"
    %include "servisi/segswap.asm"
    