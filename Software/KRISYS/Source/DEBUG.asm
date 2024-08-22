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