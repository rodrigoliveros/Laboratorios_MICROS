/*
 * ADC.c
 *
 * Created: 7/04/2025 12:15:31
 *  Author: rodri
 */ 
#include "ADC.h"

void SETUPADC(void){
	//Deshabilitar el (PC4-PC5) para iniciar lectura ADC
	DIDR0 = 0;
	DIDR0 = (1 << ADC5D) | (1 << ADC4D);
	//Configuración inicial de ADC
	ADMUX = 0;
	ADMUX |= (1<<REFS0)|(1<<ADLAR); //Vcc ref (5V), 8 bits resolucion | Mux ADC6
	ADCSRA = 0;
	ADCSRA |= (1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0); //Hab.Interrupción | Presc. 128 (125kHz)
	ADCSRA |= (1<<ADEN); // Enable
}
