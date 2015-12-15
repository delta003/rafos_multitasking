; ==================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ==================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
;
; Jednostavni sintesajzer preko ugradjenog zvucnika
; Demonstrira upotrebu tastature, alfanumerickog crtanja na ekranu
; i programiranje ugradjenog zvuka (ne i zvicne kartice!)
; ------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
; ------------------------------------------------------------------

%include "OS_API.inc"

%macro  IspisiZnak 1
        add     dl, 4
        call    OS:_move_cursor
        mov     al, %1
        int     10h 
%endmacro

%macro  CrniTaster 1
        mov     dh, 6
        mov     dl, (26 + (%1-1)*4)
        mov     si, 3
        mov     di, 13
        call    OS:_draw_block
%endmacro

%macro  Povezi 2
        cmp     al, %1
        jne   %%Izlaz
        mov     ax, %2
        mov     bx, 0
        call    OS:_speaker_tone
        jmp    .Ponovi
%%Izlaz:
%endmacro


Start:
        call    OS:_get_app_offset          ; nadji offset
        mov     word [app_offset], ax

        call    OS:_hide_cursor
        call    OS:_clear_screen
        mov     ax, Naslov                  ; Podesavanje ekrana
        add     ax, word [app_offset]
        mov     bx, Fusnota
        add     bx, word [app_offset]
        mov     cx, BELO_NA_PLAVOM  
        call    OS:_draw_background            ; Iscrtava pozadinu sa zaglavljima (Naslov i Fusnota)
        
        mov     bl, CRNO_NA_BELOM           ; Boja se za blok bira na osnovu pozadine (ovde bela)
        mov     dh, 4                       ; Gornji levi ugao belog bloka (linija 4, kolona 5)
        mov     dl, 5
        mov     si, 69                      ; Sirina belog bloka 69 znakova
        mov     di, 21                      ; Poslednja linija belog bloka                      
        call    OS:_draw_block                 ; Iscrtava beli blok 

          
; ---------------------------
; Iscrtavamo okvir tastature
; ---------------------------
; ------------------
; Gornja linija
        mov     dl, 24                      ; Kolona 24        
        mov     dh, 6                       ; Linija 6
        call    OS:_move_cursor
        mov     ah, 0Eh
        mov     al, 196                     ; IBM graficki znak za crticu
        mov     cx, 31                      ; Sirina 31 znak
.Petlja1:
        int     10h
        loop   .Petlja1

; ------------------
; Donja linija

        mov     dl, 24                      ; Kolona 24                   
        mov     dh, 18                      ; Linija 18
        call    OS:_move_cursor
        mov     ah, 0Eh
        mov     al, 196                     ; IBM graficki znak za crticu
        mov     cx, 31                      ; Sirina 31 znak
.Petlja2:
        int     10h
        loop   .Petlja2

; -----------------------------------------------------------------
; IBM graficki simboli za spajanje linija (uglovi okvira tastature)
 
        mov     dl, 23                      ; Gornji levi ugao
        mov     dh, 6
        call    OS:_move_cursor
        mov     al, 218                     ; IBM graficki znak 
        int     10h

        mov     dl, 55                      ; Gornji desni ugao
        mov     dh, 6
        call    OS:_move_cursor
        mov     al, 191                     ; IBM graficki znak 
        int     10h

        mov     dl, 23                      ; Donji levi ugao
        mov     dh, 18
        call    OS:_move_cursor
        mov     al, 192                     ; IBM graficki znak 
        int     10h

        mov     dl, 55                      ; Donji desni ugao
        mov     dh, 18
        call    OS:_move_cursor
        mov     al, 217                     ; IBM graficki znak 
        int     10h

; ------------------------------------------------------------------      
; Iscrtavanja vertikalnih linija okvira tastaure     
 
        mov     dl, 23                      ; Linija sa leve strane
        mov     dh, 7
        mov     al, 179                     ; IBM graficki znak za vertikalnu crticu
.Petlja3:
        call    OS:_move_cursor
        int     10h
        inc     dh
        cmp     dh, 18                      ; Visina vertikalne linije je 18 znakova
        jne    .Petlja3

        mov     dl, 55                      ; Linija sa desne strane
        mov     dh, 7
        mov     al, 179                     ; IBM graficki znak za vertikalnu crticu
.Petlja4:
        call    OS:_move_cursor
        int     10h
        inc     dh
        cmp     dh, 18                      ; Visina vertikalne linije je 18 znakova
        jne    .Petlja4

; ------------------------------------------------------------------        
; Linije za razdavajanje tastera        
; Visine vertikalnih linija su 18 znakova 
; Ima ukupno 7 linija i 2x7 IBM grafickih znakova 
; za spajanje linija (kod 193 za donje i kod 194 za gornje)
; ------------------------------------------------------------------ 
   
        mov     dl, 23	
        
.VelikaPetlja:
        add     dl, 4
        mov     dh, 7
        mov     al, 179                     ; IBM graficki znak za vertikalnu crticu
.Petlja5:
        call    OS:_move_cursor
        int     10h
        inc     dh
        cmp     dh, 18
        jne    .Petlja5
        cmp     dl, 51
        jne    .VelikaPetlja

        mov     al, 194                     ; IBM graficki znak za gornje sapajanje
        mov     dh, 6
        mov     dl, 27
.Petlja6:
        call    OS:_move_cursor
        int     10h
        add     dl, 4
        cmp     dl, 55
        jne    .Petlja6

        mov     al, 193                     ; IBM graficki znak za donje sapajanje
        mov     dh, 18
        mov     dl, 27
.Petlja7:
        call    OS:_move_cursor
        int     10h
        add     dl, 4
        cmp     dl, 55
        jne    .Petlja7

; ------------------------------------------------------------------
; Sada crtamo crne tastere (njih 5) ...

        mov     bl, BELO_NA_CRNOM
        
        CrniTaster 1
        CrniTaster 2
        CrniTaster 4                        ; Mesto br. 3 preskacemo jer izmedju E i F nemamo polustepen
        CrniTaster 5
        CrniTaster 6
  
; ------------------------------------------------------------------
; Na kraju, ispisujemo koji (racunarski) taster treba pritisnuti
; za dobijanje odgovarajuceg zvuka

        mov     ah, 0Eh
        mov     dh, 17       
        mov     dl, 21
        
        IspisiZnak 'Z'
        IspisiZnak 'X'
        IspisiZnak 'C'
        IspisiZnak 'V'
        IspisiZnak 'B'
        IspisiZnak 'N'
        IspisiZnak 'M'
        IspisiZnak ','
        
; ------------------------------------------------------------------
; Nacrtali smo klavijaturu i obelezili tastere
; Sada ih pojedinacno povezujemo sa visinom tona

.Ponovi:
        call    OS:_wait_for_key
   
        Povezi 'z', 4000
        Povezi 'x', 3600
        Povezi 'c', 3200
        Povezi 'v', 3000
        Povezi 'b', 2700
        Povezi 'n', 2400
        Povezi 'm', 2100
        Povezi ',', 2000
 
        cmp     al, ' '
        jne    .Zavrsetak
        call    OS:_speaker_off
        jmp    .Ponovi

.Zavrsetak:
        cmp     al, 'q'
        je     .Kraj
        cmp     al, 'Q'
        je     .Kraj
        jmp    .Ponovi

.Kraj:
        call    OS:_speaker_off
        call    OS:_clear_screen
        call    OS:_show_cursor
        call    OS:_sys_exit            ; Povratak u shell			                        

    Naslov  db 'RAF_OS demo klavijatura', 0
    Fusnota db 'Pritisni odgovarajuci taster za zvuk, Space za prekid zvuka, Q za izlaz', 0

    app_offset dw 0


