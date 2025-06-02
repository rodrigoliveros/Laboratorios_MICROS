import numpy as np
import matplotlib.pyplot as plt
# Solicitamos el caso a trabajar
while True:
    try:
        a = float(input("Ingresa el valor de a (altura, eje y): "))
        if a <= 0:
            print("El valor de a debe ser un número positivo mayor que cero. Intenta de nuevo.")
        else:
            break
    except ValueError:
        print("Por favor, ingresa un número válido para a.")

while True:
    try:
        b = float(input("Ingresa el valor de b (base, eje x): "))
        if b <= 0:
            print("El valor de b debe ser un número positivo mayor que cero. Intenta de nuevo.")
        else:
            break
    except ValueError:
        print("Por favor, ingresa un número válido para b.")

# Parámetros
V1 = 100  # voltaje en x = 0
V2 = 50   # voltaje en x = b
N_terms = 5  
dx = 0.01
dy = 0.01
x = np.arange(0, b + dx, dx) #Arreglo de valores de 0 hasta b con pasos de 0.1
y = np.arange(0, a + dy, dy) #Arreglo de valores de 0 hasta a con pasos de 0.1
X, Y = np.meshgrid(x, y) #Matrices 2D para coordenadas

# Función (teniendo en cuenta que a --> b y x ----> y respecto a la original)
def calcular_V(x, y, a, b, V1, V2, N):
    V = np.zeros_like(x) #Crea una matriz de ceros del mismo tamaño que x, para guardar los valores del potencial.
    for n in range(1, 2*N, 2):  # solo impares
        factor = (4 / (np.pi * n)) * np.sin(n * np.pi * y / a) / np.sinh(n * np.pi * b / a)
        V += factor * (V1 * np.sinh(n * np.pi * (b - x) / a) + V2 * np.sinh(n * np.pi * x / a))
    return V
V = calcular_V(X, Y, a, b, V1, V2, N_terms) #Se genera una malla de puntos por cada valor de x, y y n.

# Graficar curvas equipotenciales
plt.figure(figsize=(6, 6 * a / b)) #Creamos una figura proporcional en relacion aspecto
levels = np.linspace(np.min(V), np.max(V), 20) #Definimos 20 lineas de contorno
cs = plt.contour(X, Y, V, levels=levels, cmap='inferno') #Definimos los colores utilizando los valores V en X y Y
plt.clabel(cs, inline=True, fontsize=6, fmt="%.2f") #Etiquetas de valores.

plt.title(f'Superficies Equipotenciales (a={a}, b={b}, V1={V1}V en x=0, V2={V2}V en x=b)')
plt.xlabel('x (horizontal)')
plt.ylabel('y (vertical)')
plt.grid(True, linestyle='--', linewidth=0.5)
plt.axis('scaled')
plt.tight_layout()
plt.show()
