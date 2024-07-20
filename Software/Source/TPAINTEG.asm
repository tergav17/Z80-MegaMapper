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
rdloop:	ld	b,32
0$:	ld	a,(hl)
	cp	c
	jp	nz,memerr
	djnz	0$
	
	; Do next memory cell
next:	inc	hl
	inc	c
	or	a
	sbc	hl,sp
	ld	a,h
	inc	a
	or	l
	jp	z,pass
	add	hl,sp
	jp	rdloop
	
	; Print pass message
pass:	ld	c,b_print
	ld	de,s_pass
	call	bdos
	
	; Increment phase and retry
	ld	hl,phase
	inc	(hl)
	jp	cycle
	
	; Something went wrong, report it!
memerr:	ld	(tsvalue),bc
	ld	(tsaddr),hl 
	
	; Fill out parameters
	call	tohex
	ld	(parm1),de
	ld	a,c
	call	tohex
	ld	(parm0),de
	ld	a,b
	call	tohex
	ld	(parm2),de
	ld	a,h
	call	tohex
	ld	(parm3),de
	ld	a,l
	call	tohex
	ld	(parm3+2),de
	
	; Print it
	ld	c,b_print
	ld	de,s_alert
	call	bdos
	
	; Restore context and continue onto next
	ld	bc,(tsvalue)
	ld	hl,(tsaddr)
	jp	next

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
	defb	'FAIL: EXP '
parm0:	defb	'XX'
	defb	', RD '
parm1:	defb	'XX'
	defb	', TRY '
parm2:	defb	'XX'
	defb	', ADR '
parm3:	defb	'XXXX'
	defb	0x0A,0x0D,'$'
	
splash:
	defb	'TPA Memory Integrity Test',0x0A,0x0D
	defb	'Rev 1a, tergav17 (Gavin)',0x0A,0x0D,'$' 
	
	
; Heap
heap:
	defb	0