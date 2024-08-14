;
;********************************************************************
;*
;*        K R I S Y S   S G 1 0 0 0   C O R E
;*
;********************************************************************

#include "KRISYS.asm"

; ---------------------------
; ******** Core Init ********
; ---------------------------

.area	_TEXT

; Start of SG-1000 core
core_start:

	; Try to find rom resource
	ld	de,str_rom
	call	res_locate
	or	a
	jp	nz,cpm_exit
	
	; Open the resource
	call	res_open

	jp	cpm_exit
	
; -------------------------
; ******** Strings ********
; -------------------------

.area	_DATA

; Resource strings
str_rom:
	defb	'ROM',0