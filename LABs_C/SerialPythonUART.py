import serial

#Este codigo sirve con el primer ejemplo de UART
mi_arduino =  serial.Serial(port='COM3', baudrate=9600,timeout=0.1)
while True:
    ingreso = input("Ingrese algo: ")
    mi_arduino.write(bytes(ingreso,'utf-8'))
    retorno = mi_arduino.readline()
    print(retorno)
