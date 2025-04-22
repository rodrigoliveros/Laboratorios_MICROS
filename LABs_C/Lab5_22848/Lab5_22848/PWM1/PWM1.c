/*
 * PWM0.c
 *
 * Created: 7/04/2025 11:45:05
 *  Author: rodri
 */ 
#include "PWM1.h"
void	initPWM1A(uint8_t invertido,uint8_t mode, uint8_t top_value, uint16_t prescaler)
{
	DDRB	= 0;
	DDRB	|= (1 << DDB1)|(1 << DDB2);			// Configuración de (PB1-PB2) como salida PWM
	ICR1	= top_value;						// Configurar valor de top
	TCCR1A	&= ~((1 << COM1A1)|(1 << COM1A0));	// Protección para solo configurar modo invert o no invert
	if(invertido == inv){
		TCCR1A |= (1 <<COM1A1)|(1 << COM1A0);	// Conf. Invertido
	} 
	else{
		TCCR1A |= (1 << COM1A1);				// Conf. No invertido
	}

	TCCR1A	&=	~((1 << WGM11)|(1 << WGM10));
	TCCR1B	&=	~((1 << WGM13)|(1 << WGM12));
	if(mode == fastMode){
		TCCR1A |= (1 << WGM11);
		TCCR1B |= (1 << WGM13)|(1 << WGM12);
	}
	else { //Phase correct
		TCCR1A |= (1 << WGM11);
		TCCR1B |= (1 << WGM13);
	}		
	//Switch-Case para diferentes prescalers
	TCCR1B	&= ~((1 << CS12)|(1 << CS11)|(1 << CS10));
	switch(prescaler){
		case 1:
				TCCR1B	|= (1 << CS10);
				break;
		case 8:
				TCCR1B	|= (1 << CS11);
				break;
		case 64:
				TCCR1B	|= (1 << CS11)|(1 << CS10);
				break;
		case 256:
				TCCR1B	|= (1 << CS12);
				break;
		case 1024:
				TCCR1B	|= (1 << CS12)|(1 << CS10);
				break;
		default:
				TCCR1B	|= (1 << CS10);
				break;			
	}// Fin de Switch-Case para prescaler
}// Fin InitPWM0A
