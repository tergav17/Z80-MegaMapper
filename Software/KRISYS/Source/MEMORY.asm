;
;********************************************************************
;*
;*                    Z M M   M E M O R Y
;* 
;*    The ZMM can be configured to have different amounts
;*    of memory installed. Instead of dicking around with 
;*    on-board jumpers, KRISYS will simply check what banks
;*    are available on startup. Memory will be dynamically
;*    allocated as needed by the client process.
;*
;********************************************************************

; ----------------------------
; ********  Functions ********
; ----------------------------

.area	_TEXT
	
; Initalize the memory map
; Each bank of the ZMM will be probed, and writable
; banks will be recorded on the allocated bank map
;
; Returns nothing
; Uses: AF, BC, DE, HL
mem_map_init:
	; Go to virtual mode
	call	zmm_set_virtual
	
	; Reset free bank counter
	ld	a,0
	ld	(banks_free),a
	
	; Write tags to all banks
	ld	b,0
0$:	ld	a,b
	out	(zmm_bank_3),a
	ld	(zmm_top),a
	neg
	ld	(zmm_top+1),a
	inc	b
	jp	p,0$
	
	; Mark any banks that record correctly
	ld	b,0
	ld	hl,alloc_bank_map
1$:	xor	a
	ld	(hl),a
	ld	a,b
	out	(zmm_bank_3),a
	ld	a,(zmm_top)
	cp	b
	jp	nz,2$
	ld	a,(zmm_top+1)
	ld	c,a
	ld	a,b
	neg
	cp	c
	jp	nz,2$

	; Mark it
	ld	a,0xFF
	ld	(hl),a
	ld	a,(banks_free)
	inc	a
	ld	(banks_free),a
	
	; Next
2$:	inc	hl
	inc	b
	jp	p,1$
	
	; Disable virtual mode
	call	zmm_set_real
	
	; Print out result
	ld	a,(banks_free)
	call	tohex
	ld	(str_mem_init_cnt),de
	ld	de,str_mem_init
	call	cpm_print
	
	; Do we actually have an acceptable amount of memory?
	ld	a,(banks_free)
	dec	a
	dec	a
	jp	m,mem_empty
	
	; We do, return
	ret
	
; Error out if empty
;
; Does not return
; Uses: N/A
mem_empty:
	ld	de,str_mem_empty
	call	cpm_print
	jp	cpm_exit

; -------------------------
; ******** Strings ********
; -------------------------

.area	_DATA

; Inital string that prints when the program is started
str_mem_init:
	defb	'INITIALIZED MEMORY MAP',0x0A,0x0D
	defb	'BANK COUNT = '
str_mem_init_cnt:
	defb	'XXH',0x0A,0x0D,'$'
	
str_mem_empty:
	defb	'INSUFFICIENT MEMORY',0x0A,0x0D,'$'

; ---------------------------
; ******** Variables ********
; ---------------------------

.area	_BSS

; Free bank count
banks_free:
	defs	1

; Allocated bank map
; This 128 byte table keeps track of every single 16K bank
; that exists on the ZMM. Populated on startup
alloc_bank_map:
	defs	128