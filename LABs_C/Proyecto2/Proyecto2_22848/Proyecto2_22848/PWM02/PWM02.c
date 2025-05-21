/*
 * PWM02.c
 *
 * Created: 6/05/2025 12:58:23
 *  Author: rodri
 */ 
#include "PWM02.h"

void initPWM0B(uint8_t invertido, uint16_t prescaler){
	
	TCCR0A &= ~((1 << COM0B1)|(1 << COM0B0));
	if(invertido == inv){
		TCCR0A |= (1 << COM0B1)|(1 << COM0B0);
	}
	else {
		TCCR0A |= (1 << COM0B1);
	}
	
	TCCR0A |= (1 << WGM01)|(1 << WGM00); //Modo fast
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