;
;**************************************************************
;*
;*      I D E   I N T E R F A C E   I N T E G R I T Y   T E S T
;*
;*      Checks the integrity of NABU IDE interface in repeatedly
;*      reading the first 256 blocks of memory.
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

	; Converts the value into an 8 bit hex number
	; A = number to convert
	; DE = result
	; uses: DE
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
	
; Variables
phase:
	defb	0

tsvalue:
	defb	0,0
	
tsaddr:
	defb	0,0


; Strings

s_pass:
	defb	"PASS COMPLETE",0x0A,0x0D,'$'
	
s_alert:
	defb	'FAIL: AT1 '
parm0:	defb	'XX'
	defb	', AT2 '
parm1:	defb	'XX'
	defb	', BLK '
parm2:	defb	'XX'
	defb	', ADR '
parm3:	defb	'XXXX'
	defb	0x0A,0x0D,'$'
	
splash:
	defb	'IDE Interface Integrity Test',0x0A,0x0D
	defb	'Rev 1a, tergav17 (Gavin)',0x0A,0x0D,'$' 
	
	
; Heap
heap:
	defb	0