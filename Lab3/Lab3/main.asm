;
; Lab3.asm
;
; Created: 18/02/2025 09:10:47
; Author : rodri
; Definiciones de registros y constantes
.include "M328PDEF.inc"  ; Incluir definiciones para el ATmega328P

;GLOSARIO
;R16 = Registro variable
;R17 = Registro para el contador
;R18 = Bandera para antirrebote

; Vectores de interrupción
.org 0x0000
    RJMP        SETUP           ; Reset
.org PCI0addr					; Vector de interrupción para PCINT0 (Puerto B)
    RJMP        PCINT0_ISR      ; Saltar a la rutina de interrupción
.org OVF0addr					; Vector de interrupción para Timer0 Overflow
    RJMP        TIMER0_OVF_ISR  ; Saltar a la rutina de interrupción del Timer0

; Rutina de reset
SETUP:
    ; Configurar el stack pointer
    LDI         R16, HIGH(RAMEND)
    OUT         SPH, R16
    LDI         R16, LOW(RAMEND)
    OUT         SPL, R16

    ; Configurar Puerto C como salida (LEDs)
    LDI         R16, 0x0F       ; PC0-PC3 como salida
    OUT         DDRC, R16

    ; Configurar Puerto B como entrada (Botones)
    LDI         R16, 0x00       ; PB0-PB1 como entrada
    OUT         DDRB, R16

    ; Habilitar pull-ups internos en PB0 y PB1
    LDI         R16, (1 << PB0) | (1 << PB1)
    OUT         PORTB, R16

    ; Habilitar interrupciones on-change para PB0 y PB1
    LDI         R16, (1 << PCINT0) | (1 << PCINT1)
    STS         PCMSK0, R16

    ; Habilitar interrupciones de cambio en Puerto B
    LDI         R16, (1 << PCIE0)
    STS         PCICR, R16

    ; Configurar Timer0 para antirrebote (20 ms)
    LDI         R16, (1 << CS02) | (1 << CS00) ; Prescaler de 1024
    OUT         TCCR0B, R16
    LDI         R16, (1 << TOIE0)              ; Habilitar interrupción por overflow
    STS         TIMSK0, R16

    ; Inicializar el contador y la bandera de antirrebote
    CLR         R17
    CLR         R18
    OUT         PORTC, R17   ; Mostrar el valor inicial en los LEDs

    ; Habilitar interrupciones globales
    SEI

;MAIN
MAIN_LOOP:
    RJMP        MAIN_LOOP       

; Rutina de interrupción para PCINT0
PCINT0_ISR:
    ; Guardar el estado de los registros
    PUSH        R16
    IN          R16, SREG
    PUSH        R16

    ; Activar la bandera de antirrebote y reiniciar el Timer0
    LDI         R18, 1
    CLR         R16
    OUT         TCNT0, R16      ; Reiniciar el Timer0

    ; Restaurar el estado de los registros
    POP         R16
    OUT         SREG, R16
    POP         R16
    RETI

; Rutina de interrupción para Timer0 Overflow
TIMER0_OVF_ISR:
    ; Guardar el estado de los registros
    PUSH        R16
    IN          R16, SREG
    PUSH        R16

    ; Verificar si la bandera de antirrebote está activa
    SBRC        R18, 0
    RCALL       CHECK

    ; Restaurar el estado de los registros
    POP         R16
    OUT         SREG, R16
    POP         R16
    RETI

; Subrutina para verificar los botones después del antirrebote
CHECK:
    ; Leer el estado de los botones
    IN          R16, PINB

    ; Verificar si PB0 (Incrementar) está presionado
    SBIS        PINB, PB0
    RCALL       INCREMENTAR

    ; Verificar si PB1 (Decrementar) está presionado
    SBIS        PINB, PB1
    RCALL       DECREMENTAR

    ; Desactivar la bandera de antirrebote
    CLR         R18
    RET

; Subrutina para incrementar el contador
INCREMENTAR:
    INC         R17          ; Incrementar el contador
    ANDI        R17, 0x0F   
    OUT         PORTC, R17   ; Mostrar el valor en los LEDs
    RET

; Subrutina para decrementar el contador
DECREMENTAR:
    DEC         R17          ; Decrementar el contador
    ANDI        R17, 0x0F   
    OUT         PORTC, R17   ; Mostrar el valor en los LEDs
    RET