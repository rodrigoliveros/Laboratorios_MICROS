/*
 * ADC.c
 *
 * Created: 7/04/2025 12:15:31
 *  Author: rodri
 */ 
#include "ADC.h"

void SETUPADC(void){
	//Deshabilitar el PC5 para iniciar lectura ADC
	DIDR0 = 0;
	DIDR0 = (1 << ADC5D);
	//Configuración inicial de ADC
	ADMUX = 0;
	ADMUX |= (1<<REFS0)|(1<<ADLAR)|(1<<MUX2)|(1<<MUX1)|(1<<MUX0); //Vcc ref (5V), 8 bits resolucion | Mux ADC7
	ADCSRA = 0;
	ADCSRA |= (1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0); //Hab.Interrupción | Presc. 128 (125kHz)
	ADCSRA |= (1<<ADEN); // Enable
}
