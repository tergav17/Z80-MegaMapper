;
;********************************************************************
;*
;*                     T R A P   H A N D L E R
;* 
;*    Responsible for handling various traps from the ZMM. Both
;*    interrupt and I/O traps will be pre-processed before being
;*    sent to the virtualization core for device-specific handling
;*
;********************************************************************

; -------------------------------
; ********  Trap Handler ********
; -------------------------------

.area	_TEXT

; Entry point for traps
trap_entry:
	; Save value of SP
	ld	(trap_sp_value),sp
	ld	sp,kri_stack
	
	; Save value of AF
	push	af
	
	; Check in on device interrupts
	call	irq_handle
	
	; Grab the value of the ISR register
	in	a,(zmm_isr)
	
	; Do we actually need to handle a trap?
	or	a
	jp	p,trap_continue
	
	; OK, a trap did occur.
	; Are we doing "classic" I/O or extended I/O?
	cp	0b11101000
	jp	c,trap_io_ext
	
	; In or out?
	cp	0b11101100
	jp	c,0$
	
	; In it is
	call	in_handle
	ld	(trap_a_value),a
	jp	trap_continue
	
	; Out it is
0$:	ld	a,(trap_a_value)
	call	out_handle
	jp	trap_continue
	
	
	
	
	
	
	
; It's an extended I/O instruction
trap_io_ext:
	
	
	
	; If the number is even, then it will ALWAYS be an out instruction
	
; Continue execution
trap_continue:
	; Restore AF
	pop	af
	
	; Restore old SP
	ld	sp,(trap_sp_value)
	
	; Go back to the virtual machine
	retn
	
; ----------------------------
; ********  Functions ********
; ----------------------------

.area	_TEXT

; Initalize trap handling stuff
;
; Returns nothing
; Uses: AF, HL
trap_init:
	; Install trap vector
	ld	a,0xC3
	ld	(nmi_address),a
	ld	hl,trap_entry
	ld	(nmi_vector),hl
	
	ret
	
	

; ---------------------------
; ******** Variables ********
; ---------------------------

.area	_BSS

; Value of untrapped SP value
trap_sp_value:
	defs	2