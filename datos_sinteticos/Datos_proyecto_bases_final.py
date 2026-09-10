# TRABAJO DE BASES DATOS
# Este documento lo vamos a usar como un generador de datos sintéticos para el caso que se nos presentó como grupo de FraudeLink 
# Entonces vamos a crear 5 nodos, los cuales van a ser: Clientes, Cuenta, Dispositivo, IP y Comercio 
# Los nodos explicados con una descripción son:
# Cliente: la persona
# Cuenta: la cuenta bancaria que posee ese cliente
# Dispositivo: el celular o computadora desde donde se conecta
# IP: la dirección de red desde donde se conecta ese dispositivo
# Comercio: el negocio donde se hace un pago
# En este documento también va a haber relaciones normales y patrones de fraude intencional
# Vamos a intentar cargarlo directamente en el Memgraph (Es la idea principal)


#Esto lo corren y después lo modificamos (córranlo y luego lo onen como comentario)
#python3 Datos_proyecto_bases.py esto en terminal
# no corre el python como tal en vs pero ya corroboré que sí se pasa a memgraph

import random
from faker import Faker
from neo4j import GraphDatabase #no estamos usando neo4j solo se llama igual, explicación abajo

# Usamos el driver de neo4j en vez de gqlalchemy porque este último
# no logró instalarse en Mac (necesita compilar código en C++ y nos pedía tener OpenSSL configurado, algo que no todos en elequipo tienen). 
# Memgraph funciona con el mismo protocolo de conexión que Neo4j, así que este driver conecta sin problema.
# IMPORTANTE: seguimos usando Memgraph como base de datos, esto solo cambia cómo Python se conecta a ella (seguimos usando Memgraph, no Neo4j).



# PASO 1 que planteamos
# Configuracion inicial y semilla fija
# Esto es muy importante, leyendo las instrucciones agregar el seed asegura que, todos tengamos los mismos datos

SEED= 42
random.seed(SEED)
fake= Faker()
Faker.seed(SEED)

# Para el caso que nos tocó de Fraude link pide minimo 10,000 nodos y 50,000 relaciones en total
# por lo que con este código superamos ese limite

N_CLIENTES= 3000
CUENTAS_POR_CLIENTE_MIN= 1
CUENTAS_POR_CLIENTE_MAX= 3
N_DISPOSITIVOS= 1800
N_IPS= 1400
N_COMERCIOS= 400
N_TRANSFERENCIAS= 40000
N_PAGOS= 15000


# PASO 2 vamos abuscar la conexión directa con Memgraph
# Lo siguiente va a asumir que ya está Memgraph corriendo en nuestra computadora por medio de Docker
# Escuchando en localhost, puerto 7687

driver = GraphDatabase.driver("bolt://localhost:7687", auth=("", "")) #con esto abrimos via hacia nuestro memgraph

def ejecutar(query, params=None): #Funcion auxiliar para correr una consulta Cypher contra Memgraph
    with driver.session() as session:
        session.run(query, params or {})

# Limpiamos la base antes de cargar, para que cada ejecucion importante para mejorar nuestra base
# le decimos al código que empiece desde cero y no duplique datos
ejecutar("MATCH (n) DETACH DELETE n")
print("Base de datos limpiada.")


# PASO 3
# vamos a empezar con nuestros primeros nodos, en este caso vamos con Cliente y Cuentas
clientes = []
cuentas = [] #creamos las listas vacías

for i in range(N_CLIENTES):
    cliente_id = f"CLI_{i:05d}"
    nombre = fake.name()
    clientes.append({"id": cliente_id, "nombre": nombre})

    n_cuentas = random.randint(CUENTAS_POR_CLIENTE_MIN, CUENTAS_POR_CLIENTE_MAX) # para cada client se le agrega al azar si le tocan 1, 2 o 3 cuentas
    for j in range(n_cuentas):
        cuenta_id = f"{cliente_id}_CTA_{j}"
        cuentas.append({"id": cuenta_id, "cliente_id": cliente_id})

print(f"Generados {len(clientes)} clientes y {len(cuentas)} cuentas.")

# PASO 4 seguimos con los últimos nodos 
# Dispositivos, IPs y Comercios

dispositivos = [f"DISP_{i:05d}" for i in range(N_DISPOSITIVOS)]
ips = [fake.ipv4() for _ in range(N_IPS)]
comercios = [{"id": f"COM_{i:04d}", "nombre": fake.company()} for i in range(N_COMERCIOS)]

print(f"Generados {len(dispositivos)} dispositivos, {len(ips)} IPs, {len(comercios)} comercios.")


# PASO 5 agregamos los 5 nodos que creamos en memgraph

for c in clientes:
    ejecutar(
        "CREATE (:Cliente {id: $id, nombre: $nombre})",
        {"id": c["id"], "nombre": c["nombre"]},
    )

for c in cuentas:
    ejecutar(
        "CREATE (:Cuenta {id: $id})",
        {"id": c["id"]},
    )

for d in dispositivos:
    ejecutar("CREATE (:Dispositivo {id: $id})", {"id": d})

for ip in ips:
    ejecutar("CREATE (:IP {direccion: $ip})", {"ip": ip})

for com in comercios:
    ejecutar(
        "CREATE (:Comercio {id: $id, nombre: $nombre})",
        {"id": com["id"], "nombre": com["nombre"]},
    )

print("Todos los nodos fueron insertados en Memgraph") #nota de corroboración


# PASO 6 Unimos a los clientes con sus cuentas

for c in cuentas:
    ejecutar(
        """
        MATCH (cli:Cliente {id: $cliente_id}), (cta:Cuenta {id: $cuenta_id})
        CREATE (cli)-[:POSEE]->(cta)
        """,
        {"cliente_id": c["cliente_id"], "cuenta_id": c["id"]},
    )

print("Relaciones POSEE creadas.")


# PASO 7 Relacion USA_DISPOSITIVO y CONECTA_DESDE
# Muy importante, para este caso hacemos la mayoría de manera normal 
# pero con un grupo de dispositivos compartidos a proposito para simular fraude 
# Esto ya que nadie legitimo usa el mismo celular para manejar 50 identidades. Lo forzamos a proposito para
# tener un caso real que las consultas puedan detectar

cuentas_ids = [c["id"] for c in cuentas]

# a. Asignacion NORMAL: cada cuenta usa su propio dispositivo esto como esperaríamos que debe de ser
for c in cuentas:
    disp = random.choice(dispositivos)
    ip = random.choice(ips)
    ejecutar(
        """
        MATCH (cta:Cuenta {id: $cuenta_id}), (d:Dispositivo {id: $disp_id})
        CREATE (cta)-[:USA_DISPOSITIVO]->(d)
        """,
        {"cuenta_id": c["id"], "disp_id": disp},
    )
    ejecutar(
        """
        MATCH (d:Dispositivo {id: $disp_id}), (ip:IP {direccion: $ip})
        MERGE (d)-[:CONECTA_DESDE]->(ip)
        """,
        {"disp_id": disp, "ip": ip},
    )

# b. Patron de FRAUDE: 50 cuentas distintas comparten un mismo
# dispositivo y UNA misma IP esto provocando ese caso raro
dispositivo_sospechoso = "DISP_FRAUDE_00001"
ip_sospechosa = "190.10.99.99"
ejecutar("CREATE (:Dispositivo {id: $id})", {"id": dispositivo_sospechoso})
ejecutar("CREATE (:IP {direccion: $ip})", {"ip": ip_sospechosa})
ejecutar(
    """
    MATCH (d:Dispositivo {id: $disp_id}), (ip:IP {direccion: $ip})
    CREATE (d)-[:CONECTA_DESDE]->(ip)
    """,
    {"disp_id": dispositivo_sospechoso, "ip": ip_sospechosa},
)

cuentas_sospechosas = random.sample(cuentas_ids, 50)
for cuenta_id in cuentas_sospechosas:
    ejecutar(
        """
        MATCH (cta:Cuenta {id: $cuenta_id}), (d:Dispositivo {id: $disp_id})
        CREATE (cta)-[:USA_DISPOSITIVO]->(d)
        """,
        {"cuenta_id": cuenta_id, "disp_id": dispositivo_sospechoso},
    )

print("Relaciones de dispositivos e IPs creadas (incluyendo patron sospechoso).")


# PASO 8 Relacion TRANSFIERE_A lo cual lo tenemos como las transferencias normales

for _ in range(N_TRANSFERENCIAS):
    origen, destino = random.sample(cuentas_ids, 2)
    monto = round(random.uniform(5, 5000), 2)
    fecha = fake.date_time_this_year().isoformat()
    ejecutar(
        """
        MATCH (a:Cuenta {id: $origen}), (b:Cuenta {id: $destino})
        CREATE (a)-[:TRANSFIERE_A {monto: $monto, fecha: $fecha}]->(b)
        """,
        {"origen": origen, "destino": destino, "monto": monto, "fecha": fecha},
    )

print(f"{N_TRANSFERENCIAS} transferencias normales creadas.")


# PASO 9 Ciclos de fraude en este caso decidimo el camino de transferencias circulares como lo piden 3 a 5 saltos
# así generamos más fraude detectable

N_CICLOS = 20
for _ in range(N_CICLOS):
    largo_ciclo = random.randint(3, 5)
    cuentas_ciclo = random.sample(cuentas_ids, largo_ciclo)
    for i in range(largo_ciclo):
        origen = cuentas_ciclo[i]
        destino = cuentas_ciclo[(i + 1) % largo_ciclo]  # vuelve al inicio
        monto = round(random.uniform(1000, 9000), 2)
        fecha = fake.date_time_this_year().isoformat()
        ejecutar(
            """
            MATCH (a:Cuenta {id: $origen}), (b:Cuenta {id: $destino})
            CREATE (a)-[:TRANSFIERE_A {monto: $monto, fecha: $fecha}]->(b)
            """,
            {"origen": origen, "destino": destino, "monto": monto, "fecha": fecha},
        )

print(f"{N_CICLOS} ciclos de transferencias sospechosas creados.")


# PASO 10 Relacion PAGA_EN (pagos a comercios)

comercio_ids = [c["id"] for c in comercios]
for _ in range(N_PAGOS):
    cuenta_id = random.choice(cuentas_ids)
    comercio_id = random.choice(comercio_ids)
    monto = round(random.uniform(2, 500), 2)
    fecha = fake.date_time_this_year().isoformat()
    ejecutar(
        """
        MATCH (cta:Cuenta {id: $cuenta_id}), (com:Comercio {id: $comercio_id})
        CREATE (cta)-[:PAGA_EN {monto: $monto, fecha: $fecha}]->(com)
        """,
        {"cuenta_id": cuenta_id, "comercio_id": comercio_id, "monto": monto, "fecha": fecha},
    )

print(f"{N_PAGOS} pagos a comercios creados.")

total_nodos = N_CLIENTES + len(cuentas) + (len(dispositivos) + 1) + (len(ips) + 1) + N_COMERCIOS
total_relaciones = len(cuentas) + len(cuentas) + (len(dispositivos) + 1) + N_TRANSFERENCIAS + (N_CICLOS * 4) + N_PAGOS

print("\n--- Carga de datos completa ---")
print(f"Clientes: {N_CLIENTES}")
print(f"Cuentas: {len(cuentas)}")
print(f"Dispositivos: {len(dispositivos) + 1}")
print(f"IPs: {len(ips) + 1}")
print(f"Comercios: {N_COMERCIOS}")
print(f"Transferencias totales: {N_TRANSFERENCIAS + N_CICLOS * 4}")
print(f"Pagos: {N_PAGOS}")
print(f"Cuentas con dispositivo sospechoso compartido: {len(cuentas_sospechosas)}")
print(f"\nTOTAL NODOS: {total_nodos} (minimo requerido: 10,000)")
print(f"TOTAL RELACIONES (aprox): {total_relaciones} (minimo requerido: 50,000)")

driver.close()
print("Conexion cerrada.")
