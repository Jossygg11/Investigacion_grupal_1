  Carpeta de código fuente
// ============================================================
// FraudeLink - Verificación de escala y Requisitos 2 y 3
// XS0131 - Grupo 8 (Grafos, Memgraph)
// Versión unificada: combina las consultas propias con las del
// compañero, corrigiendo los errores encontrados en su borrador.
// ============================================================


MATCH(n) RETURN n LIMIT 100;

// ------------------------------------------------------------
// VERIFICACIÓN DE ESCALA MÍNIMA
// ------------------------------------------------------------
// No es uno de los 7 requisitos numerados del caso, pero confirma
// que se superan los mínimos exigidos: 10,000 nodos y 50,000
// relaciones EN TOTAL (sumando todos los tipos de nodo y relación).

// Cuenta cuántos nodos hay en total, sin importar el tipo (Cliente,
// Cuenta, Dispositivo, IP o Comercio)
MATCH (n)
RETURN count(n) AS total_nodos;

// Cuenta cuántas relaciones hay en total, sin importar el tipo
// (POSEE, USA_DISPOSITIVO, CONECTA_DESDE, TRANSFIERE_A, PAGA_EN)
MATCH ()-[r]->()
RETURN count(r) AS total_relaciones;


// ------------------------------------------------------------
// REQUISITO 2: "Encontrar cuentas que comparten dispositivo o IP
// con varias identidades distintas"
// ------------------------------------------------------------
// El requisito pide cubrir DOS medios: dispositivo e IP. En el
// grafo son dos relaciones distintas y a DOS SALTOS de distancia:
//
//   Cliente -[:POSEE]-> Cuenta -[:USA_DISPOSITIVO]-> Dispositivo -[:CONECTA_DESDE]-> IP
//
// Por eso hacen falta DOS consultas separadas, una por cada medio.
// El borrador original intentaba resolverlo con una sola consulta
// usando [:USA_DISPOSITIVO|CONECTA_DESDE] en el mismo tramo del
// camino, pero eso no funciona: CONECTA_DESDE nunca sale de una
// Cuenta, sale de un Dispositivo. En la práctica esa versión solo
// terminaba usando USA_DISPOSITIVO, y la parte de IP quedaba sin
// cubrir aunque el comentario dijera lo contrario.

// --- Parte A: dispositivos compartidos ---
MATCH (cli:Cliente)-[:POSEE]->(cta:Cuenta)-[:USA_DISPOSITIVO]->(d:Dispositivo)
// Agrupamos por cada dispositivo, juntando en una lista todos los
// clientes DISTINTOS que lo usaron. El DISTINCT es clave: evita
// contar dos veces a un cliente que tiene varias cuentas en el
// mismo dispositivo.
WITH d, collect(DISTINCT cli.id) AS clientes, collect(DISTINCT cta.id) AS cuentas
// El umbral de 14 no lo exige el caso, se calibró mirando los datos:
// sin filtro salen 1,542 dispositivos "compartidos" solo por azar
// (6,065 cuentas repartidas al azar entre 1,800 dispositivos vía
// random.choice en el script de generación). Con > 14 queda
// exactamente el dispositivo fraudulento sembrado a propósito.
WHERE size(clientes) > 14
RETURN d.id AS dispositivo,
       size(clientes) AS num_clientes_distintos,
       clientes,
       cuentas
ORDER BY num_clientes_distintos DESC;

// --- Parte B: IPs compartidas ---
// Mismo patrón que la Parte A, pero con un salto extra (CONECTA_DESDE)
// para llegar hasta la IP. 
MATCH (cli:Cliente)-[:POSEE]->(cta:Cuenta)-[:USA_DISPOSITIVO]->(:Dispositivo)-[:CONECTA_DESDE]->(ip:IP)
WITH ip, collect(DISTINCT cli.id) AS clientes, collect(DISTINCT cta.id) AS cuentas
WHERE size(clientes) > 14  // mismo umbral, por consistencia con la Parte A
RETURN ip.direccion AS ip_compartida,
       size(clientes) AS num_clientes_distintos,
       clientes,
       cuentas
ORDER BY num_clientes_distintos DESC;
