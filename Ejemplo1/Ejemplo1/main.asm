;
; Ejemplo1.asm
;
; Created: 24/01/2025 18:38:57
; Author : rodri
;

LDI R16, 0xF0
OUT PORTD, R16
; Replace with your application code
start:
    inc r16
    rjmp start

