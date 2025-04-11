/*
 * PWM12.c
 *
 * Created: 8/04/2025 15:46:01
 *  Author: rodri
 */ 
#include "PWM12.h"
void	initPWM1B(uint8_t invertido,uint8_t mode, uint8_t top_value, uint16_t prescaler)
{
	//ICR1	= top_value;						// Configurar valor de top
	TCCR1A	&= ~((1 << COM1B1)|(1 << COM1B0));	// Protección para solo configurar modo invert o no invert
	if(invertido == inv){
		TCCR1A |= (1 <<COM1B1)|(1 << COM1B0);	// Conf. Invertido
	}
	else{
		TCCR1A |= (1 << COM1B1);				// Conf. No invertido
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
}// Fin InitPWM0B