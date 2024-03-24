# DevSecOps

Vendría a ser como un triangulo que esta compuesto por: el desarrollo, la seguridad y las operaciones. El objetivo es integrar la seguridad en nuestro CI/CD ya sea en preproduccion o produccion.

![image-20240316174332688](/home/fede/pps_fede_Ferro_2024/docs/images/image-20240316174332688.png)

DevOps gano importancia en los ultimos años ya que combina principios clave de las operaciones con los ciclos de desarrollo.

La seguridad refiere a todas las herramientas y tecnicas necesarias para diseñar y construir una aplicacion capaz de resistir ataques, capaz de detectarlos y responder a ellas lo mas rapido posibles. Agregando la seguridad a DevOps, desde el inicio del diseño hasta la eventual implementacion, las distintas organizaciones pueden alinear estos tres componentes fundamientales en la creacion y entrega de software.

DevSecOps permite que las pruebas de seguridad ocurran al mismo tiempo que otros desarrollos o testeos se encuentren en marcha.

![image-20240316175103247](/home/fede/pps_fede_Ferro_2024/docs/images/image-20240316175103247.png)

El primer desafío implica capacitar a los equipos de DevOps en seguridad y promover una cultura de responsabilidad sobre la seguridad del software. El segundo desafío es encontrar y integrar herramientas de  seguridad adecuadas en el flujo de trabajo de DevOps. La automatización  es clave, pero las herramientas tradicionales pueden no ser suficientes  debido a cambios en el entorno de desarrollo, como el aumento del  software de código abierto y las aplicaciones en contenedores.

# Observabilidad

**La observabilidad se refiere a cómo se puede comprender el  estado interno de un sistema mediante el examen de sus salidas externas, en especial, sus datos.**

En el contexto del desarrollo de aplicaciones modernas, la  observabilidad hace referencia a la recopilación y el análisis de datos  (logs, métricas y rastreos) de una gran variedad de fuentes, con el  objetivo de brindar información detallada sobre el comportamiento de las aplicaciones que se ejecutan en tus entornos. Se puede aplicar a  cualquier sistema que compiles y desees monitorear. 

Esto se hace con la ayuda de visualizaciones (dashboards, mapas de  dependencias de servicios y rastreos distribuidos), así como con  enfoques de AIOps y machine learning. Con la solución de observabilidad  adecuada, puedes comprender el rendimiento de tus aplicaciones,  servicios e infraestructura para rastrear problemas y responder a ellos.

La observabilidad es importante porque permite a los equipos evaluar,  monitorear y mejorar el rendimiento de sistemas de IT distribuidos. Es  mucho más efectiva que los métodos de monitoreo tradicionales. Una  plataforma de observabilidad integral puede ayudar a desarmar silos y  fomentar la colaboración. Los problemas pueden diagnosticarse,  analizarse y rastrarse hasta sus orígenes de forma proactiva. 

Los tres pilares de la observabilidad son los **logs**, las **métricas** y los **rastreos**. La observabilidad del stack completo te permite rastrear el rendimiento de tu ecosistema multicloud histórico y en tiempo real. 

La observabilidad lleva a una entrega de aplicaciones más rápida y de  mayor calidad, lo que significa ahorro de costos y optimización de  recursos para tus equipos. Las aplicaciones con mejor rendimiento  llevan, en última instancia, a más ingresos.

# Diferentes áreas de aplicacion de seguridad en Kubernetes

## Configuración de Seguridad en el Cluster

- Permisos y controles de acceso

- Seguridad para el servidor API

- Auditar configuracion del cluster

- Políticas de seguridad de los PODS

- Políticas de red

- Requerimientos regulatorios


## Manejo de Identidad y Acceso

- Métodos de autentificacion seguros
- Acceso de control basado en la implementacion de roles
- Utilización de recursos
- Monitorear al usuario
- Asegurar al acceso al panel de control
- Proteger las credenciales
- Segmentación de redes para isolar los nodos y los pods del publico
- Monitorear anomalías

## Seguridad de red

- Segmentación e Isolacion de la red
- Políticas de red
- Herramientas de seguridad de red
- Encriptacion de datos
- Canales seguros de comunicacion
- Habitar la encriptacion SSL/TLS
- Ocultar los metadata de los kubernetes
- Deshabilitar servicios innecesarios
- Monitoreo de trafico
- Implementar procedimientos de respuesta 

## Seguridad del Nodo

- Seguridad del sistema operativo
- Seguridad de la red
- Seguridad del nodo
- Seguridad de los containers
- Seguridad de los contenedores de imaganes

## Seguridad del Pod

- Seguridad de los kubernetes 
- Usar contenedores seguros
- Principios menos priviligiados
- Montar volumenes seguros
- Utilizar variables de ambiente seguras
- Actividad del Pod
- Control de Acceso

## Seguridad de la imagen

- Registros del contenedor
- Escaneo de la imagen
- Actualizaciones

## Administracion de Secrets

## Monitoreo

## Recuperacion BackUp 



# Kubernetes

Kubernetes es una plataforma portable y extensible de código abierto para administrar cargas de trabajo y servicios. Kubernetes facilita la automatización y la configuración declarativa. Tiene un ecosistema grande y en rápido crecimiento. El soporte, las herramientas y los servicios para Kubernetes están ampliamente disponibles.

Kubernetes ofrece un entorno de administración **centrado en contenedores**. Kubernetes orquesta la infraestructura de cómputo, redes y almacenamiento para que las cargas de trabajo de los usuarios no tengan que hacerlo. Esto ofrece la simplicidad de las Plataformas como Servicio (PaaS) con la flexibilidad de la Infraestructura como Servicio (IaaS) y permite la portabilidad entre proveedores de infraestructura.

A pesar de que Kubernetes ya ofrece muchas funcionalidades, siempre hay nuevos escenarios que se benefician de nuevas características. Los flujos de trabajo de las aplicaciones pueden optimizarse para acelerar el tiempo de desarrollo. Una solución de orquestación propia puede ser suficiente al principio, pero suele requerir una automatización robusta cuando necesita escalar. Es por ello que Kubernetes fue diseñada como una plataforma: para poder construir un ecosistema de componentes y herramientas que hacen más fácil el desplegar, escalar y administrar aplicaciones.

Las etiquetas, o [Labels](https://kubernetes.io/es/docs/concepts/overview/working-with-objects/labels/), le permiten a los usuarios organizar sus recursos como deseen. Las anotaciones, o [Annotations](https://kubernetes.io/es/docs/concepts/overview/working-with-objects/annotations/), les permiten asignar información arbitraria a un recurso para facilitar sus flujos de trabajo y hacer más fácil a las herramientas administrativas inspeccionar el estado.

Además, el [Plano de Control](https://kubernetes.io/docs/concepts/overview/components/) de Kubernetes usa las mismas [APIs](https://kubernetes.io/docs/reference/using-api/api-overview/) que usan los desarrolladores y usuarios finales. Los usuarios pueden escribir sus propios controladores, como por ejemplo un planificador o [scheduler](https://github.com/kubernetes/community/blob/master/contributors/devel/scheduler.md), usando [sus propias APIs](https://kubernetes.io/docs/concepts/api-extension/custom-resources/) desde una [herramienta de línea de comandos](https://kubernetes.io/docs/user-guide/kubectl-overview/).

Este diseño ha permitido que otros sistemas sean construidos sobre Kubernetes.

Cuando se despliega Kubernetes, obtenemos un Cluster. Consiste en un grupo de workers, llamados nodos, que corren aplicaciones en contenedores. Cada Cluster tiene un nodo mínimo.

Los nodos workers alojan los Pods que son los componentes de la  carga de trabajo de la aplicación. El plano de control gestiona los nodos de trabajadores y los Pods en el clúster. En entornos de producción, el plano de control generalmente se ejecuta en múltiples computadoras y un Clúster generalmente ejecuta múltiples nodos,  proporcionando tolerancia a fallos y alta disponibilidad.

![Components of Kubernetes](/home/fede/pps_fede_Ferro_2024/docs/images/components-of-kubernetes.svg)
