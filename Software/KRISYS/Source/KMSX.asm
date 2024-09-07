;
;********************************************************************
;*
;*        K R I S Y S   M S X   1   C O R E
;*
;********************************************************************

#include "KRISYS.asm"

; ---------------------------
; ******** Core Init ********
; ---------------------------

.area	_TEXT

; Start of MSX 1 core
core_start:

	; Try to find bios resource
	ld	de,str_bios
	call	res_locate
	or	a
	jp	nz,res_missing
	
	; Open the resource
	call	res_open
	
	; Load resources into bankmap
	ld	hl,bm_bios
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
	
	; Set up slot map
	ld	de,str_slots
	call	cpm_print
	
	; Allocate a bank the invalid slot ID
	ld	d,1
	call	mem_alloc
	push	af
	call	zmm_bnk3_set
	ld	hl,zmm_top
	ld	de,zmm_top+1
	ld	bc,0x4000-1
	ld	(hl),0xC7
	ldir
	pop	af
	or	0b10000000
	ld	(null_page),a
	
	; Fill slot map with invalid pages
	ld	hl,mx_page_0
	ld	de,mx_page_0+1
	ld	bc,16-1
	ld	(hl),a
	ldir
	
	; Allocate free ram
	ld	de,str_ram_alloc
	call	cpm_print
	
	; Slot 1 RAM
	ld	d,1
	call	mem_alloc
	ld	(mx_page_0+1),a
	ld	d,1
	call	mem_alloc
	ld	(mx_page_1+1),a
	ld	d,1
	call	mem_alloc
	ld	(mx_page_2+1),a
	ld	d,1
	call	mem_alloc
	ld	(mx_page_3+1),a
	
	; Mount BIOS in slot 0
	ld	a,(bm_bios)
	or	0b10000000
	ld	(mx_page_0),a
	ld	a,(bm_bios+1)
	or	0b10000000
	ld	(mx_page_1),a
	
	; Initalize slots
	xor	a
	ld	(mx_slot_state),a
	call	mx_slot_sync
	
	; Set up interrupt modes
	call	zmm_irq_inter
	call	zmm_irq_off
	call	irq_vdp_on
	call	irq_keyb_on
;	call	irq_hcca_o_on
	
	; Reset joystick state
	xor	a
	ld	(mx_ctrl_sel),a
	dec	a
	ld	(mx_ctrl_1),a
	ld	(mx_ctrl_2),a
	
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
mx_vdpr_trap:
	call	zmm_prgm_in
	ld	a,zmm_trap
	ld	(zmm_map+0x99),a
	ld	(zmm_map+0x9B),a
	ld	(zmm_map+0x9D),a
	ld	(zmm_map+0x9F),a
	ret
	
; Untraps all VDP register read operations
;
; Returns nothing
; Uses: AF
mx_vdpr_untrap:
	call	zmm_prgm_in
	ld	a,nabu_vdp_addr
	ld	(zmm_map+0x99),a
	ld	(zmm_map+0x9B),a
	ld	(zmm_map+0x9D),a
	ld	(zmm_map+0x9F),a
	ret
	
	; Exit out of the emulator
mx_exit:
	call	zmm_set_real
	
	; Bodge over the serial # in VRAM
	ld	hl,0x17FE + 0x4000
	ld	a,l
	out	(nabu_vdp_addr),a
	ld	a,h
	out	(nabu_vdp_addr),a
	xor	a
	out	(nabu_vdp_data),a
	ex	(sp),hl
	ex	(sp),hl
	ex	(sp),hl
	ex	(sp),hl
	out	(nabu_vdp_data),a
	
	jp	cpm_exit
	
; -----------------------------------
; ******** Interrupt Handler ********
; -----------------------------------
	
.area	_TEXT
	
	
; Handle a "keyboard" event
mx_keyboard:
	
	; Get the latest scancode from the keyboard
	in	a,(nabu_key_data)
	ld	(mx_last_stroke),a
	
	; Is it an 'ESC'?
	cp	0x1B
	jp	z,mx_exit
	
	; Check for joystick 1
	cp	0x80
	jp	z,20$
	
	; Check for joystick 2
	cp	0x81
	jp	z,21$
	
	; Joystick data byte?
	and	0b11100000
	cp	0b10100000
	jp	z,40$
	
	; General purpose key
	ret
	
	; Joystick 1 detected
20$:	xor	a
	ld	(mx_ctrl_sel),a
	ret
	
	; Joystick 2 detected
21$:	ld	a,1
	ld	(mx_ctrl_sel),a
	ret

	; Handle a joystick data byte
40$:	push	hl
	ld	hl,mx_ctrl_1
	ld	a,(mx_ctrl_sel)
	or	a
	jp	nz,50$
	
	; Joystick 0
	ld	a,(mx_last_stroke)
	
	pop	hl
	ret
	
	; Joystick  1
50$:	ld	a,(mx_last_stroke)

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
	jp	mx_keyboard
	
	; Ok, we hit a VDP interrupt
0$:	call	irq_vdp_off
	call	zmm_irq_on
	jp	mx_vdpr_trap
	
	
; -----------------------------
; ******** I/O Handler ********
; -----------------------------
	
.area	_TEXT

; Handle an IN instruction
; Inputted value should be returned in register A
; All registers except AF must remain unchanged!
in_handle:
	in	a,(zmm_addr_lo)
	and	0b11111000
	
	; VDP?
	cp	0x98
	jp	z,vdp_in

	; PSG?
	cp	0xA0
	jp	z,psg_in
	
	; PPI?
	cp	0xA8
	jp	z,ppi_in

	ret

; Handle an OUT instruction
; A = Value outputted by virtual machine
; All registers except AF must remain unchanged!
out_handle:
	push	af
	in	a,(zmm_addr_lo)
	and	0b11111000
	
	; PSG?
	cp	0xA0
	jp	z,psg_out
	
	; PPI?
	cp	0xA8
	jp	z,ppi_out
	
	pop	af
	ret
	
	
; VDP input
vdp_in:
	call	mx_vdpr_untrap
	call	zmm_irq_off
	call	irq_vdp_on
	in	a,(nabu_vdp_addr)
	ret
	
	
; PSG input
psg_in:
	in	a,(zmm_addr_lo)
	ret
	

; PSG output
psg_out:
	in	a,(zmm_addr_lo)
	pop	af
	ret
	
	
; PPI input
ppi_in:
	in	a,(zmm_addr_lo)
	rrca
	jp	c,20$
	
	; Even address
	rrca
	jp	c,10$
	
	; Port A
	ld	a,(mx_slot_state)
	ret
	
	; Port C
	ld	a,(mx_key_cas)
10$:	ret
	
	
	; Odd address
20$:	rrca
	jp	c,$30
	
	; Port B
	jp	mx_key_scan
	
	; CTRL register
30$:	ld	a,0xFF
	ret
	

; PPI output
ppi_out:
	in	a,(zmm_addr_lo)
	rrca
	jp	c,20$
	
	; Even address
	rrca
	jp	c,10$
	
	; Port A
	pop	af
	ld	(mx_slot_state),a
	jp	mx_slot_sync
	
	; Port C
10$:	pop	af
	ld	(mx_key_cas),a
	ret
	
	
	; Odd address
20$:	rrca
	jp	c,30$
	
	; Port B
	pop	af
	ret
	
	; CTRL register
30$:	pop	af
	ret
	
	
; Get key inputs from the matrix
; A = return keyboard scan code
mx_key_scan:
	ld	a,0xFF
	ret
	
; Sync virtual memory map with expected slot state
mx_slot_sync:
	push	bc
	push	hl

	; Unpack pages 0-3, and set memory banks accordingly
	ld	a,(mx_slot_state)
	ld	b,0
	
	; Page 0
	push	af
	and	0b00000011
	ld	c,a
	ld	hl,mx_page_0
	add	hl,bc
	ld	a,(hl)
	call	zmm_bnk0_set
	pop	af
	rrca
	rrca
	
	; Page 1
	push	af
	and	0b00000011
	ld	c,a
	ld	hl,mx_page_1
	add	hl,bc
	ld	a,(hl)
	call	zmm_bnk1_set
	pop	af
	rrca
	rrca
	
	; Page 2
	push	af
	and	0b00000011
	ld	c,a
	ld	hl,mx_page_2
	add	hl,bc
	ld	a,(hl)
	call	zmm_bnk2_set
	pop	af
	rrca
	rrca
	
	; Page 3
	push	af
	and	0b00000011
	ld	c,a
	ld	hl,mx_page_3
	add	hl,bc
	ld	a,(hl)
	call	zmm_bnk3_set
	pop	af
	
	
	pop	hl
	pop	bc
	ret
	
; -------------------------
; ******** Strings ********
; -------------------------

.area	_DATA

; Resource strings
str_bios:
	defb	'BIOS',0
	
; Bootup strings
str_prgm:
	defb	'PROGRAMMING VM I/O MAP',0x0A,0x0D,'$'

; Bootup strings
str_slots:
	defb	'SETTING UP SLOT MAP',0x0A,0x0D,'$'
	
; Bootup strings
str_ram_alloc:
	defb	'ALLOCATING RAM',0x0A,0x0D,'$'
	
; Bootup strings
str_vm_start:
	defb	'STARTING VM NOW',0x0A,0x0D,'$'


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
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x8*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0x9*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xA*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xB*
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
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0x8*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA,_VDD,_VDA	; 0x9*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xA*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xB*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xC*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xD*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xE*
	defb	TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP,TRAP	; 0xF*

; ---------------------------
; ******** Variables ********
; ---------------------------

.area	_BSS

; Reflected state of control register
bm_bios:
	defs	2
	
; Invalid page
null_page:
	defs	1
	
; Keeps track of the slot # form the PPI
mx_slot_state:
	defs	1
	
; MSX slot logic
mx_page_0:
	defs	4
mx_page_1:
	defs	4
mx_page_2:
	defs	4
mx_page_3:
	defs	4

	
; Last stroke from the keyboard
mx_last_stroke:
	defs	1
	
; Keeps keyboard scan signal and cas
mx_key_cas:
	defs	1
	
; Selected joystick for updating
; 0 = Joystick 1 selected
; 1 = Joystick 2 selected
mx_ctrl_sel:
	defs	1
	
; MSX joystick states
mx_ctrl_1:
	defs	1
mx_ctrl_2:
	defs	1