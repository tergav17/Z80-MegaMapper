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
	
; Handle "real" interrupts from devices (if needed)
; All registers except AF must remain unchanged!
irq_handle:
	ret