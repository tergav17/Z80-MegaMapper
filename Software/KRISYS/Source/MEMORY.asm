;
;********************************************************************
;*
;*              I D E N T I T Y   K R I S Y S
;*
;*      The [K]lunkly [R]emapper / [I]nterpreter [SYS]tem
;*
;*             Written by Gavin Tersteeg, 2024
;*              Copyleft, All Wrongs Reserved
;*
;*
;*   This piece of software allows different classic Z80 systems
;*   to run as "virtual machines" on top of existing hardware by
;*   use of a ZMM (Z80 MEGAMAPPER). It does this by remapping RAM
;*   and I/O address space ot match that of it's target system.
;*   Anything that can't be emulated by simple remapping is instead
;*   interpreted using I/O traps. 
;*
;*   This allows virtualized machines to run with an acceptable
;*   degree of speed and accuracy. While the ZMM is still quite
;*   limited in what sort of hardware can be efficiently virtualized,
;*   anything that avoids MMIO or graphics hardware that isn't a VDP
;*   generally can be made to work.
;* 
;********************************************************************

; -------------------------
; ******** Equates ********
; -------------------------

; --------------------------------
; ******** KRISYS Startup ********
; --------------------------------

.area	_TEXT
	
; Initalize the memory map
; Each bank of the ZMM will be probed, and writable
; banks will be recorded on the allocated bank map
;
; Returns nothing
; Uses: AF, BC, DE, HL
mem_map_init:

; ---------------------------
; ******** Variables ********
; ---------------------------

.area	_BSS

; Allocated bank map
; This 256 byte table keeps track of every single 16K bank
; that exists on the ZMM. Populated on startup
alloc_bank_map:
	defs	256