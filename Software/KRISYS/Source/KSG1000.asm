;
;********************************************************************
;*
;*        K R I S Y S   S G 1 0 0 0   C O R E
;*
;********************************************************************

#include "KRISYS.asm"

; ---------------------------
; ******** Core Init ********
; ---------------------------

.area	_TEXT

; Start of SG-1000 core
core_start:
	jp	cpm_exit