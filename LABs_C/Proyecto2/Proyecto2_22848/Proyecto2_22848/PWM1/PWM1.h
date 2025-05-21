/*
 * PWM1.h
 *
 * Created: 7/04/2025 11:44:40
 *  Author: rodri
 */ 
#include <avr/io.h>
#include <stdint.h>

#ifndef PWM1_H_
#define PWM1_H_

#define inv 1
#define ninv 0
#define fastMode 1
#define phaseMode 0
void	initPWM1A(uint8_t invertido,uint8_t mode, uint8_t top_value, uint16_t prescaler);
#endif /* PWM1_H_ */