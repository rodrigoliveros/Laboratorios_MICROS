/*
 * Proyecto2_22848.c
 *
 * Created: 6/05/2025 12:44:16
 * Author : rodri
 */ 
// Utilidades
#define F_CPU 1600000 //Frecuencia de Reloj (Sistema)
#include <avr/io.h>
#include <stdint.h>
#include <util/delay.h>
#include <avr/interrupt.h>
// Librerias propias
#include "PWM1/PWM1.h"
#include "PWM12/PWM12.h"
#include "PWM0/PWM0.h"
#include "ADC/ADC.h"
#include "PWM02/PWM02.h"
// Variables
	// PWM
const uint16_t t1_top = 311; // Periodo de 20ms para PWM1(A,B)
	// ADC
uint8_t valueadc = 0x00;
uint8_t change = 0;
uint8_t	POT0 = 0;
uint8_t	POT1 = 0;
uint8_t	POT2 = 0;
uint8_t	POT3 = 0;
	// Aplicación
uint8_t state = 0;
// Prototipos de función
void SETUP(void);
void SETUPBUTTON(void);

// MAIN
int main(void)
{
	//Inicio del programa
	cli();
	SETUP();
	SETUPADC();
	OCR1A = 16;	// 1 ms inicial (ángulo mínimo)
	OCR1B = 16;	// 1 ms inicial (ángulo mínimo)
	OCR0A = 16;	// 1 ms inicial (ángulo mínimo)
	OCR0B = 16;	// 1 ms inicial (ángulo mínimo)
	sei();

	/* Replace with your application code */
	while (1)
	{
		switch(state){
			case 0:	// Control Manual de Servo motores
				ADCSRA |= (1 << ADSC);
				_delay_ms(10);
				break;
			case 1: // Control EEPROM de Servo motores
				break;
			case 2:	// Control ADAFRUIT de Servo motores
				break;
			default:
				break;
		}//Fin Switch Case
	}// Fin While
}// Fin main

// Funciones

void SETUP(void){
	// Configuración de salidas PWM
	DDRB	= 0;
	DDRB	|= (1 << DDB1)|(1 << DDB2);			// Configuración de (PB0-PB1) como salida PWM
	DDRD |= (1 << DDD6)|(1 << DDD5);			// Configuración de (PD5-PD6) como salida PWM
	// Configuración de reloj
	CLKPR = (1 << CLKPCE);
	CLKPR = (1 << CLKPS2); // RELOJ DE 1Mhz
	// Configuración de aplicación (Control de Servo motores)
	initPWM1A(ninv,fastMode,t1_top,64);
	initPWM1B(ninv,fastMode,t1_top,64);
	initPWM0A(ninv,64);
	initPWM0B(ninv,64);
}
void SETUPBUTTON(void){
	// Configuración de Pin Change
	PCICR	= 0;
	PCICR	|= (1 << PCIE1);	// Activamos la interrupcion del Puerto C
	PCMSK1	= 0;
	PCMSK1	|= (1 << PCINT10)|(1 << PCINT9)|(1 << PCINT8);		// Activamos interrupcion en (PC0-PC3), Leer, Guardar, Modo
}
ISR(PCINT1_vect){
	uint8_t modo = PINC;	// Almacenamos el valor del puerto
	switch(state){
		//	Modo manual ( Cambio de modo, Guardado)
		case 0:	// PC0: Cambiar modo | PC1: Guardar
			if(modo & (1 << DDC0)){
				state = 1; // Cambia a modo EEPROM (Lectura)
			} 
			if(modo & (1 << DDC1)) { //  Modo de guardardado
			// Ingresar aqui modo de guardado eeprom
			} 
		break;
		
		case 1: // PC0: Cambiar modo | PC2: Reproducir
			if(modo & (1 << DDC0)){
				state = 2;	// Cambia a modo Adafruit
			}
			if(modo & (1 << DDC2)){
				// Ingresar aqui modo de lectura de eeprom
			}
		break;
		
		case 2: // PC0: Cambiar modo 
			if(modo & (1 << DDC0)){
				state = 0;	// Cambia a modo manual
			}
		break;
	}// Fin de switch case de modo
}
ISR(ADC_vect){
	valueadc	= ADCH;
	ADCSRA		|= (1 << ADIF);
	// Mapeo del valor ADC (0-255) a OCR1x (16 a 31)
	uint8_t pulse_width = ((uint32_t)valueadc * (70 - 16)) / (255 + 16);
	// Cambio de lector ADC
	if(change == 0){
		ADMUX = 0;
		OCR1A = pulse_width;
		POT0  = pulse_width;
		change = 1;
		//Cambio de Lectura ADC7
		ADMUX |= (1 << REFS0)|(1 << ADLAR)|(1<<MUX2)|(1<<MUX1)|(1<<MUX0); // Vcc ref(5v), Resolución 8 bits, ADC7
		}//FIN ADC7
	
	else if(change == 1){
		ADMUX = 0;
		OCR1B = pulse_width;
		POT1  = pulse_width;
		change = 2;
		//Cambio de Lectura ADC6
		ADMUX |= (1 << REFS0)|(1 << ADLAR)|(1 << MUX2)|(1 << MUX1); // Vcc ref(5v), Resolución 8 bits, ADC6
		}//FIN ADC6
	
	else if(change == 2){
		ADMUX = 0;
		OCR0A = pulse_width;
		POT2  = pulse_width;
		change = 3;
		//Cambio de Lectura ADC5
		ADMUX |= (1 << REFS0)|(1 << ADLAR)|(1<<MUX2)|(1<<MUX0); // Vcc ref(5v), Resolución 8 bits, ADC5
		}//FIN ADC5
		
	else {
		ADMUX = 0; 
		OCR0B = pulse_width;
		POT3  = pulse_width;
		change = 0;	//Regresamos a lectura inicial
		//Cambio de Lectura ADC4
		ADMUX |= (1 << REFS0)|(1 << ADLAR)|(1<<MUX2); // Vcc ref(5v), Resolución 8 bits, ADC4
		}//FIN ADC4
}