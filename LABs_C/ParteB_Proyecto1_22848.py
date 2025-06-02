import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Arc

# Solicitamos el ángulo
angulo_grados = float(input("¿En qué ángulo se encuentra la carga (en grados)? "))

# Calculamos el número de imágenes
n = round(360 // angulo_grados - 1)
print(f"Se generarán {n} cargas imagen.")

# Posición de la carga original
angulo_r = np.radians(angulo_grados)
x0, y0 = np.cos(angulo_r), np.sin(angulo_r) # Utilizando trigonometria

# Listas para posiciones y signos
xs = [x0]
ys = [y0]
signos = [1]

# Genera las imágenes
for i in range(1, n + 1): #Rotamos la carga 1 por cada valor de i, utilizando el angulo inicial
    angulo_rad = np.radians(i * angulo_grados)
    x = x0 * np.cos(angulo_rad) - y0 * np.sin(angulo_rad)
    y = x0 * np.sin(angulo_rad) + y0 * np.cos(angulo_rad)
    #Se guardan las posiciones por cada carga y el signo
    xs.append(x)
    ys.append(y)
    signos.append((-1)**i)

# Dibuja las cargas
fig, ax = plt.subplots()
for i in range(n + 1):
    color = 'green' if i == 0 else 'blue'
    signo = '+Q' if signos[i] > 0 else '-Q'
    ax.plot(xs[i], ys[i], 'o', color=color)
    ax.text(xs[i] + 0.1, ys[i], signo, fontsize=10, color=color)

# Línea punteada desde el origen a la carga original
ax.plot([0, x0], [0, y0], 'k--', linewidth=1)

# Arco del ángulo (respecto a eje X positivo)
radio_arco = 0.3
arc = Arc((0, 0), width=2*radio_arco, height=2*radio_arco,
          theta1=0, theta2=angulo_grados, edgecolor='red', linewidth=1)
ax.add_patch(arc)

# Texto del ángulo
angulo_medio = np.radians(angulo_grados / 2)
xt = 0.38 * np.cos(angulo_medio)
yt = 0.38 * np.sin(angulo_medio)
ax.text(xt, yt, f"{angulo_grados:.1f}°", fontsize=10, color='red')

# Ajustes estéticos
ax.set_aspect('equal')
ax.set_xlim(-1.5, 1.5)
ax.set_ylim(-1.5, 1.5)
ax.set_title(f" Con {angulo_grados}° se generan {n} imágenes. Original (verde), Imagenes (azules)")
ax.set_xlabel("Para valores N no enteros, producto de la ecuacion N= 360/angulo - 1, esta gráfica solo es un aproximado")
ax.axhline(0, color='black', linewidth=1)
ax.axvline(0, color='black', linewidth=1)
plt.grid(True)
plt.show()
