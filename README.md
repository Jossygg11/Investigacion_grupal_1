# Investigacion_grupal_1
Desafío NoSQL


### Guía basica:

Piensa en esto como si estuvieras inventando una ciudad falsa llena de gente y bancos, solo para que el sistema tenga algo que investigar.

Lo que vamos a inventar son cinco tipos de "cosas" (los nodos)

Clientes: personas ficticias, cada una con un nombre inventado. Por ejemplo, "María González".
Cuentas: cada cliente tiene una o varias cuentas bancarias, como si fueran sus tarjetas o cuentas de ahorro.
Dispositivos: el celular o computadora desde donde cada quien se conecta a hacer sus transacciones.
IPs: la dirección de internet desde donde se conectan (como la ubicación digital de dónde entran).
Comercios: negocios donde la gente paga, como una tienda o restaurante.

Lo que conecta a estas cosas entre sí (las relaciones)

Un cliente posee una cuenta. Esa cuenta usa cierto dispositivo. Ese dispositivo se conecta desde cierta IP. Una cuenta le transfiere dinero a otra cuenta. Y una cuenta paga en cierto comercio.

Por qué inventamos esto en vez de usar datos reales

Porque no existe un dataset público de fraude bancario real (por razones obvias de privacidad), así que la tarea del curso es que ustedes mismos "actúen" cómo se vería ese mundo, con un script que lo crea automáticamente: en vez de escribir 10,000 personas a mano, un programa las genera todas en segundos con nombres, cuentas y conexiones al azar, pero de forma controlada.

La parte clave: escondemos "pistas de fraude" a propósito

De los 10,000 clientes y sus conexiones, la mayoría van a ser completamente normales, sin nada raro. Pero a propósito vamos a meter algunos patrones sospechosos escondidos, por ejemplo: 50 cuentas distintas que comparten el mismo dispositivo (como si una sola persona controlara 50 cuentas falsas), o un grupo de cuentas que se transfieren dinero en círculo (A le manda a B, B le manda a C, C le manda de vuelta a A), que es una forma clásica de lavado de dinero.

Para qué sirve todo esto al final

Una vez que el script mete a todos estos "personajes falsos" dentro de Memgraph, ustedes van a escribir consultas que busquen esos patrones escondidos, exactamente como lo haría un investigador de fraude real. La gracia es que el script sabe dónde escondió las pistas, así que después pueden confirmar si sus consultas realmente las encontraron.
