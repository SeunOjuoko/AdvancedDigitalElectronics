;------------------------------------------------------------------------------------------------------
; Design and Implementation of an AHB timer, a GPIO peripheral, and a 7-segment display peripheral  
; 
; 1) display text string: "INT" on VGA.
; 2) continously poll switches and output their values to LEDs. 
; 3) on (timer) interrupt, write the (16 MSBs of the) timer value to the 7-segment display.
;
; As described in B31DE lecture 6 March 2023.
; This program is for use with AHBTIMER2023.v and AHBGPIO2023.v peripherals.
;
;------------------------------------------------------------------------------------------------------

VGA_base_address 		EQU		0x50000000
UART_base_address 		EQU		0x51000000
SEVEN_SEG_base_address	EQU		0x54000000
SEVEN_SEG_DIGIT1		EQU		0x54000000
SEVEN_SEG_DIGIT2		EQU		0x54000004
SEVEN_SEG_DIGIT3		EQU		0x54000008
SEVEN_SEG_DIGIT4		EQU		0x5400000C
TIMER_base_address 		EQU		0x52000000
GPIO_write_address		EQU		0x53000004
GPIO_read_address		EQU		0x53000000

IRQ_enable_register		EQU		0xE000E100
enable_IRQ0				EQU		0x00000001

initial_MSP				EQU		0x00004000


; exception vector table to start at address 0x00000000

			PRESERVE8
			THUMB

        	AREA	RESET, DATA, READONLY	
        	EXPORT 	__Vectors
					
__Vectors	 
			DCD		initial_MSP		; initial main stack pointer
       		DCD		Reset_Handler	; reset vector
       		DCD		0  				; NMI vector
       		DCD		0				; hard fault vector
       		DCD		0				; not used
       		DCD		0				; not used
       		DCD		0				; not used
       		DCD		0				; not used
       		DCD		0				; not used
       		DCD		0				; not used
       		DCD		0				; not used
       		DCD 	0				; SVC vector
       		DCD		0				; not used
       		DCD		0				; not used
       		DCD 	0				; PendSV vector
       		DCD		0				; SysTick vector
        			
; external interrupts (IRQs)
		        				
       		DCD		Timer_Handler	; IRQ #0 vector
       		DCD		0				; IRQ #1 vector
       		DCD		0				; IRQ #2 vector
       		DCD		0				; IRQ #3 vector
       		DCD		0				; IRQ #4 vector
       		DCD		0				; IRQ #5 vector
       		DCD		0				; IRQ #6 vector
       		DCD		0				; IRQ #7 vector
       		DCD		0				; IRQ #8 vector
       		DCD		0				; IRQ #9 vector
       		DCD		0				; IRQ #10 vector
       		DCD		0				; IRQ #11 vector
       		DCD		0				; IRQ #12 vector
       		DCD		0				; IRQ #13 vector
       		DCD		0				; IRQ #14 vector
        	DCD		0				; IRQ #15 vector
        			
			AREA |.text|, CODE, READONLY

Reset_Handler	PROC
			GLOBAL Reset_Handler
			ENTRY

			LDR		R1, =IRQ_enable_register	; enable IRQ #0 interrupts
			LDR		R0, =enable_IRQ0
			STR		R0, [R1]
				
			LDR		R1, =VGA_base_address		; write 'INT' to VGA text display
			LDR 	R2, =UART_base_address		; and to terminal attached to UART
				
			MOVS	R0, #'I'
			STR		R0, [R1]
			STR		R0, [R2]

			MOVS	R0, #'N'
			STR		R0, [R1]
			STR		R0, [R2]

			MOVS	R0, #'T'
			STR		R0, [R1]
			STR		R0, [R2]			
				
			LDR		R1, =GPIO_read_address		; R1 points to GPIO input (switches)
			LDR		R7, =GPIO_write_address		; R7 points to GPIO output (LEDs)

			; main (endless) loop of program
			;
			; In this example program, R1 and R7 must not be altered by any interrupt service routine (ISR).
			; In the Cortex M0, registers R0, R1, R2, R3, R12, R14 (LR), R15 (PC), and xPSR are automatically
			; preserved by stacking and unstacking operations during ISR entry and return.
			; These registers may be used/altered by the (ISR).
			; But if R7 is used/altered by the interrupt service routine, it will need explicitly to be stored
			; (PUSH) and restored (POP) at start and end of routine.
main_loop

			LDR		R0, [R1]				; read switches
			STR		R0, [R7]				; write to LEDs
				
			B		main_loop
				
			ENDP							; matches PROC at start of Reset_Handler
				
Timer_Handler	PROC
			EXPORT	Timer_Handler
				
			; Any registers other than R0, R1, R2, R3, R12, R14 (LR), R15 (PC), and xPSR
			; used/altered in this interrupt service routine must explicitly be stored (PUSH)
			; and restored (POP) at the start and end of the routine.
			;
			; In this example program it's been decided arbitrarily to use registers R6 and R7.
			; Consequently it's necessary to store and restore these (to/from the stack).
			; It's because R6 and R7 are used in the ISR that they are stored/restored,
			; not because they are used elsewhere. 

			PUSH	{R6, R7}				; save R6 and R7 as they are used
											; in this ISR
				
			; read the current timer value, and display its 16 MSBs as 4 hex digits
			; on the seven-segment display
				
			LDR		R6, =TIMER_base_address	; read 32-bit timer value into R7
			LDR		R7, [R6]

			LDR 	R2, =0x0F				; R2 used to mask off all but 4 LSBs

			LSRS	R0, R7, #16				; right shift R7 16 bits into R0		
			ANDS    R0, R0, R2				; mask all but 4 LSBs of R0
			LDR		R1, =SEVEN_SEG_DIGIT1	; display that 4-bit hex digit
			STR		R0, [R1]				; right most seven segment digit
			
			LDR		R3, =VGA_base_address
			MOVS	R5, #8
			STR		R5, [R3]
			MOVS		R6, #48
			MOVS		R5, R0
			ADD		R5, R5, R6
			STR		R5, [R3]
			
			LSRS	R0, R7, #20				; right shift R7 20 bits into R0
			ANDS    R0, R0, R2				; mask all but 4 LSBs of R0
			LDR		R1, =SEVEN_SEG_DIGIT2	; display that 4-bit hex digit
			STR		R0, [R1]				; right most but one seven segment digit

			LSRS	R0, R7, #24				; right shift R7 24 bits into R0		
			ANDS    R0, R0, R2				; mask all but 4 LSBs of R0
			LDR		R1, =SEVEN_SEG_DIGIT3	; display that 4-bit hex digit
			STR		R0, [R1]				; right most but two seven segment digit

			LSRS	R0, R7, #28				; right shift R7 28 bits into R0
			ANDS    R0, R0, R2				; mask all but 4 LSBs of R0
			LDR		R1, =SEVEN_SEG_DIGIT4	; display that 4-bit hex digit
			STR		R0, [R1]				; left most seven segment digit
				
			POP		{R6, R7}				; restore R6 and R7
			
			BX		LR						; return from interrupt service routine
;			MOV		PC, LR					; could use this alternative form of return from ISR

			ENDP							; matches PROC at start of Timer_Handler

			ALIGN 	4						; align to a word boundary

		END                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
   