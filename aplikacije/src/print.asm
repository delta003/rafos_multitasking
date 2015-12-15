; =====================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; =====================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Aplikacija za dodavanje datoteke u print spooler
;
; ----------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (15.01.2011. Vanja Petrovic Tankovic RN05/09)
; 
; ----------------------------------------------------------------------

    %include "OS_API.inc"                   ; RAF_OS API
    PocetakTeksta equ app_main + 1000h      ; Tekst datoteka se ucitava 4KB iza pocetka aplikacije

    org app_main                            ; Svi aplikacioni programi se ucitavaju odavde
	
Start:
        cmp     byte [arg1], 0              ; Da li je zadato ime datoteke?
        jne     .ZadatoIme
        mov     si, NijeZadatoIme           ; Ako nije, ispisati poruku o gresci
        call    _print_string
        ret

.ZadatoIme:
		mov     ax, arg1
        call    _file_exists                ; Da li datoteka postoji?
        jc     .NePostoji
        jmp    .Ucitaj
    
.NePostoji:                                 ; Ako ne postoji, ispisati poruku o gresci  
        mov     si, NePostojiDat
        call    _print_string
		ret
		
.Ucitaj:									; Datoteka postoji
        mov     cx, PocetakTeksta           ; Ucitavamo datoteku u radnu memoriju
        call    _load_file		
		mov		word [Velicina], bx
		mov		bx, PocetakTeksta
		mov		cx, word [Velicina]
		call	_print_file					; Pozivamo funkciju dodavanja u red za stampanje
		jc		.Greska
		mov     si, UspesnoDodato
		call	_print_string
		ret
		
.Greska		
		mov		si, Neuspesno
		call	_print_string	
		ret
		

; ------------------------------------------------------------------------------------		
	NijeZadatoIme   db 10, 13, 'Greska: nije zadato ime datoteke.', 13, 10, 0
	NePostojiDat	db 10, 13, 'Greska: datoteka ne postoji.', 13, 10, 0
	Velicina		dw 0
	UspesnoDodato	db 10, 13, 'Datoteka uspesno dodata u queue', 13, 10, 0
	Neuspesno		db 10, 13, 'Greska: Datoteka nije dodata u queue', 13, 10, 0		
; ------------------------------------------------------------------------------------		