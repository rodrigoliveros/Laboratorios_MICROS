;
; pruebapb2.asm
;
; Created: 9/02/2025 12:08:25
; Author : rodri
;


; Replace with your application code	; CONFIGURAR PB2 COMO SALIDA
	; CONFIGURAR PB2 COMO SALIDA
	; CONFIGURAR PB2 COMO SALIDA
	LDI		R16, (1 << PB2)  
	OUT		DDRB, R16  ; PB2 EN MODO SALIDA

LOOP:
	; ENCENDER LED EN PB2
	LDI		R16, (1 << PB2)
	OUT		PORTB, R16  

	; RETARDO (DUPLICADO)
	RCALL	DELAY  

	; APAGAR LED EN PB2
	LDI		R16, 0x00
	OUT		PORTB, R16  

	; RETARDO (DUPLICADO)
	RCALL	DELAY  

	RJMP	LOOP   ; REPITE EL CICLO

; --------------------------
; SUBRUTINA DE RETARDO (DOBLE DURACI�N)
; --------------------------
DELAY:
	LDI		R18, 255
	LDI		R19, 255
DELAY_LOOP:
	DEC		R19
	BRNE	DELAY_LOOP
	DEC		R18
	BRNE	DELAY_LOOP
	RET
