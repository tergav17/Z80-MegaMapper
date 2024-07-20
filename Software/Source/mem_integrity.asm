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
cycle:	ld	hl,heap
	ld	a,(phase)
	ld	c,a
	
wrloop:	ld	(hl),c
	inc	hl
	inc	c
	or	a
	sbc	hl,sp
	ld	a,h
	or	l
	jp	z,wrdone
	add	hl,sp
	jp	wrloop
	

	; Prepare to read back all values
wrdone:	ld	hl,heap
	ld	a,(phase)
	ld	c,a
	
	; Read and test a value from memory
	; We will do this multiple times in a row
rdloop:	ld	b,64
l0$:	ld	a,(hl)
	cp	c
	jp	nz,memerr
	djnz	l0$
	
	; Do next memory cell
next:	inc	c
	or	a
	sbc	hl,sp
	ld	a,h
	or	l
	jp	z,pass
	add	hl,sp
	jp	rdloop
	
	; Print pass message and reset
pass:	ld	c,b_print
	ld	de,s_pass
	call	bdos
	jp	cycle
	
	; Something went wrong, report it!
memerr:	ld	(tsvalue),bc
	ld	(tsaddr),hl 

	; Converts the value into an 8 bit hex number
	; A = number to convert
	; DE = result
	; uses: b
tohex:	ld	b,a
	call	l0$
	ld	d,a
	ld	a,b
	call	l1$
	ld	e,a
	ret
	
l0$:	rra
	rra
	rra
	rra
l1$:	or	0xF0
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