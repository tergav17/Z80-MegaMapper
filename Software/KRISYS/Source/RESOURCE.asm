;
;********************************************************************
;*
;*               R E S O U R C E   M A N A G E M E N T
;* 
;*    These routines handle obtaining use-supplied resources
;*    such as configurations, ROM images, and storage bindings.
;*    During startup, these resources will be loaded to build
;*    the virtual machine.
;*
;********************************************************************

; -------------------------
; ******** Equates ********
; -------------------------

arg_size	equ 16

; ----------------------------
; ********  Functions ********
; ----------------------------

.area	_TEXT

; Initalize resources
;
; Returns nothing
; Uses: AF, BC, HL
res_init:
	; Start by zero-terminating string
	ld	hl,cpm_command
	ld	c,(hl)
	ld	b,0
	add	hl,bc
	inc	hl
	ld	(hl),b
	
	ret

; Find a resource from the command line
; If the resource is found, the contents will be cached in memory
; DE = Name of resource (upper case only) 
;
; Returns A = 0xFF if no resource is found
; Uses: AF, BC, DE, HL
res_locate:
	; Travel to the start of arguments
	ld	hl,cpm_command+1
0$:	ld	a,(hl)
	or	a
	jp	z,99$
	cp	0x21
	jp	nc,1$
	inc	hl
	jp	0$
	
	; Found an argument
	; Check it against the contents of (DE)
	; Also must start with '-'
1$:	cp	'-'
	jp	nz,3$
	inc	hl
	push	de
2$:	ld	a,(de)
	
	; Check if at end of string
	or	a
	jp	z,4$
	
	; No? Well lets see if (de) = (hl)
	cp	(hl)
	inc	hl
	inc	de
	jp	z,2$
	
	; Strings are different!
	; Escape from the current argument and continue
	pop	de
3$:	ld	a,(hl)
	or	a
	jp	z,99$
	cp	0x21
	jp	c,0$
	inc	hl
	jp	3$

	; Make sure we are at the end of the argument as well
4$: 	pop	de
	ld	a,(hl)
	cp	0x21
	jp	nc,3$
	
	; Ok, lets copy the argument into memory if it exists
	ld	de,res_argument
	xor	a
	ld	(de),a
	
	; Travel to the start of the argument
5$:	ld	a,(hl)
	or	a
	jp	z,89$
	cp	0x21
	jp	nc,6$
	inc	hl
	jp	5$

	; Make sure it doesn't start with '-'
6$:	cp	'-'
	jp	z,89$
	
	; Ok, lets copy up 16 bytes of this
	ld	b,arg_size
7$:	ld	a,(hl)
	cp	0x21
	jp	c,8$
	ld	(de),a
	inc	hl
	inc	de
	djnz	7$

	; Zero terminate
8$:	inc	de
	xor	a
	ld	(de),a
	
	; Good ending
89$:	xor	a
	ret

	; Bad ending
99$:	ld	a,0xFF
	ret
	
; ---------------------------
; ******** Variables ********
; ---------------------------

.area	_BSS

; Stores a zero-terminated string for the resource argument
res_argument:
	defs	arg_size+1