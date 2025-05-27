import numpy as np
import matplotlib.pyplot as plt

# Parámetros
a = 1.0  # altura (eje y)
b = 3.0  # base horizontal (eje x)
V1 = 100  # voltaje en x = 0
V2 = 50   # voltaje en x = b
N_terms = 5  # más términos = más precisión

dx = 0.01
dy = 0.01
x = np.arange(0, b + dx, dx)
y = np.arange(0, a + dy, dy)
X, Y = np.meshgrid(x, y)

# Función corregida: ahora aplica V1 y V2 en x=0 y x=b
def calcular_V(x, y, a, b, V1, V2, N):
    V = np.zeros_like(x)
    for n in range(1, 2*N, 2):  # solo impares
        factor = (4 / (np.pi * n)) * np.sin(n * np.pi * y / a) / np.sinh(n * np.pi * b / a)
        V += factor * (V1 * np.sinh(n * np.pi * (b - x) / a) + V2 * np.sinh(n * np.pi * x / a))
    return V

V = calcular_V(X, Y, a, b, V1, V2, N_terms)

# Graficar curvas equipotenciales
plt.figure(figsize=(6, 6 * a / b))
levels = np.linspace(np.min(V), np.max(V), 20)
cs = plt.contour(X, Y, V, levels=levels, cmap='inferno')
plt.clabel(cs, inline=True, fontsize=6, fmt="%.2f")

plt.title(f'Superficies Equipotenciales (a={a}, b={b}, V1={V1}V en x=0, V2={V2}V en x=b)')
plt.xlabel('x (horizontal)')
plt.ylabel('y (vertical)')
plt.grid(True, linestyle='--', linewidth=0.5)
plt.axis('scaled')
plt.tight_layout()
plt.show()
