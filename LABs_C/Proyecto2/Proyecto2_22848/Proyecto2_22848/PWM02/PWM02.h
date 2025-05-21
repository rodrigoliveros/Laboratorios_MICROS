/*
 * PWM02.h
 *
 * Created: 6/05/2025 12:58:06
 *  Author: rodri
 */ 
#include <avr/io.h>
#include <stdint.h>

#ifndef PWM02_H_
#define PWM02_H_

#define inv 1
#define ninv 0
void initPWM0B(uint8_t invertido, uint16_t prescaler);
#endif /* PWM02_H_ */