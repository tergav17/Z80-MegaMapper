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
	ld	(zmm_bank_0_state),a
	ld	(zmm_bank_1_state),a
	ld	(zmm_bank_2_state),a
	ld	(zmm_bank_3_state),a
	
	; See if we can swing in and out of virtual mode
	call	zmm_set_virtual
	call	zmm_set_real
	
	; Tell the user that the ZMM is read
	ld	de,str_zmm_init
	jp	cpm_print
	
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
zmm_set_virtual:
	ld	a,(zmm_ctrl_state)
	or	0b00000001
	ld	(zmm_ctrl_state),a
	jp	zmm_ctrl_set
	
; Go to real mode
;
; Returns nothing
; Uses: AF
zmm_set_real:
	ld	a,(zmm_ctrl_state)
	and	0b11111110
	ld	(zmm_ctrl_state),a
	jp	zmm_ctrl_set

	
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
zmm_bank_0_state:
	defs	1
	
; Bank 1 state
zmm_bank_1_state:
	defs	1
	
; Bank 2 state
zmm_bank_2_state:
	defs	1
	
; Bank 3 state
zmm_bank_3_state:
	defs	1
	
