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
	
; Loads an open resource into a bankmap
; Bankmap will be zero-padded to fill requested number of records
; HL = Address of bankmap
; BC = Number of records (128 byte blocks) to load
;
; Returns nothing
; Uses: all
res_load:

	; Set read flag
	ld	a,0xFF
	ld	(res_do_read),a

	; Save args
	ld	(res_bankmap),hl
	ld	(res_sectors),bc

	; Virtual mode should be off while we do this
	ld	a,(zmm_ctrl_state)
	push	af
	call	zmm_set_real
	
	; Do function call
	call	0$
	
	; Reset bank 3
	ld	a,(zmm_bnk3_state)
	out	(zmm_bnk3),a
	
	; Restore register
	pop	af
	ld	(zmm_ctrl_state),a
	jp	zmm_ctrl_set
	
	; Allocate a new bank
0$:	call	mem_alloc
	ld	hl,(res_bankmap)
	ld	(hl),a
	inc	hl
	ld	(res_bankmap),hl
	
	; Set the bank in slot 3
	out	(zmm_bnk3),a
	
	; Set DMA address
	ld	de,res_buffer
	ld	c,bios_set_dma
	call	bdos
	
	; Set pointer	
	ld	hl,zmm_top
	ld	(res_pointer),hl
	
	; We will be loading up to 128 records at a time here
	ld	b,128
	
	; Do read operation
1$:	push	bc
	ld	de,res_fcb
	ld	c,bdos_read
	ld	a,(res_do_read)
	or	a
	call	nz,bdos
	
	; Check file I/O result
	or	a
	call	nz,50$
	
	; Go to virtual mode
	call	zmm_set_virt
	
	; Copy record to bank
	ld	hl,res_buffer
	ld	de,(res_pointer)
	ld	bc,128
	ldir
	ld	(res_pointer),de
	
	; Back to real mode
	call	zmm_set_real 
	
	; Get BC back to restore sector counter
	pop	bc
	
	; Decrement record count
	ld	hl,(res_sectors)
	dec	hl
	ld	(res_sectors),hl
	ld	a,h
	or	l
	ret	z
	
	; Go get another sector
	djnz	1$
	jp	0$

	; Zero buffer and reset read flag
50$:	xor	a
	ld	(res_do_read),a
	
	ld	hl,res_buffer
	ld	de,res_buffer+1
	ld	bc,128-1
	ld	(hl),a
	ldir

	ret
	
; Opens a file based on the resource argument
; If the file cannot be opened, an error will be thrown
; (res_argument) = File to open
;
; Returns nothing
; Uses: all
res_open:

	; Virtual mode should be off while we do this
	ld	a,(zmm_ctrl_state)
	push	af
	call	zmm_set_real
	
	; Do function call
	call	0$
	
	; Restore register
	pop	af
	ld	(zmm_ctrl_state),a
	jp	zmm_ctrl_set
	
	; Let the user know we are loading stuff
0$:	ld	c,bdos_print
	ld	de,str_load_a
	call	bdos
	
	; Print resource name
	ld	hl,res_current
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	call	res_printzt
	
	; Next string
	ld	c,bdos_print
	ld	de,str_load_b
	call	bdos
	
	; Print file name
	ld	de,res_argument
	call	res_printzt
	
	; CRLF
	ld	c,bdos_print
	ld	de,str_crlf
	call	bdos
	
	; Detect if there is an argument
	ld	a,(res_argument)
	or	a
	jp	nz,1$
	
	; No argument, error!
	ld	c,bdos_print
	ld	de,str_arg_empty
	call	bdos
	jp	cpm_exit

	; Reset fields
1$:	xor	a
	ld	hl,res_fcb
	ld	de,res_fcb+1
	ld	bc ,36-1
	ld	(hl),a
	ldir
	
	ld	a,0x20
	ld	hl,res_fcb_name
	ld	de,res_fcb_name+1
	ld	bc ,11-1
	ld	(hl),a
	ldir

	; Is there a prefix?
	ld	hl,res_argument
	ld	a,(res_argument+1)
	cp	':'
	jp	nz,2$
	
	; Set prefix
	ld	a,(res_argument)
	sub	'A'-1
	cp	17
	jp	nc,99$
	ld	(res_fcb_drive),a
	inc	hl
	inc	hl

	; HL = Proper filename start
2$:	ld	b,8
	ld	de,res_fcb_name
	
	; Copy it over
3$:	ld	a,(hl)
	or	a
	jp	z,99$
	cp	'*'
	jp	z,4$
	cp	'.'
	jp	z,5$
	ld	(de),a
	inc	de
	inc	hl
	djnz	3$
	jp	5$

	; Fill remains of FCB file name
4$:	ld	a,'?'
	ld	(de),a
	inc	de
	djnz	4$
	inc	hl

	; We should either see a '.' or a null character
5$:	ld	a,(hl)
	or	a
	jp	z,8$
	cp	'.'
	jp	nz,99$
	inc	hl
	
	; Fill in extension
	ld	b,3
	ld	de,res_fcb_type
	
	; Copy it over
6$:	ld	a,(hl)
	or	a
	jp	z,8$
	cp	'*'
	jp	z,7$
	ld	(de),a
	inc	de
	inc	hl
	djnz	6$
	jp	8$
	
	; Fill remains of FCB file extension
7$:	ld	a,'?'
	ld	(de),a
	inc	de
	djnz	4$
	inc	hl

	; We should get a zero
8$:	ld 	a,(hl)
	or	a
	jp	nz,99$
	
	; It is filled in, attempt to open
	ld	c,bdos_open
	ld	de,res_fcb
	call	bdos
	
	; Check error
	inc	a
	ret	nz
	
	; Error!
99$:	ld	c,bdos_print
	ld	de,str_arg_fail
	call	bdos
	jp	cpm_exit
	
	
; Print a zero terminated string
; We should be in real mode for this
; DE = String
;
; Returns nothing
; Uses: All
res_printzt:
0$:	ld	a,(de)
	or	a
	ret	z
	
	; Print character
	push	de
	ld	e,a
	ld	c,bdos_con_out
	call	bdos
	pop	de
	inc	de
	jp	0$

; Find a resource from the command line
; If the resource is found, the contents will be cached in memory
; DE = Name of resource (upper case only) 
;
; Returns A = 0xFF if no resource is found
; Uses: AF, BC, DE, HL
res_locate:
	; Save resource
	ld	(res_current),de

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
8$:	xor	a
	ld	(de),a
	
	; Good ending
89$:	xor	a
	ret

	; Bad ending
99$:	ld	a,0xFF
	ret
	
; -------------------------
; ******** Strings ********
; -------------------------

.area	_DATA

; Loading string components
str_load_a:
	defb	'LOADING $'
	
str_load_b:
	defb	' FROM $'
	
; Error messages
str_arg_empty:
	defb	'NO ARGUMENT PROVIDED',0x0A,0x0D,'$'
	
str_arg_fail:
	defb	'FAILED TO OPEN FILE',0x0A,0x0D,'$'
	
; ---------------------------
; ******** Variables ********
; ---------------------------

.area	_BSS

; Stores a zero-terminated string for the resource argument
res_argument:
	defs	arg_size+1
	
; Current resource being accessed
res_current:
	defs	arg_size+1
	
; Resource buffer
res_buffer:
	defs	128
	
; Sector counter
res_sectors:
	defs	2
	
; Do we need to read?
res_do_read:
	defs	1
	
; Resource bankmap
res_bankmap:
	defs	2
	
; Loading pointer
res_pointer:
	defs	2
	
; File control block for use in loading resources
res_fcb:
	defs	36
res_fcb_drive	equ	res_fcb
res_fcb_name	equ	res_fcb+1
res_fcb_type	equ	res_fcb+9
res_fcb_ex	equ	res_fcb+12
res_fcb_s1	equ	res_fcb+13
res_fcb_s2	equ	res_fcb+14
res_fcb_rc	equ	res_fcb+15
res_fcb_data	equ	res_fcb+16
res_fcb_cr	equ	res_fcb+32
res_fcb_r0	equ	res_fcb+33
res_fcb_r1	equ	res_fcb+34
res_fcb_r2	equ	res_fcb+35