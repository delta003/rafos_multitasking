; =========================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; =========================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Boot loader
; =========================================================
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
; ---------------------------------------------------------

;                              Memorija:        segment                                                 
;                 -------------------------------------                               
;                 Tabela vektora prekida           0000                          
;                 -------------------------------                               
;                 BIOS Data Area                   0040                          
;                 -------------------------------                              
;                 PrtScr Status / neiskorisceno    0050                          
;                 -------------------------------
;                 Boot sektor                      07C0                          
;                 -------------------------------                               
;                 Bafer 8KB                        07E0                         
;                 -------------------------------                              
;                 Boot stek 4KB                    09E0              
;                 -------------------------------                              
;                 Segment gde se ucitava kernel    2000  (ImageLoadSeg)                  
;                 -------------------------------       <- aplikacije se ucitavaju na 2800 
;                 Neiskorisceno                    3000  do A000                  
;                 -------------------------------                                                         
;                                                  A000  (granica od 640 KB) 

ImageLoadSeg            equ     2000h           ;  Moze da bude bilo koji slobodni segment

;-----------------------
; Pocetak boot sektora 
;-----------------------
[org 0]
        jmp     short   start
        nop
bsOemName       db      "BootProg"              ; 0x03

;-----------------------------------
; Pocetak BPB (BIOS Parameter Block)
;-----------------------------------

; Nazivi polja su na engleskom jeziku da bi se lakse poredili sa rezultatima upotrebe raznih alata

bpbBytesPerSector       dw      0               ; 0x0B
bpbSectorsPerCluster    db      0               ; 0x0D
bpbReservedSectors      dw      0               ; 0x0E
bpbNumberOfFATs         db      0               ; 0x10
bpbRootEntries          dw      0               ; 0x11
bpbTotalSectors         dw      0               ; 0x13
bpbMedia                db      0               ; 0x15
bpbSectorsPerFAT        dw      0               ; 0x16
bpbSectorsPerTrack      dw      0               ; 0x18
bpbHeadsPerCylinder     dw      0               ; 0x1A
bpbHiddenSectors        dd      0               ; 0x1C
bpbTotalSectorsBig      dd      0               ; 0x20

;----------
;Kraj BPB
;----------

bsDriveNumber           db      0               ; 0x24   izmedju ostalog, potrebno je za INT 13h, fn.2
bsUnused                db      0               ; 0x25
bsExtBootSignature      db      0               ; 0x26
bsSerialNumber          dd      0               ; 0x27
bsVolumeLabel           db      "RAF_OS.001 "   ; 0x2B
bsFileSystem            db      "FAT12   "      ; 0x36

;------------------------------
; Pocetak koda iz boot sektora         
;------------------------------

start:                                       
        mov     ax, 07C0h +32+512            ; 32 paragrafa (512B) za loader + 512 paragrafa (8KB) za bafer.
        mov     ss, ax                       ; Podesiti 4K stek odmah iza bafera.                       
        mov     sp, 1000h                    ; Vrh steka na 4096. Stek raste ka nizim adresama.
        mov     ax, 07C0h                    ; Podesiti data segment na mesto gde je ucitan loader.
        mov     ds, ax
        mov     byte [bsDriveNumber], dl     ; Sacuvati broj boot disk jedinice.

; ------------------------------------------------------------------------------
; Prvo moramo da procitamo root direktorijum sa diska.
; U Trivijalnom operativnom sistemu RAF_OS, boot se vrsi sa poznatog medijuma.
; To je prethodno formatirana disketa 1.44 MB, ciji su parametri poznati.
;
; Poctak root direktorijuma  = 
;     = bpbReservedSectors + bpbNumberOfFATs * bpbSectorsPerFAT = LBA 19
; Broj sektora za root direktorijum = 
;     = bpbRootEntries * 32 bajta po stavci / 512 bajtova po sektoru = 14
; Pocetak polja sa podacima = 
;     = (Pocetak root) + (Broj sektora za root) = 19+14 = LBA 33
;
; Ako je boot sa nepoznatog medijuma, sve prethodno treba programski izracunati.
; -------------------------------------------------------------------------------

;---------------------------------------------------
; Parametri koje zahteva BIOS INT 13h, funkcija 2
;---------------------------------------------------  
; AH = 2 (funkcija za citanje sektora)
; AL = broj sektora koje odjednom treba procitati
; CH = cilindar (donjih 8 od 10 bitova)
; CL = preostala dva bita cilindra + 6 bitova za sektor
; DH = glava
; DL = broj disk jedinice
; ES:BX = pointer na bafer gde se smestaju sektori
;----------------------------------------------------

        mov     ax, 19                       ; Root direktorijum pocinje od LBA 19
        call    CHS12                        ; Konvertovati LBA u CHS (Cylinder Head Sector)
        mov     si, bafer                    ; Podesiti ES:BX da pokaziju na baf er (vidi kraj ovog koda)
        mov     bx, ds
        mov     es, bx
        mov     bx, si
        mov     ah, 2			               
        mov     al, 14                       ; Procitati 14 sektora odjednom
        pusha		

UcitajDir:
        popa                                 ; Za slucaj da je INT 13h promenio sadrzaj registara
        pusha
        stc                                  ; Neki BIOSi ne postavljaju ovu ispravno vrednost u slucaju greske
        int     13h                          ; Citanje sektora upotrebom BIOSa
        jnc     PretraziDir                  ; Ukoliko je sve u redu, idemo na pretrazivanje direktorijuma.
        call    ResetDisk                    ; U suprotmom, resetujemo disk kontroler i pokusavamo ponovo.
        jnc     UcitajDir                    ; Ako imamo gresku i prilikom reseta (dvostruka greska),
        jmp     Reboot                       ; resetujemo ceo sistem.

PretraziDir:
        popa
        mov     ax, ds                       ; Root direktorijum je sada u baferu
        mov     es, ax			               
        mov     di, bafer
        mov     cx, word [bpbRootEntries]    ; Pocinjemo pretragu svih (224) stavki
        mov     ax, 0                        ; u direktorijumu, pocev od ofseta 0

SledecaStavka:
        xchg    cx, dx                       ; Koristimo CX kao brojac unutrasnje petlje
        mov     si, ImeKernela               ; Trazimo ime datoteke kernela
        mov     cx, 11
        rep     cmpsb
        je      Pronadjen                    ; Pointer DI ce biti na ofsetu 11
        add     ax, 32                       ; Sledeca stavka u direktorijumu
        mov     di, bafer			            
        add     di, ax
        xchg    dx, cx			               
        loop    SledecaStavka
        mov     si, NijePronadjen            ; Ako nema kernela, ispisati poruku o gresci 
        call    _print_string                ; a onda reboot
        jmp     Reboot

Pronadjen:                                   ; Iz direktorijuma odrediti prvi klaster datoteke
        mov     ax, word [es:di+0Fh]         ; Ofset 11 + 15 = 26, sdrazi prvi klaster
        mov     word [klaster], ax
        mov     ax, 1                        ; Sektor 1 = prvi sektor prve FAT
        call    CHS12                        ; Izvrsiti konverziju LBA u CHS
        mov     di, bafer                    ; ES:BX pokazuje na nas bafer
        mov     bx, di
        mov     ah, 2                        ; INT 13h parametri: procitaj (FAT) sektore,
        mov     al, 9                        ; svih 9 sektora prve FAT
        pusha				

UcitajFAT:
        popa                                 ; Za slucaj da je INT 13h promenio sadrzaj registara
        pusha
        stc
        int     13h                          ; Procitaj sektore upotrebom BIOSa
        jnc     FATjeUcitan                  ; Ako je citanje FAT proslo OK, preskoci sledeci deo.
        call    ResetDisk                    ; U suprotnom, resetujemo disk kontroler i pokusavamo ponovo.
        jnc     UcitajFAT                    ; Ako imamo gresku i prilikom reseta (dvostruka greska),
        mov     si, GreskaCitanja            ; ispisujemo poruku o grsci i resetujemo ceo sistem.
        call    _print_string
        jmp     Reboot			              

FATjeUcitan:
        popa
        mov     ax, ImageLoadSeg             ; Segment gde ucitavamo kernel
        mov     es, ax
        mov     bx, 0
        mov     ah, 2                        ; parametri za INT 13h 
        mov     al, 1
        push    ax                           ; Cuvamo za slucaj da mi (ili prekid) promenimo vrednost


        
; -------------------------------------------------------------------------------------
; Sada ucitavamo FAT u memoriju. Pocetak FAT nalazi se na sledeci nacin:
; FAT klaster 0 = media descriptor = 0F0h
; FAT klaster 1 = filler cluster = 0FFh. Znaci, klasteri se broje od 2 do n.
; Pocetak klastera = ((trazeni klaster)-2) * bpbSectorsPerCluster + (pocetak klastera 2)
;                  = (trazeni klaster) + 31 (za FAT12 na disketi od 1.44 MB)
; Napomena: Ovo se racuna programski ukoliko unapred nije poznata geometrija i medijum.
; --------------------------------------------------------------------------------------

CitajSektor:
        mov     ax, word [klaster]           ; Kovertovati klaster u LBA
        add     ax, 31
        call    CHS12                        ; Konverzija LBA u CHS
        mov     ax, ImageLoadSeg        
        mov     es, ax
        mov     bx, word [pointer]
        pop     ax                           ; Cuvamo za slucaj da mi (ili prekid) promenimo vrednost
        push    ax
        stc
        int     13h
        jnc     SledeciKlaster               ; Ukoliko nema greske, racunamo koji je sledeci klaster
        call    ResetDisk                    ; U suprotnom, resovati disk u pokusati ponovo
        jmp     CitajSektor

;---------------------------------------------------------------------------
; Zbog istorijskih razloga (efikasnije iskoriscenje tadasnjeg dragocenog
; disk prostora i minimalno pomeranje glave diska), 12-bitne FAT stavke ne
; zauzimaju po 2 bajta (jednu celu 16-bitnu rec), vec se dele medju susednim
; bajtovima na sledeci nacin:
; - Ukoliko je klaster parni, koristiti donjih 12 bitova 16-bitne reci
; - Ukoliko je klaster neparni, koristiti gornjih 12 bitova 16-bitne reci
;
; Zbog toga je velicina FAT tabele 6KB, umesto 8KB 
; Racunica: FAT12 ima 2^12 stavki = 4096 = 4KB
; --------  - Ako se svaka adresira sa 2 cela bajta 
;             (16 bitova od kojih se koristi samo 12 donjih) to je 2*4KB=8KB
;           - Ako se svaka stavka adresira sa tacno 12 bitova (1.5 bajtova)
;             to je onda 1.5*4KB=6KB       
;----------------------------------------------------------------------------

SledeciKlaster:
        mov     ax, [klaster]
        mov     dx, 0
        mov     bx, 3
        mul     bx
        mov     bx, 2
        div     bx                           ; DX = 'klaster' mod 2
        mov     si, bafer
        add     si, ax                       ; AX = WORD (2 bajta) u FAT za 12 bitnu stavku
        mov     ax, word [ds:si]
        or      dx, dx                       ; Ako je DX = 0, 'klaster' je parni; ako je DX = 1, tada je neparni
        jz      ParniKlaster                 ; Ako je parni, odbaci gornji nibl
        shr     ax, 4                        ; Postavljanje bitova iz neparnog klastera na pravo mesto (0..11)  
        jmp     Nastavi

ParniKlaster:
        and     ax, 0FFFh                    ; Osigurati da su vazeci bitovi na pozicijama od 0..11.

Nastavi:
        mov     word [klaster], ax           ; Sacuvati klaster
        cmp     ax, 0FF8h                    ; FF8h = EOC za FAT12
        jae     kraj
        add     word [pointer], 512          ; Povecati vrednost pointera na bafer za 1 sektor (512 bajtova)
        jmp     CitajSektor

kraj:                                        ; Kernel datoteka sada je u memoriji.
        pop     ax                           ; Ocistiti stek (AX je ranije stavljen na stek).
        mov     dl, byte [bsDriveNumber]     ; Informacija kernelu koji je broj boot diska.
        jmp     ImageLoadSeg:0               ; Skok na pocetak ucitanog kernela!


; ----------------
; Lokalne rutine
; ----------------

Reboot:
        mov     ax, 0
        int     16h                          ; Sacekati da se pritisne taster
        mov     ax, 0
        int     19h                          ; Reboot (soft reset)


_print_string:
        pusha
        mov     ah, 0Eh                     ; BIOS INT 10h teletype (TTY) funcija
.Ponavljaj:
        lodsb                               ; Uzmi jedan znak iz stringa
        cmp     al, 0
        je     .Kraj                        ; Ako je znak nula, to je kraj stringa.
        int     10h                         ; Ako nije kraj, pozovi BIOS za ispisivanje
        jmp    .Ponavljaj                   ; i idi na sledeci znak.
.Kraj:
        popa
        ret
   
              
ResetDisk:                                   ; U slucaju greske, postavlja se CF (Carry)
        push    ax
        push    dx
        mov     ax, 0
        mov     dl, byte [bsDriveNumber]
        stc
        int     13h
        pop     dx
        pop     ax
        ret

; --------------------------------------------
; Racuna cilindar, glavu i sektor iz LBA  
; Ulaz: LBA u AX
; Izlaz: Odgovarajuci registri za INT 13h, fn2  
; --------------------------------------------

CHS12:				
        push    bx
        push    ax
        mov     bx, ax                       ; Sacuvati logicki sektor
        mov     dx, 0                           
        div     word [bpbSectorsPerTrack]
        add     dl, 01h                      ; Fizicki sektor pocinje od 1
        mov     cl, dl                       ; Sektori se prosledjuju preko CL 
        mov     ax, bx
        mov     dx, 0                        ; Racunati glavu
        div     word [bpbSectorsPerTrack]
        mov     dx, 0
        div     word [bpbHeadsPerCylinder]
        mov     dh, dl                       ; Glava
        mov     ch, al                       ; Cilindar
        pop     ax
        pop     bx
        mov     dl, byte [bsDriveNumber]		
        ret

;-------------------
; String konstante
;-------------------
   GreskaCitanja  db "Greska pri citanju diska! Pritisni bilo koji taster ...", 0
   NijePronadjen  db "KERNEL.BIN ne postoji!", 10, 13, 0

   klaster        dw 0                       ; Klaster koji hocemo da ucitamo
   pointer        dw 0                       ; Pointer na bafer za ucitavanje kernela
   
;------------------------------------------------
; Ispuniti peostali prostor boot sektora nulama
;------------------------------------------------

                times (512-13-($-$$)) db 0

;----------------------------------------------
; Ime programa kojeg treba ucitati i izvrsiti
;----------------------------------------------

ImeKernela      db      "KERNEL  BIN"        ; Ime i ekstenzija datoteke moraju da budu dopunjeni
                                             ; praznim mestima (ukupno 11 bajtova, tacka se ne racuna)

;--------------------------
; ID za kraj boot sektora
;--------------------------
                dw      0AA55h

bafer:                                       ; Odavde pocinje bafer od 8KB, a odmah iza njega stek.
                                             ; Koristimo samo labelu - ne rezervisemo nista, 
                                             ; jer inace izlazimo van 512 bajtova