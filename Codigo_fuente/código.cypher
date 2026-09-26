// ============================================================
// FraudeLink
// XS0131 - Grupo 8 (Grafos, Memgraph)
// ============================================================

// Esto solo va mostrar 100 nodos al azar, esto para ver el grafo dibujado
// Solo hicimos esta prueba a ver cómo iba funcionando este programa
MATCH(n) RETURN n LIMIT 100;

// -----------------------------------
// Vemos si cumplimos la escala mínima
// -----------------------------------

// Querermos mostrar que cumplimos con los requisitos de 10000 nodos y 50000 rwelaciones en total (sumando todos los tipos de nodo y relación)
// Cuenta cuántos nodos hay en total, sin importar el tipo (Cliente, Cuenta, Dispositivo, IP o Comercio)
MATCH (n)
RETURN count(n) AS total_nodos;

// Cuenta cuántas relaciones hay en total, sin importar el tipo:
// (POSEE, USA_DISPOSITIVO, CONECTA_DESDE, TRANSFIERE_A, PAGA_EN)
MATCH ()-[r]->()
RETURN count(r) AS total_relaciones;


// --------------------------------------------------------------------------------------------------
// REQUISITO 2: Encontrar cuentas que comparten dispositivo o IP con varias identidades distintas
// Lo que como grupo buscamos es encontrar dispositivos o IPs usados por más de un cliente distinto, 
// señal de identidades falsas compartiendo el mismo recurso técnico
// --------------------------------------------------------------------------------------------------

// Como grupo vamos a requerir el uso de "dispositivo" e "IP". En el grafo son dos relaciones distintas y a dos saltos de distancia:
// El flujo ses así Cliente posee una Cuenta, esa Cuenta usa un Dispositivo, y ese Dispositivo se conecta desde una IP

// Cliente -[:POSEE]-> Cuenta -[:USA_DISPOSITIVO]-> Dispositivo -[:CONECTA_DESDE]-> IP

// Importante tenemos quye notar como de cuenta a dispositivo hay un salto y de cuenta a ip hay dos saltos


// Parte A dispositivos compartidos

MATCH (cli:Cliente)-[:POSEE]->(cta:Cuenta)-[:USA_DISPOSITIVO]->(d:Dispositivo)
// Agrupamos por cada dispositivo, juntando en una lista todos los clientes DISTINTOS que lo usaron

// El DISTINCT notamos que es importante ya evita contar dos veces a un cliente que tiene varias cuentas en el mismo dispositivo
WITH d, collect(DISTINCT cli.id) AS clientes, collect(DISTINCT cta.id) AS cuentas

// el criterio de 3 desviaciones estándar es un principio estadístico general para detectar anomalías, aplica aquí porque la asignación de dispositivos es aleatoria
WITH collect({dispositivo: d.id, num: size(clientes), clientes: clientes, cuentas: cuentas}) AS datos
// Promedio de clientes distintos por dispositivo, sobre todos los dispositivos
WITH datos, reduce(s = 0, x IN datos | s + x.num) / size(datos) AS promedio 

WITH datos, promedio, // Desviación estándar: qué tanto varían los dispositivos respecto al promedio
     sqrt(reduce(s = 0.0, x IN datos | s + (x.num - promedio)^2) / size(datos)) AS desviacion

UNWIND datos AS d // Volvemos a separar la lista en filas individuales para poder filtrar

WITH d, promedio, desviacion

// Se marca como sospechoso lo que está muy por encima de lo normal (más de 3 desviaciones estándar sobre el promedio)
WHERE d.num > promedio + 3 * desviacion
RETURN d.dispositivo AS dispositivo,
       d.num AS num_clientes_distintos,
       d.clientes AS clientes,
       d.cuentas AS cuentas

ORDER BY num_clientes_distintos DESC;



// Parte A que decidimos hacer de una forma más sencilla de esta forma basada en lo observado anteriormente definimos un umbral de 14 

MATCH (cli:Cliente)-[:POSEE]->(cta:Cuenta)-[:USA_DISPOSITIVO]->(d:Dispositivo)
WITH d, collect(DISTINCT cli.id) AS clientes, collect(DISTINCT cta.id) AS cuentas
WHERE size(clientes) > 14 // Con > 14 queda exactamente el dispositivo fraudulento sembrado a propósito hay que acomodar esto 

RETURN d.id AS dispositivo,
       size(clientes) AS num_clientes_distintos,
       clientes,
       cuentas
ORDER BY num_clientes_distintos DESC;

// Parte B IPs compartidas
//En el siguiente codigo lo que hacemos es filtrar falsos positivos y retorna el ip sospechoso, el id del dispositivo
//el conteo total y la lista de cuentas afectadas

//Descarta cualquier grupo menor a 12 clientes, ya que, 12 es el limite de conexiones normales por IP

//Filtra y promedia que clientes por dispositivo sea mayor a 12. Eliminando asi redes publicas normales y dejando casos de fraude

MATCH (cli:Cliente)-[:POSEE]->(cta:Cuenta)-[:USA_DISPOSITIVO]->(disp:Dispositivo)-[:CONECTA_DESDE]->(ip:IP) //recorre la cadena
WITH ip, disp,           //agrupa por ip y dispositivo
     count(DISTINCT cli) AS num_clientes, 
     collect(DISTINCT cli.id) AS clientes, 
     collect(DISTINCT cta.id) AS cuentas,
     count(DISTINCT disp) AS num_dispositivos,
     toFloat(count(DISTINCT cli)) / count(DISTINCT disp) AS promedio_clientes_por_dispositivo // mide la densidad de clientes por dispositivo
WHERE num_clientes > 12                     // restringe que el promedio de clientes por dispositivo supere un umbral aleatorio y
  AND promedio_clientes_por_dispositivo > 12 // descarta redes wifi publicas donde muchas identidades usan distintos dispositivos
RETURN ip.direccion AS ip_sospechosa,       
       num_clientes,
       disp.id AS dispositivo,
       num_dispositivos,
       size(cuentas) AS total_cuentas,
       round(promedio_clientes_por_dispositivo) AS promedio_por_disp,
       cuentas,
       clientes
ORDER BY num_clientes DESC;

// podemos ver que desde la misma ip, 1 dispositivo accedio a 50 cuentas de clientes distintos, lo cual es extremadamente sospechoso 


// Verificación cruzada importante que queremos verificar 
// las 50 cuentas del dispositivo fraudulento son las mismas 50 cuentas que comparten la IP fraudulenta?

MATCH (cta:Cuenta)-[:USA_DISPOSITIVO]->(:Dispositivo {id: "DISP_FRAUDE_00001"}) // fijado en el generador de datos
WITH collect(cta.id) AS cuentas_dispositivo

MATCH (cta2:Cuenta)-[:USA_DISPOSITIVO]->(:Dispositivo)-[:CONECTA_DESDE]->(:IP {direccion: "190.10.99.99"}) // fijado en el generador de datos
WITH cuentas_dispositivo, collect(cta2.id) AS cuentas_ip

RETURN size(cuentas_dispositivo) AS total_dispositivo,
       size(cuentas_ip) AS total_ip,
       size([x IN cuentas_dispositivo WHERE x IN cuentas_ip]) AS coinciden;

// Eso confirma la hipótesis: el dispositivo fraudulento y la IP fraudulenta son, literalmente, el mismo grupo de 50 cuentas

// ---------------------------------------------------------------------------------------------------------------
// REQUISITO 3 Detectar una cadena o ciclo de transferencias de al menos 3 saltos y explicar por qué es relevante
// ---------------------------------------------------------------------------------------------------------------

// El requisito pide cadena O ciclo, así que se resuelve con dos
// consultas: ciclo (vuelve al origen) y cadena abierta (no vuelve).
// Ojo con el *: es TRANSFIERE_A*3..5, no TRANSFIERE_A3..5, sin el
// asterisco Cypher no corre la consulta.

// Parte A ciclo en este caso hacemos la cuenta de origen y la de cierre son la misma
MATCH camino = (a:Cuenta)-[:TRANSFIERE_A*3..5]->(a)
RETURN a.id AS cuenta_origen,
       length(camino) AS num_saltos,
       [n IN nodes(camino) | n.id] AS ruta_cuentas,
       [r IN relationships(camino) | r.monto] AS montos
LIMIT 10;

// --- Parte B ahora terminamos con la cadena lineal no necesariamente vuelve al origen
MATCH camino = (a:Cuenta)-[:TRANSFIERE_A*3..4]->(b:Cuenta)
WHERE a <> b  // descarta los casos que ya cubre la Parte A (ciclos)
RETURN a.id AS cuenta_origen,
       b.id AS cuenta_destino,
       length(camino) AS num_saltos,
       [n IN nodes(camino) | n.id] AS ruta_cuentas,
       [r IN relationships(camino) | r.monto] AS montos
// ORDER BY num_saltos DESC ESTO GENERA PROBLEMAS muy importante ya que no nos dio el almacenadiento lo cuals es un tema a poder en nuestro informe
// nos salió "Memory limit exceeded"
LIMIT 10;

// Nota de rendimiento, los caminos de rango variable (*) son más lentos que un salto fijo. 
// La Parte A tardó 9.06s sobre ~40,000 transferencias
// La Parte B es más pesada aún (no cierra el ciclo así que hay muchas más combinaciones); si tarda mucho, agregar un filtro de monto mínimo


// Lista todos los algoritmos MAGE instalados en esta instancia
CALL mg.procedures()
YIELD name
RETURN name
ORDER BY name

// Resumen para que entendamos más lo que logramos hacer con esta consulta
// Parte A (ciclo): busca transferencias que salen de una cuenta y, después de 3 a 5 saltos, vuelven a esa misma cuenta. Es el patrón clásico de lavado de dinero (mover plata en círculo para esconder de dónde vino)
// Parte B (cadena): busca transferencias de 3 a 4 saltos que no necesariamente vuelven al origen, solo una secuencia A→B→C→D

// Ciclos donde TODOS los montos superan $5,000 (el máximo posible en una
// transferencia normal). Si aparece, el ciclo viene del generador de fraude
MATCH camino = (a:Cuenta)-[:TRANSFIERE_A*3..5]->(a) // *3..5 nos dice que vamos a ver  de 3 a 5 transferencias seguidas
                                                    // (a)...(a) obliga a que el camino termine donde empezó (eso es lo que lo hace un ciclo)
WHERE ALL(r IN relationships(camino) WHERE r.monto > 5000)
RETURN a.id AS cuenta_origen,
       length(camino) AS num_saltos,
       [n IN nodes(camino) | n.id] AS ruta_cuentas,
       [r IN relationships(camino) | r.monto] AS montos
LIMIT 20;

// Util ya que usando el monto como prueba (una transferencia normal nunca supera $5,000) por lo que la tomamos como "sospechoso"

// Por qué 7 es el mínimo, esto es muy importante tenerlo en cuenta, no el total: el filtro exige que TODAS la transferencias del ciclo superen $5,000, pero los ciclos de fraude
// reales se generaron con montos entre $1,000 y $9,000, así que algunos ciclos de fraude quedan por debajo de $5,000 y no pasan el filtro.
// Siguen siendo fraude, solo que no se distinguen del ruido con este método. Por eso 7 es el piso garantizado, no los 20 completos.

// ---------------------------------------------------------------------------------------------------------------
// REQUISITO 4: PageRank sobre las cuentas
// PageRank es un algoritmo iterativo: le asigna a cada nodo un "puntaje de importancia"
//---------------------------------------------------------------------------------------------------------------


// Le asigna a cada nodo un "puntaje de importancia" basado en cuántos nodos le apuntan 
// qué tan importantes son esos nodos que le apuntan (no es solo contar conexiones)
CALL pagerank.get()
YIELD node, rank

// Filtramos porque PageRank corre sobre TODOS los nodos del grafo
// (Cliente, Dispositivo, IP, Comercio también), pero acá solo nos interesa el ranking entre Cuentas
WHERE node:Cuenta
RETURN node.id AS cuenta, rank
ORDER BY rank DESC
LIMIT 10;

// Importante tomar en cuenta con este punto
// PageRank debería destacar cuentas "importantes" del fraude, pero acá
// todas salieron casi iguales nadie destacó, porque el fraude que sembramos
// es muy poco comparado con las 40,000 transferencias aleatorias. No encontró el fraude, para nosotros como grupo nos parece bien ya que no vamos a forzar a los datos

//Al no haber una diferencia significativa vemos que no hay un patrón para ver si alguni es má importante

// Requisito 4, grado simple: para comparar contra PageRank

MATCH (c:Cuenta)
OPTIONAL MATCH (c)-[t:TRANSFIERE_A]-()
RETURN c.id AS cuenta, count(t) AS grado_transferencias
ORDER BY grado_transferencias DESC
LIMIT 10;

// Aquí lo que buscamos es una verificación
// ¿Alguna de las cuentas con más transferencias (top 10 por grado) es
// también una de las 50 cuentas sospechosas del dispositivo fraudulento?

MATCH (cta:Cuenta)-[:USA_DISPOSITIVO]->(:Dispositivo {id: "DISP_FRAUDE_00001"}) // Encuentra las cuentas conectadas al dispositivo fraudulento sembrado
WITH collect(cta.id) AS sospechosas // Las guarda en una sola list esto para poder usarla más abajo en la comparación

MATCH (c:Cuenta)
OPTIONAL MATCH (c)-[t:TRANSFIERE_A]-() // Por cada cuenta, busca todas sus transferencias (entrantes y salientes).
                                       // OPTIONAL MATCH evita que se pierdan las cuentas sin ninguna transferencia
WITH sospechosas, c.id AS cuenta_top_grado, count(t) AS grado_transferencias // Cuenta cuántas transferencias tiene cada cuenta
ORDER BY grado_transferencias DESC
LIMIT 10 // Se queda solo con las 10 cuentas más activas

RETURN cuenta_top_grado, grado_transferencias, // Compara cada una de esas 10 contra la lista de sospechosas:
                                               // true si coincide, false si no
       cuenta_top_grado IN sospechosas AS es_sospechosa_dispositivo;

// nota devuelve false
// Resultado: ninguna de las 10 cuentas con más transferencias coincide con
// las 50 sospechosas del dispositivo. El grado alto es ruido estadístico
// normal, no señal de fraude en este dataset.



















