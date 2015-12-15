; ==========================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ==========================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; PB (Pisi Boot). Radi pod DOS-om (koristi njegove sistemske pozive). 
;
; Upisuje boot sektor zadat datotekom na komandnoj liniji,
; na CHS sektor 0,0,1 prethodno formatirane disk jedinice A:
; ---------------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
; ---------------------------------------------------------------------------

org 100h

; ------------------------------------------
; Parsujemo komandnu liniju za ime datoteke 

        mov	    ch, 01h
        mov	    di, 81h
        mov	    al, ' '
repe	scasb
        lea	    dx, [di-1]
        dec	    di
        mov	    al,13
repne	scasb
        mov byte [di-1], 0

; ------------------------------------------
; Otvaramo datoteku

        mov	    ax, 3D00h                   ; Funkcija za otvaranje datoteke samo za citanje
        int	    21h                         ; DOS sistemski poziv
        jc	    Kraj                        ; Greska pri otvaranju
        xchg	bx, ax                      ; Sacuvati deskriptor datoteke (handle) u BX

; ------------------------------------------
; Ucitavamo celokupnu datoteku 
; (prvih 512 bajtova) ciji je handle u BX

        mov	    ah, 3Fh                     ; Funkcija za citanje 
        mov	    cx, 512                     ; Velicina bafera
        mov     dx, Sektor                  ; Lokacija bafera
        int	    21h                         ; DOS sistemski poziv
        jc	    Kraj                        ; Greska pri citanju datoteke

; -------------------------------------------
; Ucitavamo originalni boot sektor sa diska A

        mov	    bp, 3                       ; 3 pokusaja citanja
        mov	    cx, 0001h                   ; CH: cilindar (0-39), CL: pocetni sektor (1-9) 
        xor	    dx, dx                      ; DH: strana (0-1), DL: disk jedinica (0-3)
        mov	    bx, Original                ; ES:BX lokacija bafera

CitajPonovo:
        mov	    ax, 0201h                   ; AH=2, BIOS funkcija za citanje, AL: Broj sektora (1)
        int	    13h
        jnc	    Procitao
        xor	    ah, ah                      ; Resetujemo disk kontroler
        int	    13h			
        dec	    bp
        jnz	    CitajPonovo
        ret			

Procitao:
        mov	    si, Original+0Bh            ; Sacuvati originalni BIOS Parameter Block (do VolumeID) 
        mov	    di, Sektor+0Bh
        mov	    cl, 32			
rep	    movsb

; ------------------------------------------
; Upisujemo bafer koji sadrzi boot sektor 

        mov	    bp, 3                       ; 3 pokusaja upisivanja
        mov	    cx, 0001h                   ; Cilindar 0, sektor 1
        mov	    bx, Sektor                  ; Lokacija bafera sa sektorom

PisiPonovo:
        mov	    ax, 0301h                   ; AH=3, BIOS funkcija za pisanje, AL: Broj sektora (1)
        int	    13h
        jnc	    Kraj
        xor	    ah, ah                      ; Resetujemo disk kontroler
        int	    13h			
        dec	    bp
        jnz	    PisiPonovo		
			
Kraj:   ret

Sektor	  times 512 db 0
Original  times 512 db 0
