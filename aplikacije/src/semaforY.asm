; ==================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ==================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
;
; SemaforR proces - tester za multitasking
; ------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Sasa Vuckovic, 12.01.2015)
; ------------------------------------------------------------------

%include "OS_API.inc"

	call OS:_get_app_offset
	mov  word [app_offset], ax

	mov bh, 0h 							; pocetna iteracija

petlja:
	cmp bh, 6
	jne .nastavi

	mov bh, 0

	.nastavi:

	; prvi DL
	mov si, LocDL
	xor cx, cx
	mov cl, bh

	prvi:
	inc si
	loop prvi

	mov dl, byte [si]

	; drugi DH
	mov si, LocDH
	xor cx, cx
	mov cl, bh

	drugi:
	inc si
	loop drugi

	mov dh, byte [si]

	;treci DI
	mov si, LocDI
	xor cx, cx
	mov cl, bh

	treci:
	inc si
	loop treci

	mov di, [si]
	mov cx, di
	and cx, 00FFh
	mov di, cx

	mov bl, 11101110b
	mov si, 1h
	push dx

	cli									; Zabrani prekide. 
	mov al, 080h						; Zabrani NMI prekide
	out 070h, al

	call OS:_get_cursor_pos
	mov ax, dx
	pop dx
	push ax
	
	call OS:_draw_block
	pop dx
	call OS:_move_cursor

	xor al, al							; Dozvoli NMI prekide
	out 070h, al						; Dozvoli prekide
	sti

	inc bh
	jmp petlja

LocDL db 4Ah, 4Bh, 4Ch, 4Dh, 4Eh, 4Fh
LocDH db 02h, 01h, 00h, 00h, 01h, 02h
LocDI db 03h, 04h, 05h, 05h, 04h, 03h

app_offset dw 0
