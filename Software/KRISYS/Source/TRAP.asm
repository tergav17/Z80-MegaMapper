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
	
	; Do we actually need to handle an I/O trap?
	or	a
	jp	p,trap_continue
	
	; Yep, reset trap flag
	out	(zmm_trap),a
	
	; OK, a trap did occur.
	; Are we doing "classic" I/O or extended I/O?
trap_io:	
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

	; Input or output?
	rrca
	jp	c,trap_io_ex_out
	
	; Extended input instruction
	; INI-class?
	rrca
	jp	c,trap_io_inx
	
	; Left or right column
	rrca
	jp	c,0$
	
	; Left column
	; B, D, H, or 0?
	rrca
	jp	c,1$
	
	; B or H?
	rrca
	jp	c,2$
	
	; It's B
	call	in_handle
	ld	b,a
	jp	90$
	
	; It's H	
2$:	call	in_handle
	ld	h,a
	jp	90$

	; D or 0?
1$:	rrca
	jp	c,3$

	; It's D
	call	in_handle
	ld	d,a
	jp	90$
	
	; It's 0
3$:	call	in_handle
	jp	90$
	
	
	; Right column
	; C, E, L, or A?
0$:	rrca
	jp	c,4$
	
	; C or L?
	rrca
	jp	c,5$
	
	; It's C
	call	in_handle
	ld	c,a
	jp	90$

	; It's L
5$:	call	in_handle
	ld	l,a
	jp	90$
	
	; E or A?
4$:	rrca
	jp	c,6$
	
	; It's E
	call	in_handle
	ld	e,a
	jp	90$

	; It's A
6$:	call	in_handle
	ld	(trap_a_value),a
	jp	90$
	
	; Extended IN instructions require special flag states
	; lets set them and return
90$:	push	hl
	ld	hl,trap_f_value
	bit	0,(hl)
	pop	hl
	
	; If it's zero, we don't need the carry flag
	jp	z,91$ 
	
	; Update flags and persist carry flag
	or	a
	scf
	ld	a,(trap_a_value)
	
	; Restore old SP
	ld	sp,(trap_sp_value)
	
	; Go back to the virtual machine
	retn
	
	; Update flags and reset carry flag
91$:	or	a
	ld	a,(trap_a_value)
	
	; Restore old SP
	ld	sp,(trap_sp_value)
	
	; Go back to the virtual machine
	retn
	
; Extended output instruction
trap_io_ex_out:

	; OUTI-class?
	rrca
	jp	c,trap_io_outx
	
	; Left or right column?
	rrca
	jp	c,0$
	
	; Left column
	; B, D, H, or 0?
	rrca
	jp	c,1$
	
	; B or H?
	rrca
	jp	c,2$
	
	; It's B
	ld	a,b
	call	out_handle
	jp	trap_continue
	
	; It's H	
2$:	ld	a,h
	call	out_handle
	jp	trap_continue

	; D or 0?
1$:	rrca
	jp	c,3$

	; It's D
	ld	a,d
	call	out_handle
	jp	trap_continue
	
	; It's 0
3$:	xor	a
	call	out_handle
	jp	trap_continue
	
	
	; Right column
	; C, E, L, or A?
0$:	rrca
	jp	c,4$
	
	; C or L?
	rrca
	jp	c,5$
	
	; It's C
	ld	a,c
	call	out_handle
	jp	trap_continue

	; It's L
5$:	ld	a,l
	call	out_handle
	jp	trap_continue
	
	; E or A?
4$:	rrca
	jp	c,6$
	
	; It's E
	ld	a,e
	call	out_handle
	jp	trap_continue

	; It's A
6$:	ld	a,(trap_a_value)
	call	out_handle
	jp	trap_continue


	; INX class instructions
	; The CPU should handle the differences between INX and INXR
trap_io_inx:
	; Left or right column?
	rrca
	jp	c,trap_io_ind
	
	; Left column, it's 'I' class
	push	hl
	
	; Attempt to figure out the original virtual address
	dec	hl	; Decrement to reverse 'I' class instruction
	ld	a,h
	rlca
	jp	c,0$
	
	; 0x0000 - 0x7FFF
	rlca
	jp	c,1$
	
	; 0x0000 - 0x3FFF
	ld	a,(zmm_bnk0_state)
	jp	3$
	
	; 0x4000 - 0x7FFF
1$:	ld	a,(zmm_bnk1_state)
	jp	3$
		
	; 0x8000 - 0xFFFF
0$:	rlca
	jp	c,2$
	
	; 0x8000 - 0xBFFF
	ld	a,(zmm_bnk2_state)
	jp	3$

	; 0xC000 - 0xFFFF
2$:	ld	a,(zmm_bnk3_state)

	; Remove write protection and set
3$:	and	0b01111111
	out	(zmm_bnk3),a
	
	; Correct HL
	ld	a,0b11000000
	or	h
	ld	h,a
	
	; Do the input
	call	in_handle
	ld	(hl),a
	
	; Fix banks
	ld	a,(zmm_bnk3_state)
	out	(zmm_bnk3),a
	
	; Restore and continue
	pop	hl
	jp	trap_continue
	
	; Right column, it's 'D' class
trap_io_ind:
	push	hl
	
	; Attempt to figure out the original virtual address
	inc	hl	; Increment to reverse 'D' class instruction
	ld	a,h
	rlca
	jp	c,0$
	
	; 0x0000 - 0x7FFF
	rlca
	jp	c,1$
	
	; 0x0000 - 0x3FFF
	ld	a,(zmm_bnk0_state)
	jp	3$
	
	; 0x4000 - 0x7FFF
1$:	ld	a,(zmm_bnk1_state)
	jp	3$
		
	; 0x8000 - 0xFFFF
0$:	rlca
	jp	c,2$
	
	; 0x8000 - 0xBFFF
	ld	a,(zmm_bnk2_state)
	jp	3$

	; 0xC000 - 0xFFFF
2$:	ld	a,(zmm_bnk3_state)

	; Remove write protection and set
3$:	and	0b01111111
	out	(zmm_bnk3),a
	
	; Correct HL
	ld	a,0b11000000
	or	h
	ld	h,a
	
	; Do the input
	call	in_handle
	ld	(hl),a
	
	; Fix banks
	ld	a,(zmm_bnk3_state)
	out	(zmm_bnk3),a
	
	; Restore and continue
	pop	hl
	jp	trap_continue

	; OUTX-class instructions
	; The CPU should handle the differences between OUTX and OTXR
trap_io_outx:

	; Left or right column?
	rrca
	jp	c,trap_io_outd
	
	; Left column, it's 'I' class
	push	hl
	
	; Attempt to figure out the original virtual address
	dec	hl	; Decrement to reverse 'I' class instruction
	ld	a,h
	rlca
	jp	c,0$
	
	; 0x0000 - 0x7FFF
	rlca
	jp	c,1$
	
	; 0x0000 - 0x3FFF
	ld	a,(zmm_bnk0_state)
	jp	3$
	
	; 0x4000 - 0x7FFF
1$:	ld	a,(zmm_bnk1_state)
	jp	3$
		
	; 0x8000 - 0xFFFF
0$:	rlca
	jp	c,2$
	
	; 0x8000 - 0xBFFF
	ld	a,(zmm_bnk2_state)
	jp	3$

	; 0xC000 - 0xFFFF
2$:	ld	a,(zmm_bnk3_state)

	; Remove write protection and set
3$:	and	0b01111111
	out	(zmm_bnk3),a
	
	; Correct HL
	ld	a,0b11000000
	or	h
	ld	h,a
	
	; Do the output
	ld	a,(hl)
	call	out_handle
	
	; Fix banks
	ld	a,(zmm_bnk3_state)
	out	(zmm_bnk3),a
	
	; Restore and continue
	pop	hl
	
	jp	trap_continue
	
	; Right column, it's 'D' class
trap_io_outd:
	push	hl
	
	; Attempt to figure out the original virtual address
	inc	hl	; Increment to reverse 'D' class instruction
	ld	a,h
	rlca
	jp	c,0$
	
	; 0x0000 - 0x7FFF
	rlca
	jp	c,1$
	
	; 0x0000 - 0x3FFF
	ld	a,(zmm_bnk0_state)
	jp	3$
	
	; 0x4000 - 0x7FFF
1$:	ld	a,(zmm_bnk1_state)
	jp	3$
		
	; 0x8000 - 0xFFFF
0$:	rlca
	jp	c,2$
	
	; 0x8000 - 0xBFFF
	ld	a,(zmm_bnk2_state)
	jp	3$

	; 0xC000 - 0xFFFF
2$:	ld	a,(zmm_bnk3_state)

	; Remove write protection and set
3$:	and	0b01111111
	out	(zmm_bnk3),a
	
	; Correct HL
	ld	a,0b11000000
	or	h
	ld	h,a
	
	; Do the output
	ld	a,(hl)
	call	out_handle
	
	; Fix banks
	ld	a,(zmm_bnk3_state)
	out	(zmm_bnk3),a
	
	; Restore and continue
	pop	hl
	jp	trap_continue

	
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