;
;**************************************************************
;*
;*      T P A   M E M O R Y   I N T E G R I T Y   T E S T
;*
;*      Checks the integrity of memory within the TPA. The
;*      purpose of this program is to look for certain addresses
;*      that may be "flakey" for some reason or another
;*
;*      Program will continue to run until machine is reset
;* 
;**************************************************************

; Equates
bdos	equ	0x0005

b_exit	equ	0x00
b_coin	equ	0x01
b_cout	equ	0x02
b_print	equ	0x09

; Program start
	org	0x0100
	
	; Print "hello" splash
start:	di
	ld	c,b_print
	ld	de,splash
	call	bdos
	
	; Execute a cycle of the test
cycle:	ld	de,heap
	ld	a,(heap)
	
wrloop:	ld	(de),a
	ld	h,d
	ld	l,e
	inc	de
	inc	a
	or	a
	sbc	hl,sp
	jp	nz,wrloop
	
	
hlt:	jp	hlt
	
; Variables
phase:
	defb	0

; Strings
	
alert:
	defb	'FAIL: Expected '
parm0:	defb	'XX'
	defb	', Read '
parm1:	defb	'XX'
	defb	', Address '
parm2:	defb	'XXXX'
	defb	0x0A,0x0D,'$'
	
splash:
	defb	'TPA Memory Integrity Test',0x0A,0x0D
	defb	'Rev 1a, tergav17 (Gavin)',0x0A,0x0D,'$' 
	
	
; Heap
heap:
	defb	0