# Seguridad

## 1. Configuraciones de aplicaciones inseguras

El contexto de seguridad en una aplicacion es altamente configurable que puede generar configuraciones no seguras a lo largo de otras aplicaciones o el cluster mismo.

Los manifiestos de Kubernetes contienen muchas configuraciones diferentes que pueden afectar la confiabilidad, seguridad y escalabilidad de una aplicación dada. Estas configuraciones deben ser auditadas y corregidas continuamente. A continuación, se presentan algunos ejemplos de configuraciones de manifiestos de alto impacto:

- Los procesos no deben ejecutarse como root: Ejecutar el proceso dentro de un contenedor como el usuario root es una mala configuración común en muchos clústeres. Aunque root puede ser un requisito absoluto para algunas cargas de trabajo, debe evitarse siempre que sea posible. Si el contenedor fuera comprometido, el atacante tendría privilegios de nivel root que permitirían acciones como iniciar un proceso malicioso que de otro modo no estaría permitido con otros usuarios en el sistema.
- Los archivos del sistema con lectura unicamente: Para limitar el impacto de un contenedor comprometido en un nodo de Kubernetes, se recomienda utilizar sistemas de archivos de solo lectura siempre que sea posible. Esto evita que un proceso o aplicación maliciosa escriba en el sistema anfitrión. Los sistemas de archivos de solo lectura son un componente clave para prevenir la evasión de contenedores.
- Containers con privilegios deben ser desactivados: Al configurar un contenedor como privilegiado dentro de Kubernetes, el contenedor puede acceder a recursos adicionales y capacidades del kernel del host. Las aplicaciones que se ejecutan como root, combinados con contenedores privilegiados, pueden ser devastadores, ya que el usuario puede obtener acceso completo al host. Sin embargo, esto se limita cuando se ejecuta como un usuario que no es root. Los contenedores privilegiados son peligrosos ya que eliminan muchos de los mecanismos de aislamiento integrados en los contenedores.
- Los recursos deben ser expresados: En Kubernetes, de manera predeterminada, los contenedores se ejecutan con recursos de cómputo no limitados en un clúster. Sin embargo, se pueden asignar solicitudes y límites de CPU a contenedores individuales dentro de un pod para gestionar mejor el uso de recursos y garantizar un rendimiento predecible. Aunque es una práctica común establecer límites de CPU en Kubernetes, no siempre es necesario y, en muchos casos, puede ser contraproducente. La creencia de que siempre se necesitan límites de CPU puede llevar a una  configuración ineficiente y problemas de rendimiento, siendo el  principal problema el throttling de CPU. Por lo que lo ideal seria asignarle los recursos necesarios y no limitar el CPU.

Una de las herramientas que utilizamos para que corroborar que los manifiestos cumplan con estas pautas de seguridad y otras mas es Kubescape, que se utiliza para escanear configuraciones y políticas en los entornos de Kubernetes para detectar posibles vulnerabilidades y malas configuraciones que podrían poner en riesgo la seguridad de la infraestructura.

## 2. Modo Rootless

Los contenedores rootless se refieren a la capacidad de un usuario sin privilegios para crear, ejecutar y gestionar contenedores. Este término también incluye la variedad de herramientas relacionadas con los contenedores que también pueden ser ejecutadas por un usuario sin privilegios.

"Usuario sin privilegios" en este contexto se refiere a un usuario que no tiene derechos administrativos y "no está en los buenos términos del administrador" (en otras palabras, no tienen la capacidad de solicitar más privilegios o que se instalen paquetes de software).

Pros:

- Puede mitigar potenciales vulnerabilidades de escape de contenedores (no es una panacea, por supuesto).
- Amigable con máquinas compartidas, especialmente en entornos de HPC (computación de alto rendimiento).

Contras:

- Complejidad

Cuando hablamos de contenedores rootless, nos referimos a ejecutar todo el runtime del contenedor, así como los contenedores, sin privilegios de root.

Incluso cuando los contenedores están ejecutándose como usuarios sin privilegios, si el runtime todavía se está ejecutando como root, no los llamamos contenedores rootless.

Aunque permitimos el uso de binarios setuid (y/o setcap) para algunas configuraciones esenciales, como newuidmap, cuando una gran parte del runtime se ejecuta con setuid, no lo llamamos contenedores rootless. Tampoco los llamamos contenedores rootless cuando el usuario root dentro de un contenedor está mapeado al usuario root fuera del contenedor.

### Rootless en K3s

El modo rootless permite ejecutar servidores K3s como un usuario sin privilegios, con el fin de proteger al root real en el host de posibles ataques de escape de contenedores. Esta implementacion cuenta con algunas limitaciones conocidas

#### Limitaciones

- Puertos

Cuando se ejecuta en modo rootless, se crea un nuevo espacio de nombres de red. Esto significa que la instancia de K3s se ejecuta con una red bastante separada del host. La única forma de acceder a los Servicios que se ejecutan en K3s desde el host es configurar reenvíos de puertos al espacio de nombres de red de K3s. K3s rootless incluye un controlador que enlazará automáticamente el puerto 6443 y los puertos de servicios por debajo de 1024 al host con un desplazamiento de 10000.

Por ejemplo, un Servicio en el puerto 80 se convertirá en 10080 en el host, pero 8080 se mantendrá en 8080 sin ningún desplazamiento. Actualmente, solo los Servicios LoadBalancer se enlazan automáticamente.

- Cgroup

Cgroup v1 y el modo híbrido v1/v2 no son compatibles; solo se admite Cgroup v2 puro. Si K3s no logra iniciarse debido a la falta de cgroups cuando se ejecuta en modo rootless, es probable que tu nodo esté en modo híbrido, y los cgroups "faltantes" aún estén enlazados a un controlador v1.

- Cluster Multinodo

Actualmente, los clústeres rootless multinodo o múltiples procesos rootless de K3s en el mismo nodo no son compatibles.

#### Implementación con Multipass y K3sup

Esta seccion utilizo la imagen Ubuntu 22.04 LTS y ademas ya cuenta con cgroupv2. Pero por defecto, un usuario sin privilegios solo puede obtener el controlador de memoria y el controlador de pids delegados. Para permitir la delegación de otros controladores como cpu, cpuset y io, ejecuta los siguientes comandos dentro de nuestra instancia:

```sh
$ sudo mkdir -p /etc/systemd/system/user@.service.d
$ cat <<EOF | sudo tee /etc/systemd/system/user@.service.d/delegate.conf
[Service]
Delegate=cpu cpuset io memory pids
EOF
$ sudo systemctl daemon-reload
```

Reiniciamos la instancia y procemos a instalar k3s-rootless

```sh
# Detenemos el servicio de k3s en Servidor e instalamos uidmap
$ sudo systemctl stop k3s
$ sudo apt install uidmap

# Instalacion del k3s-rootless.service
$ mkdir -p .config/systemd/user
$ cd .config/systemd/user/
$ curl https://raw.githubusercontent.com/k3s-io/k3s/master/k3s-rootless.service -o k3s-rootless.service
$ systemctl --user daemon-reload
$ systemctl --user enable --now k3s-rootless

# Comprobamos el funcionamiento
$ KUBECONFIG=~/.kube/k3s.yaml kubectl get pods -A

# Observacion de logs
$ journalctl --user -f -u k3s-rootless
```

## 3. Vulnerabilidades en la Cadena de Aprovisionamiento

Los contenedores adoptan muchas formas en diferentes fases del ciclo de vida de la cadena de suministro del desarrollo; cada una de ellas presenta desafíos de seguridad únicos. Un solo contenedor puede depender de cientos de componentes y dependencias de terceros, lo que hace que la confianza en el origen en cada fase sea extremadamente difícil. Estos desafíos incluyen, pero no se limitan a, la integridad de la imagen, la composición de la imagen y las vulnerabilidades de software conocidas.

### Aspectos a tener en cuenta

- Integridad de la Imagen: La procedencia del software ha atraído recientemente una atención significativa en los medios debido a eventos como la brecha de SolarWinds y una variedad de paquetes de terceros comprometidos. Estos riesgos de la cadena de suministro pueden surgir en varias etapas del ciclo de construcción del contenedor, así como en tiempo de ejecución dentro de Kubernetes. Cuando no existen sistemas de registro respecto a los contenidos de una imagen de contenedor, es posible que un contenedor inesperado se ejecute en un clúster.
- Composición de la Imagen: Una imagen de contenedor consta de capas, cada una de las cuales puede presentar implicaciones de seguridad. Una imagen de contenedor bien construida no solo reduce la superficie de ataque, sino que también puede aumentar la eficiencia de la implementación. Las imágenes con software innecesario pueden ser utilizadas para elevar privilegios o explotar vulnerabilidades conocidas.
- Vulnerabilidades de Software Conocidas: Debido a su uso extensivo de paquetes de terceros, muchas imágenes de contenedores son inherentemente peligrosas para ser incorporadas en un entorno de confianza y ejecutadas. Por ejemplo, si una capa en una imagen contiene una versión de OpenSSL susceptible a una explotación conocida, esta puede propagarse a varias cargas de trabajo y, sin saberlo, poner en riesgo todo un clúster.

### Grype

Existen muchas herramientas en el mercado (tanto comerciales como de código abierto) que ofrecen escaneo de vulnerabilidades. Recientemente, encontré una herramienta de escaneo de vulnerabilidades muy ligera y ordenada, llamada Grype, gestionada por Anchore.

Grype permite identificar y reportar vulnerabilidades conocidas en imágenes de contenedores, directorios y archivos individuales. Es particularmente útil para desarrolladores y equipos de seguridad que buscan asegurar sus aplicaciones y entornos de despliegue.

#### Instalación

Para instalar grype, alcanza con ejecutar y descargar el binario

```sh
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sudo sh -s -- -b /usr/local/bin
```

#### Uso

Grype puede escanear imagenes provenientes de multiples fuentes ademas de Docker

```sh
# Escanea un archivo de imagen de contenedor(proveniente de `docker image save ...`, `podman save ...`)
grype path/to/image.tar

# Escanea un directorio
grype dir:path/to/dir

# Ejemplo: Escanea la ultima imagen de Grafana disponible
grype docker:grafana/grafana:latest  
```

## 4. Control de Acceso

El Control de Acceso Basado en Roles (RBAC, por sus siglas en inglés) es el mecanismo de autorización principal en Kubernetes y se encarga de los permisos sobre los recursos. Estos permisos combinan verbos (get, create, delete, etc.) con recursos (pods, services, nodes, etc.) y pueden estar limitados a un namespace o ser a nivel de clúster. Se proporcionan una serie de roles predeterminados que ofrecen una separación razonable de responsabilidades dependiendo de las acciones que un cliente pueda querer realizar. Configurar RBAC con la aplicación del principio de privilegio mínimo es un desafío por las razones que exploraremos a continuación.

Cuando un sujeto como una ServiceAccount, Usuario o Grupo tiene acceso al "superusuario" integrado de Kubernetes llamado cluster-admin, pueden realizar cualquier acción sobre cualquier recurso dentro de un clúster. Este nivel de permiso es especialmente peligroso cuando se utiliza en un ClusterRoleBinding, ya que otorga control total sobre todos los recursos en todo el clúster. cluster-admin también puede ser utilizado como RoleBinding, lo cual también puede representar un riesgo significativo.

Para reducir el riesgo de que un atacante abuse de las configuraciones de RBAC (Control de Acceso Basado en Roles), es importante analizar continuamente las configuraciones y asegurarse de que siempre se aplique el principio de privilegio mínimo. A continuación, se presentan algunas recomendaciones:

- Reducir el acceso directo al clúster por parte de los usuarios finales cuando sea posible.
- No utilizar tokens de Cuenta de Servicio fuera del clúster.
- Evitar montar automáticamente el token de la cuenta de servicio por defecto.
- Auditir el RBAC incluido con los componentes de terceros instalados.
- Implementar políticas centralizadas para detectar y bloquear permisos de RBAC riesgosos.
- Utilizar RoleBindings para limitar el alcance de los permisos a espacios de nombres específicos en lugar de políticas RBAC para todo el clúster.

Estas prácticas ayudarán a fortalecer la seguridad y mitigar los riesgos asociados con la configuración de RBAC en entornos Kubernetes.

### Creación de Usuarios

Como ejemplo vamos a crear un usuario fede que solamente tenga acceso a los recursos pods, pero solamente para usar get, list o watch.

Empezamos creando un certificado de usuario con openssl ```

```bash
openssl genrsa -out fede.key 2048
```

Seguimos creando una solicitud de firma del certificado de usuario

```sh
openssl req -new -key fede.key -out fede.csr -subj "/CN=fede/O=rbac"
```

Hasta ahora, el usuario ha generado un certificado que lo identifica y ha creado el fichero con la solicitud de firma del certificado.

Para realizar las siguientes acciones es necesario tener acceso a la clave privada de la entidad certificadora (*CA*) de Kubernetes, por lo que debe realizarlos un administrador del clúster. En K3s los certificados de la entidad certificadora del clúster se encuentran en `/var/lib/rancher/k3s/server/tls/`. A diferencia de lo que sucede en Kubernetes, en K3s tenemos un par de claves para la firma de certificados de usuario `client-ca.crt` y `client-ca.key` 

Para realizar la firma del certificado de usuario, usamos el par de claves `client-ca.*`:

```sh
openssl x509 -req -in fede.csr -out fede.crt -CA client-ca.crt -CAkey client-ca.key -CAcreateserial -days 365
```

Para que el usuario pueda acceder al clúster usando un cliente como `kubectl`, generamos un fichero `kubeconfig` (aunque podemos añadir la misma información a un fichero `kubeconfig` existente)

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: <server-ca.crt base64-encoded>
    server: https://10.182.137.44:6443
  name: default
contexts:
- context:
    cluster: default
    user: fede
    namespace: default
  name: fede-rbac
current-context: fede-rbac
kind: Config
preferences: {}
users:
- name: fede
  user:
    client-certificate-data: <cat fede.crt | base64 -w0>
    client-key-data: <cat fede.key | base64 -w0>
```

Creamos un role que especifica qué acciones (verbs) se pueden realizar sobre los elementos de la API (los recursos).

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: prueba
rules:
- apiGroups: [''] # '' indicates the core API group
  resources: ['pods']
  verbs: ['get', 'watch', 'list']
```

Para asignar los permisos especificados en el *Role* a un usuario, usamos un *RoleBinding* (o un *ClusterRoleBinding*):

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: default
  name: prueba
subjects:
- kind: User
  name: fede
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: prueba
  apiGroup: rbac.authorization.k8s.io
```

Con todas las configuraciones hechas, aplicamos los cambios

```sh
kubectl apply -f role.yaml
kubectl apply -f role-binding.yaml
export KUBECONFIG=kubeconfig 
```

Podemos probarlo con distintos comandos

```sh
$ k get deployments
Error from server (Forbidden): deployments.apps is forbidden: User "fede" cannot list resource "deployments" in API group "apps" in the namespace "default"

$ k get pods
No resources found in default namespace.

```

