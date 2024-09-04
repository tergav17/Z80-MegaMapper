;
;********************************************************************
;*
;*        K R I S Y S   S G 1 0 0 0   C O R E
;*
;********************************************************************

#include "KRISYS.asm"
#include "SN76489.asm"

; ---------------------------
; ******** Core Init ********
; ---------------------------

.area	_TEXT

; Start of SG-1000 core
core_start:

	; Reset PSG
	call	snpsg_reset

	; Try to find rom resource
	ld	de,str_rom
	call	res_locate
	or	a
	jp	nz,res_missing
	
	; Open the resource
	call	res_open
	
	; Load resources into bankmap
	ld	hl,bm_rom
	ld	bc,256
	call	res_load
	
	; Program the I/O map
	ld	de,str_prgm
	call	cpm_print
	
	; Do input map
	call	zmm_set_virt
	call	zmm_prgm_in
	ld	hl,io_map_input
	ld	de,zmm_map
	ld	bc,256
	ldir
	
	; Do output map
	call	zmm_prgm_out
	ld	hl,io_map_output
	ld	de,zmm_map
	ld	bc,256
	ldir
	
	; Allocate free ram
	ld	de,str_ram_alloc
	call	cpm_print
	
	; Lower RAM
	ld	d,1
	call	mem_alloc
	call	zmm_bnk2_set
	
	; Upper RAM
	ld	d,1
	call	mem_alloc
	call	zmm_bnk3_set
	
	; Set up interrupt modes
	call	zmm_irq_inter
	call	zmm_irq_off
	call	irq_vdp_on
	call	irq_keyb_on
	
	; Mount ROM
	ld	a,(bm_rom)
	call	zmm_bnk0_set
	call	zmm_bnk0_wp
	ld	a,(bm_rom+1)
	call	zmm_bnk1_set
	call	zmm_bnk1_wp
	
	; Reset joystick state
	xor	a
	ld	(sg_ctrl_sel),a
	dec	a
	ld	(sg_ctrl_1),a
	ld	(sg_ctrl_2),a
	
	; Bind debugger
;	call	debug_bind
	
	; Start up VM
	ld	de,str_vm_start
	call	cpm_print

	call	zmm_set_virt
	ld	hl,0x0000
	jp	zmm_vm_start


; Remaps address space so all reads of the VDP address register results in a trap
;
; Returns nothing
; Uses: AF
sg_vdpr_trap:
	call	zmm_prgm_in
	ld	a,zmm_trap
	; ld	(zmm_map+0x81),a
	; ld	(zmm_map+0x83),a
	; ld	(zmm_map+0x85),a
	; ld	(zmm_map+0x87),a
	; ld	(zmm_map+0x89),a
	; ld	(zmm_map+0x8B),a
	; ld	(zmm_map+0x8D),a
	; ld	(zmm_map+0x8F),a
	; ld	(zmm_map+0x91),a
	; ld	(zmm_map+0x93),a
	; ld	(zmm_map+0x95),a
	; ld	(zmm_map+0x97),a
	; ld	(zmm_map+0x99),a
	; ld	(zmm_map+0x9B),a
	; ld	(zmm_map+0x9D),a
	; ld	(zmm_map+0x9F),a
	; ld	(zmm_map+0xA1),a
	; ld	(zmm_map+0xA3),a
	; ld	(zmm_map+0xA5),a
	; ld	(zmm_map+0xA7),a
	; ld	(zmm_map+0xA9),a
	; ld	(zmm_map+0xAB),a
	; ld	(zmm_map+0xAD),a
	; ld	(zmm_map+0xAF),a
	; ld	(zmm_map+0xB1),a
	; ld	(zmm_map+0xB3),a
	; ld	(zmm_map+0xB5),a
	; ld	(zmm_map+0xB7),a
	; ld	(zmm_map+0xB9),a
	; ld	(zmm_map+0xBB),a
	; ld	(zmm_map+0xBD),a
	ld	(zmm_map+0xBF),a
	ret
	
; Untraps all VDP register read operations
;
; Returns nothing
; Uses: AF
sg_vdpr_untrap:
	call	zmm_prgm_in
	ld	a,nabu_vdp_addr
	; ld	(zmm_map+0x81),a
	; ld	(zmm_map+0x83),a
	; ld	(zmm_map+0x85),a
	; ld	(zmm_map+0x87),a
	; ld	(zmm_map+0x89),a
	; ld	(zmm_map+0x8B),a
	; ld	(zmm_map+0x8D),a
	; ld	(zmm_map+0x8F),a
	; ld	(zmm_map+0x91),a
	; ld	(zmm_map+0x93),a
	; ld	(zmm_map+0x95),a
	; ld	(zmm_map+0x97),a
	; ld	(zmm_map+0x99),a
	; ld	(zmm_map+0x9B),a
	; ld	(zmm_map+0x9D),a
	; ld	(zmm_map+0x9F),a
	; ld	(zmm_map+0xA1),a
	; ld	(zmm_map+0xA3),a
	; ld	(zmm_map+0xA5),a
	; ld	(zmm_map+0xA7),a
	; ld	(zmm_map+0xA9),a
	; ld	(zmm_map+0xAB),a
	; ld	(zmm_map+0xAD),a
	; ld	(zmm_map+0xAF),a
	; ld	(zmm_map+0xB1),a
	; ld	(zmm_map+0xB3),a
	; ld	(zmm_map+0xB5),a
	; ld	(zmm_map+0xB7),a
	; ld	(zmm_map+0xB9),a
	; ld	(zmm_map+0xBB),a
	; ld	(zmm_map+0xBD),a
	ld	(zmm_map+0xBF),a
	ret
	
	; Exit out of the emulator
sg_exit:
	call	zmm_set_real
	call	snpsg_reset
	jp	cpm_exit
	
; -----------------------------------
; ******** Interrupt Handler ********
; -----------------------------------
	
.area	_TEXT
	
	
; Handle a "joystick" event
sg_joystick:
	
	; Get the latest scancode from the keyboard
	in	a,(nabu_key_data)
	ld	(sg_last_stroke),a
	
	; Is it an 'ESC'?
	cp	0x1B
	jp	z,sg_exit
	
	; Check for joystick 1
	cp	0x80
	jp	z,20$
	
	; Check for joystick 2
	cp	0x81
	jp	z,21$
	
	; Check for momentary keys
	cp	0xE0
	jp	nc,30$
	
	; Joystick data byte?
	and	0b11100000
	cp	0b10100000
	jp	z,40$
	
	; Nothing useful
	ret
	
	; Joystick 1 detected
20$:	xor	a
	ld	(sg_ctrl_sel),a
	ret
	
	; Joystick 2 detected
21$:	ld	a,1
	ld	(sg_ctrl_sel),a
	ret
	
	; Handle a momentary key
30$:	ret

	; Handle a joystick data byte
40$:	push	hl
	ld	hl,sg_ctrl_1
	ld	a,(sg_ctrl_sel)
	or	a
	jp	nz,50$
	
	; Joystick 0
	ld	a,(sg_last_stroke)
	
	; Left 0
	rrca
	set	2,(hl)
	jp	nc,$+5
	res	2,(hl)
	
	; Down 0
	rrca
	set	1,(hl)
	jp	nc,$+5
	res	1,(hl)
	
	; Right 0
	rrca
	set	3,(hl)
	jp	nc,$+5
	res	3,(hl)
	
	; Up 0
	rrca
	set	0,(hl)
	jp	nc,$+5
	res	0,(hl)
	
	; Fire 0
	rrca
	set	5,(hl)
	jp	nc,$+5
	res	5,(hl)
	
	pop	hl
	ret
	
	; Joystick  1
50$:	ld	a,(sg_last_stroke)

	pop	hl
	ret
	
	
; Handle "real" interrupts from devices (if needed)
; All registers except AF must remain unchanged!
irq_handle:
	call	irq_status
	rrca
	ret	nc
	
	; Interrupt detected, VDP or keyboard?
	rrca
	jp	c,0$

	; Ok, we hit a keyboard interrupt
	jp	sg_joystick
	
	; Ok, we hit a VDP interrupt
0$:	call	irq_vdp_off
	call	zmm_irq_on
	jp	sg_vdpr_trap
	
	
; -----------------------------
; ******** I/O Handler ********
; -----------------------------
	
.area	_TEXT

; Handle an IN instruction
; Inputted value should be returned in register A
; All registers except AF must remain unchanged!
in_handle:
	in	a,(zmm_addr_lo)
	rlca
	jp	c,0$
	
	rlca
	jp	c,10$
	
	; Device 0
	ld	a,(sg_last_stroke)
	ret
	
	; Device 1
10$:	jp	99$

0$:	rlca
	jp	c,20$
	
	; Device 2: VDP
	call	sg_vdpr_untrap
	call	zmm_irq_off
	call	irq_vdp_on
	in	a,(nabu_vdp_addr)
	ret
	
	; Device 3: Joystick
20$	in	a,(zmm_addr_lo)
	rrca
	jp	c,25$
	
	; Read controller 1
	ld	a,(sg_ctrl_1)
	ret
	
	; Read controller 2
25$:	ld	a,(sg_ctrl_2)
	ret
	

	; Unknown device
99$:	ld	a,0xFF
	ret

; Handle an OUT instruction
; A = Value outputted by virtual machine
; All registers except AF must remain unchanged!
out_handle:
	push	af

	in	a,(zmm_addr_lo)
	rlca
	jp	c,99$
	rlca
	jp	nc,99$
	
	; PSG
	pop	af
	call	snpsg_send
	ret

99$:	pop	af
	ret
	
	
; -------------------------
; ******** Strings ********
; -------------------------

.area	_DATA

; Resource strings
str_rom:
	defb	'ROM',0
	
; Bootup strings
str_prgm:
	defb	'PROGRAMMING VM I/O MAP',0x0A,0x0D,'$'
	
; Bootup strings
str_ram_alloc:
	defb	'ALLOCATING RAM',0x0A,0x0D,'$'
	
; Bootup strings
str_vm_start:
	defb	'STARTING VM NOW',0x0A,0x0D,'$'
	
; Debug string
str_debug:
	defb 	'A = '
str_debug_val:
	defb	'XX',0x0A,0x0D,'$'


; ----------------------
; ******** Data ********
; ----------------------
	
.area	_DATA

TRAP	equ	zmm_trap	; Trap Vector
_VDD	equ	nabu_vdp_data	; VDP Data
_VDA	equ	nabu_vdp_addr	; VDP Address

; Virtual machine I/O maps
; Input map
io_map_input:
	;	0x*0 0x*1 0x*2 0x*3 0x*4 0x*5 0x*6 0x*7 0x*8 0x*9 0x*A 0x*B 0x*C 0x*D 0x*E 0x*F 
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x0*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x1*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x2*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x3*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x4*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x5*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x6*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x7*
	defb	_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0x8*
	defb	_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0x9*
	defb	_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0xA*
	defb	_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0xB*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xC*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xD*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xE*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xF*

; Output map
io_map_output:
	;	0x*0 0x*1 0x*2 0x*3 0x*4 0x*5 0x*6 0x*7 0x*8 0x*9 0x*A 0x*B 0x*C 0x*D 0x*E 0x*F 
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x0*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x1*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x2*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x3*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x4*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x5*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x6*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x7*
	defb	_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0x8*
	defb	_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0x9*
	defb	_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0xA*
	defb	_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0xB*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xC*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xD*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xE*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xF*

; ---------------------------
; ******** Variables ********
; ---------------------------

.area	_BSS

; Reflected state of control register
bm_rom:
	defs	2
	
; Last stroke from the keyboard
sg_last_stroke:
	defs	1
	
; Selected joystick for updating
; 0 = Joystick 1 selected
; 1 = Joystick 2 selected
sg_ctrl_sel:
	defs	1
	
; SG-1000 joystick states
sg_ctrl_1:
	defs	1
sg_ctrl_2:
	defs	1