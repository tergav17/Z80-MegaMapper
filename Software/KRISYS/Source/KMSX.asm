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
	
	; Try to find slot 1 resource
	xor	a
	ld	(mx_has_slot_1),a
	ld	de,str_slot_1
	call	res_locate
	or	a
	jp	nz,1$
	ld	a,0xFF
	ld	(mx_has_slot_1),a
	
	; Open the resource
	call	res_open
	
	; Load resources into bankmap
	ld	hl,bm_slot_1
	ld	bc,256
	call	res_load
	
1$:
	
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
	
	; Mount Slot 1 RAM
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
	
	; Mount User Slot 1
	ld	a,(mx_has_slot_1)
	or	a
	jp	z,50$
	ld	a,(bm_slot_1)
	or	0b10000000
	ld	(mx_page_1+2),a
	ld	a,(bm_slot_1+1)
	or	0b10000000
	ld	(mx_page_2+2),a
50$:
	
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
	
	; Reset keyboard state
	ld	hl,mx_key_matrix
	ld	de,mx_key_matrix+1
	ld	bc,16-1
	ld	(hl),0xFF
	ldir
	ld	hl,mx_key_ttl
	ld	de,mx_key_ttl+1
	ld	bc,16-1
	ld	(hl),0
	ldir
	
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
	jp	mx_strike_key
	
	; Joystick 1 detected
20$:	xor	a
	ld	(mx_ctrl_sel),a
	ret
	
	; Joystick 2 detected
21$:	ld	a,1
	ld	(mx_ctrl_sel),a
	ret

	; Handle a joystick data byte
40$:	push	bc
	push	hl
	ld	a,(mx_last_stroke)
	and	0b00011111
	ld	b,0
	ld	c,a
	ld	hl,mx_ctrltab
	add	hl,bc
	ld	a,(mx_ctrl_sel)
	or	a
	ld	a,(hl)
	jp	nz,50$
	
	; Joystick 0
	ld	(mx_ctrl_1),a
	pop	hl
	pop	bc
	ret
	
	; Joystick  1
50$:	ld	(mx_ctrl_2),a
	pop	hl
	pop	bc
	ret
	
; Strike a key on the keyboard
; Leaves an impression on the matrix
mx_strike_key:
	push	bc
	push	hl
	
	ld	a,(mx_last_stroke)
	or	a
	jp	m,99$
	
	; Get matrix vector
	ld	b,0
	ld	c,a
	sla	c
	ld	hl,mx_keytab
	add	hl,bc
	
	; Process keystroke
	ld	a,(hl)
	cp	0xFF
	jp	z,99$
	push	hl
	ld	c,a
	sra	c
	res	7,c
	sra	c
	sra	c
	sra	c
	ld	hl,mx_key_matrix
	add	hl,bc
	and	0b0001111
	ld	c,1
0$:	or	a
	jp	z,1$
	sla	c
	dec	a
	jp	0$
1$:	ld	a,c
	xor	0xFF
	ld	(hl),a
	ld 	c,16
	add	hl,bc
	ld	(hl),2
	pop	hl
	
	inc	hl
	ld	a,(hl)
	cp	0xFF
	jp	z,99$
	ld	c,a
	sra	c
	res	7,c
	sra	c
	sra	c
	sra	c
	ld	hl,mx_key_matrix
	add	hl,bc
	and	0b0001111
	ld	c,1
2$:	or	a
	jp	z,3$
	sla	c
	dec	a
	jp	2$
3$:	ld	a,c
	xor	0xFF
	ld	(hl),a
	ld 	c,16
	add	hl,bc
	ld	(hl),2
	
99$:	pop	hl
	pop	bc
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
	; Read data
	ld	a,(mx_ay_latch)
	
	; Port A?
	cp	14
	jp	z,20$
	
	; Port B?
	cp	15
	jp	z,30$
	
	out	(nabu_ay_latch),a
	in	a,(nabu_ay_data)
	ret
	
	; Read port A
20$:	ld	a,(mx_ay_port_b)
	rlca
	rlca
	jp	c,25$
	
	; Read controller 1
	ld	a,(mx_ctrl_1)
	ret
	
	; Read controller 2
25$:	ld	a,(mx_ctrl_2)
	ret
	
	; Read port B
30$:	ld	a,(mx_ay_port_b)
	ret
	

; PSG output
psg_out:
	in	a,(zmm_addr_lo)
	rrca
	jp	c,20$
	
	; Set latch
	pop	af
	and	0b00001111
	ld	(mx_ay_latch),a
	ret
	
	; Set data
20$:	ld	a,(mx_ay_latch)
	
	; Enable?
	cp	7
	jp	z,30$
	
	; Port A?
	cp	14
	jp	z,40$
	
	; Port B?
	cp	15
	jp	z,50$
	
	; Normal write
	out	(nabu_ay_latch),a
	pop	af
	out	(nabu_ay_data),a
	ret
	
	; Enable channels
30$: 	out	(nabu_ay_latch),a
	pop	af
	and	0b00111111
	or	0b01000000
	out	(nabu_ay_data),a
	ret
	
	; Write port A
40$:	pop	af
	ret
	
	; Write port B
50$:	pop	af
	ld	(mx_ay_port_b),a
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
	push	bc
	push	hl
	
	; Get matrix row
	ld	a,(mx_key_cas)
	and	0b00001111
	ld	c,a
	ld	b,0
	ld	hl,mx_key_ttl
	add	hl,bc
	ld	a,(hl)
	or	a
	ld	a,0xFF
	jp	z,99$
	dec	(hl)
	ld	hl,mx_key_matrix
	add	hl,bc
	ld	a,(hl)
	
99$:	pop	hl
	pop	bc
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
	
str_slot_1:
	defb	'S1',0
	
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

; MSX controller table
mx_ctrltab:
	defb	~0b01000000	; -----
	defb	~0b01000100	; ----L
	defb	~0b01000010	; ---D-
	defb	~0b01000110	; ---DL
	defb	~0b01001000	; --R--
	defb	~0b01001100	; --R-L
	defb	~0b01001010	; --RD-
	defb	~0b01001110	; --RDL
	defb	~0b01000001	; -U---
	defb	~0b01000101	; -U--L
	defb	~0b01000011	; -U-D-
	defb	~0b01000111	; -U-DL
	defb	~0b01001001	; -UR--
	defb	~0b01001101	; -UR-L
	defb	~0b01001011	; -URD-
	defb	~0b01001111	; -URDL
	defb	~0b01010000	; F----
	defb	~0b01010100	; F---L
	defb	~0b01010010	; F--D-
	defb	~0b01010110	; F--DL
	defb	~0b01011000	; F-R--
	defb	~0b01011100	; F-R-L
	defb	~0b01011010	; F-RD-
	defb	~0b01011110	; F-RDL
	defb	~0b01010001	; FU---
	defb	~0b01010101	; FU--L
	defb	~0b01010011	; FU-D-
	defb	~0b01010111	; FU-DL
	defb	~0b01011001	; FUR--
	defb	~0b01011101	; FUR-L
	defb	~0b01011011	; FURD-
	defb	~0b01011111	; FURDL

; Keyboard lookup table
mx_keytab:
	defb	0x26,0x61	; 0x00 CTRL-@
	defb	0x27,0x61	; 0x01 CTRL-A
	defb	0x30,0x61	; 0x02 CTRL-B
	defb	0x31,0x61	; 0x03 CTRL-C
	defb	0x32,0x61	; 0x04 CTRL-D
	defb	0x33,0x61	; 0x05 CTRL-E
	defb	0x34,0x61	; 0x06 CTRL-F
	defb	0x35,0x61	; 0x07 CTRL-G
	defb	0x75,0xFF	; 0x08 CTRL-H
	defb	0x73,0xFF	; 0x09 CTRL-I
	defb	0x40,0x61	; 0x0A CTRL-J
	defb	0x41,0x61	; 0x0B CTRL-K
	defb	0x42,0x61	; 0x0C CTRL-L
	defb	0x77,0xFF	; 0x0D CTRL-M
	defb	0x44,0x61	; 0x0E CTRL-N
	defb	0x45,0x61	; 0x0F CTRL-O
	defb	0x46,0x61	; 0x10 CTRL-P
	defb	0x47,0x61	; 0x11 CTRL-Q
	defb	0x50,0x61	; 0x12 CTRL-R
	defb	0x51,0x61	; 0x13 CTRL-S
	defb	0x52,0x61	; 0x14 CTRL-T
	defb	0x53,0x61	; 0x15 CTRL-U
	defb	0x54,0x61	; 0x16 CTRL-V
	defb	0x55,0x61	; 0x07 CTRL-W
	defb	0x56,0x61	; 0x18 CTRL-X
	defb	0x57,0x61	; 0x19 CTRL-Y
	defb	0xFF,0x61	; 0x1A CTRL-Z
	defb	0x72,0xFF	; 0x1B CTRL-[ (ESC)
	defb	0xFF,0x61	; 0x1C CTRL-<
	defb	0xFF,0x61	; 0x1D CTRL-]
	defb	0xFF,0x61	; 0x1E CTRL-^
	defb	0xFF,0x61	; 0x1F CTRL--
	defb	0x80,0xFF	; 0x20 Space
	defb	0x01,0x60	; 0x21 !
	defb	0x20,0x60	; 0x22 "
	defb	0x03,0x60	; 0x23 #
	defb	0x04,0x60	; 0x24 $
	defb	0x05,0x60	; 0x25 %
	defb	0x07,0x60	; 0x26 &
	defb	0x20,0xFF	; 0x27 '
	defb	0x11,0x60	; 0x28 (
	defb	0x00,0x60	; 0x29 )
	defb	0x10,0x60	; 0x2A *
	defb	0x13,0x60	; 0x2B +
	defb	0x22,0xFF	; 0x2C ,
	defb	0x12,0xFF	; 0x2D -
	defb	0x23,0xFF	; 0x2E .
	defb	0x24,0xFF	; 0x2F /
	defb	0x00,0xFF	; 0x30 0
	defb	0x01,0xFF	; 0x31 1
	defb	0x02,0xFF	; 0x32 2
	defb	0x03,0xFF	; 0x33 3
	defb	0x04,0xFF	; 0x34 4
	defb	0x05,0xFF	; 0x35 5
	defb	0x06,0xFF	; 0x36 6
	defb	0x07,0xFF	; 0x37 7
	defb	0x10,0xFF	; 0x38 8
	defb	0x11,0xFF	; 0x39 9
	defb	0x17,0x60	; 0x3A :
	defb	0x17,0xFF	; 0x3B ;
	defb	0x22,0x60	; 0x3C <
	defb	0x13,0xFF	; 0x3D =
	defb	0x23,0x60	; 0x3E >
	defb	0x24,0x60	; 0x3F ?
	defb	0x02,0x60	; 0x40 @
	defb	0x26,0x60	; 0x41 A
	defb	0x27,0x60	; 0x42 B
	defb	0x30,0x60	; 0x43 C
	defb	0x31,0x60	; 0x44 D
	defb	0x32,0x60	; 0x45 E
	defb	0x33,0x60	; 0x46 F
	defb	0x34,0x60	; 0x47 G
	defb	0x35,0x60	; 0x48 H
	defb	0x36,0x60	; 0x49 I
	defb	0x37,0x60	; 0x4A J
	defb	0x40,0x60	; 0x4B K
	defb	0x41,0x60	; 0x4C L
	defb	0x42,0x60	; 0x4D M
	defb	0x43,0x60	; 0x4E N
	defb	0x44,0x60	; 0x4F O
	defb	0x45,0x60	; 0x50 P
	defb	0x46,0x60	; 0x51 Q
	defb	0x47,0x60	; 0x52 R
	defb	0x50,0x60	; 0x53 S
	defb	0x51,0x60	; 0x54 T
	defb	0x52,0x60	; 0x55 U
	defb	0x53,0x60	; 0x56 V
	defb	0x54,0x60	; 0x57 W
	defb	0x55,0x60	; 0x58 X
	defb	0x56,0x60	; 0x59 Y
	defb	0x57,0x60	; 0x5A Z
	defb	0x15,0xFF	; 0x5B [
	defb	0x14,0xFF	; 0x5C N/A (\)
	defb	0x16,0xFF	; 0x5D ]
	defb	0x06,0x60	; 0x5E ^
	defb	0x12,0x60	; 0x5F _
	defb	0x25,0xFF	; 0x60 N/A (`)
	defb	0x26,0xFF	; 0x61 a
	defb	0x27,0xFF	; 0x62 b
	defb	0x30,0xFF	; 0x63 c
	defb	0x31,0xFF	; 0x64 d
	defb	0x32,0xFF	; 0x65 e
	defb	0x33,0xFF	; 0x66 f
	defb	0x34,0xFF	; 0x67 g
	defb	0x35,0xFF	; 0x68 h
	defb	0x36,0xFF	; 0x69 i
	defb	0x37,0xFF	; 0x6A j
	defb	0x40,0xFF	; 0x6B k
	defb	0x41,0xFF	; 0x6C l
	defb	0x42,0xFF	; 0x6D m
	defb	0x43,0xFF	; 0x6E n
	defb	0x44,0xFF	; 0x6F o
	defb	0x45,0xFF	; 0x70 p
	defb	0x46,0xFF	; 0x71 q
	defb	0x47,0xFF	; 0x72 r
	defb	0x50,0xFF	; 0x73 s
	defb	0x51,0xFF	; 0x74 t
	defb	0x52,0xFF	; 0x75 u
	defb	0x53,0xFF	; 0x76 v
	defb	0x54,0xFF	; 0x77 w
	defb	0x55,0xFF	; 0x78 x
	defb	0x56,0xFF	; 0x79 y
	defb	0x57,0xFF	; 0x7A z
	defb	0x15,0x60	; 0x7B {
	defb	0x14,0x60	; 0x7C N/A (|)
	defb	0x16,0x60	; 0x7D }
	defb	0xFF,0xFF	; 0x7E N/A (~)
	defb	0x83,0xFF	; 0x7F Delete

; ---------------------------
; ******** Variables ********
; ---------------------------

.area	_BSS

mx_has_slot_1:
	defs	1

; Block map for slot 1 ROM
bm_slot_1:
	defs	2

; Block map for BIOS
bm_bios:
	defs	2
	
; Invalid page
null_page:
	defs	1
	
; Keyboard matrix state
mx_key_matrix:
	defs	16
	
; Keyboard matrix time to live
mx_key_ttl:
	defs	16
	
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

; MSX AY Port B output
mx_ay_port_b:
	defs 	1
	
mx_ay_latch:
	defs	1
	
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