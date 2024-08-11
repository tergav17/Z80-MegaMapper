;
;**************************************************************
;*
;*      Z M M   B A S I C   F U N C T I O N   T E S T
;*
;*      Tests memory and basic functionality of the ZMM
;*      (Z80 MegaMapper). Segmentation as well as I/O
;*      traps.
;* 
;**************************************************************
	
; Equates
bdos	equ	0x0005

b_exit	equ	0x00
b_coin	equ	0x01
b_cout	equ	0x02
b_print	equ	0x09

zm_bnk0	equ	0x30
zm_bnk1	equ	0x31
zm_bnk2	equ	0x32
zm_bnk3	equ	0x33
zm_ctrl	equ	0x34
zm_isr	equ	0x30
zm_a_hi	equ	0x32
zm_a_lo	equ	0x33
zm_trap	equ	0x37 
zm_map	equ	0x8000
zm_top	equ	0xC000

zm_sset	equ	0b01110000
zm_sres	equ	0b01111111

nmi_adr	equ	0X0066
nmi_vec	equ	nmi_adr+1

nb_nctl	equ	0x00		; Control Register
nb_ayda	equ	0x40		; AY-3-8910 data port
nb_atla	equ	0x41		; AY-3-8910 latch port

; Program start
	org	0x0100
	
	; Print "hello" splash
start:	di
	ld	sp,0x4000
	ld	c,b_print
	ld	de,splash
	call	bdos
	
	; Test #0
test0:	ld	c,b_print
	ld	de,s_test0
	call	bdos
	
	; Set up passthru table for virtual mode
	ld	a,0b00000001
	out	(zm_ctrl),a
	ld	hl,zm_map
0$:	ld	(hl),l
	inc	l
	jp	nz,0$
	ld	a,0b00000011
	out	(zm_ctrl),a
	ld	hl,zm_map
1$:	ld	(hl),l
	inc	l
	jp	nz,1$
	
	; Disable virtual mode
	ld	a,0b00000000
	out	(zm_ctrl),a
	ld	c,b_print
	ld	de,s_pass
	call	bdos
	
	; Test #1
test1:	ld	c,b_print
	ld	de,s_test1
	call	bdos
	
	; Zero out top 16K of memory
	ld	a,0b00000001
	out	(zm_ctrl),a
	ld	hl,zm_top
	ld	de,zm_top+1 
	ld	bc,0x4000-1
	xor	a
	ld	(hl),a
	ldir
	
	; Disable virtual mode
	ld	a,0b00000000
	out	(zm_ctrl),a
	ld	c,b_print
	ld	de,s_pass
	call	bdos
	
	; Test #2
test2:	ld	c,b_print
	ld	de,s_test2
	call	bdos
	
	; Enable virtual mode
	ld	a,0b00000001
	out	(zm_ctrl),a
	
	; Write tags to all pages
	ld	b,0
0$:	ld	a,b
	out	(zm_bnk3),a
	ld	(zm_top),a
	neg
	ld	(zm_top+1),a
	inc	b
	jp	nz,0$
	
	; Mark any banks that record correctly
	ld	b,0
	ld	hl,bankmap
1$:	xor	a
	ld	(hl),a
	ld	a,b
	out	(zm_bnk3),a
	ld	a,(zm_top)
	cp	b
	jp	nz,2$
	ld	a,(zm_top+1)
	ld	c,a
	ld	a,b
	neg
	cp	c
	jp	nz,2$
	
	; Mark it
	ld	a,0xFF
	ld	(hl),a
	
	; Next
2$:	inc	hl
	inc	b
	jp	nz,1$
	
	; Disable virtual mode
	ld	a,0b00000000
	out	(zm_ctrl),a
	
	; Now try to print everything out
	ld	hl,bankmap
	ld	b,32
	ld	c,8
	
	; Get bankmap value and set register E
3$:	ld	e,'.'
	ld	a,(hl)
	or	a
	jp	z,4$
	ld	e,'X'

	; Print character
4$:	push	bc
	push	hl
	ld	c,b_cout
	call	bdos
	pop	hl
	pop	bc
	
	; Do another?
	inc	hl
	djnz	3$

	; Print CRLF
	push	bc
	push	hl
	ld	c,b_print
	ld	de,s_crlf
	call	bdos
	pop	hl
	pop	bc
	
	; New line maybe
	ld	b,32
	dec	c
	jp	nz,3$
	
	; Pass
	ld	c,b_print
	ld	de,s_pass
	call	bdos
	
	; Test #3
test3:	ld	c,b_print
	ld	de,s_test3
	call	bdos
	
	; Start checking bank map for 2 valid banks
	ld	b,0
	ld	hl,bankmap
	
0$:	ld	a,(hl)
	or	a
	jp	nz,1$
	inc	hl
	inc	b
	jp	nz,0$
	
	; Fail!
	jp	fail

	; Save to text bank
1$:	ld	a,b
	ld	(textbank),a
	jp	3$
	
2$:	ld	a,(hl)
	or	a
	jp	nz,4$
3$:	inc	hl
	inc	b
	jp	nz,2$
	
	; Fail!
	jp	fail

	; Pass
4$:	ld	a,b
	ld	(databank),a
	ld	c,b_print
	ld	de,s_pass
	call	bdos
	
	; Test #4
test4:	ld	c,b_print
	ld	de,s_test4
	call	bdos
	
	; Set bank 3 to textbank
	ld	a,(textbank)
	out	(zm_bnk3),a
	
	; Install NMI handler
	ld	a,0xC3
	ld	(nmi_adr),a
	
	; Enable virtual mode
	ld	a,0b00000001
	out	(zm_ctrl),a
	
	; Copy snippet to virtual memory
	ld	hl,snip0
	ld	de,zm_top
	ld	bc,snip0_end-snip0
	ldir
	
	; Just incase of a hardware failure
	ld	hl,fail
	push 	hl
	
	; Punch in entry address
	ld	de,zm_top
	call	trapset
	
	; Place vector
	ld	hl,1$
	ld	b,0
	ld	(nmi_vec),hl
	
	; Kick off RETN to reset trap mode
	out	(zm_trap),a
	nop
	retn
	jp	fail

	; We should end up here
1$:	ld	a,0b00000000
	out	(zm_ctrl),a

	; Check register B
	ld	a,b
	call	tohex
	ld	(s_nfail),de
	dec	b
	dec	b
	jp	nz,fail

	; Pass
	ld	c,b_print
	ld	de,s_pass
	call	bdos
	
	; Test #5
test5:	ld	c,b_print
	ld	de,s_test5
	call	bdos
	
	; Set bank 0,1,2 to databank
	ld	a,(databank)
	out	(zm_bnk0),a
	out	(zm_bnk1),a
	out	(zm_bnk2),a
	
	; Enable virtual mode
	ld	a,0b00000001
	out	(zm_ctrl),a
	
	; Punch in entry address
	ld	de,zm_top+2
	call	trapset
	
	; Place vector
	ld	hl,1$
	ld	b,0
	ld	(nmi_vec),hl
	
	; Kick off RETN to reset trap mode
	out	(zm_trap),a
	nop
	retn
	jp	fail

	; We should end up here
1$:	ld	a,0b00000000
	out	(zm_ctrl),a
	
	; Pass
	ld	c,b_print
	ld	de,s_pass
	call	bdos
	
	; Test #6
tes6:	ld	c,b_print
	ld	de,s_test6
	call	bdos
	
	; Enable virtual mode
	ld	a,0b00000001
	out	(zm_ctrl),a
	
	; Remap 0xF9 of OUT to zm_trap
	ld	a,zm_trap
	ld	(zm_map+0xF9),a
	
	; Punch in entry address
	ld	de,zm_top+4
	call	trapset
	
	; Place vector
	ld	hl,1$
	ld	b,0
	ld	(nmi_vec),hl
	
	; Kick off RETN to reset trap mode
	out	(zm_trap),a
	nop
	retn
	jp	fail
	
	; We should end up here
1$:	ld	a,0b00000000
	out	(zm_ctrl),a
	
	; Check address
	in	a,(zm_a_lo)
	ld	b,a
	call	tohex
	ld	(s_nfail),de
	ld	a,0xF9
	cp	b
	jp	nz,fail
	
	in	a,(zm_a_hi)
	ld	b,a
	call	tohex
	ld	(s_nfail),de
	ld	a,0x69
	cp	b
	jp	nz,fail
	
	; Check instruction
	in	a,(zm_isr)
	ld	b,a
	call	tohex
	ld	(s_nfail),de
	ld	a,0xBD
	cp	b
	jp	nz,fail
	
	; Reset I/O violation latch
	out	(zm_trap),a
	in	a,(zm_isr)
	ld	b,a
	call	tohex
	ld	(s_nfail),de
	ld	a,0x3D
	cp	b
	jp	nz,fail
	
	; Pass
	ld	c,b_print
	ld	de,s_pass
	call	bdos
	
; Done
exit:	ld	c,b_exit
	call	bdos
	
; Fail!
fail:	ld	a,0b00000000
	out	(zm_ctrl),a
	ld	c,b_print
	ld	de,s_nfail
	call	bdos
	jp	exit
	
; Converts the value into an 8 bit hex number
; A = Number to convert
;
; Returns DE = result
; uses: AF, DE
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
	
; Turns off all maskable interrupts to stop traps from occuring
;
; uses: AF
intoff:	ld	a,0x07
	out	(nb_atla),a	; AY register = 7
	in	a,(nb_ayda)
	and	0x3F
	or	0x40
	out	(nb_ayda),a	; Configure AY port I/O
	
	ld	a,0x0E
	out	(nb_atla),a	; AY register = 14
	ld	a,0x00
	out	(nb_ayda),a	; All interrupts disabled
	
	ret
	
; Sets the trap return address
; DE = return address
;
; uses: AF, HL
trapset:ld	hl,0
	add	hl,sp
	inc	hl
	inc	hl
	ld	a,zm_sres
	and	h
	or	zm_sset
	ld	h,a
	ld	(hl),e
	inc	hl
	ld	a,zm_sres
	and	h
	or	zm_sset
	ld	h,a
	ld	(hl),d
	ret
	
; Snippets
snip0:

	; Jump table
	jr	snip0_a
	jr	snip0_b
	jr	snip0_c

	; Play with register B, and then trap out
snip0_a:nop
	ld	b,1
	nop
	ld	b,2
	in	a,(zm_trap)
	ld	b,3

	; Blink light
0$:	ld	a,0x11
	out	(nb_nctl),a
	
	ld	bc,0
1$:	push	hl
	pop	hl
	djnz	1$
	dec	c
	jr	nz,1$
	
	ld	a,0x01
	out	(nb_nctl),a
	
2$:	nop
	nop
	nop
	nop
	djnz	2$
	dec	c
	jr	nz,2$
	jr	0$
	
	; Overwrite the first 48KB of memory, and then trap
snip0_b:ld	hl,0
	ld	de,1
	ld	bc,0x0C000-1
	ld	(hl),0
	ldir
	
	out	(zm_trap),a
0$:	jr	0$

snip0_c:ld	b,0x69
	ld	c,0xF9
	out	(c),a
	
0$:	jr	0$

snip0_end:
	

; Strings
splash:
	defb	'ZMM Basic Functionality Test',0x0A,0x0D
	defb	'Rev 1a, tergav17 (Gavin)',0x0A,0x0D,'$' 
	
s_pass:
	defb	'PASS',0x0A,0x0D,'$'
	
s_nfail
	defb	'XX '
	
s_fail:
	defb	'FAIL',0x0A,0x0D,'$'
	
s_test0:
	defb	'TEST 0: Check mapping basic: $'
	
s_test1:
	defb	'TEST 1: Check upper overlay: $'
	
s_test2:
	defb	'TEST 2: Check memory banking...'
	
s_crlf:	
	defb	0x0A,0x0D,'$'
	
s_test3:
	defb	'TEST 3: Check bank map... $'
	
s_test4:
	defb	'TEST 4: Trap engagement... $'
	
s_test5:
	defb	'TEST 5: Check full overlay... $'
	
s_test6:
	defb	'TEST 6: Trap state recovery... $'
	
; Variables
textbank:
	defb	0
	
databank:
	defb	0
	
; Heap
heap:

; Area to keep track of allocated banks
bankmap	equ	heap	; 256 bytes