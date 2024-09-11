;
;
; In this example used a cheap China 4-digit display 
; managed by TM1637 microchip, available at Aliexpress a lot.
;
; How to code displaying information
;
; In order to display some information call TM1637_display and fill registers
; TM1637_d1 .. TM1637_d4 with letters, that are coded next way:
;         0
;       +---+
;     5 | 6 | 1
;       +---+
;     4 |   | 2
;       +---+
;         3
; 
; Here the ordering numers is the bits layout in letters that to be passed to the called function.
; Number one coded as 0b00000110
; Number two coded as 0b01011011
; So this way, use bit=1 for diods to be burnt and bit=0 for bits that to be off.
;
;
; Output hex file size is only 196 bytes. Not bad. I made it for ATtiny13.
;
#define  F_CPU      1200000
.INCLUDE "tn13def.inc"
.def reg_1        = r16
.def reg_2        = r17
.def reg_3        = r18
.def reg_4	      = r19

.def TM1637_d1    = r20
.def TM1637_d2    = r21
.def TM1637_d3    = r22
.def TM1637_d4    = r23

.equ TM1637_CLK   = PB3
.equ TM1637_DATA  = PB4


.MACRO TM1637_init
    sbi DDRB, TM1637_CLK
    sbi DDRB, TM1637_DATA
.ENDMACRO


prg_entry_point:
    ldi reg_1, low(RAMEND) 
    out SPL, reg_1

	sbi DDRB, PINB0
	cbi PORTB, PINB0

    TM1637_init

main_loop:

    ldi TM1637_d1, 0b01111001	; 'H'
    ldi TM1637_d2, 0b01110110	; 'E'
    ldi TM1637_d3, 0b00111000	; 'L'
    ldi TM1637_d4, 0b00111111	; 'O'
    rcall TM1637_display

	rcall util_delay_1s

    ldi TM1637_d1, 0b01000000	; '-'
    ldi TM1637_d2, 0b01111100	; 'b'
    ldi TM1637_d3, 0b01101110	; 'Y'
    ldi TM1637_d4, 0b01111001   ; 'E'
    rcall TM1637_display

	rcall util_delay_1s

    rjmp main_loop
;
; End main loop
;

; Display something useful on a display
; params: TM1637_d1..TM1637_d4 should contain letters for output
; All four digits to be filled before calling this function. In this demo
; you cannot display a single letter, only all four ones at once.
TM1637_display:
    rcall TM1637_start
    ldi reg_1, 0x40
    rcall TM1637_writeByte
    rcall TM1637_stop
    rcall TM1637_start
    ldi reg_1, 0xC0
    rcall TM1637_writeByte

	mov reg_1, TM1637_d1
    rcall TM1637_writeByte

    mov reg_1, TM1637_d2
    rcall TM1637_writeByte

    mov reg_1, TM1637_d3
    rcall TM1637_writeByte

    mov reg_1, TM1637_d4
    rcall TM1637_writeByte

    rcall TM1637_stop
    rcall TM1637_start
    ldi reg_1, 0x89   					;яркость 0x88 min, 0x8F max
    rcall TM1637_writeByte
    rcall TM1637_stop
    ;nop
    ldi reg_1, 5
    rcall TM1637_delay
    ret


; Expected byte in reg_1
; reg_1 contains a char to be written is to be passed as an argument of the call
; used temp registers: reg_1, reg_2, reg_3
; params: reg_1 - incoming char (8-bit) that to be sent out
TM1637_writeByte:
    ldi reg_2, 8
TM1637_writeByte_1:
    cbi PORTB, TM1637_CLK

; starting if condition
    mov reg_3, reg_1
    cbr reg_3, 0xfe
    cpi reg_3, 0x01
    brne TM1637_writeByte_send_low

TM1637_writeByte_send_high:
    sbi PORTB, TM1637_DATA
    rjmp TM1637_writeByte_sync

TM1637_writeByte_send_low:
    cbi PORTB, TM1637_DATA 
    rjmp TM1637_writeByte_sync

TM1637_writeByte_sync:
    nop
    lsr reg_1 
    sbi PORTB, TM1637_CLK                    ; to be fixed, it is not correct
    nop

    dec reg_2
    cpi reg_2, 0                            ; end of 8-bit loop
    brne TM1637_writeByte_1


    cbi PORTB, TM1637_CLK
    nop
    cbi DDRB, TM1637_DATA

TM1637_writeByte_wait_ACK:
    sbic PINB, TM1637_DATA
    rjmp TM1637_writeByte_wait_ACK          ; wait for acknowledgment
    
    sbi DDRB, TM1637_DATA
    sbi PORTB, TM1637_CLK
    nop
    cbi PORTB, TM1637_CLK
    ret


; pass reg_1 number of null cycles
TM1637_delay:
    dec reg_1
    nop
    cpi reg_1, 0
    brne TM1637_delay
    ret

TM1637_start:
    sbi PORTB, TM1637_CLK
    sbi PORTB, TM1637_DATA
    nop
    cbi PORTB, TM1637_DATA
    ret


TM1637_stop:
    cbi PORTB, TM1637_CLK
    nop
    cbi PORTB, TM1637_DATA
    nop
    sbi PORTB, TM1637_CLK
    nop 
    sbi PORTB, TM1637_DATA
    ret


util_delay_1s:
    ldi  r18, 7
    ldi  r19, 23
    ldi  r20, 106
L1_1s: 
	dec  r20
    brne L1_1s
    dec  r19
    brne L1_1s
    dec  r18
    brne L1_1s
    rjmp PC+1
	ret

	
