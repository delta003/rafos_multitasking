; =============================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; =============================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Zamena segmenata pri sistemskim pozivima - RAF_OS multitasking
; Upotreba: vector.inc
; -----------------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Marko Bakovic, Sasa Vuckovic, Dusan Josipovic, 01.01.2015.).
; -----------------------------------------------------------------------------

; ------------------------------------------------------------------
; _swap_seg -- Inicijalizacija segmenata na one koje kernel koristi
; ------------------------------------------------------------------
_swap_seg:

	push ds
	push es 
	push fs 
	push gs

	push sys			; segmente inicijalizujemo na segment kernela
	push sys
	push sys
	push sys
	pop ds  			
	pop es
	pop fs
	pop gs

	pop word [ret_gs]
	pop word [ret_fs]
	pop word [ret_es]
	pop word [ret_ds]

	ret

; ------------------------------------------------------------------
; _swap_seg_back -- Povratak na segmente procesa
; ------------------------------------------------------------------
_swap_seg_back:
	
	push word [ret_ds]
	push word [ret_es]
	push word [ret_fs]
	push word [ret_gs]

	pop gs
	pop fs
	pop es
	pop ds

	retf 				; povratak tamo odakle je pozvana sistemska funkcija

; ------------------------------------------------------------------
; Segmenti na koje treba da se vratimo
; ------------------------------------------------------------------
	ret_ds dw 0
	ret_gs dw 0
	ret_fs dw 0
	ret_es dw 0