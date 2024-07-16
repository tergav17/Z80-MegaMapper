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
	
	; Set up passthru table for mapper mode
	ld	a,0b00000001
	out	(zm_ctrl),a
	ld	hl,zm_map
gentab0:ld	(hl),l
	inc	l
	jp	nz,gentab0
	ld	a,0b00000101
	out	(zm_ctrl),a
	ld	hl,zm_map
gentab0:ld	(hl),l
	inc	l
	jp	nz,gentab0
	


; Strings
	
splash:
	defb	'ZMM Basic Functionality Test',0x0A,0x0D
	defb	'Rev 1a, tergav17 (Gavin)',0x0A,0x0D,'$' 