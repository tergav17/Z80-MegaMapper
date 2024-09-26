;
;********************************************************************
;*
;*        K R I S Y S   F U Z I X   C O R E
;*
;********************************************************************

#include "KRISYS.asm"

; ---------------------------
; ******** Core Init ********
; ---------------------------

.area	_TEXT

; Start of FUZIX core
core_start:

	; Attempt to find bootrom resource
	ld	de,str_boot
	call	res_locate
	or	a
	jp	nz,res_missing
	
	; Open the resource
	call	res_open
	
	; Load resources into bankmap
	ld	hl,bm_boot
	ld	bc,128
	call	res_load

	jp	fuz_exit
	
debug_point:


; Exit handle
fuz_exit:
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
str_boot:
	defb	'BOOT',0
	
str_kblock_0:
	defb	'KD0',0
	
str_kblock_1:
	defb	'KD1',0
	
; ----------------------
; ******** Data ********
; ----------------------
	
.area	_DATA

TRAP	equ	zmm_trap

; Virtual machine I/O maps
; Input map
io_map_input:
	;	0x*0 0x*1 0x*2 0x*3 0x*4 0x*5 0x*6 0x*7 0x*8 0x*9 0x*A 0x*B 0x*C 0x*D 0x*E 0x*F 
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x0*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x1*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x2*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x3*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x4*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x5*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x6*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x7*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x8*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x9*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xA*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xB*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xC*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xD*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xE*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xF*

; Output map
io_map_output:
	;	0x*0 0x*1 0x*2 0x*3 0x*4 0x*5 0x*6 0x*7 0x*8 0x*9 0x*A 0x*B 0x*C 0x*D 0x*E 0x*F 
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x0*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x1*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x2*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x3*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x4*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x5*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x6*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x7*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x8*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x9*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xA*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xB*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xC*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xD*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xE*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xF*
	

; ---------------------------
; ******** Variables ********
; ---------------------------

.area	_BSS
	
; Block map for BIOS
bm_boot:
	defs	2