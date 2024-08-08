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
zm_a_lo	equ	0x32
zm_a_hi	equ	0x33
zm_trap	equ	0x37 
zm_map	equ	0x8000
zm_top	equ	0xC000

zm_sset	equ	0b10000000
zm_sres	equ	0b01110000

nmi_adr	equ	0X0066
nmi_vec	equ	nmi_adr+1

; Program start
	org	0x0100
	
	; Print "hello" splash
start:	di
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
	ld	a,0b00000101
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
	ld	c,b_print
	ld	de,s_fail
	call	bdos
	jp	exit

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
	ld	c,b_print
	ld	de,s_fail
	call	bdos
	jp	exit

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
	ld	bc,snip0_e-snip0
	ldir
	
	; Punch in entry address
	ld	hl,0
	add	hl,sp
	ld	a,zm_sres
	and	h
	or	zm_sset
	ld	h,a
	ld	(hl),zm_top&0xFF
	inc	hl
	ld	a,zm_sres
	and	h
	or	zm_sset
	ld	h,a
	ld	(hl),zm_top>>8
	
	; Place vector
	ld	hl,1$
	ld	b,0
	ld	(nmi_vec),hl
	
	; Kick off RETN to reset trap mode
	retn
0$:	jp	0$

	; We should end up here
1$:	dec	b
	dec	b
	jp	z,2$
	
	; Fail!
	ld	c,b_print
	ld	de,s_fail
	call	bdos
	jp	exit

	; Disable virtual mode and pass
2$:	ld	a,0b00000000
	out	(zm_ctrl),a
	ld	c,b_print
	ld	de,s_pass
	call	bdos
	
	; Done
exit:	ld	c,b_exit
	call	bdos
	
	
; Snippets
snip0:

	; Play with register B, and then trap out
	ld	b,1
	nop
	ld	b,2
	in	a,(zm_trap)
	ld	b,3
0$:	jr	0$

snip0_e:
	

; Strings
splash:
	defb	'ZMM Basic Functionality Test',0x0A,0x0D
	defb	'Rev 1a, tergav17 (Gavin)',0x0A,0x0D,'$' 
	
s_pass:
	defb	'PASS',0x0A,0x0D,'$'
	
s_fail:
	defb	'FAIL',0x0A,0x0D,'$'
	
s_test0:
	defb	'TEST 0: Check mapping basic: $'
	
s_test1:
	defb	'TEST 1: Check memory overlay: $'
	
s_test2:
	defb	'TEST 2: Check memory banking...'
	
s_crlf:	
	defb	0x0A,0x0D,'$'
	
s_test3:
	defb	'TEST 3: Check bank map... $'
	
s_test4:
	defb	'TEST 4: Trap engagement... $'
	
; Variables
textbank:
	defb	0
	
databank:
	defb	0
	
; Heap
heap:

; Area to keep track of allocated banks
bankmap	equ	heap	; 256 bytes