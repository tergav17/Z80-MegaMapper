;
;**************************************************************
;*
;*        V I R T U A L   M A C H I N E   D E B U G G E R
;*
;*    Proves a machine-language monitor for debugging the
;*    virtual machine. Does standard monitor stuff.
;* 
;**************************************************************

; ---------------------------
; ********  Debugger ********
; ---------------------------

.area	_TEXT

; Handle for the debugger
debug_handle:

	; Save machine context
	ld	(debug_temp),sp
	ld	sp,debug_state
	
	; Dump registers
	push	af
	push	bc
	push	de
	push	hl
	exx
	ex	af,af'
	push	af
	push	bc
	push	de
	push	hl
	push	ix
	push	iy
	
	ld	sp,(debug_temp)
	
	; Check to see if we are skipping over stuff
	ld	a,(debug_f_over)
	or	a
	jp	z,0$
	
	; Check stack pointer
	ld	hl,(trap_sp_value)
	ld	de,(debug_over_sp)
	sbc	hl,de
	jp	nz,debug_continue
	
	; Reset over flag
	xor	a
	ld	(debug_f_over),a
	
0$:
	
	; Debugger stuff starts here
	; Populate register dump string
	ld	bc,debug_state
	ld	hl,str_rdump_af
	call	debug_rtohex
	ld	hl,str_rdump_bc
	call	debug_rtohex
	ld	hl,str_rdump_de
	call	debug_rtohex
	ld	hl,str_rdump_hl
	call	debug_rtohex
	ld	hl,str_rdump_aaf
	call	debug_rtohex
	ld	hl,str_rdump_abc
	call	debug_rtohex
	ld	hl,str_rdump_ade
	call	debug_rtohex
	ld	hl,str_rdump_ahl
	call	debug_rtohex
	ld	hl,str_rdump_ix
	call	debug_rtohex
	ld	hl,str_rdump_iy
	call	debug_rtohex
	
	; Display stack pointer
	ld	hl,(trap_sp_value)
	inc	hl
	inc	hl
	ld	a,h
	call	tohex
	ld	(str_rdump_sp),de
	ld	a,l
	call	tohex
	ld	(str_rdump_sp+2),de
		
	; Extract PC from capture area
	ld	hl,(trap_sp_value)
	ld	a,h
	and	zmm_capt_res
	or	zmm_capt_set
	ld	h,a
	ld	a,(hl)
	ld	(debug_pc_state),a
	call	tohex
	ld	(str_rdump_pc+2),de
	inc	hl
	ld	a,h
	and	zmm_capt_res
	or	zmm_capt_set
	ld	h,a
	ld	a,(hl)
	ld	(debug_pc_state+1),a
	call	tohex
	ld	(str_rdump_pc),de
	
	; Display instruction
	ld	hl,(debug_pc_state)
	call	mem_fvbyte
	call	tohex
	ld	(str_rdump_isr),de
	inc	hl
	call	mem_fvbyte
	call	tohex
	ld	(str_rdump_isr+2),de
	inc	hl
	call	mem_fvbyte
	call	tohex
	ld	(str_rdump_isr+4),de
	inc	hl
	call	mem_fvbyte
	call	tohex
	ld	(str_rdump_isr+6),de
	
	; Get interrupt status
	ld	a,i
	ld	a,'-'
	jp	po,1$
	ld	a,'X'
1$:	ld	(str_rdump_ei),a

	; Get I/O trap status
	in	a,(zmm_isr)
	or	a
	ld 	a,'-'
	jp	p,2$
	ld	a,'X'
2$:	ld	(str_rdump_io),a

	; Copy flags
	ld	de,str_rdump_flag
	ld	hl,debug_flags
	ld	a,(debug_state-2)
	ld	b,8
	ld	c,a
3$:	ld	a,(hl)
	sla	c
	jp	c,4$
	ld	a,'-'
4$:	ld	(de),a
	inc	hl
	inc	de
	djnz	3$
	
	
	; Print
	ld	de,str_rdump
	call	cpm_print
	
; Query the user for an operation to perform
debug_query:
	call	cpm_getc
	ld	a,c
	
	; Exit?
	cp	0x1B
	jp	z,cpm_exit
	
	; Over?
	cp	'O'
	jp	z,debug_over
	
	; Upper?
	cp	'U'
	jp	z,debug_upper
	
	
	; Ok, just continue then
	jp	debug_continue


;	ld	de,str_prompt
;	call	cpm_print
;	ld	de,input_buff
;	call	cpm_input

	
; Do not enter debugger until stack is equal to the original value
debug_over:
	ld	hl,(trap_sp_value)
	ld	(debug_over_sp),hl
	
	ld	a,0xFF
	ld	(debug_f_over),a
	
	jp	debug_continue
	
; Do not enter debugger until current function has been returned from
debug_upper:
	ld	hl,(trap_sp_value)
	inc	hl
	inc	hl
	ld	(debug_over_sp),hl
	
	ld	a,0xFF
	ld	(debug_f_over),a
	
	jp	debug_continue	
	
; Go back to the virutal machine
debug_continue:
	
	; Restore IRQ state
	call	irq_restore
	
	; Restore machine context
	ld	(debug_temp),sp
	ld	sp,debug_state-20
	
	; Restore registers
	pop	iy
	pop	ix
	pop	hl
	pop	de
	pop	bc
	pop	af
	exx
	ex	af,af'
	pop	hl
	pop	de
	pop	bc
	pop	af
	
	; Go back to trap handler
	ld	sp,(debug_temp)
	ret


; ----------------------------
; ********  Functions ********
; ----------------------------

.area	_TEXT


; Initalize the debugger
;
; Returns nothing
; Uses: AF
debug_init:
	
	; Reset flags
	xor	a
	ld	(debug_f_over),a
	
	ret

; Converts a register to hexadecimal
; BC = Address of register value
; HL = Address of hex string
;
; Returns BC=BC=2
; Uses: AF, BC, DE, HL
debug_rtohex:
	dec	bc
	ld	a,(bc)
	push	bc
	call	tohex
	pop	bc
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	dec	bc
	ld	a,(bc)
	push	bc
	call 	tohex
	pop	bc
	ld	(hl),e
	inc	hl
	ld	(hl),d
	ret

; Bind the debugger to the trap handler
; Any trap can now be used to invoke the machine language monitor
;
; Returns nothing
; Uses: A, HL
debug_bind:

	; Save previous binding
	ld	a,(trap_res_flag)
	ld	hl,(trap_res_flag+1)
	ld	(debug_pbind),a
	ld	(debug_pbind+1),hl
	
	; Bind debugger handle
	ld	a,0xCD
	ld	hl,debug_handle
	ld	(trap_res_flag),a
	ld	(trap_res_flag+1),hl
	
	ret
	
; Unbind the debugger and allow traps to process normally
;
; Returns nothjing
; Uses: A, HL
debug_unbind:
	
	; Restore previous binding
	ld	a,(debug_pbind)
	ld	hl,(debug_pbind+1)
	ld	(trap_res_flag),a
	ld	(trap_res_flag+1),hl
	
	ret
	
; Print the contexts of register A onto the terminal
; This should really only be used in early system debugging
; A = Byte to print
;
; Returns nothing
; Uses: All
debug_puta:
	call	tohex
	ld	(str_debug_val),de
	ld	de,str_debug
	jp	cpm_print
	
	
	
; -------------------------
; ******** Strings ********
; -------------------------

.area	_DATA

; Debug string
str_debug:
	defb 	'REG A = '
str_debug_val:
	defb	'XX',0x0A,0x0D,'$'
	
; Flag template
debug_flags:
	defb	'SZ5H3PNC'

; Register dump string
str_rdump:
	defb	0x1E,0x17
	defb	'PC: '
str_rdump_pc:
	defb	'XXXX SP: '
str_rdump_sp:
	defb	'XXXX NEXT: '
str_rdump_isr:
	defb	'XXXXXXXX',0x0A,0x0D

	defb	'FLAGS: '
str_rdump_flag:
	defb	'-------- EI: '
str_rdump_ei:
	defb	'- I/O: '
str_rdump_io:
	defb	'-',0x0A,0x0D
	
	defb	'R= AF: '
str_rdump_af:
	defb	'XXXX BC: '
str_rdump_bc:
	defb	'XXXX DE: '
str_rdump_de:
	defb	'XXXX HL: '
str_rdump_hl:
	defb	'XXXX',0x0A,0x0D
	
	defb	'X= AF: '
str_rdump_aaf:
	defb	'XXXX BC: '
str_rdump_abc:
	defb	'XXXX DE: '
str_rdump_ade:
	defb	'XXXX HL: '
str_rdump_ahl:
	defb	'XXXX',0x0A,0x0D
	
	defb	'E= IX: '
str_rdump_ix:
	defb	'XXXX IY: '
str_rdump_iy:
	defb	'XXXX',0x0A,0x0D,'$'
	
; Debug prompt
str_prompt
	defb	0x0A,0x0D,'*','$'
	
; Input buffer
input_buff:
	defb	40
	defs	41
	
; ---------------------------
; ******** Variables ********
; ---------------------------

.area	_BSS

; Previous trap bind
debug_pbind:
	defs	3
	
; General purpose memory register
; Usually used in context swaps
debug_temp:
	defs	2
	
; Debug program counter value
debug_pc_state:
	defs	2
	
; Debug skip over flag
debug_f_over:
	defs	1
	
; Debug skip over stack value
debug_over_sp:
	defs	2
	
; Machine state
; IY	-20
; IX	-18
; 'HL	-16
; 'DE	-14
; 'BC	-12
; 'AF 	-10
; HL	-8
; DE	-6
; BC	-4
; AF	-2
; --- TOP ---
	defs	20
debug_state: