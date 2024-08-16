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
	ld	sp,zmm_capture
	
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
	; Lets figure out if it's an IN or OUT
	
	
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