; ==================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ==================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Rutine za rad sa stringovima
; ------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
; ------------------------------------------------------------------

; ------------------------------------------------------------------
; _string_length -- Vraca duzinu stringa
; Ulaz: AX = pointer na pocetak stringa
; Izlaz: AX = duzina u bajtovoma (bez zavrsne nule)
; ------------------------------------------------------------------

_string_length:
        pusha
        mov     bx, ax                      ; Adresa pocetka stringa u BX
        mov     cx, 0                       ; Brojac bajtova
.Dalje:
        cmp byte [bx], 0                    ; Da li se na lokaciji na koju pokazuje 
        je     .Kraj                        ; pointer nalazi nula (kraj stringa)?
        inc     bx                          ; Ako nije nula, uvecaj brojac za jedan
        inc     cx                          ; i pomeri pointer na sledeci bajt.
        jmp    .Dalje
.Kraj:
        mov word [.TmpBrojac], cx           ; Privremeno sacuvati broj bajtova
        popa                                ; jer vacamo sve registre sa steka (tj. menjamo AX).
        mov     ax, [.TmpBrojac]            ; Vracamo broj bajtova (duzinu stringa) u AX.
        ret

       .TmpBrojac    dw 0

; ------------------------------------------------------------------
; _string_reverse -- Invertovati redosled znakova u stringu
; Ulaz: SI = pointer na pocetak stringa 
; SI pokazuje i na pocetak invertovanog stringa
; ------------------------------------------------------------------

_string_reverse:
        pusha
        cmp byte [si], 0                    ; Ne pokusavati invertovanje praznog stringa
        je     .Izlaz
        mov     ax, si
        call    _string_length
        mov     di, si
        add     di, ax
        dec     di                          ; DI pokazuje na poslednji (nenulti) znak u stringu 
.Sledeci:
        mov byte al, [si]                   ; Zamena mesta bajtovima (swap)
        mov byte bl, [di]
        mov byte [si], bl
        mov byte [di], al
        inc     si                          ; Pomeri pointere ka sredini stringa
        dec     di
        cmp     di, si                      ; Da li su oba pointera stigla na sredinu ili  
        ja     .Sledeci                     ; prosla sredinu stringa? (JA = Jump if Above)
.Izlaz:
        popa
        ret

; ------------------------------------------------------------------
; _find_char_in_string -- Pronadji znak u stringu
; Ulaz: SI = pointer na pocetak stringa, AL = znak koji se trazi
; Izlaz: AX = prva pozicija znaka koji trazi, ili 0 ako ga nema
; ------------------------------------------------------------------

_find_char_in_string:
        pusha
        mov     cx, 1                       ; Brojac znakova (pozicija) - pocinje od 1
.Dalje:
        cmp byte [si], al
        je     .Kraj                        ; Pronasli smo znak - CX sadrzi njegovu poziciju
        cmp     byte [si], 0                ; Da li je kraj stringa?
        je     .NismoNasli
        inc     si
        inc     cx
        jmp    .Dalje
.Kraj:
        mov     [.tmp], cx                  ; Privremeno cuvamo poziciju
        popa                                ; jer vracamo predhodni sadrzaj registara
        mov     ax, [.tmp]
        ret
.NismoNasli:
        popa
        mov     ax, 0                       ; Nismo pronasli znak
        ret

       .tmp     dw 0

; -------------------------------------------------------------------------
; _string_charchange -- Zamena svake pojave znaka u stringu drugim znakom
; Ulaz: SI = pointer na pocetak stringa, AL = stari znak, BL = novi znak
; -------------------------------------------------------------------------

_string_charchange:
        pusha
        mov     cl, al
.Sledeci:
        mov byte al, [si]                   ; Ucitaj znak
        cmp     al, 0                       ; Da li je to kraj stringa?
        je     .Izlaz
        cmp     al, cl                      ; Ako nije kraj stringa, da li je to trazeni znak?
        jne    .NeMenjaj
        mov byte [si], bl                   ; Ako jeste, izvrsi zamenu
.NeMenjaj:
        inc     si                          ; Sledeci znak
        jmp    .Sledeci
.Izlaz:
        popa
        ret

; -------------------------------------------------------------------
; _string_uppercase -- Konverzija ASCII stringa u velika slova
; Ulaz/Izlaz: AX = pointer na pocetak stringa
; Konvertuju se samo slova od a do z. Brojevi i ostali znaci ostaju.
; -------------------------------------------------------------------

_string_uppercase:
        pusha
        mov     si, ax			
.Dalje:
        cmp byte [si], 0                    ; Da li je kraj stringa?
        je     .Kraj			
        cmp byte [si], 'a'                  ; Da li je znak u ASCII opsegu 'a' do 'z'?
        jb     .NijeZnak
        cmp byte [si], 'z'
        ja     .NijeZnak
        sub byte [si], 20h                  ; Ako jeste, izvrsi ASCII konverziju
        inc     si
        jmp    .Dalje
.NijeZnak:
        inc     si
        jmp    .Dalje
.Kraj:
        popa
        ret

; ------------------------------------------------------------------
; _string_lowercase -- Konverzija ASCII stringa u mala slova
; Ulaz/Izlaz: AX = pointer na pocetak stringa
; Konvertuju se samo slova od A do Z. Ostali znaci ostaju.
; ------------------------------------------------------------------

_string_lowercase:
        pusha
        mov     si, ax			
.Dalje:
        cmp byte [si], 0                    ; Da li je kraj stringa?
        je     .Kraj			
        cmp byte [si], 'A'                  ; Da li je znak u ASCII opsegu 'A' do 'Z'?
        jb     .NijeZnak
        cmp byte [si], 'Z'
        ja     .NijeZnak
        add byte [si], 20h                  ; Ako jeste, izvrsi ASCII konverziju
        inc     si
        jmp    .Dalje
.NijeZnak:
        inc     si
        jmp    .Dalje
.Kraj:
        popa
        ret

; --------------------------------------------------------------------
; _string_copy -- Kopiranje jednog stringa u drugi
; Ulaz/Izlaz: SI = izvorni, DI = odredisni
; --------------------------------------------------------------------

_string_copy:
        pusha
.Dalje:
        mov     al, [si]                    ; Kopirmo jedan bajt, 
        mov     [di], al                    ; makar to bio i samo zavrsni (nula)
        inc     si
        inc     di
        cmp byte al, 0                      ; Ako je izvorni string prazan, kraj
        jne    .Dalje
        popa
        ret


; -----------------------------------------------------------------------
; _string_truncate -- Odsecanje stringa sleva
; Ulaz: SI = pocetak stringa, AX = broj znakova koji ostaju sa leve strane
; -----------------------------------------------------------------------

_string_truncate:
        pusha
        add     si, ax
        mov byte [si], 0
        popa
        ret

; -------------------------------------------------------------------
; _string_join -- Spajanje dva stringa u treci string
; Ulaz/Izlaz: AX = prvi string, BX = drugi string , CX = odredisni string
; -------------------------------------------------------------------

_string_join:
        pusha
        mov     si, ax                      ; Kopiramo prvi string na lokaciju odredisnog
        mov     di, cx
        call    _string_copy
        call    _string_length              ; Duzina prvog stringa
        add     cx, ax                      ; Postavljamo pointer na zavrsni bajt (0)  
        mov     si, bx                      ; odredisnog stringa 
        mov     di, cx
        call    _string_copy                ; Kopiramo drugi string od tog mesta
        popa
        ret

; ---------------------------------------------------------------------   
; _string_chomp -- Odsecanje pocetnih i krajnjih 'Space' znakova
; Ulaz: AX = pointer na pocetak stringa
; Broj bajtova zauzete memorije ostace isti kao i pre poziva ove rutine 
; ---------------------------------------------------------------------

_string_chomp:
        pusha
        mov     dx, ax                      ; Sacuvati originalni pocetak stringa
        mov     di, ax             
        mov     cx, 0                       ; Brojac 'Space' znakova
.Nastavi:				                
        cmp byte [di], ' '                  ; Brojanje 'Space' znakova
        jne    .Izbrojani
        inc     cx
        inc     di
        jmp    .Nastavi
.Izbrojani:
        cmp     cx, 0                       ; Nema pocetnih 'Space' znakova?
        je     .KrajKopiranja
        mov     si, di                      ; Adresa prvog znaka koji nije 'Space'
        mov     di, dx                      ; DI = originalni pocetak stringa
.KopirajDalje:
        mov     al, [si]                    ; Premesti string bez pocetnih 'Space' znakova
        mov     [di], al                    ; na pocetak originalnog stringa
        cmp     al, 0                       ; ukljucujuci i zavrsni bajt (nulu)
        je     .KrajKopiranja
        inc     si
        inc     di
        jmp    .KopirajDalje
.KrajKopiranja:
        mov     ax, dx                      ; AX = originalni pocetak stringa
        call    _string_length         
        cmp     ax, 0                       ; Ukoliko je njegova duzna = 0, kraj
        je     .Kraj
        mov     si, dx
        add     si, ax                      ; Idemo na kraj stringa
.Dalje:
        dec     si                          ; Unazad proveravamo da li je 'Space'
        cmp byte [si], ' '
        jne    .Kraj                        ; Kraj ako smo naisli na znak koji nije 'Space'
        mov byte [si], 0                    ; Pronadjena mesta popunjavamo nulama 
        jmp    .Dalje                       ; (prva nula oznacava kraj stringa, ostale se ne koriste)
.Kraj:
        popa
        ret

; ---------------------------------------------------------------------------
; _string_strip -- Uklanja zadati znak iz stringa maksimalne duzine 255
; Ulaz: SI = pointer na pocetak stringa, AL = znak kojeg treba ukloniti
; Broj bajtova zauzete memorije ostace isti kao i pre poziva ove rutine 
; ---------------------------------------------------------------------------

_string_strip:
        pusha
        mov     di, si                      ; Inicijalizacija pointera za LODSB i STOSB 
        mov     bl, al                      ; Sacuvati znak u BL jer LODSB i STOSB koriste AL
.SledeciZnak:
        lodsb                               ; Inkrementalno premestanje stringa
        stosb
        cmp     al, 0                       ; Da li smo stigli na kraj stringa?
        je     .Izlaz                     
        cmp     al, bl                      ; Da li je ovo znak koji trazimo?
        jne    .SledeciZnak                 ; Ako nije, idemo na sledeci znak
.Preskoci:                                      
        dec     di                          ; Ako jeste, dekrementiramo pointer DI, tako da 
        jmp    .SledeciZnak                 ; u sledecem prolazu prepisujemo preko tog znaka
.Izlaz:
        popa
        ret

; ------------------------------------------------------------------
; _string_compare -- Poredi dva stringa
; Ulaz: SI = prvi string, DI = drugi string
; Izlaz: CF = 1 ako su isti, CF = 0 ako su razliciti
; ------------------------------------------------------------------

_string_compare:
        pusha
.Dalje:
        mov     al, [si]                    ; Ucitati po jedan znak iz svakog stringa
        mov     bl, [di]
        cmp     al, bl                      ; Uporediti ucitane znakove
        jne    .NisuIsti
        cmp     al, 0                       ; Kraj stringa? Ako su isti, ovo je kraj i drugog stringa.
        je     .Zavrsen
        inc     si                          ; Ponteri na sledeci znak u stringovima
        inc     di
        jmp    .Dalje
.NisuIsti:                                  ; Ukoliko se razlikuju 
        popa                                
        clc                                 ; CF = 0
        ret
.Zavrsen:                                   ; Kraj i jednog i drugog stringa
        popa
        stc                                 ; CF = 1
        ret

; -------------------------------------------------------------------------
; _string_strincmp -- Poredi prvih n znakova zadatih stringova
; Ulaz: SI = prvi string, DI = drugi string, CL = broj znakova (n)
; Izlaz: CF = 1 ako su isti, CF = 0 ako su razliciti
; -------------------------------------------------------------------------

_string_strincmp:
        pusha
.Dalje:
        mov     al, [si]                    ; Ucitati po jedan znak iz svakog stringa
        mov     bl, [di]
        cmp     al, bl                      ; Uporediti ucitane znakove
        jne    .NisuIsti
        cmp     al, 0                       ; Kraj stringa? Ako su isti, ovo je kraj i drugog stringa.
        je     .Zavrsen
        inc     si
        inc     di
        dec     cl                      
        cmp     cl, 0                       ; Ukoliko smo prosi n puta, trazeni broj znakova se poklapa
        je     .Zavrsen
        jmp    .Dalje
.NisuIsti:                                  ; Ukoliko se razlikuju 
        popa			
        clc                                 ; CF = 0
        ret
.Zavrsen:                                   ; Kraj i jednog i drugog stringa
        popa
        stc                                 ; CF =1 
        ret

; ----------------------------------------------------------------------
; _string_parse -- Parsira string koji sadrzi prazna mesta
; (npr. "komanda arg1 agr2 arg3") i vraca pointere na odvojene stringove
; (npr. AX na "komanda", BX na "arg1", CX na "arg2" i DX na "arg3")
; Ulaz: SI = pocetni string; Izlaz: AX, BX, CX, DX = pojedinacni stringovi
; Pointeri pokazuju na novostvorene podstringove u pocetnom stringu ! 
; Zauzece memorije se ne menja.
; -----------------------------------------------------------------------

_string_parse:
        push    si
        mov     ax, si                      ; AX = pocetak prvog podstringa
        mov     bx, 0                       ; Ostali podstringovi pocinju kao prazni
        mov     cx, 0
        mov     dx, 0
        push    ax                          ; Sacuvati kao povratnu vrednost za kraj
.Sledeci1:
        lodsb                               ; Ucitati bajt
        cmp     al, 0                       ; Kraj stringa?
        je     .Izlaz
        cmp     al, ' '                     ; Prazno mesto?
        jne    .Sledeci1
        dec     si
        mov byte [si], 0                    ; Ako je prazno mesto, zavrsi podstring nulom
        inc     si                          ; Sacuvati adresu sledeceg znaka u BX
        mov     bx, si
.Sledeci2:                                  ; Ponovi gornji algoritam za CX i DX  
        lodsb
        cmp     al, 0
        je     .Izlaz
        cmp     al, ' '
        jne    .Sledeci2
        dec     si
        mov byte [si], 0
        inc     si
        mov     cx, si                      ; Sacuvati adresu sledeceg znaka u CX
.Sledeci3:
        lodsb
        cmp     al, 0
        je     .Izlaz
        cmp     al, ' '
        jne    .Sledeci3
        dec     si
        mov byte [si], 0
        inc     si
        mov     dx, si                      ; Sacuvati adresu sledeceg znaka u DX
.Izlaz:
        pop     ax
        pop     si
        ret
        
; ------------------------------------------------------------------
; _string_to_int -- Konvertuje decimalni string u int
; Ulaz: SI = pocetak stringa (maksimalno 5 znakova, do '65536')
; Izlaz: AX = celobrojna vrednost (int)
; -------------------------------------------------------------------
_string_to_int:
        pusha
        mov     ax, si                      ; Duzina stringa
        call    _string_length
        add     si, ax                      ; Pocinjemo od znaka sa krajnje desne strane
        dec     si
        mov     cx, ax                      ; Duzina stringa se koristi kao brojac znakova
        mov     bx, 0                       ; U BX ce biti trazena celobrojna vrednost
        mov     ax, 0

      ; Racunamo decimalnu vrednost kod pozicionog sistema sa osnovom 10        

        mov word [.multiplikator], 1        ; Prvi znak mnozimo sa 1
.Sledeci:
        mov     ax, 0
        mov byte al, [si]                   ; Uzimamo znak
        sub     al, 48                      ; Konvertujemo iz ASCII u broj
        mul word [.multiplikator]           ; Mnozimo sa pozicijom
        add     bx, ax                      ; Dodajemo u BX
        push    ax                          ; Mnozimo multiplikator sa 10
        mov word ax, [.multiplikator]
        mov     dx, 10
        mul     dx
        mov word [.multiplikator], ax
        pop     ax
        dec     cx                          ; Da li ima jos znakova
        cmp     cx, 0
        je     .Izlaz
        dec     si                          ; Pomeramo se na sledecu poziciju ulevo
        jmp    .Sledeci
.Izlaz:
        mov word [.tmp], bx                 ; Privremeno cuvamo dobijeni int zbog 'popa'
        popa
        mov word ax, [.tmp]
        ret

       .multiplikator   dw 0  
       .tmp             dw 0

; -----------------------------------------------------------------------
; _int_to_string -- Konvertuje unsigned int u string decimalnih brojeva
; Ulaz: AX = unsigned int
; Izlaz: AX = pocetak stringa
; ------------------------------------------------------------------

_int_to_string:
        pusha
        mov     cx, 0
        mov     bx, 10                      ; BX = 10, za div 10 i mod 10
        mov     di, .t                      ; Pointer na mesto gde ce se smestiti string 
.push:
        mov     dx, 0
        div     bx                          ; Rezutatat je u AX, a ostatak u DX
        inc     cx              
        push    dx                          ; Stavljamo ostatak na stek da bismo invertovali redosled
        test    ax, ax                      ; Da li je rezultat 0?
        jnz    .push                        ; Ako nije, nastavljamo dalje
.pop:
        pop     dx                          ; Uzimamo vrednosti sa steka i konvertijemo ih 
        add     dl, '0'                     ; u ASCII vrednosti.
        mov     [di], dl                    ; String snimamo u memoriju (na koju pokazuje DI) 
        inc     di
        dec     cx
        jnz    .pop
        mov byte [di], 0                    ; Oznacavamo kraj stringa
        popa
        mov     ax, .t                      ; Vracamo u AX pocetak strnga 
        ret

       .t times 7 db 0

; ------------------------------------------------------------------
; _sint_to_string -- Konvertuje signed int u decimalni string
; Ulaz: AX = signed int
; Izlaz: AX = pocetak stringa
; ------------------------------------------------------------------

_sint_to_string:
        pusha
        mov     cx, 0
        mov     bx, 10                      ; BX = 10, za div 10 i mod 10
        mov     di, .t                      ; Pointer na mesto gde ce se smestiti string 
        test    ax, ax                      ; Da li je zadata vrednost >= 0
        js     .neg                         ; Vrednsot je negativna
        jmp    .push                        
.neg:
        neg     ax                          ; Negativnu vrednost u AX pravimo pozitivnom
        mov byte [.t], '-'                  ; i dodajemo znak za minus na pocetak stringa
        inc     di                          ; sledece mesto za ASCII znak
.push:
        mov     dx, 0
        div     bx                          ; Rezutatat je u AX, a ostatak u DX
        inc     cx   
        push    dx                          ; Stavljamo ostatak na stek da bismo invertovali redosled
        test    ax, ax                      ; Da li je rezultat 0?
        jnz    .push                        ; Ako nije, nastavljamo dalje
.pop:
        pop     dx                          ; Uzimamo vrednosti sa steka i konvertijemo ih 
        add     dl, '0'                     ; u ASCII vrednosti
        mov     [di], dl                    ; String snimamo u memoriju (na koju pokazuje DI)
        inc     di
        dec     cx
        jnz    .pop
        mov byte [di], 0                    ; Oznacavamo kraj stringa
        popa
        mov     ax, .t                      ; Vracamo u AX pocetak strnga
        ret

       .t times 7 db 0

; -----------------------------------------------------------------
; _long_int_to_string -- Konvertuje long int (32 bita) u string       
; Ulaz: DX:AX = long unsigned int, BX = brojna osnova, DI = string 
; Izlaz: DI = string sa koji predstavlja broj u trazenoj osnovi
; -----------------------------------------------------------------

_long_int_to_string:
        pusha
        mov     si, di                      ; Pocetak stringa zadaje programer
        mov word [di], 0                    ; Oznaka za kraj stringa
        cmp     bx, 37                      ; Brojne osnove > 37 ili < 0 nisu podrzane. Vrati gresku (null).
        ja     .Kraj
        cmp     bx, 0                       ; Brojna osnova = 0 pravi prekoracenje (overflow). Vrati gresku (null).
        je     .Kraj

.Konverzija:
        mov     cx, 0                       ; Prosiri broj nulama. Sada je broj = CX:DX:AX
                                            ; Ukoliko je broj = 0, idemo samo jednom kroz petlju i snimamo '0'
        xchg    ax, cx                      ; Sada je broj u obliku DX:AX:CX za deljenje viseg reda
        xchg    ax, dx
        div     bx                          ; AX = visi rezultat, DX = visi ostatak
        xchg    ax, cx                      ; Redosled za deljenje nizeg reda
        div     bx                          ; CX = visi rezultat, AX = nizi rezultat, DX = ostatak
        xchg    cx, dx                      ; CX = dobijena cifra

        cmp     cx, 9                       ; Preskacemo ASCII znake interpunkcije izmedju '9' and 'A'
        jle    .KonvertujCifru
        add     cx, 'A'-'9'-1

.KonvertujCifru:
        add     cx, '0'                     ; Konvertujemo u ASCII
        push    ax                          ; Upisuje se ova ASCII cifra na pocetak stringa
        push    bx
        mov     ax, si
        call    _string_length              ; AX = duzina stringa (bez zavrsne nule)
        mov     di, si
        add     di, ax                      ; DI = kraj stringa
        inc     ax                          ; AX = broj znakova koje treba premestiti, ukljucujuci i zavrsnu nulu

.StringNaGore:
        mov     bl, [di]                    ; Stavljamo cifre u pravilni redosled
        mov     [di+1], bl
        dec     di
        dec     ax
        jnz    .StringNaGore
        pop     bx
        pop     ax
        mov     [si], cl                    ; Poslednja cifra ce sada biti prva (na levoj strani)
        mov     cx, dx                      ; DX = ponovo gornja rec
        or      cx, ax                      ; Da li je jos nesto preostalo?
        jnz    .Konverzija
.Kraj:
        popa
        ret  
 
; -----------------------------------------------------------------------
; _get_time_string -- Tekuce vreme u obliku stringa (npr. '10:25:07')
; Ulaz/Izlaz: BX = lokacija stringa (zadaje programer uz obezbedjenu memoriju)
; -----------------------------------------------------------------------

%define T_SEPARATOR   ':'

_get_time_string:
        pusha
        mov     di, bx                      ; Mesto gde se smesta string sa vremenom 
        clc                                 ; Za svaku sigurnost
        mov     ah, 2                       ; Uzimamo BIOS vreme u BCD obliku
        int     1Ah                         ; BIOS vraca vreme u obliku CH: sati, CL: minuti, DH: sekunde 
        jnc    .Citaj
        clc
        mov     ah, 2                       ; BIOS je vrsio osvezavanje, probati ponovo
        int     1Ah
.Citaj:
        mov     al, ch                      ; Sati
        shr     al, 4                       ; Premestamo BCD desetice u donji nibl
        and     ch, 0Fh                     ; BCD jedinice
        call    DodajCifru
        mov     al, ch                      ; Isto se ponavlja za minute (CL) i sekunde (DH)
        call    DodajCifru
        mov     al, T_SEPARATOR
        stosb
        mov     al, cl                      ; Minuti
        shr     al, 4			
        and     cl, 0Fh	
        call    DodajCifru
        mov     al, cl
        call    DodajCifru
        mov     al, T_SEPARATOR
        stosb
        mov     al, dh                      ; Sekunde
        shr     al, 4
        and     dh, 0Fh 
        call    DodajCifru
        mov     al, dh
        call    DodajCifru
        mov     al, 0                       ; Kraj stringa
        stosb
        popa
        ret

; -----------------------------------------------------------------------
; _get_date_string -- Tekuci datum u obliku stringa (npr. '15.8.2010')
; Ulaz/Izlaz: BX = lokacija stringa (zadaje programer uz obezbedjenu memoriju)
; -----------------------------------------------------------------------

%define D_SEPARATOR   '.'

_get_date_string:
        pusha
        mov     di, bx                      ; Mesto gde se smesta string sa datumom 		
        clc                                 ; Za svaku sigurnost
        mov     ah, 4                       ; Uzimamo BIOS datum u BCD obliku
        int     1Ah                         ; BIOS vraca datum u obliku CH: vek, CL: godina (dvocifreno),
        jnc    .Citaj                       ; DH: mesec, DL: dan
        clc
        mov     ah, 4                       ; BIOS je vrsio osvezavanje, probati ponovo
        int     1Ah
.Citaj:
        mov     ah, dl                      ; Dan
        call   .Dodaj2Cifre
        mov     al, D_SEPARATOR
        stosb				
        mov     ah, dh                      ; Mesec
        call   .Dodaj2Cifre		
        mov     al, D_SEPARATOR
        stosb
        mov     ah, ch                      ; Vek
        call   .Dodaj2Cifre		
        mov     ah, cl                      ; Godina
        call   .Dodaj2Cifre		
        mov     ax, 0                       ; Kraj stringa
        stosw
        popa
        ret

.Dodaj2Cifre:
        mov     al, ah                      ; Konvertuje AH u dve ASCII cifre
        shr     al, 4
        call    DodajCifru
        mov     al, ah
        and     al, 0Fh
        call    DodajCifru
        ret
              
DodajCifru:  
        add     al, '0'	                    ; Konvertuje AL u ASCII cifru
        stosb                               ; i stavlja rezultat u bafer
        ret





