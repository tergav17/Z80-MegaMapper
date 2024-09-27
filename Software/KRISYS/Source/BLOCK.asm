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
;*	Internally, block devices are given a numeric
;*      ID to be accessed by once opened.
;* 
;**************************************************************


; ----------------------------
; ********  Functions ********
; ----------------------------

.area	_TEXT

; Initalize block device handler
; 
; Returns nothing
; Uses: AF, BC, DE, HL
block_init:
	ret
	
	
; Opens a block device
; Will error if block device can't be opened
; [Resource argument] = Physical resource to open
; A = Device ID to open into
;
; Uses: All
; Returns nothing
block_open:
	ret
	
; Reads a 512 byte block into the buffer
; Will fail if attempting to access an uninitalized block device
; A = Device ID to access
; BC = Block #
;
; Uses: All
; Returns nothing
block_read:
	ret

; Writes a 512 byte block from the buffer
; Will fail if attempting to access an uninitalized block device
; A = Device ID to access
; BC = Block #
;
; Uses: All
; Returns nothing
block_write:
	ret


; ---------------------------
; ******** Variables ********
; ---------------------------

.area	_BSS

; 512 byte buffer for storing blocks
block_buffer:
	defs	512