;
;********************************************************************
;*
;*                  Z M M   M A N A G E M E N T
;* 
;*    These routines are used to manage the state of the ZMM.
;*    This includes the setting of the registers as well as setting
;*    up trap and interrupt stuff.
;*
;********************************************************************

; ----------------------------
; ********  Functions ********
; ----------------------------

.area	_TEXT

; Initalize ZMM and reset registers
;
; Returns nothing
; Uses: AF
zmm_init:
	; Zero out control register
	ld	a,0
	ld	(zmm_ctrl_state),a
	ld	(zmm_bnk0_state),a
	ld	(zmm_bnk1_state),a
	ld	(zmm_bnk2_state),a
	ld	(zmm_bnk3_state),a
	
	; See if we can swing in and out of virtual mode
	call	zmm_set_virt
	call	zmm_set_real
	
	; Tell the user that the ZMM is read
	ld	de,str_zmm_init
	jp	cpm_print
	
; Start execution of the virtual machine at a specific location
; HL = Address to start execution at
; 
; Does not return
; Uses: All registers zeroed
zmm_vm_start:
	ld	sp,0xFFFF-1
	ld	a,h
	ld	((zmm_capture + 0x1000) - 2),a
	ld	a,l
	ld	((zmm_capture + 0x1000) - 1),a
	
	; Reset I/O trap flag just in case
	out	(zmm_trap),a
	
	; Zero everything
	xor	a
	ld	b,a
	ld	c,a
	ld 	d,a
	ld	e,a
	ld	h,a
	ld	l,a
	exx
	ex	af,af'
	xor	a
	ld	b,a
	ld	c,a
	ld 	d,a
	ld	e,a
	ld	h,a
	ld	l,a
	
	ld	ix,0
	ld	iy,0
	
	; Enter virtual machine
	retn
	
; Set the ZMM control register to the recorded state
; (zmm_ctrl_state) = New value of ZMM control register
;
; Returns nothing
; Uses: AF
zmm_ctrl_set:
	ld	a,(zmm_ctrl_state)
	out	(zmm_ctrl),a
	ret
	
; Go to virtual mode
;
; Returns nothing
; Uses: AF
zmm_set_virt:
	ld	a,(zmm_ctrl_state)
	or	0b00000001
	ld	(zmm_ctrl_state),a
	out	(zmm_ctrl),a
	ret
	
; Go to real mode
;
; Returns nothing
; Uses: AF
zmm_set_real:
	ld	a,(zmm_ctrl_state)
	and	0b11111110
	ld	(zmm_ctrl_state),a
	out	(zmm_ctrl),a
	ret
	
; Set program direction to "IN"
;
; Returns nothing
; Uses: AF
zmm_prgm_in:
	ld	a,(zmm_ctrl_state)
	or	0b00000010
	ld	(zmm_ctrl_state),a
	out	(zmm_ctrl),a
	ret
	
; Set program direction to "OUT"
;
; Returns nothing
; Uses: AF
zmm_prgm_out:
	ld	a,(zmm_ctrl_state)
	and	0b11111101
	ld	(zmm_ctrl_state),a
	out	(zmm_ctrl),a
	ret
	
; Turn on irq intercept mode
;
; Returns nothing
; Uses: AF
zmm_irq_inter:
	ld	a,(zmm_ctrl_state)
	or	0b00000100
	ld	(zmm_ctrl_state),a
	out	(zmm_ctrl),a
	ret
	
; Turn off irq intercept mode
;
; Returns nothing
; Uses: AF
zmm_irq_normal:
	ld	a,(zmm_ctrl_state)
	and	0b11111011
	ld	(zmm_ctrl_state),a
	out	(zmm_ctrl),a
	ret

; Turn on force virtual irq
;
; Returns nothing
; Uses: AF
zmm_irq_on:
	ld	a,(zmm_ctrl_state)
	or	0b00001000
	ld	(zmm_ctrl_state),a
	out	(zmm_ctrl),a
	ret
	
; Turn off force virtual irq
;
; Returns nothing
; Uses: AF
zmm_irq_off:
	ld	a,(zmm_ctrl_state)
	and	0b11110111
	ld	(zmm_ctrl_state),a
	out	(zmm_ctrl),a
	ret
	
; Set bank 0
; A = Bank to set
;
; Returns nothing
; Uses: AF, B
zmm_bnk0_set:
	ld	(zmm_bnk0_state),a
	out	(zmm_bnk0),a
	ret
	
; Set bank 1
; A = Bank to set
;
; Returns nothing
; Uses:  AF, B
zmm_bnk1_set:
	ld	(zmm_bnk1_state),a
	out	(zmm_bnk1),a
	ret
	
; Set bank 2
; A = Bank to set
;
; Returns nothing
; Uses:  AF, B
zmm_bnk2_set:
	ld	(zmm_bnk2_state),a
	out	(zmm_bnk2),a
	ret
	
; Set bank 3
; A = Bank to set
;
; Returns nothing
; Uses:  AF, B
zmm_bnk3_set:
	ld	(zmm_bnk3_state),a
	out	(zmm_bnk3),a
	ret
	
	
; Write protect bank 0
;
; Returns nothing
; Uses: AF
zmm_bnk0_wp:
	ld	a,(zmm_bnk0_state)
	or	0b10000000
	jp 	zmm_bnk0_set
	
; Write enable bank 0
;
; Returns nothing
; Uses: AF
zmm_bnk0_we:
	ld	a,(zmm_bnk0_state)
	and	~0b10000000
	jp 	zmm_bnk0_set
	
; Write protect bank 1
;
; Returns nothing
; Uses: AF
zmm_bnk1_wp:
	ld	a,(zmm_bnk1_state)
	or	0b10000000
	jp 	zmm_bnk1_set
	
; Write enable bank 1
;
; Returns nothing
; Uses: AF
zmm_bnk1_we:
	ld	a,(zmm_bnk1_state)
	and	~0b10000000
	jp 	zmm_bnk1_set
	
; Write protect bank 2
;
; Returns nothing
; Uses: AF
zmm_bnk2_wp:
	ld	a,(zmm_bnk2_state)
	or	0b10000000
	jp 	zmm_bnk2_set
	
; Write enable bank 2
;
; Returns nothing
; Uses: AF
zmm_bnk2_we:
	ld	a,(zmm_bnk2_state)
	and	~0b10000000
	jp 	zmm_bnk2_set
	
; Write protect bank 3
;
; Returns nothing
; Uses: AF
zmm_bnk3_wp:
	ld	a,(zmm_bnk3_state)
	or	0b10000000
	jp 	zmm_bnk3_set
	
; Write enable bank 3
;
; Returns nothing
; Uses: AF
zmm_bnk3_we:
	ld	a,(zmm_bnk3_state)
	and	~0b10000000
	jp 	zmm_bnk3_set
	
; -------------------------
; ******** Strings ********
; -------------------------

.area	_DATA

; Inital string that prints when the program is started
str_zmm_init:
	defb	'INITIALIZED ZMM',0x0A,0x0D,'$'
	
; ---------------------------
; ******** Variables ********
; ---------------------------

.area	_BSS

; Reflected state of control register
zmm_ctrl_state:
	defs	1
	
; Bank 0 state
zmm_bnk0_state:
	defs	1
	
; Bank 1 state
zmm_bnk1_state:
	defs	1
	
; Bank 2 state
zmm_bnk2_state:
	defs	1
	
; Bank 3 state
zmm_bnk3_state:
	defs	1
	
