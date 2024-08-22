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

stack_size = 0x20

#target BIN
#code	_TEXT,0x0100	; Setup to run as a CP/M executable
#code	_DATA,_TEXT_end
#data	_BSS,_DATA_end

; Make sure w don't overrun available memory
#assert	_BSS_end < (zmm_capture-stack_size)

.area	_TEXT
	jp	kri_start

; -------------------------
; ******** Equates ********
; -------------------------

; CP/M Stuff
bdos		equ	0x0005
bdos_exit	equ	0x00
bdos_con_in	equ	0x01
bdos_con_out	equ	0x02
bdos_print	equ	0x09
bdos_open	equ	0x0F
bdos_read	equ	0x14
bios_set_dma	equ	0x1A

cpm_command	equ	0x0080

; Z80 MEGAMAPPER Stuff
zmm_bnk0	equ	0x30	; 16K Bank 0 (0x0000 - 0x3FFF)
zmm_bnk1	equ	0x31	; 16K Bank 1 (0x4000 - 0x7FFF)
zmm_bnk2	equ	0x32	; 16K Bank 2 (0x8000 - 0xBFFF)
zmm_bnk3	equ	0x33	; 16K Bank 3 (0xC000 - 0xFFFF)
zmm_ctrl	equ	0x34	; ZMM Control Register
zmm_isr		equ	0x30	; ZMM Trapped Instruction Register
zmm_addr_hi	equ	0x32	; ZMM Trap Address High
zmm_addr_lo	equ	0x33	; ZMM Trap Address Low
zmm_trap	equ	0x37 	; ZMM Trap Vector

zmm_capture	equ	0x7000
zmm_map		equ	0x8000
zmm_top		equ	0xC000

zmm_capt_set	equ	0b01110000
zmm_capt_res	equ	0b01111111

; General Z80 Stuff
nmi_address	equ	0x0066
nmi_vector	equ	nmi_address+1

; NABU Specific Stuff
nabu_nctl	equ	0x00	; NABU Control Register
nabu_ay_data	equ	0x40	; AY-3-8910 Data Port
nabu_ay_latch	equ	0x41	; AY-3-8910 Latch Port
nabu_vdp_data	equ	0xA0	; VDP Data Port
nabu_vdp_addr	equ	0xA1	; VDP Address Port

; Stack / Trap Management
kri_stack	equ	zmm_capture
trap_a_value	equ	kri_stack-1
trap_f_value	equ	kri_stack-2

; -------------------------------------
; ******** Additional Includes ********
; -------------------------------------

#include "MEMORY.asm"
#include "ZMM.asm"
#include "RESOURCE.asm"
#include "TRAP.asm"
#include "IRQ.asm"
#include "DEBUG.asm"

; --------------------------------
; ******** KRISYS Startup ********
; --------------------------------

.area	_TEXT
	
	; KRISYS entry point
kri_start:	
	; Set up stack
	di
	ld	sp,kri_stack
	ld	hl,cpm_exit
	push	hl
	
	; Print "hello" splash
	ld	c,bdos_print
	ld	de,str_splash
	call	bdos
	
	; Initalize subcomponents
	call	irq_init
	call	zmm_init
	call	trap_init
	call	mem_map_init
	call	res_init
	
	
	; Start the core
	jp	core_start
	
; ------------------------------
; ******** CP/M Service ********
; ------------------------------
	
; Print something to the CP/M console
; DE = Address of string to print
;
; Returns nothing
; Uses: All
cpm_print:
	; Save control register state
	ld	a,(zmm_ctrl_state)
	push	af
	
	; Go to real mode
	call zmm_set_real
	
	; Do BDOS call
	ld	c,bdos_print
	call	bdos
	
	; Restore register
	pop	af
	ld	(zmm_ctrl_state),a
	jp	zmm_ctrl_set
	
; Go back to CP/M
;
; Does not return
; Uses: N/A
cpm_exit:
	call	zmm_set_real
	ld	c,bdos_exit
	call	bdos	
	
; ----------------------
; ******** Misc ********
; ----------------------
	
; Converts the value into an 8 bit hex number
; A = Number to convert
;
; Returns DE = result
; Uses: AF, DE
tohex:	ld	d,a
	call	0$
	ld	e,a
	ld	a,d
	call	1$
	ld	d,a
	ret
	
0$:	rra
	rra
	rra
	rra
1$:	or	0xF0
	daa
	add	a,0xA0
	adc	a,0x40
	ret

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
	
