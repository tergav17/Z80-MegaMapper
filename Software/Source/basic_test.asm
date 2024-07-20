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

zm_ctrl	equ	0x34

zm_map	equ	0x8000

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
l0$:	ld	(hl),l
	inc	l
	jp	nz,l0$
	ld	a,0b00000101
	out	(zm_ctrl),a
	ld	hl,zm_map
l1$:	ld	(hl),l
	inc	l
	jp	nz,l1$
	
	; Disable mapper mode
	ld	a,0b00000000
	out	(zm_ctrl),a
	ld	c,b_print
	ld	de,s_pass
	call	bdos
	
	; Pass
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
	ld	hl,zm_map
	ld	hl,0xC000
	ld	de,0xC001
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
	
	; Done
	ld	c,b_exit
	call	bdos
	

; Strings
	
splash:
	defb	'ZMM Basic Functionality Test',0x0A,0x0D
	defb	'Rev 1a, tergav17 (Gavin)',0x0A,0x0D,'$' 
	
s_pass:
	defb	'PASS',0x0A,0x0D,'$"
	
s_test0:
	defb	'TEST 0: Basic instruction set mapping sanity check: $'
	
s_test1:
	defb	'TEST 1: Check memory overlay: $'