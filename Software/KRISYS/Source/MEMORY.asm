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
;*    Memory can be assigned to specific owners in the code.
;*    Valid owner IDs range from 1 to 254. Owner 0 is reserved
;*    for unallocatable banks.
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
	
; Allocates a bank of memory
; Will produce an error if no banks are available,
; check (banks_free) to avoid
; D = Owner ID (1-254)
;
; Returns A = Bank #
; Uses: AF, BC, HL
mem_alloc:
	; Check and decrement free memory
	ld	a,(banks_free)
	dec	a
	ld	(banks_free),a
	jp	m,mem_empty
	
	; Look for the first free bank
	ld	hl,alloc_bank_map
	ld	bc,0x0080
	ld	a,0xFF
	cpir
	
	; Make sure we found something
	jp	nz,mem_empty
	
	; Save and exit
	dec	hl
	ld	(hl),d
	ld	bc,alloc_bank_map
	or	a
	sbc	hl,bc
	ld	l,a
	ret
	
; Frees a bank of memory
; Safe to use on banks that are not free / not owned
; A = Bank #
; D = Owner ID (1-254)
;
; Returns nothing
; Uses: AF, BC, HL
mem_free:
	; Find location in memory
	ld	b,0
	ld	c,a
	ld	hl,alloc_bank_map
	add	hl,bc
	
	; Check owner
	ld	a,(hl)
	cp	d
	ret	nz
	
	; Free bank
	ld	a,0xFF
	ld	(hl),a
	
	; Increment banks free
	ld	hl,banks_free
	inc	(hl)
	ret
	
; Free all banks by owner
; D = Owner ID (1-254)
;
; Returns nothing
; Uses: AF, BC, HL
mem_free_all:
	; Free a bank
	xor	a
0$:	push	af
	call	mem_free
	pop	af
	
	; Next bank
	inc	a
	jp	p,0$
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