/*
 * PWM0.c
 *
 * Created: 10/04/2025 12:07:27
 *  Author: rodri
 */ 
#include "PWM0.h"
void initPWM0A(uint8_t invetido, uint16_t prescaler){
	DDRD |= (1 << DDD6);
	TCCR0A &= ~((1 << COM0A1)|(1 << COM0A0));
	if(invetido == inv){
		TCCR0A |= (1 << COM0A1)|(1 << COM0A0);
	}
	else {
		TCCR0A |= (1 << COM0A1);
	}
	TCCR0A |= (1 << WGM01)|(1 << WGM00);
	TCCR0B	&= ~((1 << CS02)|(1 << CS01)|(1 << CS00));
	
	switch(prescaler){
		case 1:
			TCCR0B |= (1 << CS00);
			break;
		case 8:
			TCCR0B |= (1 << CS01);
			break;
		case 64:
			TCCR0B |= (1 << CS01)|(1 << CS00);
			break;
		case 256:	
			TCCR0B |= (1 << CS02);
			break;
		case 1024:
			TCCR0B |= (1 << CS02)|(1 << CS00);
			break;
		default:
			TCCR0B |= (1 << CS00);
			break;
	}
}