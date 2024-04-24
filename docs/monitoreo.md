# Monitoreo

## PLG Stack

No te sorprendas si no encuentras este acrónimo, es más conocido como Grafana Loki. De todos modos, este conjunto de herramientas está ganando popularidad debido a sus decisiones de diseño concretas. Quizás conozcas Grafana, que es una herramienta de visualización popular. Grafana Labs diseñó Loki, que es un sistema de agregación de registros horizontalmente escalable, altamente disponible y multiinquilino inspirado en Prometheus. Solo indexa metadatos y no el contenido del registro. Esta decisión de diseño lo hace muy rentable y fácil de operar.

**Promtail** es un agente que manda los logs del sistema local al cluster de Loki.

**Grafana** es la herramienta de visualización que consume la información proveniente de Loki.

**Loki** se construye sobre los mismos principios de diseño que Prometheus, por lo tanto, es una buena opción para almacenar y analizar los registros de Kubernetes.

![PLG Stack](/home/fede/pps_fede_Ferro_2024/docs/images/plg-stack.png)

### Componentes

- Promtail: Este es el agente que se instala en los nodos (como Daemonset); extrae los registros de los trabajos y se comunica con el servidor de API de Kubernetes para obtener los metadatos y utilizar esta información para etiquetar los registros. Luego, reenvía el registro al servicio central de Loki. Los agentes admiten las mismas reglas de etiquetado que Prometheus para asegurarse de que los metadatos coincidan.
- Distribuidor: Promtail envía registros al distribuidor, que actúa como un búfer. Para manejar millones de escrituras, agrupa el flujo de entrada y lo comprime en bloques a medida que llegan. Hay múltiples ingesters, los registros pertenecientes a cada flujo terminarían en el mismo ingester para todas las entradas relevantes en el mismo bloque. Esto se hace utilizando el anillo de ingesters y el hashing consistente. Para proporcionar resiliencia y redundancia, lo hace n veces (predeterminado 3).
- Ingester: A medida que llegan los bloques, se comprimen con gzip y se agregan registros. Una vez que el bloque se llena, se vuelca en la base de datos. Los metadatos van a Index y los datos de registro del bloque van a Chunks (generalmente en un almacenamiento de objetos). Después del volcado, el ingester crea un nuevo bloque y agrega nuevas entradas en él.

Algunos de los terminos basicos utilizados son:

- Index: El índice es una base de datos como DynamoDB, Cassandra, Google Bigtable, etc.
- Chunks: El bloque de registros en formato comprimido se almacena en los almacenes de objetos como S3.
- Querier: Esto está en la ruta de lectura y realiza todo el trabajo pesado. Dado el rango de tiempo y el selector de etiquetas, busca en el índice para averiguar cuáles son los bloques coincidentes. Luego, lee esos bloques y realiza una búsqueda para obtener el resultado.

Una vez que el chunk "se llena", lo volcamos en la base de datos.

![Base de Datos](/home/fede/pps_fede_Ferro_2024/docs/images/database.png)

### Arquitectura

![Arquitectura de registros](/home/fede/pps_fede_Ferro_2024/docs/images/arquitectura.png)

### Instalación

Creamos un namespace para desplegar el stack PLG:

```bash
kubectl create namespace loki
```

Utilizamos helm para descargar Grafana

```bash
helm repo add grafana <https://grafana.github.io/helm-charts>
```

Actualizamos el repositorio local en caso de que haya alguna actualización

```bash
helm repo update
```

Desplegamos el Stack PLG

```bash
helm upgrade --install loki loki/loki-stack --namespace=loki --set grafana.enabled=true
```

Obtenemos la contraseña

```bash
kubectl get secret loki-grafana --namespace=loki -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

Exponemos el puerto para ingresar a Grafana de forma local

```bash
kubectl port-forward --namespace loki service/loki-grafana 3000:80
```

Podemos ingresar a Grafana entrando a http://localhost:3000. Ingresando con el usuario **admin** y la contraseña obtenida anteriormente

### Referencias

https://www.infracloud.io/blogs/logging-in-kubernetes-efk-vs-plg-stack/

https://codersociety.com/blog/articles/loki-kubernetes-logging