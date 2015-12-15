; ==================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ==================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Matematicke rutine
;
; ------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
; ------------------------------------------------------------------

; -----------------------------------------------------------------
; _seed_random -- Pocetna vrednost generatora slucajnih brojeva
; na osnovu vrednosti tekuceg vremena sistemskog casovnika
; Ulaz/Izlaz: -
; -----------------------------------------------------------------

_seed_random:
        push    bx
        push    ax
        mov     bx, 0
        mov     al, 0x02                    ; Minuti
        out     0x70, al
        in      al, 0x71
        mov     bl, al
        shl     bx, 8
        mov     al, 0                       ; Sekunde
        out     0x70, al
        in      al, 0x71
        mov     bl, al                      ; Pocetna vrednost se nalazi u BX u obliku mmss     
        mov word [RandomSeed], bx           ; gde su mm minuti, a ss sekundi protekli od punog sata
        pop     ax
        pop     bx
        ret

        RandomSeed dw 0

; -------------------------------------------------------------------
; _get_random -- Vraca slucajnu vrednost izmedju donje i gornje
; Ulaz:  AX = donja celobrojna vrednost, BX = gornja celobrojna vrednost
; Izlaz: CX = slucajna celobrojna vrednost
; -------------------------------------------------------------------

_get_random:
        push    dx
        push    bx
        push    ax
        sub     bx, ax                      ; Trazimo broj izmedju 0 i (gornja - donja)
        call   .GenerisiBroj
        mov     dx, bx
        add     dx, 1
        mul     dx
        mov     cx, dx
        pop     ax
        pop     bx
        pop     dx
        add     cx, ax                      ; Vratiti donji ofset
        ret

.GenerisiBroj:
        push    dx
        push    bx
        mov     ax, [RandomSeed]
        mov     dx, 0x7383                  ; Magicni broj (videti random.org) 
        mul     dx                          ; DX:AX = AX * DX
        mov     [RandomSeed], ax
        pop     bx
        pop     dx
        ret

; ------------------------------------------------------------------
; _bcd_to_int -- Konverzija BCD u celobrojnu vrednost
; Ulaz:  AL = BCD broj
; Izlaz: AX = celobrojna vrednost
; ------------------------------------------------------------------

_bcd_to_int:
        pusha
        mov     bl, al                      ; Sacuvati privremeno BCD broj 
        and     ax, 0Fh                     ; Izdvojiti donji nibl
        mov     cx, ax                      ; CL = donji BCD broj, dopunjen nulama
        shr     bl, 4                       ; Pomeriti gornja 4 bita u donji polozaj, a gornje anuliraj
        mov     al, 10            
        mul     bl                          ; AX = 10 * BL
        add     ax, cx                      ; Dodaj donji BCD nibl na 10*gornji
        mov     [.tmp], ax
        popa
        mov     ax, [.tmp]                  ; Vrati rezultat preko AX
        ret

       .tmp     dw 0

; ------------------------------------------------------------------
; _long_int_negate -- Pomnozi broj u DX:AX sa -1
; Ulaz: DX:AX = long int;
; Izlaz: DX:AX = -(pocetna vrednost DX:AX)
; ------------------------------------------------------------------

_long_int_negate:
        neg     ax
        adc     dx, 0
        neg     dx
        ret


