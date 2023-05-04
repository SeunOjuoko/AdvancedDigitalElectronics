//////////////////////////////////////////////////////////////////////////////////
//END USER LICENCE AGREEMENT                                                    //
//                                                                              //
//Copyright (c) 2012, ARM All rights reserved.                                  //
//                                                                              //
//THIS END USER LICENCE AGREEMENT ("LICENCE") IS A LEGAL AGREEMENT BETWEEN      //
//YOU AND ARM LIMITED ("ARM") FOR THE USE OF THE SOFTWARE EXAMPLE ACCOMPANYING  //
//THIS LICENCE. ARM IS ONLY WILLING TO LICENSE THE SOFTWARE EXAMPLE TO YOU ON   //
//CONDITION THAT YOU ACCEPT ALL OF THE TERMS IN THIS LICENCE. BY INSTALLING OR  //
//OTHERWISE USING OR COPYING THE SOFTWARE EXAMPLE YOU INDICATE THAT YOU AGREE   //
//TO BE BOUND BY ALL OF THE TERMS OF THIS LICENCE. IF YOU DO NOT AGREE TO THE   //
//TERMS OF THIS LICENCE, ARM IS UNWILLING TO LICENSE THE SOFTWARE EXAMPLE TO    //
//YOU AND YOU MAY NOT INSTALL, USE OR COPY THE SOFTWARE EXAMPLE.                //
//                                                                              //
//ARM hereby grants to you, subject to the terms and conditions of this Licence,//
//a non-exclusive, worldwide, non-transferable, copyright licence only to       //
//redistribute and use in source and binary forms, with or without modification,//
//for academic purposes provided the following conditions are met:              //
//a) Redistributions of source code must retain the above copyright notice, this//
//list of conditions and the following disclaimer.                              //
//b) Redistributions in binary form must reproduce the above copyright notice,  //
//this list of conditions and the following disclaimer in the documentation     //
//and/or other materials provided with the distribution.                        //
//                                                                              //
//THIS SOFTWARE EXAMPLE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ARM     //
//EXPRESSLY DISCLAIMS ANY AND ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING     //
//WITHOUT LIMITATION WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR //
//PURPOSE, WITH RESPECT TO THIS SOFTWARE EXAMPLE. IN NO EVENT SHALL ARM BE LIABLE/
//FOR ANY DIRECT, INDIRECT, INCIDENTAL, PUNITIVE, OR CONSEQUENTIAL DAMAGES OF ANY/
//KIND WHATSOEVER WITH RESPECT TO THE SOFTWARE EXAMPLE. ARM SHALL NOT BE LIABLE //
//FOR ANY CLAIMS, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, //
//TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE    //
//EXAMPLE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE EXAMPLE. FOR THE AVOIDANCE/
// OF DOUBT, NO PATENT LICENSES ARE BEING LICENSED UNDER THIS LICENSE AGREEMENT.//
//////////////////////////////////////////////////////////////////////////////////


;------------------------------------------------------------------------------------------------------
; Design and Implementation of an AHB Interrupt Mechanism  
; 1)Input characters from keyboard (UART) and output to the terminal (using interrupt)
; 2)A counter is incremented from 1 to 10 and displayed on the 7-segment display (using interrupt)
;------------------------------------------------------------------------------------------------------



; Vector Table Mapped to Address 0 at Reset

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
   