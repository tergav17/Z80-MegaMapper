;
;********************************************************************
;*
;*        K R I S Y S   C O L E C O V I S I O N   C O R E
;*
;********************************************************************

#include "KRISYS.asm"

; ---------------------------
; ******** Core Init ********
; ---------------------------

.area	_TEXT

; Start of ColecoVision core
core_start:
	jp	cpm_exit


; -----------------------------------
; ******** Interrupt Handler ********
; -----------------------------------

.area	_TEXT
	
; Handle "real" interrupts from devices (if needed)
; All registers except AF must remain unchanged!
irq_handle:
	ret
	

; -----------------------------
; ******** I/O Handler ********
; -----------------------------
	
.area	_TEXT

; Handle an IN instruction
; Inputted value should be returned in register A
; All registers except AF must remain unchanged!
in_handle:
	ld	a,0xFF
	ret

; Handle an OUT instruction
; A = Value outputted by virtual machine
; All registers except AF must remain unchanged!
out_handle:
	ret