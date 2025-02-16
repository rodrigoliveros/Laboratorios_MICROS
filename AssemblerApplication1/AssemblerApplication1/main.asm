;-----------------------------------------------
; Universidad del Valle de Guatemala
; IE2023: Programacion de Microcontroladores
; Botones_y_Timer0.asm
; Autor: Ian Anleu Rivera
; Proyecto: Laboratorio 2
; Hardware: ATMEGA328P
; Creado: 05/02/2024
; Ultima modificacion: 06/02/2024
;-----------------------------------------------

.include "M328PDEF.INC" ; Nombres de Registros
.cseg

.org 0x00 ; Vector Reset

;-----------------------------------------------
; Stack Pointer

	LDI R16, LOW(RAMEND) ; Funcion LOW da la parte baja
	OUT SPL, R16
	LDI R16, HIGH(RAMEND) ; Funcion HIGH da la parte alta
	OUT SPH, R16

;-----------------------------------------------
; Configuracion

Setup:
	; Clock en 2MHz
	LDI R16, 0b1000_0000 
	STS CLKPR, R16 ; Habilitar prescaler
	LDI R16, 0b0000_0011
	STS CLKPR, R16  ; 0011 es Divisor entre 8 para 2MHz	
	
	; Timer0
	CALL Setup_Timer ; Llama a inicializar el Timer0

	; Entradas (PORTB a Buttons)
	LDI R16, 0xFF
	LDI R17, 0x00
	OUT DDRB, R17 ; Configura todos de PORTB a Entradas
	OUT PORTB, R16 ; Configurar todos Pull-Up

	; Salidas (PORTD y PORTC a LEDs)
	OUT DDRD, R16 ; Configura PORTD a Salida
	OUT DDRC, R16 ; Configura PORTC a Salida
	STS UCSR0B, R17 ; Deshabilita USART en D

	; Registros adicionales
	; R16 será multiusos
	LDI R17, 0xFF ; R17 Estados previos
	; R18 Estado de B
	; R19 Contador Timer0
	; R20 Contador 7seg
	; R21 Contador secundario 1s
	; R22 LED Alerta
	; R23 Reg de Combinacion

;-----------------------------------------------
; LOOP de flash memory

Loop:	
	IN R16, TIFR0 ; Cargar valor de Timer 
	CPI R16, (1<<TOV0) ; Se compara la posicion de bandera de overflow en el timer
	BRNE Verif7seg 
	
	; Contador Binario 4 bits ----------------------------------------------------
	INC R21 ; Al momento en que cambia, incremento el contador R21
	CPI R21, 10 ; Compara si el Timer0 ha pasado 10 ciclos (100ms*10)
	BRNE ResT1 ; Si no han pasado 10 ciclos, salto hasta el Reset de Timer0
	; Si ya paso 1 segundo
	LDI R21, 0x00 ; Reset de R21 
	INC R19 ; Incremento del contador Binario
	ANDI R19, 0x0F ; Y limpio el nibble más alto
	MOV R23, R22 ; Copio la alerta de LED al R de comb
	OR R23, R19 ; Combino Alerta LED con Contador 
	OUT PORTC, R23 ; Despliego la combinacion en PORTC

	; Reset de Timer0 ------------------------------------------------------------
ResT1: ; Simple label para poder skippear a esta posición
	CALL Res_Timer
	SBI TIFR0, TOV0 ; Para borrar bandera, set bandera en TIFR0
	
	; Contador Hexadecimal 7 SEG -------------------------------------------------
Verif7seg:
	; Antirrebote de PinB
	IN R18, PINB
	; Ya tengo estados previos en R19
	CP R17, R18 ; Comparo los estados actual y previo por algun cambio
	BREQ Modif7seg ; Si no han cambiado, voy a desplegar el resultado actual
	CALL Antirrebote
	IN R18, PINB
	CP R17, R18 ; Comparo los estados actual y previo por algun cambio
	BREQ Loop ; Si no han cambiado, mantengo el loop
	; Si cambiaron
	MOV R17, R18 ; Modifico el estado actual y

	CALL Contador7Seg ; Verifico operaciones del contador del 7 seg

	ANDI R20, 0x0F ; Limpio el nibble mayor del contador R20

Modif7seg:
	LDI ZH, HIGH(Tabla7seg<<1)
	LDI ZL, LOW(Tabla7seg<<1) ; Puntero Z siempre apuntará a la Tabla
	ADD ZL, R20 ; Añadir el valor del contador R20 al puntero Z para obtener la salida en PORTD
	LPM R16, Z ; Copia el valor guardado en el nuevo Z
	OUT PORTD, R16 ; Modifico el 7 segmentos en PORTD

	; Comparación de R21 y R20 ------------------------------------------
CompConts: 
	CP R19, R20 ; Compara el contador de segundos y el del 7Seg
	BRNE Loop ; Si no son iguales vuelve al loop
	LDI R19, 0x00 ; De ser iguales: Resetea el C.segundos
	LDI R21, 0x00 ; Resetea el C.Timer0
	SWAP R22 ; Revierte R22 a su estado original
	INC R22 ; Y modifica el registro de alerta LED
	ANDI R22, 0X01 ; Limpia los bits que no sean el primero 
	SWAP R22 ; Y devuelve al nibble alto

	RJMP Loop ; Vuelve a Loop

;-----------------------------------------------
; Subrutinas
;-----------------------------------------------

Setup_Timer:
	; Como se usa el modo normal, no se necesita configurar TCCR0A
	LDI R16, 0b0000_0101 ; Prescaler de timer0 en 1024
	OUT TCCR0B, R16
Res_Timer:
	LDI R16, 61 ; Desbordamiento (TCNT0) segun calculadora
	OUT TCNT0, R16 ; Aprox 99.84ms
	RET

;-------------------------------------------------

Antirrebote:
	LDI R16, 100 ; 100 Ciclos entre lecturas
Delay:
	DEC R16 ; Disminuye el contador
	CPI R16, 0x00 ; Compara Contador con 0
	BRNE Delay ; Vuelve a Delay si no son iguales
	RET

;-----------------------------------------------

Contador7seg:
; CONTADOR R20
Aumentar:
	SBRC R18, PB0 ; Determino si el boton de aumentar esta presionado 
	RJMP Decrementar ; De no estar presionado, verifico el otro botón
	INC R20 ; De estar presionado, aumento contador R20

Decrementar:
	SBRC R18, PB1 ; Determino si el boton de decrementar esta presionado 
	RET ; De no estar presionado, vuelvo al CALL
	DEC R20 ; De estar presionado, disminuyo contador R20
	
	RET

;-----------------------------------------------
; Tabla de Valores para 7seg
Tabla7seg: .db 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90, 0x88, 0x83, 0xC6, 0xA1, 0x86, 0x8E
