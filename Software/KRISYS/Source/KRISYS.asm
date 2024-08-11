;
;********************************************************************
;*
;*              I D E N T I T Y   K R I S Y S
;*
;*      The [K]lunkly [R]emapper / [I]nterpreter [SYS]tem
;*
;*             Written by Gavin Tersteeg, 2024
;*              Copyleft, All Wrongs Reserved
;*
;*
;*   This piece of software allows different classic Z80 systems
;*   to run as "virtual machines" on top of existing hardware by
;*   use of a ZMM (Z80 MEGAMAPPER). It does this by remapping RAM
;*   and I/O address space ot match that of it's target system.
;*   Anything that can't be emulated by simple remapping is instead
;*   interpreted using I/O traps. 
;*
;*   This allows virtualized machines to run with an acceptable
;*   degree of speed and accuracy. While the ZMM is still quite
;*   limited in what sort of hardware can be efficiently virtualized,
;*   anything that avoids MMIO or graphics hardware that isn't a VDP
;*   generally can be made to work.
;* 
;********************************************************************
	
; ----------------------------
; ******** ZASM Setup ********
; ----------------------------

#target BIN
#code	_TEXT,0x0100	; Setup to run as a CP/M executable
#code	_DATA,_TEXT_end
#data	_BSS,_DATA_end

.area	_TEXT
	jp	start

; -------------------------
; ******** Equates ********
; -------------------------

; CP/M Stuff
bdos		equ	0x0005
bdos_exit	equ	0x00
bdos_con_in	equ	0x01
bdos_con_out	equ	0x02
bdos_print	equ	0x09

; Z80 MEGAMAPPER Stuff
zmm_bank_0	equ	0x30	; 16K Bank 0 (0x0000 - 0x3FFF)
zmm_bank_1	equ	0x31	; 16K Bank 1 (0x4000 - 0x7FFF)
zmm_bank_2	equ	0x32	; 16K Bank 2 (0x8000 - 0xBFFF)
zmm_bank3	equ	0x33	; 16K Bank 3 (0xC000 - 0xFFFF)
zmm_ctrl	equ	0x34	; ZMM Control Register
zmm_isr		equ	0x30	; ZMM Trapped Instruction Register
zmm_addr_hi	equ	0x32	; ZMM Trap Address High
zmm_addr_lo	equ	0x33	; ZMM Trap Address Low
zmm_trap	equ	0x37 	; ZMM Trap Vector

zmm_capture	equ	0x7000
zmm_map		equ	0x8000
zmm_top		equ	0xC000

zmm_capture_set	equ	0b01110000
zmm_capture_res	equ	0b01111111

; General Z80 Stuff
nmi_address	equ	0x0066
nmi_vector	equ	nmi_address+1

; NABU Specific Stuff
nabu_nctl	equ	0x00	; NABU Control Register
nabu_ay_data	equ	0x40	; AY-3-8910 Data Port
nabu_at_latch	equ	0x41	; AY-3-8910 Latch Port

; -------------------------------------
; ******** Additional Includes ********
; -------------------------------------

#include "MEMORY.asm"

; --------------------------------
; ******** KRISYS Startup ********
; --------------------------------

.area	_TEXT
	
	; KRISYS entry point
start:	
	; Set up stack
	di
	ld	sp,zmm_capture
	ld	hl,cpm_exit
	push	hl
	
	; Print "hello" splash
	ld	c,bdos_print
	ld	de,str_splash
	call	bdos
	
	jp	cpm_exit
	
; Go back to CP/M
;
; Does not return
; Uses: N/A
cpm_exit:
	ld	c,bdos_exit
	call	bdos	

; -------------------------
; ******** Strings ********
; -------------------------

.area	_DATA

; Inital string that prints when the program is started
str_splash:
	defb	'IDENTITY KRISYS HYPERVISOR, CP/M EDT.',0x0A,0x0D
	defb	'VER. 0.0.1, GAVIN TERSTEEG 2024'
	
; Carriage return, line break
str_crlf:
	defb	0x0A,0x0D,'$' 
	
