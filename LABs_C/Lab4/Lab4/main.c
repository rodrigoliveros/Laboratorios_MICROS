/*
 * main.c
 *
 * Created: 3/31/2025 11:43:19 AM
 *  Author: rodri
 */ 
#define F_CPU 1600000 //Frecuencia de Reloj (Sistema)
#include <avr/io.h>
#include <stdint.h>	
#include <util/delay.h>
#include <avr/interrupt.h>


//PROTOTIPOS
void SETUP(void);
void SETUPADC(void);
	// Variables
	uint8_t contador8 = 0x00;
	uint8_t e_actual = 0x00;
	uint8_t	e_previo = 0xFF;
	uint8_t valueadc = 0x00;
	
	//Tabla de conversión para display de 7 segmentos (cátodo común)
	uint8_t TABLA7SEGM[] ={0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71};
//INTERRUPCIONES
//ADC
ISR(ADC_vect){
	valueadc = ADCH; // Almacenar valor
	ADCSRA |= (1<<ADIF); // Apagar bandera
	ADCSRA |= (1<<ADSC); //Volver a iniciar
}

int main(void)
{	
	//Inicio de programa
	cli();
	SETUP();
	SETUPADC();
	sei();
	ADCSRA |= (1<<ADSC); // Primera lectura del ADC
    while(1)
    {
	e_actual = PINC;
	//Antirrebote
	if(e_previo!=e_actual){		// Leemos
		_delay_ms(10);			// Esperamos para volver a leer
		e_actual = PINC;		
		if(e_previo!=e_actual){ // Volvemos a leer
			if(!(PINC & 0x01)){ // Si esta presionado PB0 se decrementa contador
				contador8--;
			}// Fin decrementar	
			if(!(PINC & 0x02)){	// Si esta presionado PB1 se aumenta el contador
				contador8++;
			}// Fin de aumentar
			e_previo = e_actual;
		}// Fin de controlador
		
	}// Fin de Antirrebote
	// Subrutina de alarma
	if(valueadc > contador8){
	PORTB  |= 0b00001000;
	}
	else {
	PORTB  |= 0b00000000;	
	}
	// Mostramos el valor del contador en el Puerto D
	_delay_ms(70);
	PORTB  = 0x00;
	PORTD  =  contador8;		// Mostrar contador 8 bits
	PORTB |= 0b000000001;
	_delay_ms(70);
	PORTB  = 0x00;
	PORTD  = TABLA7SEGM[(valueadc & 0xF0)>>4];		// Mostrar 
	PORTB |= 0b000000010;
	_delay_ms(70);
	PORTB  = 0x00;
	PORTD  = TABLA7SEGM[valueadc & 0x0F];
	PORTB |= 0b000000100;
    }// Fin de while
}// Fin de Main

//FUNCIONES

void SETUP(void){
	// Entradas
	DDRC		&=	0xF0;			// Marcar Puerto C como entrada
	PORTC		|=	0xFF;			// Colocar entradas como Pull-Up
	// Salidas
	DDRD		|=  0xFF;			// Marcar Puerto D como salida
	UCSR0B		 =	0x00;			// Apagar comunicación UART	(PD0-PD1)
	PORTD		 =	0x00;			// Puerto D inicialmente apagado
	//Mux
	DDRB		|=  0xFF;
	PORTB		 =  0x00;
}
void SETUPADC(void){
	ADMUX = 0;
	ADMUX |= (1<<REFS0)|(1<<ADLAR)|(1<<MUX2)|(1<<MUX1); //Vcc ref (5V), 8 bits resolucion | Mux ADC6
	ADCSRA = 0;
	ADCSRA |= (1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0); //Int. En | Presc. 128 (125kHz)
	ADCSRA |= (1<<ADEN); // Enable
}
