/*
 * PWM12.h
 *
 * Created: 8/04/2025 15:45:46
 *  Author: rodri
 */ 

#include <avr/io.h>
#include <stdint.h>

#ifndef PWM12_H_
#define PWM12_H_

#define inv 1
#define ninv 0
#define fastMode 1
#define phaseMode 0
void	initPWM1B(uint8_t invertido,uint8_t mode, uint8_t top_value, uint16_t prescaler);




#endif /* PWM12_H_ */