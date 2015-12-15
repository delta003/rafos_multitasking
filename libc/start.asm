; ==========================================================================
; Univerzitet Union, Racunarski fakultet u Beogradu
; 08.2008. Operativni sistemi
; ==========================================================================
; RAF_OS -- Trivijalni skolski operativni sistem
; Startna rutina za C programe 
;
; Borlandov Turbo Linker (TLINK) ne moze da eksplicitno postavi ulaznu tacku
; (pocetnu adresu) za izvrsnu COM datoteku. Da ne bismo zavisili od DOS-a,
; mi ne koristimo c0t.obj koja stize u Borlandovom paketu i koja obavlja
; ovu funkciju, vec koristimo ovu start.asm. Prevodimo je upotrebom TASM,
; jer NASM ne dozvoljava pravljenje objektne datoteke sa apsolutnom adresom.
; ---------------------------------------------------------------------------
; Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
; ---------------------------------------------------------------------------

.model  tiny
.code

global _main : proc
org 100h

pocetak:
	call _main
        ret
end pocetak
end