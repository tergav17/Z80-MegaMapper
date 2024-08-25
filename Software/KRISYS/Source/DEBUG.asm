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
	ld	bc,trap_sp_value+2
	ld	hl,str_rdump_sp
	call	debug_rtohex
	
		
	; Extract PC from capture area
	ld	hl,(trap_sp_value)
	ld	a,h
	and	zmm_capt_res
	or	zmm_capt_set
	ld	h,a
	ld	a,(hl)
	call	tohex
	ld	(str_rdump_pc+2),de
	inc	hl
	ld	a,h
	and	zmm_capt_res
	or	zmm_capt_set
	ld	h,a
	ld	a,(hl)
	call	tohex
	ld	(str_rdump_pc),de
	
	; Print
	ld	de,str_rdump
	call	cpm_print
	
	; Prompt the user for commands
debug_prompt:
	ld	de,str_prompt
	call	cpm_print
	ld	de,input_buff
	call	cpm_input
	
	
; Go back to the virutal machine
debug_continue:
	
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
	
	
	
; -------------------------
; ******** Strings ********
; -------------------------

.area	_DATA

; Register dump string
str_rdump:
	defb	0x1E,0x17
	defb	'PC: '
str_rdump_pc:
	defb	'XXXX, SP: '
str_rdump_sp:
	defb	'XXXX',0x0A,0x0D
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