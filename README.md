# Investigacion_grupal_1
Desafío NoSQL

## Cómo correr nuestra base
### Básicamente lo que buscamos es aclarar cómo ejecutar Memgraph y cargarle los datos del caso FraudeLink que nos tocó

Esta guía la hicimos pata que sirva para Mac o Windows, no importa quién lo corra.

Consideramos imporatnte aclarar que todos los comandos de abajo se escriben en la Terminal 
Se corre una linea a la vez y se le da enter después de cada una, la última dura bastante porque crea los datos

### Nota: Lo que se necesita tener instalado antes

Docker Desktop
Python 3
Git (o GitHub Desktop)

### Si todavía no tienes el repositorio en tu compu

Si ya lo tienes clonado (como el equipo), te saltas este paso.

En la Terminal:

```
git clone https://github.com/Jossygg11/Investigacion_grupal_1.git
cd Investigacion_grupal_1
```

El nombre varía de compu a compu cabe recalcar

### Ejecutar Memgraph

Primero hay que asegurarse de estar parado en la carpeta del repositorio. Si nuestra Terminal no está ahí, entramos con:

```
cd /ruta/donde/tengas/Investigacion_grupal_1
```
Está general porque como ya dijimos, es distinto de compu a compu, hay que revisar donde se guardó al clonarla

Luego se corre, recordar que todo en la consola

```
docker compose up -d
```

La primera vez tarda varios minutos porque baja las imágenes de internet. Después de eso queda corriendo en segundo plano, no hace falta repetirlo cada vez a menos que reinicies la compu.

### Instalar lo que usa el script de Python

En la Terminal, entrá a la carpeta de datos:

```
cd datos_sinteticos
pip install -r requirements.txt
```

### Correr el script que carga los datos

Sin salir de esa misma carpeta, en la Terminal:

```
python3 Datos_proyecto_bases_final.py
```

Este script mete todos los nodos y relaciones del caso a Memgraph. Tiene una semilla fija, o sea que a cualquiera que lo corra le va a salir exactamente el mismo grafo. Tarda un rato, recordar que son más de 70 mil relaciones entre nodos, no es instantáneo, y muestra mensajes de progreso en la misma Terminal mientras corre.

### Para comprobar que sí cargó

Este paso ya no es en la Terminal, es en el navegador. hay que abrir nuestro Chrome o Safari, y pegamos localhost:3000 

Posterior corremos este código en el panel de memgraph

```cypher
MATCH (n) RETURN count(n)
```

Tiene que dar como 12,600 y algo, y aquí ya se confirma que funcionó

### Por si algo falla

Si pip te da error de que no encuentra Python o usa uno raro, revisá en la Terminal con `which python3` cuál está usando antes de instalar nada. En Windows todo es igual, solo hay que tener activado WSL 2 para que Docker funcione 
