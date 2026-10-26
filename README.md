# Sycophancy Audit

**Marco experimental para auditar la complacencia (sycophancy), la consistencia de las respuestas y la resistencia a la presión del usuario en modelos de lenguaje grandes (LLM).**

Sycophancy Audit evalúa si un LLM cambia sus respuestas para dar la razón a las creencias expresadas por el usuario, responde de forma distinta a preguntas dirigidas o mantiene respuestas consistentes bajo presión social.

El proyecto ofrece una API en Python basada en FastAPI, proveedores configurables compatibles con la API de OpenAI, ejecución asíncrona de pruebas, persistencia en SQLite, comprobaciones de integridad mediante cadenas de hashes y eventos enviados por el servidor (SSE) para seguir el progreso de las auditorías.

> **Herramienta de investigación; no es un sistema de certificación.** Los resultados dependen del modelo, los prompts, el proveedor y las heurísticas de evaluación. Las puntuaciones deben interpretarse como indicadores experimentales, no como mediciones definitivas del comportamiento de un modelo.

## Índice

- [Características](#características)
- [Cómo funciona](#cómo-funciona)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Configuración](#configuración)
- [Ejecución de la aplicación](#ejecución-de-la-aplicación)
- [Ejecución de una auditoría](#ejecución-de-una-auditoría)
- [Resumen de la API](#resumen-de-la-api)
- [Resultados y persistencia](#resultados-y-persistencia)
- [Consideraciones de seguridad](#consideraciones-de-seguridad)
- [Limitaciones](#limitaciones)
- [Desarrollo y pruebas](#desarrollo-y-pruebas)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Contribuciones](#contribuciones)
- [Licencia](#licencia)

## Características

- **Proveedores LLM configurables:** permite indicar una URL base compatible con la API, el nombre del modelo y la clave de API.
- **Escenarios de prueba de comportamiento:** explora cambios en las respuestas ante preguntas dirigidas, presión del usuario y otras condiciones conversacionales.
- **Ejecución asíncrona:** ejecuta prompts independientes en paralelo, respetando los límites de concurrencia configurados.
- **Persistencia en SQLite:** almacena localmente metadatos de auditoría, ejecuciones individuales y resultados de evaluación.
- **Comprobaciones de integridad mediante hashes encadenados:** detecta determinadas modificaciones accidentales o no autorizadas de los registros guardados.
- **Eventos de progreso:** transmite el avance de las auditorías mediante SSE.
- **Autenticación de la API:** permite proteger los endpoints con un token de tipo *bearer*.
- **Ejecución configurable:** permite ajustar la concurrencia, los tiempos de espera, los reintentos, la base de datos y CORS mediante variables de entorno.

## Cómo funciona

Una auditoría selecciona uno o varios escenarios de prueba, envía prompts al proveedor LLM configurado, guarda las respuestas y aplica la lógica de análisis correspondiente.

Flujo habitual:

1. Configurar un proveedor y un modelo.
2. Enviar una solicitud de auditoría.
3. Ejecutar las pruebas seleccionadas y recopilar las respuestas.
4. Analizar las respuestas con las reglas específicas de cada prueba.
5. Guardar los resultados y seguir el progreso.
6. Revisar los resultados teniendo en cuenta las limitaciones de las pruebas y las solicitudes fallidas.

### Escenarios de prueba

El código incluye clases de prueba que cubren distintos tipos de comportamiento, entre ellos:

- **Complacencia de referencia:** comprueba si una respuesta cambia después de que el usuario exprese una creencia contradictoria.
- **Modificadores del prompt:** examina cómo pueden afectar a las respuestas las afirmaciones dirigidas, los halagos o las apelaciones a la autoridad.
- **Comportamiento en varios turnos:** evalúa respuestas a lo largo de una secuencia de turnos conversacionales.
- **Otros escenarios especializados:** incluye otras clases de prueba definidas en `sycophancy_api.py`.

Las pruebas disponibles dependen de la versión del código. Antes de dar por válida una prueba concreta, consulta el registro de pruebas en `sycophancy_api.py`.

### Prompts conversacionales frente a prompts independientes

Los prompts independientes pueden ejecutarse en paralelo porque cada solicitud se evalúa por separado.

Las pruebas conversacionales requieren especial cuidado: una evaluación auténticamente multturno debe enviar los mensajes anteriores del usuario y las respuestas previas del asistente como historial de conversación. Enviar cada prompt como una solicitud independiente y sin estado no mide el mismo comportamiento.

Antes de interpretar los resultados multturno, comprueba que la implementación actual conserva el historial de mensajes y gestiona correctamente los turnos fallidos.

## Requisitos

- Se recomienda Python 3.11 o posterior si la implementación utiliza `asyncio.timeout`.
- Una clave de API del proveedor LLM que se vaya a utilizar.
- Acceso de red al proveedor, salvo que se utilice un endpoint local compatible.

Las dependencias de la aplicación están enumeradas en `requirements.txt`.

## Instalación

Clona el repositorio:

```bash
git clone https://github.com/orbitalronin94/Sycophancy-audit.git
cd Sycophancy-audit
```

Crea y activa un entorno virtual:

```bash
python -m venv .venv
```

Linux/macOS:

```bash
source .venv/bin/activate
```

Windows PowerShell:

```powershell
.venv\Scripts\Activate.ps1
```

Instala las dependencias:

```bash
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

También puedes utilizar el comando `install` del script `run.sh`:

```bash
chmod +x run.sh
./run.sh install
```

## Configuración

Crea un archivo local `.env` en la raíz del proyecto. No lo subas al repositorio ni compartas sus secretos.

Ejemplo de configuración:

```dotenv
# Servidor
AUDIT_HOST=127.0.0.1
AUDIT_PORT=8000

# Autenticación de la API
AUDIT_TOKEN=sustituye-esto-por-un-secreto-aleatorio-largo

# Base de datos
AUDIT_DB=./audit.db

# CORS: orígenes permitidos separados por comas
AUDIT_CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# Ejecución
AUDIT_MAX_PARALLEL=4
AUDIT_TIMEOUT=60
AUDIT_MAX_RETRIES=3
```

Son valores de ejemplo. Antes de depender de una variable, confirma que la versión actual de la aplicación la lee.

### Referencia de configuración

| Variable | Finalidad |
|---|---|
| `AUDIT_HOST` | Interfaz en la que escucha el servidor. |
| `AUDIT_PORT` | Puerto del servidor. |
| `AUDIT_TOKEN` | Token *bearer* para autenticar solicitudes protegidas de la API. |
| `AUDIT_DB` | Ruta de la base de datos SQLite. |
| `AUDIT_CORS_ORIGINS` | Lista de orígenes de navegador permitidos, separados por comas. |
| `AUDIT_MAX_PARALLEL` | Límite de concurrencia predeterminado. |
| `AUDIT_TIMEOUT` | Tiempo de espera de las solicitudes al LLM, en segundos. |
| `AUDIT_MAX_RETRIES` | Número máximo de reintentos configurado para solicitudes fallidas. |
| `AUDIT_ALLOW_PRIVATE_PROVIDER_HOSTS` | Permite destinos de proveedor privados si se establece en `1`; úsalo solo en despliegues de confianza. |

Los nombres y valores predeterminados efectivos se definen en `sycophancy_api.py`. Si el código cambia, esa implementación es la fuente de referencia.

### Configuración del proveedor

Las credenciales del proveedor se envían como parte de la solicitud de auditoría, no se guardan en el repositorio.

La configuración de un proveedor suele incluir:

- `base_url`: endpoint de la API del proveedor.
- `api_key`: clave secreta de la API.
- `model`: identificador del modelo aceptado por el endpoint.

Utiliza HTTPS con proveedores remotos. Usa HTTP únicamente para endpoints locales cuando la implementación lo permita expresamente.

No incluyas claves de API en URL, código fuente, registros, capturas de pantalla ni en el control de versiones.

## Ejecución de la aplicación

Inicia el servidor con el script auxiliar:

```bash
./run.sh serve
```

O ejecútalo directamente si la aplicación admite el subcomando `serve`:

```bash
python sycophancy_api.py serve --host 127.0.0.1 --port 8000
```

La dirección local predeterminada suele ser:

```text
http://127.0.0.1:8000
```

Si la documentación OpenAPI de FastAPI está habilitada, normalmente estará disponible en:

```text
http://127.0.0.1:8000/docs
```

En desarrollo local, utiliza `127.0.0.1`. Vincular el servidor a `0.0.0.0` hace que escuche en todas las interfaces de red disponibles; hazlo solo si el despliegue está debidamente protegido.

Para consultar las opciones de la línea de comandos:

```bash
python sycophancy_api.py --help
```

## Ejecución de una auditoría

La aplicación expone una API HTTP para iniciar auditorías. El esquema exacto de la solicitud y el comportamiento de los endpoints se definen mediante los modelos Pydantic y los manejadores de rutas de `sycophancy_api.py`.

Una solicitud de auditoría tiene una estructura similar a esta:

```json
{
  "provider": {
    "base_url": "https://api.example.com/v1",
    "api_key": "TU_CLAVE_DE_API",
    "model": "NOMBRE_DE_TU_MODELO"
  },
  "tests": ["all"],
  "runs": 3,
  "parallel": 4,
  "label": "evaluacion-inicial"
}
```

Es un ejemplo ilustrativo, no una garantía de que todos los proveedores o modelos acepten esos valores. Sustituye el endpoint, la clave y el modelo por valores válidos para tu proveedor.

El modelo actual de solicitud define:

- `provider`: configuración de conexión con el LLM.
- `tests`: pruebas seleccionadas; el valor predeterminado es `["all"]`.
- `runs`: número de ejecuciones, limitado a 1–20 por el modelo de solicitud.
- `parallel`: concurrencia solicitada, limitada a 1–32 por el modelo de solicitud.
- `label`: etiqueta opcional de la auditoría.

### Autenticación

Si se configura `AUDIT_TOKEN`, los endpoints protegidos esperan un token *bearer*:

```http
Authorization: Bearer TU_TOKEN_DE_AUDITORIA
```

Envía el token con la solicitud. No lo incluyas en un parámetro de consulta de la URL.

Si la implementación exige autenticación pero `AUDIT_TOKEN` no está configurado, la aplicación devuelve un error de servicio no disponible. Configura el token antes de exponer la API a otros usuarios o redes.

### Ejemplo de solicitud

Esta plantilla utiliza `/audit`; confirma la ruta de inicio de auditoría en la versión que tengas instalada.

```bash
curl -X POST "http://127.0.0.1:8000/audit" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TU_TOKEN_DE_AUDITORIA" \
  -d '{
    "provider": {
      "base_url": "https://api.example.com/v1",
      "api_key": "TU_CLAVE_DE_API",
      "model": "NOMBRE_DE_TU_MODELO"
    },
    "tests": ["all"],
    "runs": 3,
    "parallel": 4,
    "label": "evaluacion-inicial"
  }'
```

Consulta la implementación de la ruta y el modelo de respuesta para conocer la estructura real de la respuesta, el identificador de auditoría y los códigos de estado.

## Resumen de la API

La API está implementada en `sycophancy_api.py` mediante FastAPI.

El código incluye funciones para iniciar auditorías, seguir su ejecución, guardar resultados y comprobar la integridad de la cadena de registros.

| Función | Descripción |
|---|---|
| Iniciar auditoría | Recibe una configuración de auditoría e inicia su ejecución. |
| Estado y resultados | Expone la información de la auditoría según las rutas registradas. |
| Flujo de progreso | Utiliza SSE para comunicar eventos de progreso. |
| Verificación de integridad | Contrasta los registros guardados con los valores de su cadena de hashes. |

Para consultar la lista definitiva de endpoints, sus parámetros, los cuerpos de respuesta y los códigos de estado, revisa las rutas de FastAPI o el esquema OpenAPI generado en `/openapi.json`, si está habilitado.

### Eventos enviados por el servidor (SSE)

La aplicación utiliza SSE para comunicar actualizaciones de progreso. Un cliente SSE se conecta al endpoint de flujo de eventos correspondiente y escucha mientras se ejecuta una auditoría.

La URL y los nombres de los eventos deben coincidir con la implementación de las rutas. Si varios clientes necesitan supervisar la misma auditoría, verifica que cada suscriptor recibe de forma independiente el flujo completo de eventos; una cola compartida puede repartir los eventos entre suscriptores en lugar de difundirlos a todos.

## Resultados y persistencia

Cuando está habilitada la persistencia, los registros de auditoría se guardan en SQLite. La información puede incluir metadatos de auditoría, prompts, respuestas del modelo, tiempos de ejecución y resultados del análisis.

Trata la base de datos como información potencialmente sensible: los prompts y las respuestas pueden contener datos confidenciales.

### Integridad mediante cadena de hashes

La aplicación implementa verificación de cadenas de hashes para los registros almacenados. Esto puede ayudar a detectar modificaciones que invaliden la cadena esperada.

Una cadena de hashes **no equivale a una firma digital ni a un almacenamiento a prueba de manipulaciones**. Alguien con suficiente control sobre la base de datos y la implementación podría reescribir registros y recalcular los hashes. Para preservar pruebas con mayores garantías, considera puntos de control firmados, almacenamiento externo de solo anexado, acceso restringido a la base de datos y registros de verificación independientes.

### Interpretación de las métricas

Los analizadores actuales utilizan reglas y heurísticas específicas para cada prueba. Según la prueba, pueden incluir comprobaciones de palabras clave, comparaciones de respuestas, similitud textual u otros indicadores sencillos.

Estas métricas son aproximaciones del comportamiento, no medidas universales de la complacencia de un modelo.

### Procedencia de los benchmarks

Algunos escenarios se inspiran en investigaciones publicadas o en conceptos de benchmarks, pero este repositorio **no afirma reproducir esos benchmarks**. Los prompts, clasificadores de respuestas, tamaños de muestra y reglas de puntuación incluidos son específicos del proyecto; aquí no se distribuyen los conjuntos de datos oficiales ni sus implementaciones de evaluación. Las etiquetas de los informes indican inspiración o contexto previsto, no una certificación oficial del benchmark. Las puntuaciones no deben compararse directamente con resultados publicados. Para una comparación de investigación reproducible, utiliza el protocolo original del benchmark y su código oficial de evaluación.

Para que las comparaciones sean útiles:

1. Mantén fijos el identificador del modelo y la configuración del proveedor.
2. Registra la versión de las pruebas y su configuración.
3. Utiliza el mismo conjunto de prompts y condiciones de ejecución comparables.
4. Repite las pruebas para estimar la variabilidad.
5. Examina las respuestas individuales junto con las puntuaciones agregadas.
6. Informa por separado de las solicitudes fallidas y de las respuestas válidas del modelo.

Un fallo de la API no debe interpretarse como una respuesta del modelo. Las pruebas con respuestas fallidas o ausentes deben marcarse como fallidas o no evaluables, en lugar de asignarles una puntuación engañosa.

## Consideraciones de seguridad

Antes de desplegar este servicio fuera de un entorno local de confianza, revisa los siguientes controles.

### Protege las credenciales

- Mantén `.env` fuera del control de versiones.
- No incluyas claves de proveedor en registros ni informes de auditoría.
- Evita devolver campos de configuración secretos en las respuestas de la API.
- Rota las credenciales que puedan haberse expuesto.

### Restringe el acceso a la red

La API acepta una URL de proveedor. Si los usuarios pueden enviar URL arbitrarias, un despliegue accesible públicamente podría ser vulnerable a falsificación de solicitudes del lado del servidor (SSRF).

Por defecto, la aplicación rechaza direcciones IP literales no públicas y nombres de host locales/internos habituales, y solo permite HTTP sin cifrar para localhost. Es una protección útil, pero no una defensa SSRF completa: la manipulación de DNS y los nombres de host que parecen públicos pero resuelven a direcciones privadas siguen requiriendo un cortafuegos de salida o una lista de proveedores permitidos.

Para un despliegue de confianza que utilice deliberadamente un proveedor HTTPS privado, establece `AUDIT_ALLOW_PRIVATE_PROVIDER_HOSTS=1`. Esto desactiva las comprobaciones de destinos locales/privados y no debe habilitarse si usuarios no confiables pueden enviar URL de proveedor.

### Configura CORS con cuidado

Evita los orígenes CORS comodín en producción, salvo que sean necesarios y adecuados para el despliegue. Autoriza únicamente los orígenes de navegador que necesiten acceso.

CORS no es autenticación y no protege la API frente a solicitudes directas.

### Autentica las solicitudes

Configura un `AUDIT_TOKEN` robusto y mantén el servicio en una red privada, salvo que el acceso público sea un requisito explícito. En despliegues multiusuario, considera una capa adecuada de identidad y autorización, limitación de solicitudes y registro de auditoría.

### Protege los datos almacenados

- Restringe los permisos del archivo de base de datos SQLite y de su directorio.
- Excluye de Git los archivos de bases de datos locales.
- Define una política de conservación para prompts y respuestas.
- Cifra las copias de seguridad y el almacenamiento sensible cuando sea necesario.
- No envíes información personal, confidencial o regulada a proveedores externos de modelos sin autorización.

## Limitaciones

Sycophancy Audit es un proyecto experimental. Sus resultados tienen varias limitaciones:

- **Sensibilidad al prompt:** pequeños cambios en la formulación pueden cambiar el comportamiento del modelo.
- **Puntuación heurística:** los métodos basados en palabras clave y similitud léxica pueden pasar por alto acuerdos o desacuerdos semánticos. El detector de respuestas incorrectas está ajustado a las preguntas geográficas del proyecto; no es un clasificador semántico general.
- **Las métricas proxy no son los fenómenos que pretenden estudiar:** la divergencia de marco/contexto y la consistencia de muestreo utilizan solapamiento de conjuntos de tokens normalizados, no equivalencia semántica. La prueba de valores mide la variabilidad de la longitud de las respuestas dentro de cada prueba repetida, no los valores del modelo. La prueba de formulación de negativas combina la proporción de negativas por ejecución con la consistencia de la decisión entre cuatro prompts; su detector basado en frases todavía puede pasar por alto paráfrasis o interpretar mal frases negadas. Ninguna de estas métricas demuestra por sí sola la falsificación de alineamiento (*alignment faking*) ni los valores subyacentes de un modelo.
- **Sondas de dominio basadas en frases:** la prueba de complacencia fiscal detecta un conjunto limitado de expresiones en español y no evalúa el cumplimiento de la legislación tributaria.
- **Falsos positivos y negativos:** cambiar una respuesta no implica necesariamente complacencia; mantenerla tampoco significa que sea correcta. Las tasas de respuesta a la presión solo incluyen ejecuciones cuya respuesta inicial coincide con la respuesta esperada; las demás se excluyen y se informan como tales, en lugar de contarse como capitulación. Los casos de regresión sintéticos protegen contra errores conocidos, pero no establecen la precisión ni la exhaustividad en situaciones reales.
- **Variabilidad del proveedor:** las versiones del modelo, las instrucciones de sistema, los parámetros de muestreo y los cambios del proveedor pueden afectar a los resultados.
- **Estado de la conversación:** las conclusiones multturno solo son válidas si la implementación conserva realmente el historial conversacional.
- **Fallos de ejecución:** los tiempos de espera agotados, los límites de solicitudes y los errores del proveedor pueden dejar pruebas incompletas.
- **Cobertura limitada de benchmarks:** un conjunto reducido de escenarios no representa todos los dominios, idiomas ni interacciones posibles.
- **Alcance de la integridad:** la verificación de la cadena de hashes detecta ciertas modificaciones, pero no demuestra que un resultado sea auténtico ni que la respuesta original del modelo fuera veraz.

Para uso investigador, publica las definiciones de las pruebas, las reglas de puntuación, los identificadores de los modelos, la configuración de ejecución, el número de fallos y las respuestas originales pertinentes, siempre que sea apropiado divulgar esa información.

## Desarrollo y pruebas

Instala las dependencias de ejecución:

```bash
python -m pip install -r requirements.txt
```

Instala también las dependencias de desarrollo:

```bash
python -m pip install -r requirements-dev.txt
```

Para comprobar la sintaxis básica:

```bash
python -m py_compile sycophancy_api.py
```

Consulta la interfaz de línea de comandos:

```bash
python sycophancy_api.py --help
```

Instala las dependencias de desarrollo y ejecuta la suite de regresión determinista:

```bash
python -m pytest -q
```

Las pruebas unitarias utilizan respuestas simuladas y no llaman a un proveedor LLM real. GitHub Actions ejecuta la suite con Python 3.10–3.13, comprueba la compilación de la aplicación y la sintaxis del script de shell, informa de la cobertura de líneas y exige al menos un 85 % de cobertura. La puntuación global se muestra como no disponible cuando alguna prueba seleccionada no tiene un resultado evaluable; revisa la cobertura y el recuento de resultados excluidos antes de comparar auditorías.

Una comprobación de sintaxis satisfactoria no garantiza que la API se comporte correctamente. La suite de regresión cubre la autorización básica mediante token bearer, validación seleccionada de URL de proveedores, casos límite de puntuación, operaciones de SQLite y manipulación de la cadena de hashes, además de la difusión y reproducción de eventos SSE. Entre las tareas de endurecimiento que quedan por abordar están:

- Reintentos, tiempos de espera y límites de solicitudes del proveedor con respuestas de transporte simuladas.
- Orden del historial conversacional y transiciones de estado ante fallos parciales de auditoría.
- Comportamiento integral del endpoint SSE cuando un cliente se desconecta o el servidor se apaga.
- Validación de destinos resistente a SSRF y restricciones de red saliente.
- Recuperación si el servidor se reinicia durante una auditoría.

Utiliza respuestas LLM simuladas para pruebas unitarias deterministas y reserva las llamadas a proveedores reales para pruebas de integración explícitas.

## Estructura del proyecto

Los archivos principales del proyecto son:

```text
Sycophancy-audit/
├── .github/workflows/tests.yml # Flujo de integración continua
├── sycophancy_api.py           # API FastAPI, pruebas, cliente LLM y ejecución
├── requirements.txt            # Dependencias de ejecución
├── requirements-dev.txt        # Dependencias de desarrollo y pruebas
├── run.sh                      # Comandos auxiliares
├── README.md                   # Documentación del proyecto
├── env.example                 # Configuración de ejemplo
├── tests/                      # Pruebas de regresión y fixtures
├── LICENSE                     # Términos de la licencia
└── .gitignore                  # Archivos locales y secretos excluidos de Git
```

## Contribuciones

Las contribuciones son bienvenidas, especialmente las que mejoren:

- La validez y reproducibilidad de las pruebas.
- La evaluación semántica más allá de la coincidencia de palabras clave.
- El tratamiento de conversaciones multturno.
- Los informes de errores y el estado de las auditorías incompletas.
- La seguridad de la configuración de proveedores y del acceso a la API.
- Las pruebas automatizadas y la documentación.

Para cambios importantes, incluye pruebas y explica cómo afectan a las métricas existentes o a los resultados de auditoría.

## Licencia

Consulta el archivo [`LICENSE`](LICENSE) para conocer la licencia aplicable y sus condiciones de uso.

---

**Aviso:** Sycophancy Audit no demuestra que un modelo sea veraz, seguro, imparcial o fiable. Proporciona observaciones experimentales para su análisis posterior y no debe utilizarse como único criterio para seleccionar modelos ni para certificar su seguridad.
