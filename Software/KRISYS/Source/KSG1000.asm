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
	
	; Load resources into bankmap
	ld	hl,bm_rom
	ld	bc,256
	call	res_load

	jp	cpm_exit
	
	
; -----------------------------------
; ******** Interrupt Handler ********
; -----------------------------------
	
.area	_TEXT
	
; Handle "real" interrupts from devices (if needed)
; All registers except AF must remain unchanged!
irq_handle:
	ret
	
	
; -----------------------------
; ******** I/O Handler ********
; -----------------------------
	
.area	_TEXT

; Handle an IN instruction
; Inputted value should be returned in register A
; All registers except AF must remain unchanged!
in_handle:
	ld	a,0xFF
	ret

; Handle an OUT instruction
; A = Value outputted by virtual machine
; All registers except AF must remain unchanged!
out_handle:
	ret
	
	
; -------------------------
; ******** Strings ********
; -------------------------

.area	_DATA

; Resource strings
str_rom:
	defb	'ROM',0
	
	
; ---------------------------
; ******** Variables ********
; ---------------------------

.area	_BSS

; Reflected state of control register
bm_rom:
	defs	2