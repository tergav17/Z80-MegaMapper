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
	
	; Translate attenuation
	push	hl
	ld	c,a
	ld	hl,snpsg_vol_tab
	add	hl,bc
	ld	a,(hl)
	pop	hl
	ld	(hl),a
	jp	80$
	
	; Frequency (maybe)
10$:	ld	a,0x03
	cp	c
	jp	z,20$

	; Frequency (low bits)
	ld	a,b
	ld	b,0
	sla	c
	ld	hl,snpsg_freq
	add	hl,bc
	and	0b00001111
	ld	b,a
	ld	a,(hl)
	and	0b11110000
	or	b
	ld	(hl),a
	ld	(snpsg_lastf),hl
	jp	80$
	
	; Noise control
20$:	ld	a,b
	and	0b00001111
	ld	(snpsg_n_ctrl),a
	jp	80$
	
	; Frequency (high bits)
30$:	ld	a,b
	ld	b,0
	rlca
	rlca
	rlca
	rl	b
	rlca
	rl	b
	and	0b11110000
	ld	c,a
	ld	hl,(snpsg_lastf)
	ld	a,0b00001111
	and	(hl)
	or	c
	ld	(hl),a
	inc	hl
	ld	(hl),b
	
	; Update the state to the AY-3-8910
80$:	ld	a,0
	ld	c,nabu_ay_data
	ld	hl,snpsg_freq
	
	; Set frequency
81$:	out	(nabu_ay_latch),a
	outi
	inc	a
	cp	6
	jp	nz,81$
	
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
	inc	c
	djnz	82$
	
99$	pop	hl
	pop	bc
	ret

; -------------------------
; ******** Tables ********
; -------------------------

.area	_DATA

; Volume translation table
; Translates SN attenuation to AY amplitude
snpsg_vol_tab:
	defb	0
	defb	0x8
	defb	0xA
	defb	0xB
	defb	0xC
	defb	0xC
	defb	0xE
	defb	0xE
	defb	0xE
	defb	0xE
	defb	0xE
	defb	0xF
	defb	0xF
	defb	0xF
	defb	0xF
	defb	0
	

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
