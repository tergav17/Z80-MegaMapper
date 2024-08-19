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
	
	; Return
	ret
	
	
; Turns on the VDP interrupt
;
; Returns nothing
; Uses: AF
irq_vdp_on:
	; Set up the AY-3-8910 I/O
	; Make sure to only change the two most significant bits
	ld	a,7		; AY register = 7
	out	(nabu_ay_latch),a
	in	a,(nabu_ay_data)
	and	0x3F
	or	0x40
	out	(nabu_ay_data),a


	; Mask on interrupt
	ld	a,14		; AY register = 14	
	out	(nabu_ay_latch),a
	in	a,(nabu_ay_data)
	or	0b00010000
	out	(nabu_ay_data),a
	
	ret
	
; Turns off the VDP interrupt
;
; Returns nothing
; Uses: AF
irq_vdp_off:
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
	in	a,(nabu_ay_data)
	and	~0b00010000
	out	(nabu_ay_data),a
	
	ret
	
; Turns on the keyboard interrupt
;
; Returns nothing
; Uses: AF
irq_keyb_on:
	; Set up the AY-3-8910 I/O
	; Make sure to only change the two most significant bits
	ld	a,7		; AY register = 7
	out	(nabu_ay_latch),a
	in	a,(nabu_ay_data)
	and	0x3F
	or	0x40
	out	(nabu_ay_data),a


	; Mask on interrupt
	ld	a,14		; AY register = 14	
	out	(nabu_ay_latch),a
	in	a,(nabu_ay_data)
	or	0b00100000
	out	(nabu_ay_data),a
	
	ret
	
; Turns off the keyboard interrupt
;
; Returns nothing
; Uses: AF
irq_keyb_off:
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
	in	a,(nabu_ay_data)
	and	~0b00100000
	out	(nabu_ay_data),a
	
	ret