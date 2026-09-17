## Cómo correr esto

Sirve para Mac o Windows. Todos los comandos van en una terminal: en Mac es la app "Terminal" (Cmd+Espacio, buscar "Terminal"), en Windows es "PowerShell" (buscarlo en el menú de inicio). Una línea a la vez, Enter después de cada una.

### Lo que necesitas instalado antes de empezar

- Docker Desktop (docker.com/products/docker-desktop)
- Python 3
- Git o GitHub Desktop

**En Windows, ojo con este paso**: al instalar Python, el instalador tiene una casilla que dice "Add Python to PATH" (o "Add python.exe to PATH"). Hay que marcarla sí o sí. Si no la marcás, después de instalar te va a salir un error tipo "pip no se reconoce como un cmdlet", aunque Python sí esté instalado. Si ya te instalaste Python sin marcar esa casilla, reinstalalo marcándola, o volvé a correr el instalador y elegí "Modify" para agregarla después.

También puede aparecer un aviso de Windows sobre "rutas largas" (long paths) durante la instalación. Aceptalo (escribí "y" o "s" y Enter), y si te pide reiniciar la compu para que tome efecto, reiniciá antes de seguir.

### Si todavía no tenés el repositorio clonado

Si ya lo tenés (como la mayoría del equipo), te saltás este paso.

```
git clone https://github.com/Jossygg11/Investigacion_grupal_1.git
cd Investigacion_grupal_1
```

### 1. Ubicate en la carpeta del repositorio

Necesitás saber la ruta exacta donde tenés guardada la carpeta `Investigacion_grupal_1` en tu compu. La forma más fácil de conseguirla: abrí GitHub Desktop, andá a Repository → "Show in Finder" (Mac) o "Show in Explorer" (Windows), y ahí ves la ruta completa.

En Mac se ve así (con barra normal):
```
cd /Users/tu_usuario/Desktop/Investigacion_grupal_1
```

En Windows se ve así (con barra invertida, y sin barra antes de la letra de la unidad):
```
cd C:\Users\tu_usuario\Documents\GitHub\Investigacion_grupal_1
```

Confirmá que llegaste bien escribiendo `pwd` (Mac) o simplemente mirando lo que dice al inicio de la línea en PowerShell.

### 2. Levantar Memgraph con Docker

Parado en la carpeta del repositorio (la de arriba, no la de datos_sinteticos):

```
docker compose up -d
```

La primera vez tarda varios minutos porque baja las imágenes de internet. Las siguientes veces es rápido.

**Si te sale un error de "port is already allocated"**: significa que ese puerto ya lo está usando otra cosa en tu compu (a veces un intento anterior que quedó a medias). Primero probá:

```
docker compose down
```

y después volvé a correr `docker compose up -d`. Si el error persiste con el mismo puerto, asegurate de tener la última versión del `docker-compose.yml` del repositorio (hacé `git pull`), porque ya sacamos del archivo un puerto que causaba conflictos seguido.

### 3. Instalar las librerías de Python

```
cd datos_sinteticos
pip install -r requirements.txt
```

**Si en Windows te sale "pip no se reconoce"**: probá con esto en su lugar:

```
python -m pip install -r requirements.txt
```

Si tampoco funciona, es señal de que Python no quedó bien agregado al PATH (ver la nota de instalación más arriba).

### 4. Correr el script que carga los datos

En Mac:
```
python3 Datos_proyecto_bases_final.py
```

En Windows:
```
python Datos_proyecto_bases_final.py
```

(en Windows a veces hace falta usar `py` en vez de `python`, depende de cómo haya quedado instalado)

Este script mete todos los nodos y relaciones del caso en Memgraph. Tiene una semilla fija, así que a cualquiera que lo corra le va a salir exactamente el mismo grafo. Tarda varios minutos, no es instantáneo, y va mostrando mensajes de progreso mientras corre.

### 5. Confirmar que cargó bien

Esto ya no es en la terminal, es en el navegador. Abrí Chrome o Safari y andá a:

```
http://localhost:3001
```

Ahí vive Memgraph Lab. En el menú de la izquierda hacé clic en "Query execution", y en la pestaña "Cypher editor" escribí:

```cypher
MATCH (n) RETURN count(n)
... (14 lines left)
