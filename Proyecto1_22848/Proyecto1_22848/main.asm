;
; Proyecto1_22848.asm
;
; Created: 10/03/2025 10:52:25
; Author : rodri

; Definiciones de registros y constantes
.include "M328PDEF.inc"  ; Incluir definiciones para el ATmega328P

.equ	T0VALUE		=	100
.equ	MODOS		=	8
.equ	MAX_UMIN	=	10
.equ	MAX_DMIN	=	6
.equ	MAX_UHOR	=	10
.equ	MAX_DHOR	=	3
.def	MODO		=	R20
.def	MOSTRAR		=	R21
; Definici�n de variables en RAM
.dseg
.org	SRAM_START //0x0100
SFLAG:	.byte	1
USEG:	.byte	1
DSEG:   .byte	1
UMIN:	.byte	1
DMIN:	.byte	1
UHOR:	.byte	1
DHOR:	.byte	1

; Vectores de interrupci�n
.cseg
.org 0x0000
    RJMP        SETUP           ; Reset
.org PCI1addr					; Vector de interrupci�n para PCINT1 (Puerto C)
    RJMP        PCINT1_ISR      ; Saltar a la rutina de interrupci�n
.org OVF0addr					; Vector de interrupci�n para Timer0 Overflow
    RJMP        TIMER0_OVF_ISR  ; Saltar a la rutina de interrupci�n del Timer0

; Rutina de reset
SETUP:
    ; Configurar el stack pointer
    LDI         R16, HIGH(RAMEND)
    OUT         SPH, R16
    LDI         R16, LOW(RAMEND)
    OUT         SPL, R16

    ; Configurar Puerto C como entrada (PC0-PC3) y salida (PC4-PC5)(LEDs)
    LDI         R16, 0xF0       ; PC0-PC3 como entrada y PC4-PC5 como salida
    OUT         DDRC, R16
	
    ; Habilitar pull-ups internos en PC0-PC2
    LDI         R16, (1 << PC0) | (1 << PC1) | (1 << PC2) 
    OUT         PORTC, R16
	
    ; Configurar interrupciones on-change para PC0-PC2
    LDI         R16, (1 << PCINT8) | (1 << PCINT9) | (1 << PCINT10)
    STS         PCMSK1, R16

    ; Habilitar interrupciones de cambio en Puerto C
    LDI         R16, (1 << PCIE1)
    STS         PCICR, R16

	; Configurar Puerto D como salida (PORTD (7 segmentos))
	LDI			R16, 0xFF
	OUT			DDRD, R16 ; PORTD SALIDAS
	
    ; Desactivar comunicaci�n UART
    LDI			R16,	0x00
    STS			UCSR0B,	R16			; Desactivar TX y RX

    ; Configurar Puerto B como salida (Transistores y Alarma)
    LDI         R16, 0xFF       ; PB0-PB4
    OUT         DDRB, R16

    ; Configurar Timer0  (10 ms)
    LDI         R16, (1 << CS02) | (1 << CS00) ; Prescaler de 1024
    OUT         TCCR0B, R16
    LDI         R16, (1 << TOIE0)              ; Habilitar interrupci�n por overflow
    STS         TIMSK0, R16
	LDI			R16, T0VALUE
	OUT			TCNT0, R16
	
	; Tabla de conversi�n para display de 7 segmentos (c�todo com�n)
	TABLA7SEGM: .db 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F

	; Inicializar variables

	; Registros R0 -R31
	CLR			MODO
	CLR			MOSTRAR

	; Registros RAM
	LDI			R16, 0x00
	STS			UMIN, R16
	STS			DMIN, R16
	STS			UHOR, R16
	STS			DHOR, R16
	STS			USEG, R16
	STS			DSEG, R16
	STS			SFLAG, R16


    ; Habilitar interrupciones globales
    SEI

;MAIN
MAIN_LOOP:
	
	OUT		PORTD, MOSTRAR	
	CPI		MODO, 0
	BRNE	SIGUIENTE1
	JMP		S_HORA  
	SIGUIENTE1:
	CPI		MODO, 1
	BRNE	SIGUIENTE2
	JMP		S_FECHA
	SIGUIENTE2:
	CPI		MODO, 2
	BRNE	SIGUIENTE3
	JMP		M_HORA_MIN
	SIGUIENTE3:
	CPI		MODO, 3
	BRNE	SIGUIENTE4
	JMP		M_HORA_HOR
	SIGUIENTE4:
	CPI		MODO, 4
	BRNE	SIGUIENTE5
	JMP		M_FECHA_MES
	SIGUIENTE5:
	CPI		MODO, 5
	BRNE	SIGUIENTE6
	JMP		M_FECHA_DIA
	SIGUIENTE6:
	CPI		MODO, 6
	BRNE	SIGUIENTE7
	JMP		M_ALARM_MIN
	SIGUIENTE7:
	CPI		MODO, 7
	BRNE	FIN
	JMP		M_ALARM_HORA
	FIN:


;Subrutinas de estado
S_HORA:							; LEDS |-|0|
	SBI			PORTC, PC5 
	CBI			PORTC, PC4
	; Menu de intercambio para displays
	LDS			R16, SFLAG
	CPI			R16, 0
	BREQ		COM1
	CPI			R16, 1
	BREQ		COM2
	CPI			R16, 2
	BREQ		COM3
	CPI			R16, 3
	BREQ		COM4

	COM1:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la direcci�n de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la direcci�n de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la direcci�n de la tabla
		LDS			R16, UMIN
		ADD         ZL, R16								; A�adir el valor de UMIN a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB0
		RJMP		MAIN_LOOP
	COM2:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la direcci�n de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la direcci�n de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la direcci�n de la tabla
		LDS			R16, DMIN
		ADD         ZL, R16								; A�adir el valor de DMIN a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB1
		RJMP		MAIN_LOOP
	COM3:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la direcci�n de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la direcci�n de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la direcci�n de la tabla
		LDS			R16, UHOR
		ADD         ZL, R16								; A�adir el valor de UHOR a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB2
		RJMP		MAIN_LOOP
	COM4:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la direcci�n de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la direcci�n de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la direcci�n de la tabla
		LDS			R16, DHOR
		ADD         ZL, R16								; A�adir el valor de DHOR a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB3
		RJMP		MAIN_LOOP
S_FECHA:						; LEDS |0|-|
	LDI			MOSTRAR, 0x06
	CBI			PORTC, PC5
	SBI			PORTC, PC4
	RJMP		MAIN_LOOP
M_HORA_MIN:						; LEDS |-|0|
	LDI			MOSTRAR, 0x5B		
	SBI			PORTC, PC5
	CBI			PORTC, PC4
	RJMP		MAIN_LOOP
M_HORA_HOR:						; LEDS |-|0|
	LDI			MOSTRAR, 0x4F
	SBI			PORTC, PC5
	CBI			PORTC, PC4
	RJMP		MAIN_LOOP
M_FECHA_MES:					; LEDS |0|-|
	LDI			MOSTRAR, 0x66
	CBI			PORTC, PC5
	SBI			PORTC, PC4
	RJMP		MAIN_LOOP
M_FECHA_DIA:					; LEDS |0|-|
	LDI			MOSTRAR, 0x6D
	CBI			PORTC, PC5
	SBI			PORTC, PC4
	RJMP		MAIN_LOOP	
M_ALARM_MIN:					; LEDS |0|0|
	LDI			MOSTRAR, 0x7D
	SBI			PORTC, PC5
	SBI			PORTC, PC4
	RJMP		MAIN_LOOP
M_ALARM_HORA:					; LEDS |0|0|
	LDI			MOSTRAR, 0x07
	SBI			PORTC, PC5
	SBI			PORTC, PC4
	RJMP		MAIN_LOOP	   
; RUTINAS DE INTERRUPCI�N

; Rutina de interrupci�n para PCINT1
PCINT1_ISR:
    ; Guardar el estado de los registros
    PUSH        R16
    IN          R16, SREG
    PUSH        R16
	; Verificar si estamos en el modo m�ximo
	SBIS		PINC, PC0	; Verifico si el pin modo esta presionado "0"
	INC			MODO		
	LDI			R16, MODOS	; Modos es el valor m�ximo de modos
	CPSE		MODO, R16	; Si no son iguales ejecuta la siguiente linea
	RJMP		PC+2		; Salta dos lineas
	CLR			MODO
	; Revisar en que modo estamos
	CPI			MODO, 0
	BREQ		MODO0_ISR
	CPI			MODO, 1
	BREQ		MODO1_ISR
	CPI			MODO, 2
	BREQ		MODO2_ISR
	CPI			MODO, 3
	BREQ		MODO3_ISR
	CPI			MODO, 4
	BREQ		MODO4_ISR
	CPI			MODO, 5
	BREQ		MODO5_ISR
	CPI			MODO, 6
	BREQ		MODO6_ISR
	CPI			MODO, 7
	BREQ		MODO7_ISR
	RJMP		EXIT_PDINT1_ISR
    ; Restaurar el estado de los registros
	MODO0_ISR:
		//Relacionado con mostrar hora
		RJMP EXIT_PDINT1_ISR
	MODO1_ISR:
		//Relacionado con mostrar fecha
		RJMP EXIT_PDINT1_ISR
	MODO2_ISR:
		//Relacionado con configurar minutos
		RJMP EXIT_PDINT1_ISR
	MODO3_ISR:
		//Relacionado con configurar hora
		RJMP EXIT_PDINT1_ISR
	MODO4_ISR:
		//Relacionado con configurar meses
		RJMP EXIT_PDINT1_ISR
	MODO5_ISR:
		//Relacionado con configurar dias
		RJMP EXIT_PDINT1_ISR
	MODO6_ISR:
		//Relacionado con alarma minutos
		RJMP EXIT_PDINT1_ISR
	MODO7_ISR:
		//Relacionado con alarma horas
		RJMP EXIT_PDINT1_ISR
	EXIT_PDINT1_ISR:
    POP         R16
    OUT         SREG, R16
    POP         R16
    RETI

; Rutina de interrupci�n para Timer0 Overflow
TIMER0_OVF_ISR:
	; Guardar el estado de los registros
    PUSH        R16
    IN          R16, SREG
    PUSH        R16
	
	; Reiniciar TIMER0
	LDI			R16, T0VALUE
	OUT			TCNT0, R16
	
	; L�gica de Hora
	LDS			R16, SFLAG			; Aqu� alternamos la bandera SFLAG que nos servira para alternar entre los displays
	INC			R16
	CPI			R16, 4
	BRNE		RELOJ
	CLR			R16
	STS			SFLAG, R16
RELOJ:
	STS			SFLAG, R16
	LDS			R16, USEG
	INC			R16
	CPI			R16, 100			; Aqu� verificamos si ya pasaron 1000 ms
	BRNE		STORE_USEG
	CLR			R16
	STS			USEG, R16			; Ya paso 1 seg, borramos y guardamos valor
	LDS			R16, DSEG
	INC			R16
	CPI			R16, 60				; Verificamos si ya paso 60 seg
	BRNE		STORE_DSEG
	CLR			R16
	STS			DSEG, R16			; Paso 1 min, borramos y guardamos valor
	LDS			R16, UMIN
	INC			R16
	CPI			R16, MAX_UMIN		; Verificamos si pasaron 10 min
	BRNE		STORE_UMIN
	CLR			R16
	STS			UMIN, R16			; Ya pasaron 10 min, borramos y guardamos valor
	LDS			R16, DMIN
	INC			R16
	CPI			R16, MAX_DMIN		; Verificamos si pasaron 60 min
	BRNE		STORE_DMIN
	CLR			R16
	STS			DMIN, R16			; Ya pasaron 60 min, borramos y guardamos valor
	LDS			R16, DHOR
	CPI			R16, 2				; Verificamos si estamos por debajo de las 20 horas
	BRNE		HORA_NORMAL			; Si estamos por debajo, hacemos el overflow normal cada 10 horas
	LDS			R16, UHOR			; Si no estamos por debajo hacemos el overflow despues de 4 horas
	INC			R16
	CPI			R16, 4				; Verificamos si llegamos a las 24 horas
	BRNE		STORE_UHOR			; Si no hemos llegado, guardamos y seguimos contando
	CLR			R16					; Si llegamos, borramos y guardamos valor para UHORA y DHORA.
	STS			UHOR, R16
	STS			DHOR, R16
	RJMP		EXIT_TIMER0_ISR
	HORA_NORMAL:
	LDS			R16, UHOR	
	INC			R16
	CPI			R16, MAX_UHOR		; Verificamos si pasaron 10 horas
	BRNE		STORE_UHOR
	CLR			R16
	STS			UHOR, R16			; Ya pasaron 10 horas, borramos y guardamos valor
	LDS			R16, DHOR
	INC			R16		
	STS			DHOR, R16
	RJMP		EXIT_TIMER0_ISR



	; Rutinas de guardado 
STORE_USEG:
	STS			USEG, R16
	RJMP		EXIT_TIMER0_ISR
STORE_DSEG:
	STS			DSEG, R16
	RJMP		EXIT_TIMER0_ISR
STORE_UMIN:
	STS			UMIN, R16
	RJMP		EXIT_TIMER0_ISR
STORE_DMIN:
	STS			DMIN, R16
	RJMP		EXIT_TIMER0_ISR
STORE_UHOR:
	STS			UHOR, R16
	RJMP		EXIT_TIMER0_ISR
STORE_DHOR:
	STS			DHOR, R16
	RJMP		EXIT_TIMER0_ISR


EXIT_TIMER0_ISR:
	; Restaurar el estado de los registros

    POP         R16
    OUT         SREG, R16
    POP         R16
    RETI