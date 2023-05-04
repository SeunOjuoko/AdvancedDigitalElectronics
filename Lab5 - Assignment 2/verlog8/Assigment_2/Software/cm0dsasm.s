;------------------------------------------------------------------------------------------------------
; Design and Implementation of an AHB Interrupt Mechanism  
; 1)Input characters from keyboard (UART) and output to the terminal (using interrupt)
; 2)A counter is incremented from 1 to 10 and displayed on the 7-segment display (using interrupt)
;------------------------------------------------------------------------------------------------------


; Vector Table Mapped to Address 0 at Reset
VGA_base_address	    EQU	0x50000000
UART_base_address	    EQU	0x51000000
timer_base_address    	EQU	0x52000000
GPIO_base_address	    EQU	0x53000000
GPIO_direction_address 	EQU	0x53000004
GPIO_Data 				EQU 0x53000000
SEG7_base_address	    EQU	0x54000000
SEG7_digit_1_register 	EQU 0x54000000
SEG7_digit_2_register 	EQU 0x54000004
SEG7_digit_3_register 	EQU 0x54000008
SEG7_digit_4_register 	EQU 0x5400000C
LED_base_address	    EQU	0x55000000
timer_value_address 	EQU 0x52000004
timer_control_address 	EQU 0x52000008
initial_SP		    	EQU	0x00003FFC	; initial stack pointer value
	

						PRESERVE8
                		THUMB

        				AREA	RESET, DATA, READONLY	  			; First 32 WORDS is VECTOR TABLE
        				EXPORT 	__Vectors
					
__Vectors		    	DCD		0x00003FFC
        				DCD		Reset_Handler
        				DCD		0  			
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD 	0
        				DCD		0
        				DCD		0
        				DCD 	0
        				DCD		0
        				
        				; External Interrupts
						        				
        				DCD		Timer_Handler
        				DCD		UART_Handler
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
              
                AREA |.text|, CODE, READONLY
;Reset Handler
Reset_Handler   PROC
                GLOBAL Reset_Handler
                ENTRY

                LDR     R1, =0xE000E400           ;Interrupt Priority Register
                LDR     R0, =0x00004000           ;Priority: IRQ0(Timer): 0x00, IRQ1(UART): 0x40
                STR     R0, [R1]
                LDR     R1, =0xE000E100           ;Interrupt Set Enable Register
                LDR     R0, =0x00000003           ;Enable interrupts for UART and timer 
                STR     R0, [R1]
		

				;Configure the timer
				
				LDR 	R1, =0x52000000		;timer load value register
				LDR 	R0, =0x02FAF080		;=50,000,000 (system tick frequency)
				STR		R0,	[R1]			
				LDR 	R1, =0x52000008		;timer control register
				MOVS	R0, #0x03			;prescaler=1, enable timer, reload mode
				STR		R0,	[R1]

                LDR     R5, =0x00000030		;counting-up counter, start from '0' (ascii=0x30)  

AGAIN			
				LDR		R1, = GPIO_direction_address
				MOVS	R0, #00
				STR		R0, [R1]
				
				LDR		R1, = GPIO_base_address
				LDR		R2, [R1]
				
				LDR		R1, = GPIO_direction_address
				MOVS	R0, #01
				STR		R0, [R1]
				
				LDR		R1, = GPIO_base_address
				STR		R2, [R1]
				    
				LDR 	R1, =0x52000004		;timer current value register
				LDR		R3,	[R1]
				LSRS	R3,	R3, #16			;choose the higher 16 bits

				MOVS	R0,	R3				;display the 1st digit
				LDR 	R2, =0x0F
				ANDS    R0, R0, R2
				LDR 	R1, =0x54000000
				STR		R0, [R1]

				LSRS	R0,	R3, #4			;display the 2nd digit
				LDR 	R2, =0x0F
				ANDS    R0, R0, R2
				LDR 	R1, =0x54000004
				STR		R0, [R1]
				
				LSRS	R0,	R3, #8			;display the 3rd digit
				LDR 	R2, =0x0F
				ANDS    R0, R0, R2
				LDR 	R1, =0x54000008
				STR		R0, [R1]
				
				LSRS	R0,	R3, #12			;display the 4th digit
				LDR 	R2, =0x0F
				ANDS    R0, R0, R2
				LDR 	R1, =0x5400000C
				STR		R0, [R1]					
			
				
				B		AGAIN		


				ENDP

Timer_Handler   PROC
                EXPORT Timer_Handler
                PUSH    {R0,R1,R2,LR}

				LDR 	R1, =0x5200000c		;clear timer interrupt
				MOVS	R0, #0x01
				STR		R0, [R1]

				LDR 	R1, =0x50000000		;VGA BASE
				STR		R5, [R1]
				ADDS	R5, R5, #0x01
				CMP		R5,	#0x3A
				BNE		NEXT
				LDR 	R1, =0x52000008		;timer control register
				MOVS	R0, #0x00			;Stop timer if counts to 9
				STR		R0,	[R1]				

NEXT			MOVS	R0, #' '
				STR		R0, [R1]
				
                POP     {R0,R1,R2,PC}                    ;return
                ENDP

UART_Handler    PROC
                EXPORT UART_Handler

                PUSH    {R0,R1,R2,LR}
                LDR     R1, =0x51000000               ;UART
                LDR     R0, [R1]                      ;Get Data from UART
                STR     R0, [R1]                      ;Write to UART

                POP     {R0,R1,R2,PC}
                ENDP

				ALIGN 		4					 ; Align to a word boundary

		END                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
   