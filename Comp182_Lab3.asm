*
*  IR_sen.asm - an IR proximity sensor for the Ep2711E9 Rev. C board
*               (c)2003, EVBplus.com, Written By Wayne Chu
*
*      Modified by: Andrew Hobden, Patrick Brus
*
*     Function:	A robot application by using the IR light beam to detect
*		an object in its vicinity.
*
*     Instruction: The PD1 will be reset to low to enable the IR transmitter.
*		   The IR light beam will be bounced back by an object,
*		   so the IR receiver will receive the IR light via PD0 and
*		   display the result on the LCD display module.
*
*		   Sometime the table surface can reflect the light.
*		   For the best result, place the board near the edge of the
*		   table to reduce the reflection by the table surface.
*		   Two T1 red LEDs near the IR transceiver will indicate
*		   its status.  After running the program, make sure that
*		   the TX LED is on and the RX LED is off without an object
*		   in the front of them.  If your body is too close to them,
*		   it also will reflect the IR light, so stay 1 foot away
*		   from them. When the RX LED is off, then put your hand
*		   in the front of them and read the LCD display.

*		   The range is about 6-10 inches and can be increased by
*		   reducing the resister R11s value, but it should not be
*		   smaller than 100 Ohm.
*
portd:		equ	8
ddrd:		equ	9
REGBLK:		equ	$1000
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
*
		org	$F000
		jmp	start
bcd:            fcb     0,0       	; Reserves 2 byte for bcd

delay_10ms:
		pshx
		ldx     #TEN_MS		; 2500 x 8 = 20,000 cycles = 10ms
del1:		dex			; 3 cycles, decrement register x
		nop			; 2 cycle
		bne	del1		; 3 cycles
		pulx
       		rts
*
start:
     		lds	#STACK
   		jsr	delay_10ms	; Delay 20ms during power up
    		jsr	delay_10ms
		ldx	#REGBLK
		ldaa	#2
		staa	ddrd,x		; PD0=input, PD1=output

		clr	portd,x		; Make PD1=0 to xmit IR light

    		jsr	lcd_ini		; Initialize the LCD

back:		ldaa	portd+$1000
		rora			; Rotate PD0 into carry bit
		bcs	no_IR_light     ; Branch if carry set

		ldx    	#MSG2		; MSG2 for line1, x points to MSG2
        	ldab    #16             ; Send out 16 characters
     		jsr	lcd_line1	; Print MSG2 to LCD line 1

		;ldx     #MSG3+10s         ; Sets buffer after count
		jsr     BCDinc
		;jsr     LongDelay

     		; Need to add a loop here.
		; Need to use anda #%00001111 to get first digit.
		; 
		ldaa    bcd
		adda	#$30            ;
     		staa    0,x
     		ldx    	#MSG3		; MSG3 for line2, x points to MSG3
        	ldab    #16             ; Send out 16 characters
     		jsr	lcd_line2	; Print MSG3 to LCD line 2

     		jsr	delay_10ms
     		jsr	delay_10ms
     		jmp	back

no_IR_light:
		ldx    	#MSG1		; MSG1 for line1, x points to MSG1
       		ldab    #16             ; send out 16 characters
    		jsr	lcd_line1
*
     		jsr	delay_10ms
     		jsr	delay_10ms
     		jmp	back
; Inputs: x = The BCD
BCDinc:
		pshx                    ; Push the buffers
		pshb
		psha
		abx                     ; b added x
		dex                     ; x is decremented 1
BCDcount:
		ldaa    bcd             ;
		adda	#1		; Add 1 to A
		daa			; Decimal Adjust A
		staa    bcd		; Storing A at 0, offset by x
		bcc     BCDdone
		dex			; Decrement x
		decb			; Decrement b
		bne     BCDcount
BCDdone:
		pula			; Pull the bufers so we dont screw other things up
		pulb
		pulx
		rts

LongDelay:      jsr	delay_10ms
                jsr	delay_10ms
                jsr	delay_10ms
                jsr	delay_10ms
                jsr	delay_10ms
                jsr	delay_10ms
                jsr	delay_10ms
                jsr	delay_10ms
                jsr	delay_10ms
                jsr	delay_10ms
                rts

MSG1:   	FCC     "NO OBJECT NEARBY"
MSG2:   	FCC     "OBJECT DETECTED "
MSG3:   	FCC     "Count:          "
       		org	$FFFE
     		fdb	start
       		end

