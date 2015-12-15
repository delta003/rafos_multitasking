; =============================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; =============================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Scheduler - RAF_OS multitasking 
;
; 
; Pogledati u prekidi.asm scheduler rutinu na int 08h.
; -----------------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Marko Bakovic, Sasa Vuckovic, Dusan Josipovic, 01.01.2015.).
;
; -----------------------------------------------------------------------------

; --------------------------------------------------------------------------
; _init_scheduler -- Inicijalizuje scheduler tabele i postavlja shell kao
; jedini proces
; --------------------------------------------------------------------------
_init_scheduler: 
	mov byte [sch_active_proc], 0		; trenutno aktivan proces je shell ciji je pid = 0
	mov byte [sch_fg], 0 				; shell je u foreground-u
	mov byte [sch_kills], 0 			
	mov byte [sch_sizes], 1 			; shell procesu dodeljujemo 1kb (sch_sizes[0])
	mov word [sch_stacks], sp			; izdvajamo 28kB od 0FFFFh (dno SS-a) za druge procese,
										; a shell dobije od 28kB na gore
	mov byte [sch_queue], 0 			; u queue ubacimo shell proces
	mov byte [sch_queue_size], 1
	mov byte [sch_mmt], 0FFh   			; svi memorijski segmenti osim nultog su slobodni (u nuli je shell) 

	ret

; --------------------------------------------------------------------------
; _ubaci_proces -- Ucitava proces u memoriju
; Ulaz: AX = datoteka, BX = 1 - fg proces, 0 - bg proces
; Izlaz: CF=1 ukoliko nema trazene datoteke ili nije moguce ucitati datoteku u
; memoriju verovatno zato sto nema dovoljno memorije
; --------------------------------------------------------------------------
_ubaci_proces:
	pusha
	push bx 							; sacuvamo tip procesa
	push ax 							; sacuvamo ime datoteke na stack-u

	xor bx, bx
	clc
	call _get_file_size					; odredimo velicinu fajla (bx je velicina u byte-ovima)
	cmp bx, 0 							; ukoliko nije 0 
	jne .nadjen_fajl 					; fajl postoji 

	pop ax
	pop bx
	popa
	ret

.nadjen_fajl:
	mov ax, bx							; pretvaramo velicinu u kb
	xor dx, dx							; cistimo dx registar jer zelimo da delimo
	mov bx, 1024 						; dx(prazan):ax(velicina u bajtovima) sa bx(1024)
	div bx 								; da dobijemo broj kilobajtova u ax
	cmp dx, 0 							; ako ne postoji ostatak idemo dalje
	je	.sch_nastavi 						
	inc ax 								; ako postoji samo povecaj ax da bismo mu dali dovoljno mesta
.sch_nastavi:
	mov cx, 1
	mov	bx, 0           				; brojac slobodnih memorijskih jedinica do cx-te
.petlja: 								; Trazimo ax slobodnih mesta u mmt-u i setujemo pid na cx 
	mov	si, cx 							 
	add si, sch_mmt 					
	cmp byte [si], 0					; if mmt[cx] != 0  // testiramo cx-ti bajt u mmt-u
	jne .resetuj_brojac					; resetuj brojac 
	inc bx 								; ako jeste povecaj bx
	cmp bx, ax 							; da li je sada bx == ax
	jl .sledeci_bajt
	sub cx, ax 							; proces ucitavamo na mmt[cx-ax+1] i sledecih cx mesta 
	inc cx								; a njegov pid je cx-ax+1 i to smestamo u cx							
	jmp .nadjen_pid						
.resetuj_brojac
	xor bx, bx
.sledeci_bajt:
	inc cx
	cmp cx, 29
	jl .petlja
	mov si, sch_no_memory_error 		; posto cx nije manje od 29 printamo error i izlazimo sa CF=1
	call _print_string
	stc
	pop ax
	pop bx
	popa 								
	ret 

; Ucitavamo proces u memoriju na odredjenu adresu, upisujemo ime u sch_names	
.nadjen_pid: 							; PID za proces je pronadjen
	mov dx, ax 							; u ax je velicina 
	pop ax 								; vratimo ime na ax
	push dx 							; ubacimo velicinu na stack
	push cx 							; ubacimo pid na stack

	mov bx, cx 							; na bx izracunamo gde program treba da se ucita
	shl bx, 10 							; bx * 2^10 (KB)
	add bx, 8000h 						; dodamo na 8000
	mov cx, bx 							; pomerimo adresu na cx kao parametar za _load_file_current_folder
	xor bx, bx
	push ax 							; ubacimo ime na stack 

	call _load_file_current_folder		; ucitamo program u memoriju

	pop ax 								; na ax vratimo ime
	pop cx 								; na cx vratimo pid

	mov si, ax 							; sacuvamo ime procesa u si
	mov di, sch_names 					; sch_names je velicine 32x32 i koristimo pid * 32 offset za upisivanje imena
	mov bx, cx 							; 
	shl bx, 5 							; pid * 32 
	add di, bx 							; sch_names[pid*32] 
	call _string_copy 					; kopiramo iz si (ime procesa) u di (sch_names[pid*32])

	pop ax 								; na ax vratimo velicinu
	pop bx 								; na bx tip procesa
	call _update_scheduler

	popa
	ret

; --------------------------------------------------------------------------
; _update_scheduler -- Azurira tabele sch_mmt sch_sizes sch_queue 
; Ulaz: AX = velicina, CX = pid procesa, BX = 1 - fg proces, 0 - bg proces
; --------------------------------------------------------------------------
_update_scheduler:
	pusha
	push bx     							; sacuvamo tip procesa (fg/bg)

	mov si, cx 								; azuriranje sch_mmt tabele
	add si, sch_mmt 						; od sch_mmt[pid]
	push cx
	mov cx, ax 								; do sch_mmt[pid+velicina]
.petlja:
	mov	byte [si], 0FFh 					; ubaci jedinice
	inc si 	
	loop .petlja
	pop cx 									; vrati pid na cx

	; update sch_sizes
	mov si, sch_sizes
	add si, cx 			
	mov byte [si], al 						; na sch_sizes[pid] upisi velicinu procesa

	mov bx, ax 								
	add bx, cx 								
	dec bx 									
	shl bx, 10 								; racunamo adresu steka za program kao : velicina+pid-1 * 2^10 + 8FFFF (ofset koji smo zadali)
	add bx, 08FFFh 							; na adresu koja je u bx smestamo stek pointer

	mov dx, sp 							 	; privremeno zameni stek
	mov sp, bx 								

	; izracunaj segmente za novi proces
	mov bx, cx
	shl bx, 6								; cs = 2000h + ( 8000h + pid * 400h ) / 10h
	add bx, 2800h							; skraceno: cs = 2000h + 800h + pid * 40h
	

	; ubaci predefinisane vrednosti na stack novog procesa
	; tako da pomisli da se vec izvrsavao 

	pushf								

	push bx 								; ovo je u stvari izracunati cs
	push 0									; ubacimo ip = 0
	push bx									; ds
	push bx									; gs
	push bx									; es
	push bx									; fs

	push ax
	push bx
	push cx
	push dx
	push bp
	push si
	push di 								; ubaci registre

	; vrati stack i na bx pomeri adresu stack-a novog procesa (na koji su ubacene predefinisane vrednosti)
	mov bx, sp
	mov sp, dx

	; update sch_stacks
	mov si, sch_stacks
	add si, cx
	add si, cx
	mov word [si], bx  					; na sch_stacks[pid*2 (jer je dw)] ubacimo vrednost sp-a za proces 

	
	mov si, sch_kills
	add si, cx
	mov byte [si], 0 					; na sch_kills[pid] ubacimo 0
	
	cli									; Zabrani prekide. 
	mov al, 080h						; Zabrani NMI prekide
	out 070h, al 	

	mov si, sch_queue 					
	xor ax, ax
	mov al, byte [sch_queue_size] 
	dec al
	add si, ax							; u niz sch_queue, na sch_queue+sch_queue_size-1 dodaj novi
	mov byte [si], cl 					; proces sa pidom cx a posle cemo (zavisno da li je fg ili bg) shell dodati na kraj

	pop bx 								; vrati bg/fg u bx
	cmp bx, 0 
	je .bg_proces

.fg_proces:
	mov	byte [sch_fg], cl 				; Ukoliko je trenutni proces fg, ne zelimo shell da se izvrsava 
	jmp .kraj 							

.bg_proces:
	inc si 								; ako je background proces 
	mov al, 0 							; shell id = 0
	mov byte [si], al 					; dodaj shell na kraj queue-a
	inc byte [sch_queue_size] 			; povecavamo velicinu queue-a

.kraj:
	xor al, al							; Dozvoli NMI prekide
	out 070h, al						; Dozvoli prekide
	sti

	popa
	ret

; --------------------------------------------------------------------------
; _izbaci_proces -- Brise proces pid iz queue-a, update-uje mmt i ostalo 
; --------------------------------------------------------------------------
_izbaci_proces:
	
	xor ch, ch
	mov cl, byte [sch_active_proc]		; na cx vratimo pid
	
	mov si, sch_sizes 					
	add si, cx
	xor ah, ah
	mov al, byte [si]					; na ax stavi velicinu 

	mov si, sch_sizes 
	add si, cx 
	mov byte [si], 0  					; na sch_sizes[pid] ubaci 0

	; azuriraj mmt
 	mov si, cx 							
	add si, sch_mmt 					; sch_mmt[pid]
	push cx 							; sacuvaj pid
	mov cx, ax 							; postavi brojac na velicinu procesa

	cli									; Zabrani prekide. 
	mov al, 080h						; Zabrani NMI prekide
	out 070h, al 	

.petlja:								; ocisti mmt ubacivanjem nula na mesto 
	mov byte [si], 0 					; koje je zauzimao proces
	inc si
	loop .petlja

	pop cx 								; vratimo pid

	dec byte [sch_queue_size]			; proces koji se izvrsava je na kraju queue-a,
										; tako da samo smanjimo queue_size

	; proveri da li je proces bio u foreground-u i ako jeste vrati shell u foreground
	mov cl, byte [sch_active_proc]
	mov al, byte [sch_fg]
	cmp al, 0 							; ako je shell u foreground-u cekaj
	je .cekaj
	cmp cl, al
	jne .cekaj
	
	; ubaci shell u queue
	mov cl, 0 							; na cl postavimo pid shell-a

	; ubacimo shell u queue
	mov si, sch_queue
	xor ax, ax
	mov al, byte [sch_queue_size]
	add si, ax							
	mov byte [si], cl 			 		; ubacimo shell na kraj queue-a		

	inc byte [sch_queue_size]

	mov byte [sch_fg], 0

.cekaj:

	xor al, al							; Dozvoli NMI prekide
	out 070h, al						; Dozvoli prekide
	sti

	jmp $								; cekamo prekidnu rutinu za scheduler

	ret

; --------------------------------------------------------------------------
; _get_app_offset -- Vraca lokaciju gde je program ucitan, koristi se za
; korekciju adresa korisnickih aplikacija
; Izlaz: AX - offset
; --------------------------------------------------------------------------
_get_app_offset:
	xor ah, ah
	mov al, byte [sch_active_proc]
	shl ax, 10
	add ax, 8000h 						; ax = 8000h + pid * 400h
	ret

; --------------------------------------------------------------------------
; _kill_pid -- Ubija proces
; Ulaz: AX - pid procesa
; --------------------------------------------------------------------------
_kill_pid:
	pusha

	mov si, sch_kills
	add si, ax
	mov byte [si], 1  					; za ubijanje 

	popa
	ret

; --------------------------------------------------------------------------
; _print_pids -- Stampa pid - ime proces za aktivne procese
; --------------------------------------------------------------------------
_print_pids:
	pusha

	call _print_newline
	mov si, sch_pids_string_start
	call _print_string

	mov si, sch_queue
	xor ch, ch
	mov cl, byte [sch_queue_size] 		; postavimo brojac na sch_queue_size

.petlja:
	
	xor ah, ah
	mov al, byte [si]

	push si

	cmp ax, 0 							; preskacemo shell
	je .sledeci

	cmp ax, 10
	jge .print 							; ukoliko je broj manji od 9 
	call _print_space 					; printamo spejs da bi dvocifreni brojevi bili poravnati
.print:
	call _print_dec						; odstampamo pid

	call _print_space

	mov si, sch_names
	shl ax, 5 							; pid * 32
	add si, ax
	call _print_string 					; odstampamo ime

	call _print_newline

.sledeci:
	pop si
	inc si

	loop .petlja
	
	mov si, sch_pids_string_end
	call _print_string

	popa
	ret

sch_active_proc db 0					; trenutno aktivan proces
sch_fg db 0 							; pid procesa u foreground-u
sch_sizes times 32 db 0					; velicine procesa(kB), primer sch_sizes[1] 
										; je velicina procesa ciji je pid = 1
sch_stacks times 32 dw 0				; stack pointeri procesa, primer sch_stacks[1] je sp ciji je pid = 1
sch_queue times 32 db 0					; queue pid-ova koji cekaju na izvrsavanje
sch_queue_size db 0						; broj pid-ova u queue (broj aktivnih procesa)
sch_mmt times 32 db 0   				; tabela zauzetih memorijskih prostora
sch_kills times 32 db 0  				; tabela procesa koji treba da budu ubijeni (kada oni dodju na red za izvrsavanje)

sch_names times 1024 db 0               ; tabela imena pokrenutih procesa, 32x32

sch_no_memory_error db 'Nema dovoljno memorije!', 13, 10, 0
sch_pids_string_start db '==== Aktivni procesi ( pid proces ) ====', 13, 10, 0
sch_pids_string_end db   '========================================', 13, 10, 0

; --------------------------------------------------------------------------
; DEBUG
; --------------------------------------------------------------------------

_dbg_string_start 	db '---- DEBUG INFO -----', 13, 10, 0
_dbg_active_proc 	db 'sch_active_proc: ', 0
_dbg_sizes_content  db 'sch_sizes: ', 0
_dbg_queue_content  db 'sch_queue: ', 0
_dbg_queue_size 	db 'sch_queue_size: ', 0
_dbg_mmt_hex 		db 'mmt_hex: ', 0
_dbg_stacks 		db 'sch_stacks: ', 0
_dbg_string_end 	db '---- DEBUG INFO END -----', 13, 10, 0


_dbg_dump:
	pusha
	call _print_newline
	mov si, _dbg_string_start
	call _print_string
	
	; printa koji je proces aktivan
	mov si, _dbg_active_proc
	call _print_string
	xor ax,ax
	mov  al, byte [sch_active_proc]
	call _print_digit
	call _print_newline

	; printa sch_sizes niz
	mov si, _dbg_sizes_content
	call _print_string
	mov cx, 32
	mov si, sch_sizes

	.dbg_petlja2:
	mov al, byte [si]
	call _print_2hex
	inc si
	loop .dbg_petlja2

	call _print_newline

	; printa sch_queue niz
	mov si, _dbg_queue_content
	call _print_string
	xor ch, ch
	mov cl, byte [sch_queue_size]
	mov si, sch_queue

	.dbg_petlja:
	mov al, byte [si]
	call _print_2hex
	inc si
	loop .dbg_petlja

	call _print_newline	

	; printa queue_size
	mov si, _dbg_queue_size
	call _print_string
	xor ax, ax
	mov al, byte [sch_queue_size]
	call _print_digit
	call _print_newline

	; mmt string: value (u hexu) - littleendian-bigendian 
	mov si, _dbg_mmt_hex
	call _print_string
	mov cx, 32
	mov si, sch_mmt

	.dbg_petlja3:
	mov al, byte [si]
	call _print_2hex
	inc si
	loop .dbg_petlja3

	call _print_newline	

	mov si, _dbg_string_end
	call _print_string
	call _print_newline
	popa
	ret

	; printa sch_stacks
_dbg_dump_stacks:
	pusha

	call _print_newline

	mov si, _dbg_string_start
	call _print_string

	mov si, _dbg_stacks
	call _print_string

	mov si, sch_stacks
	xor ch, ch
	mov cl, byte [sch_queue_size]
.petlja:
	mov ax, word [si]
	call _print_4hex
	call _print_space
	inc si
	inc si
	loop .petlja 

	call _print_newline	

	mov si, _dbg_string_end
	call _print_string

	call _print_newline	

	popa
	ret