;
;**************************************************************
;*
;*         S N 7 6 4 8 9   P S G   E M U L A T O R
;*
;*    Translates audio data meant for a SN76489 PSG into
;*    commands for the AY-3-8910.
;*
;*    This translation isn't perfect, but for most games
;*    it's "good enough".
;* 
;**************************************************************


; ----------------------------
; ********  Functions ********
; ----------------------------

.area	_TEXT

; Reset the PSG emulator
;
; Returns nothing
; Uses: AF, HL
snpsg_reset:

	; Reset registers
	ld	hl,0
	ld	(snpsg_freq),hl
	ld	(snpsg_freq+2),hl
	ld	(snpsg_freq+4),hl

	ld	a,0x0F
	ld	(snpsg_atten),a
	ld	(snpsg_atten+1),a
	ld	(snpsg_atten+2),a
	ld	(snpsg_atten+3),a

	xor	a
	ld	(snpsg_n_ctrl),a

	; Reset AY-3-8910
	ld	a,7
	out	(nabu_ay_latch),a
	ld	a,0b01111111
	out	(nabu_ay_data),a

	ret
	
	
	
	
; Send a byte to the "SN76489"
; A = Byte to send
;
; Uses: AF
snpsg_send:
	push	bc
	push 	hl
	
	; Save latest command byte
	ld	b,a
	ld	c,0
	
	; Check bit 7
	rlca
	jp	nc,30$
	
	; Get register offset
	rlca
	rl	c
	rlca
	rl	c
	
	; Frequency or attenuation?
	rlca
	jp	nc,10$
	
	; Attenuation
	ld	a,b
	and	0b00001111
	ld	b,0
	ld	hl,snpsg_atten
	add	hl,bc
	ld	(hl),a
	jp	80$
	
	; Frequency (maybe)
10$:	ld	a,0x03
	cp	c
	jp	z,20$

	ld	a,b
	ld	b,0
	sla	c
	add	hl,bc
	rrca
	rr	b
	rrca
	rr	b
	and	0b00000011
	ld	(hl),a
	inc	hl
	ld	a,(hl)
	and	0b00111111
	or	b
	ld	(hl),a
	ld	(snpsg_lastf),hl
	jp	80$
	
	; Noise control
20$:	ld	a,b
	and	0b00001111
	ld	(snpsg_n_ctrl),a
	jp	80$
	
	; Frequency (low bits)
30$:	ld	a,b
	and	0b00111111
	ld	b,a
	ld	hl,(snpsg_lastf)
	ld	a,0b11000000
	and	(hl)
	or	b
	ld	(hl),a
	
	; Update the state to the AY-3-8910
80$:	ld	a,7
	ld	c,nabu_ay_data
	ld	hl,snpsg_freq+6
	
	; Set frequency
81$:	out	(nabu_ay_latch),a
	outd
	dec	a
	jp	p,81$
	
	; Set channel mask
	ld	a,7
	out	(nabu_ay_latch),a
	ld	a,0b01111000
	out	(nabu_ay_data),a
	
	; Set amplitude
	ld	hl,snpsg_atten
	ld	c,8
	ld	b,3
82$:	ld	a,c
	out	(nabu_ay_latch),a
	ld	a,(hl)
	cp	0x0F
	jp	nz,83$
	xor	a
83$:	out	(nabu_ay_data),a
	djnz	82$
	
99$	pop	hl
	pop	bc
	ret

; ---------------------------
; ******** Variables ********
; ---------------------------

.area	_BSS

; Channel frequency
; Each channel stores is frequency between 2 bytes, there are 3 channels
snpsg_freq:
	defs	6
	
; Channel attenuation
; Similar to frequency, but only 1 byte wide and there are 4 channels
snpsg_atten:
	defs	4
	
; Noise control
snpsg_n_ctrl:
	defs	1
	
; Last frequency accessed
snpsg_lastf:
	defs	2
