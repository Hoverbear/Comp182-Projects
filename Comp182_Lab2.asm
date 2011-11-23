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



start:
        ldx     #REGBLK
        ldaa    #0
back:
;-------------------------------------------------------------------------------
tick1:	adda    #$01                    ; Add 1

check1:	bita	#$0F                    ; Check if we need to clear.
	bne	#noclr1			; If we do, clear the least sig 4
	suba    #$0F
	
noclr1: staa    portb,x			; Set LEDs
        jsr     delay
        jsr     delay
	
tick2:	adda    #$01                    ; Add to first nibble (Why do we call it that?)
	adda    #$10                    ; Add to the second.
	
check2: bita	#$0F                    ; Check if we need to clear.
 	bne	#noclr2			; If we do, get rid of it and set it back to 0.
	suba    #$0F
	
noclr2: staa    portb,x			; Set LEDs
	jsr     delay
        jsr     delay
	jmp	back

;-------------------------------------------------------------------------------

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


