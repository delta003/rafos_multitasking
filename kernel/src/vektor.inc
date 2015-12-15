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
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
; ---------------------------------------------------------------------------

    jmp _main                  ; 0000h 

	call _swap_seg             ; 0003h
    call _print_string      
    jmp  _swap_seg_back

	call _swap_seg             ; 000Ch
    call _move_cursor          
    jmp  _swap_seg_back

	call _swap_seg             ; 0015h
    call _clear_screen         
    jmp  _swap_seg_back

	call _swap_seg             ; 001Eh
    call _print_horiz_line     
    jmp  _swap_seg_back

	call _swap_seg             ; 0027h
    call _print_newline        
    jmp  _swap_seg_back

	call _swap_seg             ; 0030h
    call _wait_for_key         
    jmp  _swap_seg_back

	call _swap_seg             ; 0039h
    call _check_for_key        
    jmp  _swap_seg_back

	call _swap_seg             ; 0042h
    call _int_to_string        
    jmp  _swap_seg_back

	call _swap_seg             ; 004Bh
    call _speaker_tone         
    jmp  _swap_seg_back

	call _swap_seg             ; 0054h
    call _speaker_off          
    jmp  _swap_seg_back

	call _swap_seg             ; 005Dh
    call _load_file            ; 0021h
    jmp  _swap_seg_back

	call _swap_seg             ; 0066h
    call _pause                ; 0024h
    jmp  _swap_seg_back

	call _swap_seg             ; 006Fh
    call _fatal_error          ; 0027h
    jmp  _swap_seg_back

	call _swap_seg             ; 0078h
    call _draw_background      ; 002Ah
    jmp  _swap_seg_back

    times 3 db 0               ; ova je nebitna sluzi kao filler 081
    times 3 db 0               ; 084h - Rezervisano
    times 3 db 0               ; 087h - Rezervisano

	call _swap_seg             ; 008Ah
    call _string_length        ; 002Dh
    jmp  _swap_seg_back

	call _swap_seg             ; 0093h
    call _string_uppercase     ; 0030h
    jmp  _swap_seg_back

	call _swap_seg             ; 009Ch
    call _string_lowercase     ; 0033h
    jmp  _swap_seg_back

    times 3 db 0               ; ova je nebitna sluzi kao filler 0A5
    times 3 db 0               ; 0A8h - Rezervisano
    times 3 db 0               ; 0ABh - Rezervisano

	call _swap_seg             ; 00AEh
    call _string_copy          ; 0039h
    jmp  _swap_seg_back

	call _swap_seg             ; 00B7h
    call _dialog_box           ; 003Ch
    jmp  _swap_seg_back

	call _swap_seg             ; 00C0h
    call _string_join          ; 003Fh
    jmp  _swap_seg_back

	call _swap_seg             ; 00C9h
    call _get_dir              ; 0042h
    jmp  _swap_seg_back

	call _swap_seg             ; 00D2h
    call _string_compare       ; 0045h
    jmp  _swap_seg_back

	call _swap_seg             ; 00DBh
    call _string_chomp         ; 0048h
    jmp  _swap_seg_back

	call _swap_seg             ; 00E4h
    call _string_strip         ; 004Bh
    jmp  _swap_seg_back

	call _swap_seg             ; 00EDh
    call _string_truncate      ; 004Eh
    jmp  _swap_seg_back

	call _swap_seg             ; 00F6h
    call _bcd_to_int           ; 0051h
    jmp  _swap_seg_back

	call _swap_seg             ; 00FFh
    call _get_time_string      ; 0055h
    jmp  _swap_seg_back

	call _swap_seg             ; 0108h
    call _get_api_version      ; 0057h
    jmp  _swap_seg_back

	call _swap_seg             ; 0111h
    call _get_random           ; 005Ah
    jmp  _swap_seg_back

	call _swap_seg             ; 011Ah
    call _get_date_string      ; 005Dh
    jmp  _swap_seg_back

	call _swap_seg             ; 0123h
    call _send_via_serial      ; 0060h
    jmp  _swap_seg_back

	call _swap_seg             ; 012Ch
    call _get_via_serial       ; 0063h
    jmp  _swap_seg_back

	call _swap_seg             ; 0135h
    call _find_char_in_string  ; 0066h
    jmp  _swap_seg_back

	call _swap_seg             ; 013Eh
    call _get_cursor_pos       ; 0069h
    jmp  _swap_seg_back

	call _swap_seg             ; 0147h
    call _print_space          ; 006Ch
    jmp  _swap_seg_back

	call _swap_seg             ; 0150h
    call _dump_string          ; 006Fh
    jmp  _swap_seg_back

	call _swap_seg             ; 0159h
    call _print_digit          ; 0072h
    jmp  _swap_seg_back

	call _swap_seg             ; 0162h
    call _print_1hex           ; 0075h
    jmp  _swap_seg_back

	call _swap_seg             ; 016Bh
    call _print_2hex           ; 0078h
    jmp  _swap_seg_back

	call _swap_seg             ; 0174h
    call _print_4hex           ; 007Bh
    jmp  _swap_seg_back

	call _swap_seg             ; 017Dh
    call _long_int_to_string   ; 007Eh
    jmp  _swap_seg_back

	call _swap_seg             ; 0186h
    call _long_int_negate      ; 0081h
    jmp  _swap_seg_back

	call _swap_seg             ; 018Fh
    call _show_cursor          ; 008Ah
    jmp  _swap_seg_back

	call _swap_seg             ; 0198h
    call _hide_cursor          ; 008Dh
    jmp  _swap_seg_back

	call _swap_seg             ; 01A1h
    call _dump_registers       ; 0090h
    jmp  _swap_seg_back

	call _swap_seg             ; 01AAh
    call _string_strincmp      ; 0093h
    jmp  _swap_seg_back

	call _swap_seg             ; 01B3h
    call _write_file           ; 0096h
    jmp  _swap_seg_back

	call _swap_seg             ; 01BCh
    call _file_exists          ; 0099h
    jmp  _swap_seg_back

	call _swap_seg             ; 01C5h
    call _create_file          ; 009Ch
    jmp  _swap_seg_back

	call _swap_seg             ; 01CEh
    call _remove_file          ; 009Fh
    jmp  _swap_seg_back

	call _swap_seg             ; 01D7h
    call _rename_file          ; 00A2h
    jmp  _swap_seg_back

	call _swap_seg             ; 01E0h
    call _get_file_size        ; 00A5h
    jmp  _swap_seg_back

    call _swap_seg             ; 01E9h
    call _input_string         ; 0036h
    jmp  _swap_seg_back

	call _swap_seg             ; 01F2h
    call _string_reverse       ; 00AEh
    jmp  _swap_seg_back

	call _swap_seg             ; 01FBh
    call _string_to_int        ; 00B1h
    jmp  _swap_seg_back

	call _swap_seg             ; 0204h 
    call _draw_block           ; 00B4h
    jmp  _swap_seg_back

	call _swap_seg             ; 020Dh 
    call _get_random           ; 00B7h
    jmp  _swap_seg_back

	call _swap_seg             ; 0216h
    call _string_charchange    ; 00BAh
    jmp  _swap_seg_back

	call _swap_seg             ; 021Fh
    call _serial_port_enable   ; 00BDh
    jmp  _swap_seg_back

	call _swap_seg             ; 0228h
    call _sint_to_string       ; 00C0h
    jmp  _swap_seg_back

	call _swap_seg             ; 0231h
    call _string_parse         ; 00C3h
    jmp  _swap_seg_back

	call _swap_seg             ; 023Ah
    call _run_batch            ; 00C6h
    jmp  _swap_seg_back

	call _swap_seg             ; 0243h
    call _port_byte_out        ; 00C9h
    jmp  _swap_seg_back

	call _swap_seg             ; 024Ch
    call _port_byte_in         ; 00CCh
	jmp  _swap_seg_back

	call _swap_seg             ; 0255h
    call _print_file		   ; 00CFh
    jmp  _swap_seg_back

	call _swap_seg             ; 025Eh
    call _get_app_offset       ; 00D5h
    jmp  _swap_seg_back

    call _swap_seg             ; 0267h
    jmp  _izbaci_proces        ; 00D2h      ; izbacivanje procesa iz queue-a
	