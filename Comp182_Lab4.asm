*      Modified by: Andrew Hobden, Patrick Brus
*
portd:		equ	8
ddrd:		equ	9
REGBLK:		equ	$1000
PORTA		equ	$00		; offset of PORTA from REGBAS
PORTB   	equ     $04   		; offset of PORTB from REGBAS
TOC2		equ	$18		; offset of TOC2 from REGBAS
TCNT		equ	$0E		; offset of TCNT from REGBAS
TCTL1		equ	$20		; offset of TCTL1 from REGBAS
TFLG1		equ	$23		; offset of TFLG1 from REGBAS
TMSK1		equ	$22		; offset of TMSK1 from REGBAS
hitime		equ	250		; value to set high time to 250 us
lotime		equ	750		; value to set low time to 250 us
toggle		equ	$40		; value to select the toggle action
OC2		equ	$40		; value to select OC2 pin and OC2F flag
clear		equ	$40		; value to clear OC2F flag
sethigh		equ	$40		; value to set OC2 pin to high
TEN_MS:		equ	2500		; 2500 x 8 cycles = 20,000 cycles = 10ms
*
STACK:		equ	$FF
*
              	org     $0800		; EVBplus2 board I/O routines
rs485_recv:     rmb     3		; Enables rs485 recv mode
rs485_xmit:     rmb     3		; Enables rs485 xmit mode
get_date:       rmb     3		; Gets current date from PTC
get_time:       rmb     3		; Gets current time from PC
outstrg00:	rmb	3		; Outputs a string terminated by 0
lcd_ini:	rmb	3		; Initializes the 16x2 LCD module
lcd_line1:	rmb	3		; Displays 16 char on the first line
lcd_line2:	rmb	3		; Displays 16 char on the second line
sel_inst:	rmb	3		; Selects instruction before writing LCD module
sel_data:	rmb	3		; Selects data before writing the LCD module
wrt_pulse:	rmb	3		; Generates a write pulse to the LCD module
*
		ORG	$FFE6	     	; set up the OC2 interrupt vector
		FDB	oc2_ISR
*
		org	$F000
		jmp	start
secondBCD:	fcb     #0      	; Reserves 1 byte for seconds.
minuteBCD:	fcb	#0		; Reserves 1 byte for minutes.
hourBCD:	fcb	#0		; Reserves 1 byte for hours.
unitLength:	equ	1		; length of bcd in bytes
ASCIILength:    equ     6               ; Length of the ASCII output
interuptCount:  fcb     #0              ; We're looking for 100 of these to make a second if the interupt is every 20 ms.
interuptGap:    equ     20000           ; Two bytes for the Timer compare gap



****************************************
* START
****************************************
start:		lds	#STACK
   		jsr	delay_10ms	; Delay 20ms during power up
    		jsr	delay_10ms
    		jsr	lcd_ini		; Initialize the LCD
		ldx	#REGBLK

		BSET	PORTA,x OC2 	; set OC2 pin to high  (PA6)
		LDAA	#clear
		STAA	TFLG1,x	    	; clear the OC2F flag
		LDAA	#toggle	     	; select the OC2 action to be toggle
		STAA	TCTL1,x

		LDD	TCNT,x	    	; Start an OC2 compare.
		ADDD	#interuptGap
		STD	TOC2,x

		ldaa    #%01000000
		staa    TMSK1,x         ; Enable the OC2 interrupt
		ldd     #oc2_ISR
		std     OC2,x
		CLI	             	; Enable interrupts

****************************************
* The main program loop.
****************************************
back:
		ldaa    interuptCount
break:		cmpa    #$64
		beq     secondINC
* Do seconds ACSII display.
		ldx     #SecondLCD	; Loading position of MSG3 where numerical digits display.
		ldy     #secondBCD      ; Loading the seconds buffer.
		ldab	#unitLength	; Loading the number of BCD digits there are.
		jsr     ASCIIInsert	; Stepping through inserts of Digits onto the display buffer.
* Do Minutes ACSII display.
		ldx     #MinuteLCD	; Loading position of MSG3 where numerical digits display.
		ldy     #minuteBCD      ; Loading the seconds buffer.
		ldab	#unitLength	; Loading the number of BCD digits there are.
		jsr     ASCIIInsert	; Stepping through inserts of Digits onto the display buffer.
* Do Hours ACSII display.
		ldx     #HourLCD	; Loading position of MSG3 where numerical digits display.
		ldy     #hourBCD      ; Loading the seconds buffer.
		ldab	#unitLength	; Loading the number of BCD digits there are.
		jsr     ASCIIInsert	; Stepping through inserts of Digits onto the display buffer.
* Write out to the display.
     		ldx    	#MSG		; MSG3 for line2, x points to MSG3
        	ldab    #16             ; Send out 16 characters
     		jsr	lcd_line2	; Print MSG3 to LCD line 2
     		jsr     delay_10ms	; Take a short break!
     		jsr     delay_10ms	; Take a short break!
    		jmp	back		; Reloop.

****************************************
* TIMER
****************************************
* Do seconds increment.
secondINC: 	ldab    #unitLength     ; Loads the B register with the unit length (2)
		;ldaa    #0
		;staa    interuptCount

		ldx	#secondBCD	; Sets to secondsBCD for subroutine
		jsr     BCDinc		; Increment the seconds by one and adjust as needed.
		ldaa	secondBCD	; Load A with the *value* of the BCD.
		cmpa	#$60		; Compare A to 60, checking to see if we need to inc minute.
		beq	minuteINC	; Increment the minute if needed.
		rts

* Do minutes increment, happens if secondsBCD = $60.
minuteINC:	ldaa	#00		; Load A with 0
		staa	secondBCD	; Store 0 into the secondsBCD, resetting it.
		ldab	#unitLength	; In case it got overwritten somehow. Safety first!
		ldx	#minuteBCD	; Sets to minutesBCD for our subroutine.
		jsr	BCDinc		; Increment the seconds by one and adjust as needed
		ldaa	minuteBCD	; Load A with the *value* of the BCD.
		cmpa	#$60		; Compare A to 60, checking to see if we need to inc hour.
		beq	hourINC		; Increment the hour if needed.
		rts

* Do hour increment, happens if minutesBCD = $60.
hourINC:	ldab	#unitLength	; In case it got overwritten somehow. Safety first!
		ldx	#hourBCD	; Sets to minutesBCD for our subroutine.
		jsr	BCDinc		; Increment the seconds by one and adjust as needed
		ldaa	hourBCD		; Load A with the value of the BCD.
		cmpa	#$24		; Compare it to the max of 24.
		rts
		; TODO: Timer Reset Code



****************************************
* ASCII
****************************************
* Inputs:
*		x = message to append to,
*		y = the bcd buffer,
*		B = the number of digits
*
ASCIIInsert:	pshx			; Pushing all buffers for safety concerns.
		pshy
		psha
		pshb
		ldab    #2      	; Load the BCD
		;iny                     ; Get to the right byte.
*
ASCIILoop:	LDAA	0,y		; Loading BCD byte. (2 digits per byte)
		ANDA	#%00001111	; Remove second digit within the bye.
		ADDA	#$30		; Convert to ASCII.
		STAA	0,x		; Store within first digit of display buffer.
		LDAA	0,y		; Reload the BCD byte so we can pull the second digit of the byte.
		LSRA			; Logical Shifting so we can access the last 4 bytes and form a byte.	; 1st
		LSRA			; 									; 2nd
		LSRA			; 									; 3rd
		LSRA			; 									; 4th
		ADDA	#$30		; Converting the digit into ASCII code.
		DEX			; Moving too next digit in display buffer.
		STAA	0,x		; Writing bcd bytes.
		DEY			; Changing BCD byte.
		DEX			; Mark completed display buffer digit.
		DEX			; Since we've done 2 digits we skip one for the ":"
		DECB			; Mark completed BCD pair, move to next byte.
		BNE	ASCIILoop	; If B is not zero, return to begining of loop.
*
ASCIIEnd:       pulb
		pula
		puly
		pulx
		rts			; Return to subroutine.

****************************************
* BCD
****************************************
* Inputs:
*		x = BCDbuffer address,
*		b = Length in bytes of BCDBuff
*
BCDinc:		psha			; Push and go.
		pshx
		pshb
		abx			; Add the BCDBuff length to the address (End of smallest digit.)
		dex			; Get to the BCDbuff location we want (Right before last byte/digit-pair)
*
BCDloop:	ldaa	0,x		; Load the byte (2 digits) so we can work with it.
		ADDA	#1		; Increment the byte.
		daa			; Allow the proc to adjust for us to get a proper BCD.
		staa	0,x		; Restore the byte to it's location.
		bcc	BCDfinish	; C=0? We're done, step to finished.
*					; C=1? We need to move across more digits.
		dex			; Change x to address next largest byte.
		decb			; Reduce length by 1 so we don't overrun (We check this next step)
		bne	BCDloop		; Z=0? Continue looping.
*					; Z=1? We're done else we overrun.
*
BCDfinish:	pulb
		pulx
		pula
		rts			; Clean up and return

*
* Clears the BCD.
* No inputs.
*
BCDClear:       PSHX
;		LDX     #bcd            ; Loading the place of the BCD into X register
		bclr    0,x     $FF     ; Clearing all the bits in the largest pair of BCD numbers
		inx                     ; Incrementing X so we can get to the next pair
		BCLR    0,x     $FF     ; Clearing the smallest pair of BCDs
		PULX
		RTS                     ; Returning home

****************************************
* DELAY
****************************************
*
* A simple 10 second delay for general use.
*
delay_10ms:
		pshx
		ldx     #TEN_MS		; 2500 x 8 = 20,000 cycles = 10ms
del1:		dex			; 3 cycles, decrement register x
		nop			; 2 cycle
		bne	del1		; 3 cycles
		pulx
       		rts

****************************************
* Message
****************************************
MSG:   		FCC     "Time:     :  :  "
SecondLCD:	equ	#MSG+15	 	; Gets us to the desired "drop point"
MinuteLCD:      equ	#MSG+12	 	; Gets us to the desired "drop point"
HourLCD:        equ	#MSG+9	 	; Gets us to the desired "drop point"
       		;org	$FFFE
     		;fdb	start

****************************************
* Interupt
****************************************
oc2_ISR         LDX     #REGBLK
		LDAA	#clear		; clear the OC2F flag
		STAA	TFLG1,X	        ;
		LDD	TOC2,X	        ; pull OC2 pin to high 700 E clock cycles later
		ADDD	#interuptGap	;
		STD	TOC2,X	        ;
		ldaa    interuptCount
		inca
		staa    interuptCount
exit		RTI
       		end

