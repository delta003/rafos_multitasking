; ==================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ==================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Jednostavni tekst editor. Radi sa ekranom 80x25.
;
; ------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
;
; Verzija 0.0.2 - Dodavanje datoteke u print spooler (15.01.2011).
; Vanja Petrovic Tankovic RN05/09

; Verzija 0.1.1 - Izbacen poziv BASIC interpretera (04.12.2011). 
; Stevan Milinkovic
; ------------------------------------------------------------------

    %include "OS_API.inc"                   ; RAF_OS API
    PocetakTeksta equ app_main + 1000h      ; Tekst datoteka se ucitava 4KB iza pocetka editora

    org app_main                            ; Svi aplikacioni programi se ucitavaju odavde

; ------------------------------------------------------    
; Ime datoteke mora da se zada preko komandne linije.
; Ukoliko datoteka ne postoji, treba kreirati novu. 
; ------------------------------------------------------
    
Start:
        mov     ax, 1003h                   ; Prikazi tekst sjajno, bez blinkovanja
        mov     bx, 0			
        int     10h
        cmp     byte [arg1], 0              ; Da li je zadato ime datoteke?
        jne     .ZadatoIme
        mov     si, NijeZadatoIme           ; Ako nije, ispisati poruku o gresci
        call    _print_string
        ret

.ZadatoIme:
        call    _file_exists                ; Da li datoteka postoji?
        jc     .NePostoji
        jmp    .ImeDat
    
.NePostoji:                                 ; Ako ne postoji, kreirati novu datoteku  
        mov     ax, arg1
        call    _create_file

.ImeDat:
        mov     ax, arg1
        mov     si, ax                      ; Lokalno sacuvati ime datoteke za kasniju upotrebu.
        mov     di, ImeDatoteke
        call    _string_copy 
        mov     ax, ImeDatoteke
        mov     cx, PocetakTeksta             
        call    _load_file
        mov word [Velicina], bx             ; BX sadrzi broj bajtova datoteke
        add     bx, PocetakTeksta           ; Racunamo adresu poslednjeg bajta u memoriji 
        cmp     bx, PocetakTeksta           ; Ako adresa odgovara pocetku, datoteka je prazna
        jne    .NijePrazna
        mov byte [bx], LF                   ; Ubaciti znak za novi red kojim pocinje datoteka 
        inc     bx                   
        inc word [Velicina]                 ; Uvecati velicinu datoteke za 1

.NijePrazna:
        mov word [PoslednjiBajt], bx        ; Sacuvati poziciju poslednjeg bajta datoteke
        mov     cx, 0                       ; Broj linija koje treba preskociti kod skrolovanja
        mov word [PreskociLinije], 0        ; (one ce "iznad" vidljivog ekrana).
        mov byte [KursorX], 0               ; Pocetna pozicija kursora je na pocetku teksta
        mov byte [KursorY], 2               ; Datoteka se ispisuje od druge linije na ekranu


; ----------------------------------------------------------
; Ispisivanje teksta na ekranu. Petlja za ponovo ispisivanje
; sadrzaja ekrana (rutina OblikujTekst) poziva se prilikom
; skrolovanja ekrana, upotrebe Backspace, Del. itd, ali ne
; i prilikom pomeranja kursora. 
; ----------------------------------------------------------

OblikujTekst:
        call    PodesiEkran
        mov     dh, 2                       ; Postaviti kursor na prvi znak u drugom redu 
        mov     dl, 0                       ; (preskoci prvi red zaglavlja) 
        call    _move_cursor
        mov     si, PocetakTeksta           ; Pointer na pocetak teksta u memoriji
        mov     ah, 0Eh                     ; BIOS TTY
        mov word cx, [PreskociLinije]       ; Proveravamo da li treba preskociti neku liniju (skrol)

IspisiPonovo:
        cmp     cx, 0                       ; Da li treba preskociti neku liniju?
        je      PetljaIspisivanja           ; Ako ne treba, poceti ispisivanje znakova iz bafera
        dec     cx                          ; U suprotnom, preskoci potreban broj linija

.Preskoci:
        lodsb                               ; Citati bajtove do nailaska LF, da bi se ta linija preskocila
        cmp     al, LF
        jne    .Preskoci                    ; Proveri za sledecu liniju
        jmp     IspisiPonovo

PetljaIspisivanja:                          ; Spremni za ispisivanje teksta 
        lodsb                               ; Uzeti znak iz datoteke u memoriji
        cmp     al, LF                      ; Ukoliko je uzeti znak LF, idi na pocetak linije
        jne     ProveriPoslednji
        call    _get_cursor_pos
        mov     dl, 0                       ; DL = 0 znaci kolona = 0
        call    _move_cursor

ProveriPoslednji:
        call    _get_cursor_pos             ; Da li je u pitanju poslednja kolona u liniji?
        cmp     dl, 79                      ; Ako je poslednja kolona, ne ispisujemo nista,
        je     .NeIspisuj                   ; tj. linija nema 'wrap'.
        int     10h                         ; Ispisi procitani znak

.NeIspisuj:                              
        mov word bx, [PoslednjiBajt]
        cmp     si, bx                      ; Da li su ispisani svi bajtovi iz datoteke?
        je near UnesiZnak
        call    _get_cursor_pos             ; Da li smo na dnu ekrana?
        cmp     dh, 23
        je      UnesiZnak                   ; Ako jesmo, cekamo da se pritisne neki taster
        jmp     PetljaIspisivanja           ; Ako nismo, nastavljamo sa ispisivanjem znakova

; -------------------------------------------------------------------
; Tekst je uspesno ispisan na ekranu. Sada postavljamo kursor 
; na lokaciju koju je zahtevao korisnik tako sto je pritisnuo
; neki kursorski i drugi kontrolni taster.
; -------------------------------------------------------------------

UnesiZnak:
        call    Koordinate			           
        mov byte dl, [KursorX]               ; Pomeriti kursor na poziciju kojo je zadao korisnik
        mov byte dh, [KursorY]
        call    _move_cursor
        call    _wait_for_key                ; Sacekati da korisnik pritisne neki taster
        cmp     ah, KEY_UP                   ; Da li je pritisnut neki od kursorskih tastera?
        je near IdiGore
        cmp     ah, KEY_DOWN
        je near IdiDole
        cmp     ah, KEY_LEFT
        je near IdiLevo
        cmp ah, KEY_RIGHT
        je near IdiDesno
        cmp     al, KEY_ESC                  ; Izadji iz editora ako je bio pritisnut taster Esc
        je near Zatvori
        jmp     UnosTeksta                   ; Ako nije nista od prethodnog, korisnik verovatno
                                             ; unosi normalan tekst.

; ------------------------------------------------------------------
; Pomeri kursor za jedno mesto ulevo i podesi pointer za podatke
; ------------------------------------------------------------------

IdiLevo:
        cmp byte [KursorX], 0               ; Da li smo na pocetku linije?
        je     .NeMoguUlevo
        dec byte [KursorX]                  ; Ako nismo, pomeri kursor za jedno mesto ulevo
        dec word [KursorBajt]               ; i dekrementiraj pointer za podatke u memoriji

.NeMoguUlevo:                               ; Na pocetku smo linije - ne moze vise ulevo
        jmp     UnesiZnak

; ------------------------------------------------------------------
; Pomeri kursor za jedno mesto udesno i podesi pointer za podatke
; ------------------------------------------------------------------

IdiDesno:
        pusha
        cmp byte [KursorX], 79              ; Da li smo na kraju linije?
        je     .NeRadiNista                 ; Ako jesmo, ne raditi nista
        mov word ax, [KursorBajt]
        mov     si, PocetakTeksta
        add     si, ax                      ; SI pokazuja na znak koji je ispod kursora
        inc     si                           
        cmp word si, [PoslednjiBajt]        ; Da li smo na kraju datoteke?
        je     .NeRadiNista                 ; Na moze vise desno ako smo na kraju datoteke
        dec     si
        cmp byte [si], LF                   ; Ne idemo desno ako smo na znaku za novi red
        je     .NeRadiNista
        inc word [KursorBajt]               ; Inkrementiraj pointer za podatke u memoriji
        inc byte [KursorX]                  ; Pomeri kursor za jedno mesto udesno

.NeRadiNista:
        popa
        jmp     UnesiZnak

; ------------------------------------------------------------------
; Pomeri kursor za jedno mesto nadole i podesi pointer za podatke
; ------------------------------------------------------------------

IdiDole:
	; Kao prvo, moramo da odredimo na koji ce znak kursor da
    ; pokazuje kada se pomeri za jedno mesto nadole

        pusha
        mov word cx, [KursorBajt]
        mov     si, PocetakTeksta
        add     si, cx                      ; SI pokazuje na znak ispod kursora

.Dalje:
        inc     si
        cmp word si, [PoslednjiBajt]        ; Da li pokazuje na poslednji bajt u datoteci?
        je     .NeRadiNista                 ; Ako pokazuje a poslednji bajt, ne treba raditi nista
        dec     si
        lodsb                               ; Ukoliko bajt nije poslednji, ucitaj ga
        inc     cx                          ; Pomeri se na sledecu poziciju bajta
        cmp     al, LF                      ; Da li je ucitani bajt znak za novi red?
        jne    .Dalje                       ; Pokusavaj sve dok ne naidjes na novi red
        mov word [KursorBajt], cx
	
; .nowhere_to_go:
        popa
        cmp byte [KursorY], 22              ; Ukoliko je pritisnut kursor nadole, 
        je     .SkrolujNadole               ; a nalazimo se na dnu ekrana - skroluj
        inc byte [KursorY]                  ; Ako to nije slucaj, samo pomeri kursor nadole
        mov byte [KursorX], 0               ; i postavi ga na prvu kolonu
        jmp     OblikujTekst                ; Ispisi ponovo tekst na ekranu

.SkrolujNadole:
        inc word [PreskociLinije]           ; Inkrementiraj broj linija za skrolovanje
        mov byte [KursorX], 0               ; i postavi kursor na prvu kolonu u sledecoj liniji
        jmp     OblikujTekst                ; Ispisi ponovo tekst na ekranu

.NeRadiNista:
        popa
        jmp     OblikujTekst                ; Samo ispisi tekst

; ------------------------------------------------------------------
; Pomeri kursor za jedno mesto nagore i podesi pointer za podatke
; ------------------------------------------------------------------

IdiGore:
        pusha
        mov word cx, [KursorBajt]
        mov     si, PocetakTeksta
        add     si, cx                      ; SI pokazuje na znak ispod kursora
        cmp     si, PocetakTeksta           ; Ako smo na pocetku datoteke, ne treba raditi nista
        je     .PocetakDatoteke

        mov byte al, [si]                   ; Da li je kursor na znaku za novi red?
        cmp     al, LF
        je     .NaNovojLiniji
        jmp    .Kompletiraj                 ; Ako nije, idi unazad dok ga ne pronadjes

.NaNovojLiniji:
        cmp     si, PocetakTeksta + 1
        je     .PocetakDatoteke

        cmp byte [si-1], LF                 ; Da li je znak pre ovoga znak za novi red?
        je     .JosJednaNovaLinija
        dec     si
        dec     cx
        jmp    .Kompletiraj

.JosJednaNovaLinija:                        ; Da li je znak i pre njega znak za novi red?
        cmp byte [si-2], LF
        jne    .IdiNaPocetakLinije     
        dec word [KursorBajt]               ; Korisnik je vise puta bio pritisnuo Enter (novi red)
        jmp    .PomeriDisplej               ; Mi hocemo samo da se popnemo jedan red nagore i nista vise

.IdiNaPocetakLinije:
        dec     si
        dec     cx
        cmp     si, PocetakTeksta
        je     .PocetakDatoteke
        dec     si
        dec     cx
        cmp     si, PocetakTeksta           ; Ako smo na pocetku datoteke, ne treba raditi nista
        je     .PocetakDatoteke
        jmp    .JosTrazimo

.Kompletiraj:
        cmp     si, PocetakTeksta
        je     .PocetakDatoteke
        mov     byte al, [si]
        cmp     al, LF                      ; Trazimo sve dok ne nadjemo znak za novi red
        je     .NasaoNovuLiniju
        dec     cx
        dec     si
        jmp    .Kompletiraj

.NasaoNovuLiniju:
        dec     si
        dec     cx

.JosTrazimo:
        cmp     si, PocetakTeksta
        je     .PocetakDatoteke
        mov byte al, [si]
        cmp     al, LF                      ; Trazimo znak za novi red
        je     .ZavrsioTrazenje
        dec     cx
        dec     si
        jmp    .JosTrazimo

.ZavrsioTrazenje:
        inc     cx
        mov word [KursorBajt], cx
        jmp    .PomeriDisplej

.PocetakDatoteke:
        mov word [KursorBajt], 0           ; Ponter na pocetak datoteke
        mov byte [KursorX], 0              ; Kursor na pocetak linije

.PomeriDisplej:
        popa
        cmp byte [KursorY], 2              ; Ako je pritisnut taster Up, a kursor je na vrhu, sskrolovati nagore
        je     .SkrolujNagore
        dec byte [KursorY]                 ; Ako je Up pritisnut drugde, samo pomeri kursor nagore
        mov byte [KursorX], 0              ; i idi u prvu kolonu prethodne linije
        jmp     UnesiZnak

.SkrolujNagore:
        cmp word [PreskociLinije], 0       ; Ukoliko smo u prvoj liniji, ne treba skrolovati nagore
        jle     UnesiZnak
        dec word [PreskociLinije]          ; Ako nismo, dekrementiraj broj linija za skrolovanje
        jmp     OblikujTekst
  
; --------------------------------------------------------
; Pritisnut je taster koji nije kursorski ili Esc
; To znaci da korisnik unosi ili obradjuje tekst
; -------------------------------------------------------- 
UnosTeksta:
        pusha
        cmp     ah, KEY_F1                  ; Provera koji je od komandnih tastera pritisnut             
        je  near .PritisnutF1
        cmp     ah, KEY_F2                   
        je near SnimiDatoteku
        cmp		ah, KEY_F3
		je near .PritisnutF3	
        cmp     ah, KEY_F5                   
        je near .PritisnutF5
        cmp     ah, KEY_DEL                 ; Ovo je scan_code (nije ASCII)              
        je near .PritisnutDEL
        cmp     al, KEY_BKSP
        je near .PritisnutBKSP
        cmp     al, KEY_ENTER
        je near .PritisnutENTER
        cmp     al, KEY_SPACE                
        jl near .NeRadiNista
 
        cmp     al, 127                     ; 127 je ASCII kod za Delete koji se razlicito 
        je near .NeRadiNista                ; implementira u ralicitim sistemima.

        call    _get_cursor_pos
        cmp     dl, 78
        jg near .NeRadiNista

        push    ax
        call    PomeriZnakoveUnapred
        mov word cx, [KursorBajt]
        mov     si, PocetakTeksta
        add     si, cx                      ; SI pokazuje na znak ispod kursora
        pop     ax
        mov byte [si], al
        inc word [KursorBajt]
        inc byte [KursorX]

.NeRadiNista:
        popa
        jmp     OblikujTekst

.PritisnutDEL:
        mov     si, PocetakTeksta + 1
        add si, word [KursorBajt]
        cmp si, word [PoslednjiBajt]
        je     .KrajDatoteke
        cmp byte [si], LF
        jl     .PoslednjiZnakLinije
        call    PomeriZnakoveUnazad
        popa
        jmp     OblikujTekst

.PoslednjiZnakLinije:
        call    PomeriZnakoveUnazad         ; Znak i bajt za novi red
        call    PomeriZnakoveUnazad    
        popa
        jmp     OblikujTekst

.PritisnutBKSP:
        cmp word [KursorBajt], 0
        je     .NeTrebaNista
        cmp byte [KursorX], 0
        je     .NeTrebaNista
        dec word [KursorBajt]
        dec byte [KursorX]

        mov     si, PocetakTeksta
        add     si, word [KursorBajt]
        cmp si, word [PoslednjiBajt]
        je     .KrajDatoteke
        cmp byte [si], LF
        jl     .PoslednjiZnLin
        call    PomeriZnakoveUnazad
        popa
        jmp     OblikujTekst

.PoslednjiZnLin:
        call    PomeriZnakoveUnazad         ; Znak i bajt za novi red
        call    PomeriZnakoveUnazad
        popa
        jmp     OblikujTekst

.NeTrebaNista:
        popa
        jmp     OblikujTekst

.KrajDatoteke:
        popa
        jmp     OblikujTekst

.PritisnutENTER:
        call    PomeriZnakoveUnapred
        mov word cx, [KursorBajt]
        mov     di, PocetakTeksta
        add     di, cx                       ; SI pokazuje na znak ispod kursora
        mov byte [di], LF                    ; Dodati znak za novi red
        popa
        jmp     IdiDole

.PritisnutF1:                                ; Prikazi kratak help
        mov     dx, 0                        ; upotrebom dijalog boksa
        mov     ax, .Poruka1
        mov     bx, .Poruka2
        mov     cx, .Poruka3
        call    _dialog_box
        popa
        jmp     OblikujTekst

	.Poruka1	db	'Backspace uklanja klasicne znakove,', 0
	.Poruka2	db	'a Delete uklanja znak za novi red.', 0
	.Poruka3	db	'Datoteke su Unix-formatirane (samo LF).', 0

    
.PritisnutF3:								 ; Stampanje datoteke
		mov		bx, PocetakTeksta
		mov		cx, [Velicina]
		call	_print_file
		jc		.Greska
		mov     ax, .Por1
        mov     bx, .Por2
        mov     cx, .Por3
		call	_dialog_box
		popa
		jmp		OblikujTekst
		
.Greska		
		mov     ax, .Por1
        mov     bx, .Por4
        mov     cx, .Por3
		call	_dialog_box
		popa
		jmp		OblikujTekst
		
		
	.Por1	db	'-------------------------------', 0
	.Por2	db	'Datoteka uspesno dodata u queue', 0
	.Por3	db	'-------------------------------', 0	
	.Por4	db	'Greska: Datoteka nije dodata u queue', 0	  
    
    
.PritisnutF5:                                ; Izbrisi celu liniju
        cmp byte [KursorX], 0
        je     .ZavrsioUlevo
        dec byte [KursorX]
        dec word [KursorBajt]
        jmp    .PritisnutF5

.ZavrsioUlevo:
        mov     si, PocetakTeksta
        add     si, word [KursorBajt]
        inc     si
        cmp     si, word [PoslednjiBajt]
        je     .NistaOvde
        dec     si
        cmp byte [si], 10
        je     .KonacniZnak
        call    PomeriZnakoveUnazad
        jmp    .ZavrsioUlevo

.KonacniZnak:
        call    PomeriZnakoveUnazad

.NistaOvde:
        popa
        jmp     OblikujTekst

.Izlaz:   
        popa
        jmp     OblikujTekst

; ------------------------------------------------------------------
; Operacija Insert.
; Pomera podatke od trenutne pozicije kursora jedan znak unapred.
; ------------------------------------------------------------------

PomeriZnakoveUnapred:
        pusha
        mov     si, PocetakTeksta
        add     si, word [Velicina]         ; SI = poslednji bajt u datoteci
        mov     di, PocetakTeksta
        add di, word [KursorBajt]

.Dalje:
        mov byte al, [si]
        mov byte [si+1], al
        dec     si
        cmp     si, di
        jl     .Kraj
        jmp    .Dalje

.Kraj:
        inc word [Velicina]
        inc word [PoslednjiBajt]
        popa
        ret

; ------------------------------------------------------------------
; Operacija Delete.
; Pomera podatke od trenutne pozicije kursora+1 jedan znak unazad.
; ------------------------------------------------------------------

PomeriZnakoveUnazad:
        pusha
        mov     si, PocetakTeksta
        add si, word [KursorBajt]

.Dalje:
        mov byte al, [si+1]
        mov byte [si], al
        inc     si
        cmp word si, [PoslednjiBajt]
        jne    .Dalje
        dec word [Velicina]
        dec word [PoslednjiBajt]
        popa
        ret

; --------------------------------------------------------------------
; Snimanje datoteke
; --------------------------------------------------------------------

SnimiDatoteku:
        mov     ax, ImeDatoteke             ; Obrisati datoteku
        call    _remove_file              
        mov     ax, ImeDatoteke
        mov word cx, [Velicina]
        mov     bx, PocetakTeksta
        call    _write_file                 ; Upisati podatke u novu datoteku
        jc     .Neuspesno                   ; Greska ako ne mozemo da snimimo

        mov     ax, .Uspesno                ; Greska se ispisuje upotrebom jednostavnog dialog boksa
        mov     bx, 0
        mov     cx, ImeDatoteke
        mov     dx, 0
        call    _dialog_box
        popa
        jmp     OblikujTekst

.Neuspesno:
        mov     ax, .Neuspesno1
        mov     bx, .Neuspesno2
        mov     cx, 0
        mov     dx, 0
        call    _dialog_box
        popa
        jmp     OblikujTekst

.Neuspesno1      db "      Datoteka ne moze da se snimi!      ", 0
.Neuspesno2      db "(Disk je pun ili je zasticen od snimanja)", 0
.Uspesno         db "Datoteka je uspesno snimljena:",0

; ------------------------------------------------------------------
; Izlaz iz editora
; ------------------------------------------------------------------
Zatvori:
        call    _clear_screen
        ret

; ------------------------------------------------------------------
; Podesava izgled ekrana (boje, naslovi, horizontalne linije)
; ------------------------------------------------------------------
 
PodesiEkran:
        pusha
        mov     ax, Naslov                  ; Podesavanje izgleda ekrana editora 
        mov     bx, Fusnota
        mov     cx, BELO_NA_CRNOM
        call    _draw_background
        mov     dh, 1                       ; Iscrtati linije na vrhu i dnu ekrana
        mov     dl, 0				        
        call    _move_cursor
        mov     ax, 0                       ; Jednostruka linija
        call    _print_horiz_line
        mov     dh, 23
        mov     dl, 0
        call    _move_cursor
        call    _print_horiz_line
        popa
        ret

; -----------------------------------------------------
; Ispisivanje koordinata kursora u gornjem desnom uglu
; -----------------------------------------------------

Koordinate:
        pusha
        mov     dh, 0
        mov     dl, 66
        call    _move_cursor
        
        mov     si, StringLinija
        call    _print_string
        xor     ax, ax
        mov     al, [KursorY]               ; KursorY pokazuje u kojoj smo liniji
        add     ax, word [PreskociLinije]   ; Na to se dodaje broj skrolovanih linija
        dec     ax
        call    _int_to_string
        mov     si, ax
        call    _print_string
        call    _print_space
        
        mov     si, StringKolona
        call    _print_string
        xor     ax, ax
        mov     al, [KursorX]               ; KursorX pokazuje u kojoj smo koloni (od 0 do 79)
        inc     al
        call    _int_to_string
        mov     si, ax
        call    _print_string
        call    _print_space
        popa
        ret
         
; ----------------------------------------------------------------------------------------------------
    Naslov          db 'RAF_OS jednostavni tekst editor ver. 0.1.2', 0
    Fusnota         db '[Esc] Izlaz [F1] Help [F2] Snimi [F3] Stampaj [F5] Obrisi liniju            ', 0 
    BasEkstenzija   db 'BAS', 0
    PreskociLinije  dw 0
    KursorX         db 0                    ; Pozicija kursora
    KursorY         db 0
    KursorBajt      dw 0                    ; Vrednost bajta na mestu na koje pokazuje kursor
    PoslednjiBajt   dw 0                    ; Adresa poslednjeg bajta datoteke u memoriji
    ImeDatoteke     times 12 db 0
    Velicina        dw 0
    NijeZadatoIme   db 10, 13, '[EDIT] Greska: nije zadato ime datoteke.', 13, 10, 0
    StringLinija    db 'Lin:',0
    StringKolona    db 'Kol:',0
; -----------------------------------------------------------------------------------------------------



