 ;*****************************************

;

; TM1637 + Tiny24 8MHz

; CLK = PA3

; DIO = PA1

; Отображение в старших разрядах надписи "123"

; и необработанного байта состояния клавиатуры в 4-м разряде

;

;*******************************************

.include "tn13def.inc"

;****** РЕГИСТРЫ

.def tmp0 =r16

.def tmp1 =r17

.def tmp2 =r18

.def tmp3 =r19

;****** БИТЫ

.equ CLK =0x03 ;

.equ DIO =0x01 ;

 

rjmp RESET ; Reset Handler

;rjmp EXINT ; IRQ0 Handler

rjmp INT0 ; PCINT0 Handler

rjmp INT1 ; PCINT1 Handler

rjmp WD0 ; Watchdog Interrupt Handler

rjmp TIM1_CAPT ; Timer1 Capture Handler

rjmp TIM1_COMPA ; Timer1 Compare A Handler

rjmp TIM1_COMPB ; Timer1 Compare B Handler

rjmp TIM1_OVF ; Timer1 Overflow Handler

rjmp TIM0_COMPA ; Timer0 Compare A Handler

rjmp TIM0_COMPB ; Timer0 Compare B Handler

rjmp TIM0_OVF ; Timer0 Overflow Handler

rjmp ANA_COMP ; Analog Comparator Handler

rjmp ADCHN ; ADC Conversion Handler

rjmp EE_RDY ; EEPROM Ready Handler

rjmp USI_STR ; USI STart Handler

rjmp USI_OVF ; USI Overflow Handler

 

RESET: ldi tmp1, low(RAMEND)

out SPL,tmp1

 

ldi tmp0,0xFF ;

out ddra,tmp1 ;весь porta как выход

out porta,tmp1 ;всем 1

 

;***************************************************

;***************************************************

LOOP:

;инициализация

rcall start ;маркер начала посылки

ldi tmp0,0x88 ;включение дисплея. Яркость минимальная.

rcall outcom ;вывожу команду

rcall end ;маркер конца посылки

 

rcall pause ;пауза 100 мкс

;включение режима передачи данных с автоинкрементом адреса

rcall start ;маркер начала посылки

ldi tmp0,0x40 ;режим передачи данных с автоинкрементом адреса

rcall outcom ;вывожу команду

rcall end ;маркер конца посылки

 

rcall pause ;пауза 100 мкс

;вывод сообщения "123" на табло

rcall start ;маркер начала посылки

ldi tmp0,0xC0 ;УСТАНОВКА НАЧАЛЬНОГО АДРЕСА (0хC0 - крайнее левое знакоместо)

rcall outcom ;вывожу адрес

ldi tmp0,0x06 ;1 в первый разряд

rcall outcom ;вывожу данные

ldi tmp0,0x5b ;2 во второй разряд

rcall outcom ;вывожу данные

ldi tmp0,0x4f ;3 в третий разряд

rcall outcom ;вывожу данные

rcall end ;маркер конца посылки

rcall pause ;пауза 100 мкс

 

;чтение клавиатуры

rcall start ;маркер начала посылки

ldi tmp0,0x42 ;режим чтения клавиатуры

rcall outcom ;вывожу команду

rcall incom ;получаю данные

rcall end ;маркер конца посылки

 

mov tmp2,tmp0 ;сохраняю данные клавиатуры в tmp2

 

;включение режима передачи данных с фиксированным адресом

rcall start ;маркер начала посылки

ldi tmp0,0x44 ;режим передачи данных с фиксированным адресом

rcall outcom ;вывожу команду

rcall end ;маркер конца посылки

;вывод необработанного байта состояния клавиатуры в четвертый разряд табло

rcall pause ;пауза 100 мкс

rcall start ;маркер начала посылки

ldi tmp0,0xC3 ;УСТАНОВКА АДРЕСА (0хC3 - четвертое знакоместо)

rcall outcom ;вывожу адрес

mov tmp0,tmp2 ;восстанавливаю в tmp0 сохранённые данные клавиатуры

rcall outcom ;вывожу данные

rcall end ;маркер конца посылки

 

rjmp LOOP

;***********************************

start: ;маркер начала посылки

rcall pause ;пауза 100 мкс

sbi porta,clk ;

sbi porta,dio ;

rcall pause ;пауза 100 мкс

cbi porta,dio ;

rcall pause ;пауза 100 мкс

ret

;***********************************

end: ;маркер конца посылки

sbi porta,clk ;

rcall pause ;пауза 100 мкс

sbi porta,dio ;

rcall pause ;пауза 100 мкс

ret

;***********************************

outcom: ;последовательный вывод. выводимый байт должен находиться в tmp0

push tmp1

; вывод восьми битов регистра tmp0

ldi tmp1,0x08 ;

outc10: cbi porta,clk ;опускаю CLK

rcall pause ;пауза 100 мкс

 

lsr tmp0 ; \

brcc outc20 ; |

sbi porta,dio ; > младший бит tmp0 выставляю на DIO

rjmp outc30 ; |

outc20: cbi porta,dio ; /

 

outc30: rcall pause ;пауза 100 мкс

sbi porta,clk ;поднимаю CLK

rcall pause ;пауза 100 мкс

dec tmp1 ;

brne outc10 ;последовательно вывожу весь байт

; стоп-бит

cbi ddra,dio ;переключаю DIO как вход, чтобы исключить коллизию с ACK

cbi porta,clk ;опускаю CLK

rcall pause ;пауза 100 мкс

sbi porta,clk ;поднимаю clk

rcall pause ;пауза 100 мкс

cbi porta,clk ;опускаю CLK

cbi porta,dio ;

sbi ddra,dio ;окончание стоп-бита, переключаю DIO как выход

; (выхожу с нулями на обеих шинах)

rcall pause ;пауза 100 мкс

pop tmp1 ;

ret ;

 

;********************************

incom: ;Чтение кнопок. выходные данные будут в tmp0

push tmp1

clr tmp0 ;

;последовательный ввод восьми битов в tmp0

ldi tmp1,0x08 ;

inc10: cbi porta,clk ;опускаю CLK

cbi ddra,dio ;переключение линии DIO как входа

sbi porta,dio ;включаю подтяжку DIO

rcall pause ;пауза 100 мкс

sbi porta,clk ;поднимаю CLK

rcall pause ;пауза 100 мкс

lsr tmp0 ;

sbr tmp0,0x80 ;\

sbis pina,dio ; >перенос пина DIO в tmp0

cbr tmp0,0x80 ;/

dec tmp1 ;

brne inc10 ;последовательно ввожу весь байт

 

rcall pause ;пауза 100 мкс

cbi porta,clk ;

;стоп-бит

rcall pause ;пауза 100 мкс

sbi porta,clk ;девятый импульс CLK

rcall pause ;пауза 100 мкс

cbi porta,clk ;опускаю CLK

 

cbi porta,dio ;выключаю подтяжку DIO

sbi ddra,dio ;переключение линии DIO как выхода

; выход с нулями на о
