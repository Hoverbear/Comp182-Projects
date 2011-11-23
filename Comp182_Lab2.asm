*
* Andrew_Hobden_Lab2.asm  ---- A demonstration program for COMP 182 lab2
*               Sept. 25 2011
*
*     Function: This is meant to be a starting point for completing lab 2.
*               The program uses the 8 leds as a binary counter.
*
*	Authors: Andrew Hobden (C0344649), Patrick Brus
*
* The 68HC11 control register address is the offset address from the
* register base address $1000, so index addressing mode can also be used,
* otherwise only extended addressing mode can be used.
*
*
portb:  equ	$4
REGBLK: equ	$1000

SPEED:  equ     $10000			 ; change this number to change counting speed

STACK:	equ	$FF
*
        org     $F000
* reserve some memory for global variables here


s:
start:
        ldx     #REGBLK
        ldaa    #0

back:   staa    portb,x			; Set LEDs

return:	inca
	bita    #%00000001		; Check if we need to tick the second group.
	beq     #secondtick		; Tick the second group.
;	bita    #%00001111		; Check if we have a value of 15
	bita	#$0F
;	bne     #clearfour		; If so, reset that group to 0.
	beq	#clearfour		; If we do, get rid of it and set it back to 0.
        jsr     delay
        jsr     delay
	jmp	back

clearfour:
;	anda	#%00001111		; A dirty, dirty, terrible way to reset group 1.
	suba	#$0F			; Possibly a better way to get rid of the 1at group.
	jmp	#return			; Go back to where we were.
	
secondtick:
	adda    #$10			; Add 16, or increment the second group.
	jmp     back

delay:	pshx
	ldx	#SPEED			; delay n loops. delay = n * 10 cycles.
dly:	dex					; 3 cycles
	nop					; 2 cycle
	nop					; 2 cycle
	bne	dly				; 3 cycles
	pulx
	rts
	
	org	$FFFE
	fdb	start
	end


