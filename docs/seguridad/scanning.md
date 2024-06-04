# Escaneo

El escaneo de seguridad en Kubernetes es un proceso fundamental para garantizar la integridad y protección de los entornos de contenedores y las aplicaciones desplegadas. Kubernetes, al ser una plataforma de orquestación de contenedores, gestiona el despliegue, escalado y operación de aplicaciones contenedorizadas, lo que lo convierte en un objetivo atractivo para posibles ataques. Por ello, implementar prácticas de seguridad robustas es esencial.

El escaneo de seguridad en Kubernetes se centra en dos áreas principales: la búsqueda de vulnerabilidades y el escaneo de manifiestos. La búsqueda de vulnerabilidades implica la identificación de fallos de seguridad en las imágenes de contenedores, configuraciones y dependencias utilizadas por las aplicaciones. Este proceso puede detectar problemas como software desactualizado, configuraciones inseguras y dependencias vulnerables, permitiendo a los administradores remediar estos problemas antes de que sean explotados.

Por otro lado, el escaneo de manifiestos se refiere a la revisión y análisis de los archivos de configuración de Kubernetes, comúnmente escritos en YAML o JSON, que definen el estado deseado del clúster y sus componentes. Estos manifiestos incluyen configuraciones para pods, servicios, despliegues, entre otros. El objetivo del escaneo de manifiestos es asegurar que las configuraciones siguen las mejores prácticas de seguridad y cumplimiento normativo, previniendo configuraciones inseguras como permisos excesivos, falta de políticas de red, y uso incorrecto de secretos.

En conjunto, estas prácticas de escaneo permiten mantener un entorno de Kubernetes más seguro y resiliente, reduciendo la superficie de ataque y mitigando los riesgos asociados con las operaciones de contenedores. Implementar herramientas y procesos automatizados para el escaneo de vulnerabilidades y de manifiestos es crucial para cualquier organización que dependa de Kubernetes para sus aplicaciones y servicios.

## Kubescape

**Kubescape** es una plataforma de seguridad de Kubernetes de código abierto que incluye análisis de riesgos, cumplimiento de seguridad y escaneo de configuraciones incorrectas. Está dirigido a practicantes de DevSecOps o ingenieros de plataformas, ofreciendo una interfaz CLI fácil de usar, formatos de salida flexibles y capacidades de escaneo automatizadas. Ayuda a los usuarios y administradores de Kubernetes a ahorrar tiempo, esfuerzo y recursos valiosos.

Kubescape puede escanear clústeres, archivos YAML y Helm charts, detectando configuraciones incorrectas según múltiples marcos (incluidos NSA-CISA, MITRE ATT&CK® y el CIS Benchmark). Se puede utilizar tanto como CLI como operador dentro del clúster mismo.

### CLI

El CLI de Kubescape consta de un solo binario que se puede descargar y poner en marcha con los siguientes comandos:

```sh
curl -s https://raw.githubusercontent.com/kubescape/kubescape/master/install.sh | /bin/bash
export PATH=$PATH:/home/<user>/.kubescape/bin 
```

Ejecutar `kubescape scan` sin otros parámetros realizará el escaneo de seguridad de visión general/baseline del clúster. Esto realiza algunas comprobaciones clave de seguridad y muestra el número de recursos que tienen ciertos permisos. Luego, puedes configurar reglas de aceptación de riesgos para permitir elementos que se han instalado o configurado deliberadamente en tu clúster.

Por ejemplo, el malware en un clúster a menudo intentará crear un rol de administrador del clúster o un rol con permisos similares. Con el escaneo baseline de Kubescape, puedes identificar qué roles has instalado que deben tener estos permisos, y luego ver fácilmente o ser notificado cuando la configuración cambie desde tu baseline segura.

Para ejecutar un escaneo con un marco específico, utiliza el siguiente comando:

```sh
kubescape scan framework <framework>
```

En modo verbose (cuando se proporciona la bandera `--verbose`), Kubescape realizará un escaneo de tu clúster especificado como de costumbre. La salida incluirá entonces información por recurso para cada recurso que desencadenó un fallo de control, incluyendo un enlace a la documentación para ese control y asistencia en la remediación. Kubescape sugerirá qué parámetros pueden ser cambiados para mitigar o eliminar el fallo.

Kubescape también se puede utilizar para escanear manifiestos antes de ponerlos en producción:

```sh
kubescape scan *.yaml                  # Escanea todos los manifiestos en el directorio
kubescape scan <url de github>         # Escanea todos los manifiestos en un repositorio de GitHub
kubescape scan </path/to/directory>    # Escanea todos los manifiestos dentro de un Helm Chart
```

### Operador

La instalación consta de utilizar el siguiente comando

```sh
helm repo add kubescape https://kubescape.github.io/helm-charts/
helm repo update
helm upgrade --install kubescape kubescape/kubescape-operator -n kubescape --create-namespace --set clusterName=`kubectl config current-context` --set capabilities.continuousScan=enable
```

Cuando se instala en tu clúster, Kubescape se ejecuta como un conjunto de microservicios. Estos te permiten monitorear continuamente la postura de seguridad del clúster en el que está instalado el operador.

El operador Kubescape incluye:

- Escaneo de configuraciones incorrectas.
- Escaneo de todas las imágenes implementadas en busca de vulnerabilidades (CVE).
- Exposición de datos dentro del clúster como objetos de la API de Kubernetes.
- Exportación de datos a un proveedor configurado.
- Permitir un control seguro por parte de un proveedor configurado.

El microservicio `storage` proporciona un servidor de API agregado para exponer los datos de escaneo de Kubescape dentro del clúster.

Los resultados del escaneo dentro del clúster se consideran efímeros, ya que se actualizan regularmente y pueden regenerarse por completo. Si deseas un historial, se recomienda que utilices la interfaz del proveedor de Kubescape para enviar los datos fuera del clúster cuando los escaneos estén completos.

Para ver una lista de los tipos que se agregan a tu clúster, utiliza `kubectl api-resources`.

El operador Kubescape incluye un componente que realiza escaneos de vulnerabilidades de todas las imágenes de contenedor que se están ejecutando en tu clúster.

El componente `Kubevuln` escanea imágenes que se implementan en el clúster cuando:

- Se crea un nuevo Deployment, StatefulSet, DaemonSet o Pod desnudo.
- Se cambia la etiqueta de la imagen del contenedor en un Deployment, StatefulSet, DaemonSet o Pod existente.

Utiliza el motor Grype para evaluar contra una base de datos de vulnerabilidades conocidas de una variedad de fuentes de datos de vulnerabilidades públicamente disponibles. Las fuentes incluyen los datos de anuncios de seguridad de todas las distribuciones de Linux principales, la Base de Datos Nacional de Vulnerabilidades y los avisos de seguridad de GitHub.

Los resultados están disponibles en objetos de API expuestos por el motor de almacenamiento de Kubescape.

#### Resultados

Kubescape proporciona resultados de escaneo como Recursos Personalizados para que puedas acceder a ellos de la misma manera conveniente que accedes a otros objetos de Kubernetes. Por ejemplo, para obtener una vista panorámica de la seguridad de tu clúster, puedes ver el resumen del escaneo de configuración a nivel de clúster con el siguiente comando:

```sh
kubectl get workloadconfigurationscansummaries -o yaml
```

Ejecutar este comando devolverá una lista en formato YAML de los resúmenes de escaneo de configuración para tu clúster por namespaces.

En clústeres con muchos namespaces, los resultados pueden ser abrumadores e incluso pueden exceder el historial de tu terminal. Dado que Kubescape sirve los resultados como objetos de Kubernetes, que son archivos YAML al final del día, puedes aplicar tus procesos habituales para agregarlos de manera legible. Por ejemplo, redirígelos a archivos, editores de texto, etc. Comúnmente usamos el siguiente comando:

```sh
kubectl get workloadconfigurationscansummaries -o yaml | less
```

De esta manera, obtienes el resultado completo en un archivo y puedes navegar por él como mejor te convenga.

## Referencias

[Documentación de Kubescape](https://kubescape.io/docs/)
