# Pruebas

Acá documentamos cómo validamos que las consultas realmente detectan lo que
dicen detectar. Las consultas de validación están en
`Codigo_fuente/código.cypher`; el detalle completo del método está en la
Sección XII del paper.

## Cómo probamos

No validamos "a ojo" viendo si los resultados se ven razonables. El generador
de datos (`datos_sinteticos/Datos_proyecto_bases_final.py`) siembra patrones de
fraude a propósito, con identificadores fijos (un dispositivo y una IP
compartidos por un grupo conocido de cuentas, y un número fijo de ciclos de
transferencias de 3 a 5 saltos). Como sabemos de antemano qué cuentas son
fraudulentas, cada consulta se evalúa con una pregunta concreta: ¿recupera
exactamente el patrón sembrado?

Además hicimos verificaciones cruzadas entre requisitos (por ejemplo, contrastar
qué cuentas marca la identidad compartida contra las que marca PageRank) para
ver si las distintas técnicas convergen sobre las mismas cuentas.

## Tiempos de ejecución

Cada consulta principal se midió en Memgraph Lab, en la misma instancia, para
que los tiempos sean comparables entre sí. La tabla completa está en el paper
(Tabla IX). Como referencia, van de milisegundos en las consultas puntuales
hasta ~9–16 s en las que recorren todo el grafo.

## Cómo repetir las pruebas

1. Levantar la base y cargar los datos (ver el README de la raíz).
2. Confirmar que hay 12,667 nodos con `MATCH (n) RETURN count(n)`.
3. Correr las consultas de `Codigo_fuente/código.cypher` en orden; cada bloque
   trae comentarios con el requisito que valida.
