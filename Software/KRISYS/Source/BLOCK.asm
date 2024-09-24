;
;**************************************************************
;*
;*	B L O C K   D E V I C E   I N T E R F A C E
;*
;*      Allows virtual machines to access abstracted
;*      block devices on the host machines. These can
;*      either be genuine block devices, partitioned
;*      block devices, or native CP/M files.
;* 
;**************************************************************


; ----------------------------
; ********  Functions ********
; ----------------------------

.area	_TEXT

; ---------------------------
; ******** Variables ********
; ---------------------------

.area	_BSS