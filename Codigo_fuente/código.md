  Carpeta de código fuente
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

// Flujo que sabemos que debe de seguir
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

ORDER BY num_clientes_distintos DESC



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

// Muy similar a lo que hicimos en la Parte A, pero con un salto extra "CONECTA_DESDE" para llegar hasta la IP
// nos salen 885 filas ya que es normal que cada celular está conectado a varias IPS distintas

MATCH (cli:Cliente)-[:POSEE]->(cta:Cuenta)-[:USA_DISPOSITIVO]->(:Dispositivo)-[:CONECTA_DESDE]->(ip:IP)
WITH ip, collect(DISTINCT cli.id) AS clientes, collect(DISTINCT cta.id) AS cuentas
WHERE size(clientes) > 14  // mismo umbral, por consistencia con la Parte A
RETURN ip.direccion AS ip_compartida,
       size(clientes) AS num_clientes_distintos,
       clientes,
       cuentas
ORDER BY num_clientes_distintos DESC;

// Verificación cruzada importante que queremos verificar 
// las 50 cuentas del dispositivo fraudulento son las mismas 50 cuentas que comparten la IP fraudulenta?

MATCH (cta:Cuenta)-[:USA_DISPOSITIVO]->(:Dispositivo {id: "DISP_FRAUDE_00001"}) // fijado en el generador de datos
WITH collect(cta.id) AS cuentas_dispositivo

MATCH (cta2:Cuenta)-[:USA_DISPOSITIVO]->(:Dispositivo)-[:CONECTA_DESDE]->(:IP {direccion: "190.10.99.99"}) // fijado en el generador de datos
WITH cuentas_dispositivo, collect(cta2.id) AS cuentas_ip

RETURN size(cuentas_dispositivo) AS total_dispositivo,
       size(cuentas_ip) AS total_ip,
       size([x IN cuentas_dispositivo WHERE x IN cuentas_ip]) AS coinciden

// Eso confirma la hipótesis: el dispositivo fraudulento y la IP fraudulenta son, literalmente, el mismo grupo de 50 cuentas

RETURN ip.direccion AS ip_compartida,
       size(clientes) AS num_clientes_distintos,
       clientes,
       cuentas
ORDER BY num_clientes_distintos DESC;
