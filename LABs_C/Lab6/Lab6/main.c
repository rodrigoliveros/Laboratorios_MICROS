/*
 * Lab6.c
 *
 * Created: 22/04/2025 12:08:49
 * Author : rodri
 */ 
#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>
#include "ADC/ADC.h"

void initUART9600(void);
void writeUART(char Caracter);
void writeTEXTUART(char * Texto);
uint8_t valueadc = 0;
volatile uint8_t buffertx;
uint8_t	flag = 0;


int main(void)
{
	cli();
	initUART9600();
	SETUPADC();
	sei();
	/* Replace with your application code */
	while (1)
	{
		writeUART('\n');
		writeTEXTUART("Menu");
		writeUART('\n');
		writeTEXTUART("1. Leer Potenciometro");
		writeUART('\n');
		writeTEXTUART("2. Enviar ASCII");
		writeUART('\n');
		while(flag == 0); // FIN MENU
		if(flag == 1){	//Modo potenciometro
			writeTEXTUART("El valor del potenciometro es:");
			// Rutinas para convertir el valor
			 uint8_t c = 0;
			 uint8_t d = 0;
			 uint8_t u = 0;

			 // Copiamos el valor leído a una variable local
			 uint8_t val = valueadc;

			 // Calcular centenas, decenas y unidades
			 c = val / 100;
			 val = val % 100;

			 d = val / 10;
			 u = val % 10;

			 // Mostrar por UART
			 writeUART(c + '0');
			 writeUART(d + '0');
			 writeUART(u + '0');
			 writeUART('\n');
			 flag = 0;
		}// Fin de modo potenciometro
		else {
			if(flag == 2){
				writeTEXTUART("Introduce el caracter: ");
				while(flag == 2);
				writeUART((char) buffertx);
				writeUART('\n');
			}// Fin de modo ASCII
			else{
				writeTEXTUART("Elija un modo valido\n");
				flag = 0;
				
				}// Modo error	
		}//Modo final
		
	}// Modo menu
} // While
void initUART9600(void){
	DDRB = 0xFF;			// Definimos Puerto B como salida
	DDRC = 0;
	DDRC |= (1 << DDC1) |(1 << DDC0); // Definimos Puerto C
	PORTB = 0x00;			// Puerto B inicialmente apagado
	// Configurar PD0 como entrada y PD1 como salida
	DDRD &= ~(1 << DDD0);
	DDRD |= (1 << DDD1);
	// Configuración UCSR0A
	UCSR0A = 0;
	//Configurar el UCSR0B, interrupción al recibir, habilitar recepción.
	UCSR0B = 0;
	UCSR0B |= (1 << RXCIE0) | (1 << RXEN0) |(1 << TXEN0);
	//Configurar UCSR0C, ASINCRONO, PARIEDAD NONE, 1 BIT STOP, DATA 8 BITS
	UCSR0C = 0;
	UCSR0C |= (1 << UCSZ01) | (1 << UCSZ00);
	//Configurar velocidad de Baudrate: 9600 @16Mhz
	UBRR0 = 103;
}
void writeUART(char Caracter) {
	while(!(UCSR0A & (1<<UDRE0))); //UCSR0A sea 1
	UDR0 = Caracter;
}

void writeTEXTUART(char* Texto) {
	for(uint8_t i = 0; *(Texto+i) != '\0'; i++)
	{
		writeUART(*(Texto+i));
	}
}

ISR(USART_RX_vect) {
	buffertx = UDR0;
	if(flag == 0){
		if(buffertx == '1'){ //Leemos si es la opción 1, cambiamos flag en consecuencia
			flag = 1;
		}
		else {
			if(buffertx == '2'){ //Leemos si es la opción 2, cambiamos flag en consecuencia
				flag = 2;
			}
			else {				// Entramos al modo error
				flag = 3;
			}
		}//Fin intercambio modos
	} // Fin menu
	else {						//Mostrar en leds
		PORTB = buffertx;
		PORTC = (buffertx>>6);
		flag = 0;
	}
}// Fin interrupción

ISR(ADC_vect){
	valueadc = ADCH; // Almacenar valor
	ADCSRA |= (1<<ADIF); // Apagar bandera
	ADCSRA |= (1<<ADSC); //Volver a iniciar
}