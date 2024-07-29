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
	
	; Set up passthru table for mapper mode
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
	
	; Disable mapper mode
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
	
	; Disable mapper mode
	ld	a,0b00000000
	out	(zm_ctrl),a
	ld	c,b_print
	ld	de,s_pass
	call	bdos
	
	; Test #2
test2:	ld	c,b_print
	ld	de,s_test2
	call	bdos
	
	; Enable mapper mode
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
	
	; Disable mapper mode
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
	
	; Done
	ld	c,b_exit
	call	bdos
	

; Strings
	
splash:
	defb	'ZMM Basic Functionality Test',0x0A,0x0D
	defb	'Rev 1a, tergav17 (Gavin)',0x0A,0x0D,'$' 
	
s_pass:
	defb	'PASS',0x0A,0x0D,'$'
	
s_test0:
	defb	'TEST 0: Check mapping basic: $'
	
s_test1:
	defb	'TEST 1: Check memory overlay: $'
	
s_test2:
	defb	'TEST 2: Check memory paging...'
	
s_crlf:	
	defb	0x0A,0x0D,'$'
	
; Heap
heap:

; Area to keep track of allocated banks
bankmap	equ	heap	; 256 bytes