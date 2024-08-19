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
	jp	nz,res_missing
	
	; Open the resource
	call	res_open
	
	; Load resources into bankmap
	ld	hl,bm_rom
	ld	bc,256
	call	res_load
	
	; Program the I/O map
	ld	de,str_prgm
	call	cpm_print
	
	; Do input map
	call	zmm_set_virt
	call	zmm_prgm_in
	ld	hl,io_map_input
	ld	de,zmm_map
	ld	bc,256
	ldir
	
	; Do output map
	call	zmm_prgm_out
	ld	hl,io_map_output
	ld	de,zmm_map
	ld	bc,256
	ldir
	
	; Allocate free ram
	ld	de,str_ram_alloc
	call	cpm_print
	
	; Lower RAM
	ld	d,1
	call	mem_alloc
	call	zmm_bnk2_set
	
	; Upper RAM
	ld	d,1
	call	mem_alloc
	call	zmm_bnk3_set
	
	; Mount ROM
	ld	a,(bm_rom)
	call	zmm_bnk0_set
	call	zmm_bnk0_wp
	ld	a,(bm_rom+1)
	call	zmm_bnk1_set
	call	zmm_bnk1_wp
	
	; Enable VDP interrupt
	; call	irq_vdp_on
	
	; Start up VM
	ld	de,str_vm_start
	call	cpm_print

	call	zmm_set_virt
	ld	hl,0
	jp	zmm_vm_start
	
	
	ld	a,(zmm_bnk1_state)
	out	(zmm_bnk3),a
	ld	a,(zmm_top+0)
	call	debug_point
	ld	a,(zmm_top+1)
	call	debug_point
	ld	a,(zmm_top+2)
	call	debug_point
	ld	a,(zmm_top+3)
	call	debug_point
	
	jp	cpm_exit
	
	
; A = Value to print
debug_point:
	call	tohex
	ld	(str_debug_val),de
	ld	de,str_debug
	jp	cpm_print
	
	
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
	
; Bootup strings
str_prgm:
	defb	'PROGRAMMING VM I/O MAP',0x0A,0x0D,'$'
	
; Bootup strings
str_ram_alloc:
	defb	'ALLOCATING RAM',0x0A,0x0D,'$'
	
; Bootup strings
str_vm_start:
	defb	'STARTING VM NOW',0x0A,0x0D,'$'
	
; Debug string
str_debug:
	defb 	'A = '
str_debug_val:
	defb	'XX',0x0A,0x0D,'$'


; ----------------------
; ******** Data ********
; ----------------------
	
.area	_DATA

TRAP	equ	zmm_trap	; Trap Vector
_VDD	equ	nabu_vdp_data	; VDP Data
_VDA	equ	nabu_vdp_addr	; VDP Address

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
	defb	_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0x8*
	defb	_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0x9*
	defb	_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0xA*
	defb	_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0xB*
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
	defb	_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0x8*
	defb	_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0x9*
	defb	_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0xA*
	defb	_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0xB*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xC*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xD*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xE*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xF*

; ---------------------------
; ******** Variables ********
; ---------------------------

.area	_BSS

; Reflected state of control register
bm_rom:
	defs	2