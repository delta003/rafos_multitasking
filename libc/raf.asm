
SEGMENT _TEXT PUBLIC CLASS=CODE USE16
%include "..\aplikacije\src\OS_API.inc"


; STDIO.H
; -------

GLOBAL _puts, _gets

; GLOBAL _printf, _puts, _gets
; %include "printf.asm"

_puts:
        mov     si, ax
        mov     ax, _print_string
        call    ax
        mov     ax, _print_newline
        call    ax
        ret

_gets:
        mov     bx, _input_string
        call    bx
        ret



; STDLIB.H
; --------

%define  RAND_MAX  7FFFh
GLOBAL  _atoi, _srand, _rand

_atoi:
        push    bp
       	mov     bp, sp
        mov     si, [bp+4]                                  ; Pointer na ASCII string
        mov 	dx, _string_to_int
        call    dx                                          ; AX sadrzi konvertovanu int vrednost
        pop     bp			
        ret


_srand:	
; -----------------------------------------------------------------------------
; Trenutna implementacija srand ignorise zadatu vrednost seed, vec je uzima iz
; sistemskog casovnika sto, u sustini, garantuje vecu "slucajnost" ovog broja.
; Ako ovu funkciju treba usaglasiti sa ANSI standardom, postoji vise nacina:
; 1) Obezbediti da sistemska promenljiva RandomSeed bude deljena izmedju
;    kernela i aplikacije.
; 2) Napraviti novi sistemski poziv koji radi get i set ove promenljive.
; 3) Modifikovati postojece sistemske pozive tako da imaju i ovu funcionalnost.     
; -----------------------------------------------------------------------------
        push    bp
        mov     bp, sp
        mov     cx, [bp+4]                                  ; Zadata pocetna vrednost (za sada se ne koristi)
        mov 	dx, _seed_random
        call    dx
        pop     bp			
        ret


_rand:
        mov     ax, 0
        mov     bx, RAND_MAX
        mov 	dx, _get_random
        call    dx
        mov     ax, cx                                      ; Slucajni broj u opsegu od 0 do RAND_MAX
        ret


; STRING.H
; --------

GLOBAL _strlen, _strchr, _strcmp, _strncmp, _strcpy, _strcat

_strlen:
        push    bp
        mov     bp, sp
        mov     ax, [bp+4]                                  ; Pointer na string
        mov     bx, _string_length
        call    bx
        pop     bp
        ret


_strchr:
        push    bp
        mov     bp, sp
        mov     ax, [bp+6]                                  ; Znak koji se trazi
        mov     si, [bp+4]                                  ; Pointer na string
        mov     bx, _find_char_in_string
        call    bx
        pop     bp
        ret

_strcmp:
        push    bp
        mov     bp, sp
        mov     si, [bp+6]                                  ; Prvi string
        mov     di, [bp+4]                                  ; Drugi string
        mov 	bx, _string_compare
        call    bx
        jc     .Isti
        mov     ax, 1
        pop 	bp
        ret
.Isti:	mov     ax, 0
        pop     bp
        ret


_strncmp:
        push    bp
        mov     bp, sp
        mov     cl, [bp+8]                                  ; Broj znakova koji se porede
        mov     si, [bp+6]                                  ; Prvi string
        mov     di, [bp+4]                                  ; Drugi string
        mov 	bx, _string_strincmp
        call    bx
        jc     .Isti
        mov     ax, 1
        pop 	bp
        ret
.Isti:	mov     ax, 0
        pop     bp
        ret


_strcpy:
        push    bp
        mov     bp, sp
        mov     si, [bp+6]                                  ; String koji se kopira 
        mov     di, [bp+4]                                  ; String u koji se kopira
        mov     ax, di                                      ; Povratna vrednost
        mov     bx, _string_copy
        call    bx
        pop     bp
        ret


_strcat:
        push    bp
        mov     bp, sp
        mov     bx, [bp+6]                                  ; Prvi string
        mov     ax, [bp+4]                                  ; Drugi string
        mov 	dx, _string_join
        call    dx
        mov     ax, cx                                      ; Spojeni string
        pop 	bp
        ret
