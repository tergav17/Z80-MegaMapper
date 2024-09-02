;
;**************************************************************
;*
;*          I / O   I N S T R U C T I O N   T E S T
;*
;*    Tests all of the different Z80 I/O instructions.
;*    Nuff said
;* 
;**************************************************************

test_port	equ 0x00

; Program start
	org	0x0000
	
start:
	ld	sp,0xFFFF
	
	; --- IN INSTRUCTIONS ---
	call	set_all
	in	a,(test_port)
	call	res_all
	in	a,(test_port)
	
	call	set_all
	ld	c,test_port
	in	b,(c)
	call	res_all
	ld	c,test_port
	in	b,(c)
	
	call	set_all
	ld	c,test_port
	in	c,(c)
	call	res_all
	ld	c,test_port
	in	c,(c)
	
	call	set_all
	ld	c,test_port
	in	d,(c)
	call	res_all
	ld	c,test_port
	in	d,(c)
	
	call	set_all
	ld	c,test_port
	in	e,(c)
	call	res_all
	ld	c,test_port
	in	e,(c)
	
	call	set_all
	ld	c,test_port
	in	h,(c)
	call	res_all
	ld	c,test_port
	in	h,(c)
	
	call	set_all
	ld	c,test_port
	in	l,(c)
	call	res_all
	ld	c,test_port
	in	l,(c)
	
	call	set_all
	ld	c,test_port
	in	f,(c)
	call	res_all
	ld	c,test_port
	in	f,(c)
	
	call	set_all
	ld	c,test_port
	in	a,(c)
	call	res_all
	ld	c,test_port
	in	a,(c)
	
	call	set_all
	ld	c,test_port
	ld	hl,0xC000
	ini
	ld	a,(0xC000)
	in	f,(c)
	call	res_all
	ld	c,test_port
	ld	hl,0xC000
	ini
	ld	a,(0xC000)
	in	f,(c)
	
	call	set_all
	ld	c,test_port
	ld	hl,0xC000
	ind
	ld	a,(0xC000)
	in	f,(c)
	call	res_all
	ld	c,test_port
	ld	hl,0xC000
	ind
	ld	a,(0xC000)
	in	f,(c)
	
	call	set_all
	ld	b,1
	ld	c,test_port
	ld	hl,0xC000
	inir
	ld	a,(0xC000)
	in	f,(c)
	call	res_all
	ld	b,1
	ld	c,test_port
	ld	hl,0xC000
	inir
	ld	a,(0xC000)
	in	f,(c)
	
	call	set_all
	ld	b,1
	ld	c,test_port
	ld	hl,0xC000
	indr
	ld	a,(0xC000)
	in	f,(c)
	call	res_all
	ld	b,1
	ld	c,test_port
	ld	hl,0xC000
	indr
	ld	a,(0xC000)
	in	f,(c)
	
	; --- OUT INSTRUCTIONS ---
	call	inc_all
	out	(test_port),a
	
	call	inc_all
	ld	c,test_port
	out	(c),b
	
	call	inc_all
	ld	c,test_port
	out	(c),c
	
	call	inc_all
	ld	c,test_port
	out	(c),d
	
	call	inc_all
	ld	c,test_port
	out	(c),e
	
	call	inc_all
	ld	c,test_port
	out	(c),h
	
	call	inc_all
	ld	c,test_port
	out	(c),l
	
	call	inc_all
	ld	c,test_port
	out	(c),0
	
	call	inc_all
	ld	c,test_port
	out	(c),a
	
	call	inc_all
	ld	hl,0xC000
	ld	(hl),0x69
	ld	c,test_port
	ld	b,3
	outi
	
	call	inc_all
	ld	hl,0xC000
	ld	(hl),0x69
	ld	c,test_port
	ld	b,3
	outd
	
	call	inc_all
	ld	hl,0xC000
	ld	(hl),0x69
	ld	c,test_port
	ld	b,3
	otir
	
	call	inc_all
	ld	hl,0xC000
	ld	(hl),0x69
	ld	c,test_port
	ld	b,3
	otdr
	
done:	jp	done
	
	
	; Sets all registers to incrementing values
inc_all:
	ld	a,0x01
	ld	b,0x02
	ld	c,0x03
	ld	d,0x04
	ld	e,0x05
	ld	h,0x06
	ld	l,0x07
	ex	af,af'
	exx
	ld	a,0x08
	ld	b,0x09
	ld	c,0x0A
	ld	d,0x0B
	ld	e,0x0C
	ld	h,0x0D
	ld	l,0x0E
	ex	af,af'
	exx
	ld	ix,0x1011
	ld	iy,0x1213
	ret
	
	; Sets all registers to 0xFF
set_all:
	ld	a,0xFF
	ld	b,a
	ld	c,a
	ld	d,a
	ld	e,a
	ld	h,a
	ld	l,a
	ex	af,af'
	exx
	ld	a,0xFF
	ld	b,a
	ld	c,a
	ld	d,a
	ld	e,a
	ld	h,a
	ld	l,a
	ld	ix,0xFFFF
	ld	iy,0xFFFF
	ret
	
	; Resets all registers to 0x00
res_all:
	ld	a,0x00
	ld	b,a
	ld	c,a
	ld	d,a
	ld	e,a
	ld	h,a
	ld	l,a
	ex	af,af'
	exx
	ld	a,0x00
	ld	b,a
	ld	c,a
	ld	d,a
	ld	e,a
	ld	h,a
	ld	l,a
	ld	ix,0xFFFF
	ld	iy,0xFFFF
	ret