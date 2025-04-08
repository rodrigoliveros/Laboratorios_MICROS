/*
 * Lab5_22848.c
 *
 * Created: 7/04/2025 11:22:10
 * Author : rodri
 */
 #define F_CPU 1600000 //Frecuencia de Reloj (Sistema)
 #include <avr/io.h>
 #include <stdint.h>
 #include <util/delay.h>
 #include <avr/interrupt.h>
//Librerias propias
 #include "PWM1/PWM1.h"
 #include "ADC/ADC.h"
//Variables
 const uint16_t t1_top = 311; //periodo de 20ms
 uint8_t valueadc = 0x00;
 uint8_t change = 0;
 
//Prototipos de función
void setup(void);

//MAIN
int main(void)
{
//Inicio del programa
cli();
//uint16_t dutyCycle = 7811;
setup();
SETUPADC();
OCR1A = 16; // 1 ms inicial (ángulo mínimo)
OCR1B = 16; // 1 ms inicial (24)(ángulo medio)
sei();

    /* Replace with your application code */
    while (1) 
    {
		ADCSRA |= (1 << ADSC);
		_delay_ms(100);
    }
}
void setup(void){
	CLKPR = (1 << CLKPCE);
	CLKPR = (1 << CLKPS2); // RELOJ DE 1Mhz
	initPWM1A(ninv,fastMode,t1_top,64);
	initPWM1B(ninv,fastMode,t1_top,64);
	DDRB	= 0;
	DDRB	|= (1 << DDB1)|(1 << DDB2);			// Configuración de (PB0-PB1) como salida PWM
}
ISR(ADC_vect){
	valueadc	= ADCH;
	ADCSRA		|= (1 << ADIF);
	// Mapeo del valor ADC (0-255) a OCR1x (16 a 31)
	uint8_t pulse_width = ((uint32_t)valueadc * (31 - 16)) / (255 + 16);
	if(change == 0){
		OCR1A = pulse_width;
		change = 1;
		//Cambio de Lectura ADC6
		ADMUX = 0;
		ADMUX |= (1 << REFS0)|(1 << ADLAR)|(1 << MUX2)|(1 << MUX1); // Vcc ref(5v), Resolución 8 bits, ADC6
	}//FIN ADC6
	else if(change == 1){
		OCR1B = pulse_width;
		change = 2;
		//Cambio de Lectura ADC7
		ADMUX = 0;
		ADMUX |= (1 << REFS0)|(1 << ADLAR)|(1 << MUX1)|(1 << MUX0); // Vcc ref(5v), Resolución 8 bits, ADC7
	}//FIN ADC7
	else {
		change = 0;
		//Cambio de Lectura ADC5
		ADMUX = 0;
		ADMUX |= (1 << REFS0)|(1 << ADLAR)|(1 << MUX2)|(1 << MUX0); // Vcc ref(5v), Resolución 8 bits, ADC5
	}//FIN ADC5
}