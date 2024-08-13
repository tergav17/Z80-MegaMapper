;
;********************************************************************
;*
;*               R E S O U R C E   M A N A G E M E N T
;* 
;*    These routines handle obtaining use-supplied resources
;*    such as configurations, ROM images, and storage bindings.
;*    During startup, these resources will be loaded to build
;*    the virtual machine.
;*
;********************************************************************


; Initalize resources
;
; Returns nothing
; Uses: AF, BC, HL
res_init:
	; Start by zero-terminating string
	ld	hl,cpm_command
	ld	c,(hl)
	ld	b,0
	add	hl,bc
	inc	hl
	ld	(hl),b

; Find a resource from the command line
; HL = Name of resource (upper case only) 
;
; Returns A = 0xFF if no resource is found
res_locate:
	
	push	hl

	pop	hl