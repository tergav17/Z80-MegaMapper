;
;********************************************************************
;*
;*             I N T E R R U P T   M A N A G E M E N T
;* 
;*    Manages "real" system interrupts on the host hardware.
;*    Also deals with mocking interrupts to the virtual machine
;*    if it is needed.
;*
;********************************************************************

; ----------------------------
; ********  Functions ********
; ----------------------------

.area	_TEXT

; Initalize interrupt stuff
;
; Returns nothing
; Uses: AF
irq_init:
	; Set up the AY-3-8910 I/O
	; Make sure to only change the two most significant bits
	ld	a,7		; AY register = 7
	out	(nabu_ay_latch),a
	in	a,(nabu_ay_data)
	and	0x3F
	or	0x40
	out	(nabu_ay_data),a


	; Mask off all interrupts
	ld	a,14		; AY register = 14	
	out	(nabu_ay_latch),a
	xor	a
	out	(nabu_ay_data),a
	ld	(irq_mask_state),a
	
	; Return
	ret
	
	
; Turns on the VDP interrupt
;
; Returns nothing
; Uses: AF
irq_vdp_on:
	ld	a,(irq_mask_state)
	or	0b00010000
	ld	(irq_mask_state),a
	
	jp	irq_restore
	
; Turns off the VDP interrupt
;
; Returns nothing
; Uses: AF
irq_vdp_off:
	ld	a,(irq_mask_state)
	and	~0b00010000
	ld	(irq_mask_state),a
	
	jp	irq_restore
	
; Turns on the keyboard interrupt
;
; Returns nothing
; Uses: AF
irq_keyb_on:
	ld	a,(irq_mask_state)
	or	0b00100000
	ld	(irq_mask_state),a
	
	jp	irq_restore
	
; Turns off the keyboard interrupt
;
; Returns nothing
; Uses: AF
irq_keyb_off:
	ld	a,(irq_mask_state)
	and	~0b00100000
	ld	(irq_mask_state),a
	
	jp	irq_restore

; Turns on the HCCA output
;
; Returns nothing
; Uses: AF
irq_hcca_o_on:
	ld	a,(irq_mask_state)
	or	0b01000000
	ld	(irq_mask_state),a
	
	jp	irq_restore
	
; Turns off the HCCA input
;
; Returns nothing
; Uses: AF
irq_hcca_o_off:
	ld	a,(irq_mask_state)
	and	~0b01000000
	ld	(irq_mask_state),a
	
	jp	irq_restore
	
; Restore the IRQ mask from 
;
; Returns nothing
; Uses: AF
irq_restore:
	; Set up the AY-3-8910 I/O
	; Make sure to only change the two most significant bits
	ld	a,7		; AY register = 7
	out	(nabu_ay_latch),a
	in	a,(nabu_ay_data)
	and	0x3F
	or	0x40
	out	(nabu_ay_data),a


	; Mask off interrupt
	ld	a,14		; AY register = 14	
	out	(nabu_ay_latch),a
	ld	a,(irq_mask_state)
	out	(nabu_ay_data),a
	ret
	
; ---------------------------
; ******** Variables ********
; ---------------------------

.area	_BSS

; Value interrupt mask
irq_mask_state:
	defs	1