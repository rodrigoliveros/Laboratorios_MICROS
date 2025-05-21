/*
 * PWM0.h
 *
 * Created: 10/04/2025 12:07:16
 *  Author: rodri
 */ 

#include <avr/io.h>
#include <stdint.h>

#ifndef PWM0_H_
#define PWM0_H_

#define inv 1
#define ninv 0
void initPWM0A(uint8_t invertido, uint16_t prescaler);
#endif /* PWM0_H_ */