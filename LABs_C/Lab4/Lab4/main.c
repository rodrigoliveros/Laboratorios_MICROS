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

//PROTOTIPOS
void SETUP(void);


int main(void)
{	
	//Inicio de programa
	SETUP();
	// Variables
	uint8_t contador8 = 0x00;
	uint8_t e_actual = 0x00;
	uint8_t	e_previo = 0xFF;
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
	PORTD =  contador8;			// Mostramos el valor del contador en el Puerto D
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
}
