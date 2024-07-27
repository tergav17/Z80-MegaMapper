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

id_base	equ	0xC0

; Program start
	org	0x0100
	
	; Print "hello" splash
start:	di
	ld	c,b_print
	ld	de,splash
	call	bdos
	
	; Select IDE drive
	ld	a,0xE0
	out	(id_base+0xC),a
	ld	b,10
	call	id_stal
	in	a,(id_base+0xC)
	inc	a
	jp	nz,cycle
	
	; Print error and exit
	ld	c,b_print
	ld	de,s_nosel
	call	bdos
	ld	c,b_exit
	call	bdos
	
	; Do a pass of the test
	; Set upeer address registers
cycle:	xor	a
	out	(id_base+0x8),a
	out	(id_base+0xA),a
	
	; First read of sector
	ld	a,(block)
	out	(id_base+6),a
	ld	hl,at0
	call	id_rphy
	
	; Second read of sector
	ld	a,(block)
	out	(id_base+6),a
	ld	hl,at1
	call	id_rphy
	
	; Compare
	ld	de,at0
compare:ld	hl,512
	add	hl,de
	ld	a,(de)
	ld	b,(hl)
	cp	b
	jp	z,next
	
	; Does not equal!
	ex	de,hl
	ld	(tsaddr),hl
	ld	de,at0
	or	a
	sbc	hl,de
	call	tohex
	ld	(parm0),de
	ld	a,b
	call	tohex
	ld	(parm1),de
	ld	a,h
	call	tohex
	ld	(parm3),de
	ld	a,l
	call	tohex
	ld	(parm3+2),de
	ld	a,(block)
	call	tohex
	ld	(parm2),de
	
	; Print it
	ld	c,b_print
	ld	de,s_alert
	call	bdos
	
	; Restore context and continue onto next
	ld	de,(tsaddr)
	
	; Move on to the next value
next:	inc	de
	ld	hl,at1
	or	a
	sbc	hl,de
	jp	nz,compare
	
	; Next block
	ld	a,(block)
	inc	a
	ld	(block),a
	jp	nz,cycle
	
	; Pass
	ld	c,b_print
	ld	de,s_pass
	call	bdos
	
	; Restart test
	jp	cycle

; Executes a read command
; HL = Destination of data
;
; Returns HL += 512
; uses: AF, BC, D, HL
id_rphy:ld	a,1
	out	(id_base+0x04),a
	call	id_busy
	ld	a,0x20
	call	id_comm
	call	id_wdrq
	ld	d,0
	ld	c,id_base
id_rph0:ini
	inc	c
	ini
	dec	c
	dec	d
	jr	nz,id_rph0
	call	id_busy
	ret

; Waits for a DRQ (Data Request)
;
; uses: AF
id_wdrq:in	a,(id_base+0xE)
	bit	3,a
	jr	z,id_wdrq
	ret
	
; Issues an IDE command
; A = Command to issue
;
; uses: AF
id_comm:push	af
	call	id_busy
	pop	af
	out	(id_base+0xE),a
	ret
	
	
; Waits for the IDE drive to no longer be busy
;
; Resets flag z on error
id_busy:in	a,(id_base+0xE)
	bit	6,a
	jr	z,id_busy
	bit	7,a
	jr	nz,id_busy
	bit	0,a
	ret


; Waits a little bit
;
; uses: B
id_stal:push	bc
	pop	bc
	djnz	id_stal
	ret

	; Converts the value into an 8 bit hex number
	; A = Number to convert
	;
	; Returns DE = result
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
block:
	defb	0
	
tsaddr:
	defb	0,0


; Strings

s_pass:
	defb	"PASS COMPLETE",0x0A,0x0D,'$'
	
s_nosel:
	defb	"CANNOT SELECT IDE DRIVE",0x0A,0x0D,'$'
	
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
	
at0	equ	heap
at1	equ	heap+512