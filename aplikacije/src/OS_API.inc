; ==========================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ==========================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Aplikacioni programski interfejs (API)
;
; Vektori eksportovnaih sistemskih poziva nalaze se na statickim lokacijama.
; Ove lokacije ne treba menjati! 
; ---------------------------------------------------------------------------
; Inicijalna OS verzija 0.0.1. API verzija 1 (Stevan Milinkovic, 20.08.2010.)
; ---------------------------------------------------------------------------

; ------------------------------------------------------------------
; Vazne memorijske lokacije

OS 			    equ 2000h
_sys_exit 		equ 0267h

os_main         equ 0000h                   ; Prostor kernela
app_main        equ 8400h                   ; OBRISATI <- Multiprocesiranje ne radi za (stare) aplikacije koje koriste app_main
_get_app_offset equ 025Eh 					; Vraca offset za lokalne adrese u AX

input           equ 8400h - 100h        	; Deljene oblasti izmedju
arg1            equ 8400h - 080h         	; kernela i korisnika

; ------------------------------------------------------------------
; Definicije boja

%define CRNO_NA_BELOM               11110000b
%define BELO_NA_CRNOM               00001111b
%define BELO_NA_CRVENOM             01001111b
%define BELO_NA_ZELENOM             00101111b
%define BELO_NA_PLAVOM              00011111b
%define BELO_NA_SVETLO_CRVENOM      11001111b
%define CRVENO_NA_SVETLO_ZELENOM    10100100b
%define BELO_NA_SVETLO_PLAVOM       10011111b


; ------------------------------------------------------------------
; Tasteri

; Scan kodovi (bajtovi koji se nigde ne upisuju)
; Koriste se samo za komande

%define KEY_UP      48h
%define KEY_PGUP    49h
%define KEY_DOWN    50h
%define KEY_PGDN    51h
%define KEY_HOME    47h
%define KEY_END     4Fh
%define KEY_LEFT    4Bh
%define KEY_RIGHT   4Dh
%define KEY_F1      3Bh
%define KEY_F2      3Ch
%define KEY_F3      3Dh
%define KEY_F4      3Eh
%define KEY_F5      3Fh
%define KEY_F6      40h
%define KEY_F7      41h
%define KEY_F8      42h
%define KEY_F9      43h
%define KEY_F10     44h
%define KEY_DEL     53h

; ASCII kodovi
; Bajtovi koji mogu da se upisuju, ali ne moraju uvek da se prikazuju 

%define KEY_ESC     27
%define KEY_ENTER   13
%define KEY_BKSP    8
%define KEY_SPACE   32

%define LF          0Ah
%define CR          0Dh

; --------------------------------------------------------------------
; ====================================================================
; Sistemski pozivi.
; Da bi se izbegla memorijska zavisnost sistemskih poziva, bolje je
; koristiti softverske prekide.
; ====================================================================
; --------------------------------------------------------------------
 
; ====================================================
; Rutine za rad sa tekst ekranom 80x25 znakova 
; ====================================================

; ----------------------------------------------------
; _print_string -- Ispisuje tekst upotrebom BIOS-a
; Ulaz: SI = pointer na pocetak stringa
; String mora da se zavrsi nulom.

; _move_cursor -- Pomera kursor
; Ulaz: DH = linija, DL = kolona

; _clear_screen -- Brise ekran (u boju pozadine)
; Ulaz/Izlaz: -

; _print_horiz_line -- Crta horizontalnu liniju
; Ulaz: AX = vrsta linije (1 za dvostruku (=), 
; ostale vrednosti za jednostruku (-))

; _print_newline -- Postavlja kursor na pocetak novog reda
; Ulaz/Izlaz: -

; _draw_background -- Brise ekran i iscrtava gore i dole bele trake,
; odgovarajuci tekst i obojenu radnu povrsinu.
; Ulaz: AX = gornji string, BX = donji string, CX = boja  

; _draw_block -- Crta blok u zadatoj boji (boja se nalazi u BL)
; Ulaz: 
;       Pocetak bloka: DH = linija, DL = kolona
;       Sirina bloka: SI 
;       Poslenja linija bloka: DI

; _dialog_box -- Iscrtava dialog boks sa dugmetom 'OK'
; Ulaz: AX, BX, CX = pointeri na pocetak stringova 
; Svaki string je maksimalne duzine 40 znakova

; _get_cursor_pos -- Polozaj kursora
; Izlaz: DH = linija, DL = kolona

; _print_space -- Ispisuje znak za prazno mesto (Space)
; Ulaz/Izlaz: -

; _dump_string -- Ispisuje string kao niz hex bajtova i znakova
; Ulaz: SI = pointer na pocetak stringa

; _print_digit -- Ispisuje sadrzaj AX kao cifru 
; Radi sa osnovama do 37, tj. ciframa  0-Z
; Ulaz: AX = "cifra" koji treba formatirati i ispisati

; _print_1hex -- Ispisuje donji nibl AL u hex formatu
; Ulaz: AL = broj koji je potrebno ispisati

; _print_2hex -- Ispisuje AL u hex formatu
; Ulaz: AL = broj koji je potrebno ispisati

; _print_4hex -- Ispisuje AX u hex formatu
; Ulaz: AX = broj koji je potrebno ispisati

; _show_cursor -- Pikazi kursor
; Ulaz/Izlaz: -

; _hide_cursor -- Sakrij kursor
; Ulaz/Izlaz: -

; _dump_registers -- Ispisuje sadrzaj registara u hex formatu
; Ulaz/Izlaz: AX/BX/CX/DX/SI/DI = registri ciji se sadrzaj ispisuje

; ----------------------------------------------------

_print_string       equ 0003h
_move_cursor        equ 000Ch
_clear_screen       equ 0015h
_print_horiz_line   equ 001Eh
_print_newline      equ 0027h
_draw_background    equ 0078h
_draw_block         equ 0204h	
_dialog_box         equ 00B7h	                    
_get_cursor_pos     equ 013Eh	
_print_space        equ 0147h	
_dump_string        equ 0150h	
_print_digit        equ 0159h	
_print_1hex         equ 0162h	
_print_2hex         equ 016Bh	
_print_4hex         equ 0174h
_show_cursor        equ 018Fh	
_hide_cursor        equ 0198h	
_dump_registers     equ 01A1h	

; ====================================================
; Rutine za rad sa tastaturom 
; ====================================================

; _wait_for_key -- Ceka da se pritisne taster 
; Ulaz: -
; Izlaz: AX = pritisnuti taster

; _check_for_key -- Propituje tastaturu za ulaz, ali ne ceka
; Ulaz: -
; Izlaz: AX = 0 ako nije pritisnut taster. Ako jeste, sadrzi scan_code

; ----------------------------------------------------

_wait_for_key       equ 0030h	
_check_for_key      equ 0039h	

; ====================================================
; Sistem datoteka FAT12 (rutine za rad sa flopi diskom)
; ====================================================

; _load_file -- Ucitava datoteku u operativnu memoriju
; Ulaz: AX = ime datoteke, CX = adresa odakle pocinje ucitavanje
; Izlaz: BX = velicina datoteke (u bajtovima), CF=1 ako ne postoji

; _get_dir -- Generise listu imena datoteka iz direktorijumskih stavki
; Ulaz: BX = Bafer gde se smesta string sa listom datoteka

; _write_file -- Snima datoteku (maksimalne velicine 64K) na disk
; Ulaz: AX = ime datoteke, BX = adresa podataka, CX = broj bajtova
; Izlaz: Ukoliko ima geske, CF = 1. 

; _file_exists -- Poveriti da li postoji datoteka sa zadatim imenom
; Ulaz: AX = ime datoteke; Izlaz: CF=0, ako postoji

; _create_file -- Kreira novu praznu datoteku
; Ulaz: AX = ime datoteke; Izlaz: CF=1 ako je greska

; _remove_file -- Brise datoteku sa zadatim imenom
; Ulaz: AX = ime datoteke
; Ovo je genericka rutina za FAT12 (ukljuceni su svi potrebni segmenti)

; _rename_file -- Preimenuje datoteku
; Ulaz: AX = originalno ime datoteke, BX = Novo ime datoteke
; Izlaz: CF=1 ukoliko nastane greska

; _get_file_size -- Vraca informaciju o velicini datoteke
; Ulaz: AX = datoteka; Izlaz: BX = velicina u bajtovima (do 64KB),
; CF=1 ukoliko nema trazene datoteke

; ----------------------------------------------------

_load_file          equ 005Dh	
_get_dir            equ 00C9h	
_write_file         equ 01B3h	
_file_exists        equ 01BCh	
_create_file        equ 01C5h	
_remove_file        equ 01CEh	
_rename_file        equ 01D7h	
_get_file_size      equ 01E0h	

; ====================================================
; Rutine za rad sa zvukom
; ====================================================

; _speaker_tone -- Generise zvuk na ugradjenom zvucniku
; Ulaz AX = visina (frekvencija) tona 
; Izlaz: -

; _speaker_off -- Iskljucuje zvucnik
; Ulaz/Izlaz:

; ----------------------------------------------------

_speaker_tone       equ 004Bh	
_speaker_off        equ 0054h	

; ====================================================
; Rutine za rad sa stringovima
; ====================================================

; _int_to_string -- Konvertuje unsigned int u string decimalnih brojeva
; Ulaz: AX = unsigned int
; Izlaz: AX = pocetak stringa

; _string_length -- Vraca duzinu stringa
; Ulaz: AX = pointer na pocetak stringa
; Izlaz: AX = duzina u bajtovoma (bez zavrsne nule)

; _string_uppercase -- Konverzija ASCII stringa u velika slova
; Ulaz/Izlaz: AX = pointer na pocetak stringa
; Konvertuju se samo slova od a do z. Brojevi i ostali znaci ostaju.

; _string_lowercase -- Konverzija ASCII stringa u mala slova
; Ulaz/Izlaz: AX = pointer na pocetak stringa
; Konvertuju se samo slova od A do Z. Ostali znaci ostaju.

; _input_string -- Ucitava string sa tastature
; Ulaz/Izlaz: AX = pointer na pocetak stringa
; Maksimalna velicina unetog stinga je 255, ukljucujuci i zavrsnu nulu

; _string_copy -- Kopiranje jednog stringa u drugi
; Ulaz/Izlaz: SI = izvorni, DI = odredisni (obezbediti dovoljno memorije!)

; _string_join -- Spajanje dva stringa u treci string
; Ulaz/Izlaz: AX = prvi string, BX = drugi string , CX = odredisni string

; _string_compare -- Poredi dva stringa
; Ulaz: SI = prvi string, DI = drugi string
; Izlaz: CF = 1 ako su isti, CF = 0 ako su razliciti

; _string_chomp -- Odsecanje pocetnih i krajnjih 'Space' znakova
; Ulaz: AX = pointer na pocetak stringa
; Broj bajtova zauzete memorije ostace isti kao i pre poziva ove rutine 

; _string_strip -- Uklanja zadati znak iz stringa maksimalne duzine 255
; Ulaz: SI = pointer na pocetak stringa, AL = znak kojeg treba ukloniti
; Broj bajtova zauzete memorije ostace isti kao i pre poziva ove rutine 

; _string_truncate -- Odsecanje stringa sleva
; Ulaz: SI = pocetak stringa, AX = broj znakova koji ostaju sa leve strane

; _get_time_string -- Tekuce vreme u obliku stringa (npr. '10:25:07')
; Ulaz/Izlaz: BX = lokacija stringa (zadaje programer uz obezbedjenu memoriju)

; _get_date_string -- Tekuci datum u obliku stringa (npr. '15.8.2010')
; Ulaz/Izlaz: BX = lokacija stringa (zadaje programer uz obezbedjenu memoriju)

; _find_char_in_string -- Pronadji znak u stringu
; Ulaz: SI = pointer na pocetak stringa, AL = znak koji se trazi
; Izlaz: AX = prva pozicija znaka koji trazi, ili 0 ako ga nema

; _long_int_to_string -- Konvertuje long int (32 bita) u string       
; Ulaz: DX:AX = long unsigned int, BX = brojna osnova, DI = string 
; Izlaz: DI = string sa koji predstavlja broj u trazenoj osnovi

; _string_strincmp -- Poredi prvih n znakova zadatih stringova
; Ulaz: SI = prvi string, DI = drugi string, CL = broj znakova (n)
; Izlaz: CF = 1 ako su isti, CF = 0 ako su razliciti

; _string_reverse -- Invertovati redosled znakova u stringu
; Ulaz: SI = pointer na pocetak stringa 
; SI pokazuje i na pocetak invertovanog stringa

; _string_to_int -- Konvertuje decimalni string u int
; Ulaz: SI = pocetak stringa (maksimalno 5 znakova, do '65536')
; Izlaz: AX = celobrojna vrednost (int)
; Ne proverava se da si radi o broju, niti njegova velicina ! 

; _string_charchange -- Zamena svake pojave znaka u stringu drugim znakom
; Ulaz: SI = pointer na pocetak stringa, AL = stari znak, BL = novi znak

; _sint_to_string -- Konvertuje signed int u decimalni string
; Ulaz: AX = signed int
; Izlaz: AX = pocetak stringa

; _string_parse -- Parsira string koji sadrzi prazna mesta
; (npr. "komanda arg1 agr2 arg3") i vraca pointere na odvojene stringove
; (npr. AX na "komanda", BX na "arg1", CX na "arg2" i DX na "arg3")
; Ulaz: SI = pocetni string; Izlaz: AX, BX, CX, DX = pojedinacni stringovi
; Pointeri pokazuju na novostvorene podstringove u pocetnom stringu ! 
; Zauzece memorije se ne menja.

; ----------------------------------------------------

_int_to_string       equ 017Dh	
_string_length       equ 008Ah	
_string_uppercase    equ 0093h
_string_lowercase    equ 009Ch
_input_string        equ 01E9h 
_string_copy         equ 00AEh
_string_join         equ 00C0h	
_string_compare      equ 00D2h	
_string_chomp        equ 00DBh	
_string_strip        equ 00E4h	
_string_truncate     equ 00EDh
_get_time_string     equ 00FFh	
_get_date_string     equ 011Ah	
_find_char_in_string equ 0135h	
_long_int_to_string  equ 017Dh	
_string_strincmp     equ 01AAh	
_string_reverse      equ 01F2h	
_string_to_int       equ 01FBh	
_string_charchange   equ 0216h	
_sint_to_string      equ 0228h	
_string_parse        equ 0231h	                  
                    
; ====================================================
; Matematicke rutine
; ====================================================

; _bcd_to_int -- Konverzija BCD u celobrojnu vrednost
; Ulaz:  AL = BCD broj
; Izlaz: AX = celobrojna vrednost

; _long_int_negate -- Pomnozi broj u DX:AX sa -1
; Ulaz: DX:AX = long int;
; Izlaz: DX:AX = -(pocetna vrednost DX:AX)

; _seed_random -- Pocetna vrednost generatora slucajnih brojeva
; na osnovu vrednosti tekuceg vremena sistemskog casovnika
; Ulaz/Izlaz: -

; _get_random -- Vraca slucajnu vrednost izmedju donje i gornje
; Ulaz:  AX = donja celobrojna vrednost, BX = gornja celobrojna vrednost
; Izlaz: CX = slucajna celobrojna vrednost

; ----------------------------------------------------

_bcd_to_int         equ 00F6h	
_long_int_negate    equ 0186h
_seed_random        equ 0111h
_get_random         equ 020Dh	

; ====================================================
; Rutine za rad sa portovima
; ====================================================

; _send_via_serial -- Posalji bajt preko serijskg porta
; Ulaz:  AL = bajt kojeg treba poslati
; Izlaz: AH bit 7 = 0 ukoliko je OK

; _get_via_serial -- Ucitati bajt preko serijskog porta
; Izlaz: AL = primljeni bajt; AH bit 7 = 0, ukoliko je OK

; _serial_port_enable -- Podesavanje serijskog porta
; Ulaz: AX = 0 za 9600 baud ili 1 za 1200 baud (oba N,8,1)

; _port_byte_out -- Posalji bajt na odgovarajuci port
; Ulaz: DX = adresa porta, AL = bajt kojeg treba poslati

; _port_byte_in -- Ucitati bajt sa porta
; Ulaz:  DX = adresa porta
; Izlaz: AL = bajt ucitan sa porta

; ----------------------------------------------------

_send_via_serial    equ 0123h	
_get_via_serial     equ 012Ch	
_serial_port_enable equ 021Fh
_port_byte_out      equ 0243h	
_port_byte_in       equ 024Ch	
	
; ====================================================
; Ostale rutine
; ====================================================

; _pause -- Cekanje odredjeno vreme
; Ulaz: AX = broj desetinki koje treba cekati (znaci 10 = 1 sekunda)

; _fatal_error -- Ispisi poruku o fatalnoj gresci i zaustavi sistem
; Ulaz: AX = Ponter na pocetak poruke o gresci

; _get_api_version -- Vraca trenutni verziju RAF_OS API
; Ulaz: -
; Izlaz: AL = API verzija

; _run_basic -- Startuje BASIC interpreter
; Ulaz/Izlaz: -

; ----------------------------------------------------

_pause              equ 0066h	
_fatal_error        equ 006Fh		
_get_api_version    equ 0108h	
_run_batch          equ 023Ah


; ====================================================
; Rutina za stampanje preko paralelnog porta
; ====================================================

; _print_file -- Stampanje na paralelni port
; BX = adresa podataka, CX = broj bajtova
; Izlaz: CF = 1 ako nema mesta u queue

; ----------------------------------------------------

_print_file			equ 0255h
