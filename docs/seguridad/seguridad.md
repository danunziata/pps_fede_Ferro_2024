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

## 5. Secretos

En las aplicaciones, un 'secret' es un dato sensible que se utiliza en la aplicación y que requiere un 'nivel implícito de seguridad' para proteger dichos secretos, por ejemplo: contraseñas, claves y tokens, entre otros. 

Desde la perspectiva del desarrollo de aplicaciones, normalmente se sigue algún principio de diseño; el principio de diseño más defendido es "Mantener un bajo grado de acoplamiento y un alto grado de cohesión", lo que significa reducir las dependencias al escribir código entre componentes. Para adoptar este principio de diseño, las configuraciones se externalizan del código y se guardan en archivos planos separados llamados 'archivos de configuración', como: YAML, properties, archivos conf, etc. Esta externalización de la configuración también trae consigo la idea de almacenar los secretos aparte del código.

Al igual que los Vaults, Kubernetes (también llamado K8s) proporciona un objeto para almacenar secretos opacos, certificados y claves privadas. Sin embargo, no se considera tan seguro en comparación con los vaults especializados porque los secretos de Kubernetes se almacenan por defecto sin cifrar en el almacén de datos subyacente del servidor API (etcd). Cualquier persona con acceso a la API puede recuperar y modificar un secreto de Kubernetes. Además, estos secretos pueden ser utilizados por diferentes objetos como Pods (montándolos en rutas similares a Kubernetes ConfigMap).

En Kubernetes, los objetos (objetos de K8s como ConfigMap, Secrets, Deployment, Pod, etc.) se crean mediante configuraciones declarativas basadas en YAML. Y las herramientas de gestión de código fuente (SCM) como Git, SVN, etc., se utilizan para almacenar el código fuente y las configuraciones declarativas (por ejemplo, YAMLs de K8s) del código fuente de la aplicación para mantener el control de versiones, el intercambio de código, la liberación y el etiquetado. En este caso, la configuración declarativa (YAML de K8s) para crear secretos de Kubernetes también necesita ser almacenada en el SCM. Esto expondrá el 'secreto' a todos los usuarios que tengan acceso al código en el SCM.

Para resolver este requisito, Bitnami Lab proporciona una utilidad llamada 'SealedSecret y Kubeseal'. SealedSecret / Kubeseal y su caso de uso se discuten en la siguiente sección.

### KubeSeal

SealedSecret y Kubeseal son una extensión de Kubernetes Secret creada por Bitnami Labs como parte del componente Sealed-Secret. Añade una capa adicional de cifrado a la configuración declarativa YAML del secreto, que luego puede almacenarse en cualquier herramienta de gestión de código fuente (SCM). El acceso inmediato no obtendrá el valor real del secreto al leerlo.

El Sealed-Secret se instala en el clúster de Kubernetes y gestiona el flujo de cifrado de secretos. El flujo es muy sencillo: cifra el secreto y crea un nuevo objeto de Kubernetes llamado SealedSecret.

**SealedSecret:** Un SealedSecret es un objeto en Kubernetes (disponible una vez que se instala Bitnami Labs Sealed-Secret) que es una extensión de K8s Secret y que almacena secretos cifrados.

#### Implementación

instalar la utilidad kubeseal desde donde deseas conectarte al clúster de Kubernetes, idealmente en la misma máquina donde está instalado kubectl

```sh
KUBESEAL_VERSION='0.26.0'
curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION:?}/kubeseal-${KUBESEAL_VERSION:?}-linux-amd64.tar.gz"
tar -xvzf kubeseal-${KUBESEAL_VERSION:?}-linux-amd64.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

Bitnami Labs ha proporcionado un paquete Helm para instalar **SealedSecret**. Para instalar SealedSecret en el clúster de K8s, utilizaremos el gestor de paquetes Helm.

```sh
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
helm install sealed-secrets -n kube-system --set-string fullnameOverride=sealed-secrets-controller sealed-secrets/sealed-secrets
```

Con los componentes instalados, creamos un secret de ejemplo con el nombre `ejemplo.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  creationTimestamp: null
  name: ejemplo
data:
  ejemplo: ZWplbXBsbw==
```

Convertimos nuestro secret a un SealedSecret

```sh
kubeseal --controller-name=sealed-secrets-controller --controller-namespace=kube-system --format yaml --secret-file ejemplo.yaml > mysealedsecret-ejemplo.yaml
```

Creará un archivo llamado `mysealedsecret-ejemplo.yaml` con el siguiente contenido (el YAML declarativo para SealedSecret):

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  creationTimestamp: null
  name: ejemplo
  namespace: default
spec:
  encryptedData:
    ejemplo: AgBNeeDOIJGmS6j49Mw0PYLsPh2jjiFKLlIVGc0j6l7aNrA6K0K+MJYTAlf1QZHNAmfG9h/wSzbRbBwSbnoewO6v9uPtiF/E1VWuIIN7yh6FJCykQcd+Yfk2Tw/ToQz7YnNq6tBG0melnE0itBn1PrBFFCfYMMldc0vq8u9iHEAe0bIlfQIvZV17ZrskzQgOBnGV03bNlI+VWGtxNT+he+98tZNW9wujEhlF0X66OWuqIvZpH7eJMeumYVBjBJmbltD1bozpJFJM8mu8+ZoUtxLVMwNOdwOGjMdTB8UFOhHh/ByG0ups15EAADCIOTaal+BNOKYXWbvYTUGhPBeanTYO9Z0Skv+prPhNNDAhBuNQGIX6+kXp+O+rdqOmnejnKFdpgWR4cdsFpguW8HplgmvyTVc+snkihV+nStqLXBxLpbTuVASfFSe9Om47/Mv7/Slf1wb+/+7kP9Sh7O+zIEDLzBuXdLy62IYiI6upGOCVOVenK1CNV1I/dwDWFR5mk82mVHT1dwUmYXQibtlfUVlQmrWgseeDIC9zbmc5Y6Xp2zuzJPWZMmmfjUscUbuojnBKTeJw7weDeoiM5eL4QaQyPvqqX5m0WvrWopYU7obAhF/UfMVwl9IwhygZSVEvRfIFQPAg7XNBwyqgGh5qyuh95P3RE0wOW+xvdfUjeb8y1txdT09b6u/7bcAzXbV9GK2WopUrGvuq
  template:
    metadata:
      creationTimestamp: null
      name: ejemplo
      namespace: default
```

Ahora, tenemos el archivo YAML declarativo de SealedSecret que se puede usar para crear un SealedSecret en K8s.

```sh
kubectl apply -f mysealedsecret-ejemplo.yaml
```

De esta forma el cluster desencripta el secret y lo coloca en el cluster de Kubernetes

### Vault by Hashicorp

HashiCorp Vault es una herramienta de gestión de secretos que se utiliza para controlar el acceso a secretos sensibles, como tokens de API, contraseñas, certificados y claves de cifrado. Aquí hay una breve descripción de cómo funciona Vault:

1. **Almacenamiento Seguro de Secretos**: Vault permite almacenar secretos en un almacenamiento seguro y centralizado. Los secretos pueden ser estáticos (como contraseñas) o dinámicos (como tokens de acceso que expiran después de un tiempo).

2. **Autenticación**: Los usuarios y aplicaciones deben autenticarse antes de acceder a los secretos. Vault admite múltiples métodos de autenticación, como LDAP, GitHub, tokens, y métodos de autenticación de nube como AWS IAM.

3. **Control de Acceso**: Vault utiliza políticas para controlar quién puede acceder a qué secretos. Las políticas definen qué operaciones (lectura, escritura, borrado) están permitidas en qué caminos dentro del almacenamiento de secretos.

4. **Rotación de Secretos**: Vault puede rotar automáticamente los secretos, como contraseñas de bases de datos, a intervalos regulares para mejorar la seguridad. Esto ayuda a minimizar el riesgo de exposición a largo plazo.

5. **Auditoría**: Vault mantiene un registro de auditoría detallado de todas las operaciones que se realizan, proporcionando visibilidad y rastreo de acceso a los secretos.

6. **Cifrado**: Todos los datos almacenados en Vault están cifrados tanto en tránsito como en reposo. Vault utiliza algoritmos de cifrado fuertes para proteger los datos sensibles.

7. **Almacenamiento Dinámico de Credenciales**: Vault puede generar credenciales temporales bajo demanda para servicios como bases de datos y nubes. Esto reduce la necesidad de gestionar credenciales estáticas.

8. **API**: Vault proporciona una API RESTful que permite a las aplicaciones interactuar con Vault para gestionar secretos de manera programática.

#### Implementación

Ejecutar Vault en Kubernetes es generalmente lo mismo que ejecutarlo en cualquier otro lugar. Kubernetes, como un motor de orquestación de contenedores, facilita algunas de las cargas operativas y los Helm charts proporcionan el beneficio de una interfaz refinada para desplegar Vault en una variedad de modos diferentes.

Vault gestiona los secretos que se escriben en estos volúmenes montables. Para proporcionar estos secretos se requiere un único servidor de Vault. Para esta demostración, Vault puede ejecutarse en modo de desarrollo para manejar automáticamente la inicialización, el desbloqueo y la configuración de un motor de secretos KV.

Agregar el repositorio de Helm de HashiCorp:

```bash
$ helm repo add hashicorp https://helm.releases.hashicorp.com
"hashicorp" has been added to your repositories
```

Actualizar todos los repositorios para asegurar que Helm esté al tanto de las últimas versiones:

```bash
$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "secrets-store-csi-driver" chart repository
...Successfully got an update from the "hashicorp" chart repository
Update Complete. ⎈Happy Helming!⎈
```

Para verificar, busca repositorios para vault en charts:

```bash
$ helm search repo hashicorp/vault
NAME            CHART VERSION   APP VERSION DESCRIPTION
hashicorp/vault 0.20.0          1.10.3      Official HashiCorp Vault Chart
```

Crea un archivo llamado helm-vault-raft-values.yml con el siguiente contenido:

```bash
$ cat > helm-vault-raft-values.yml <<EOF
server:
   affinity: ""
   ha:
      enabled: true
      raft: 
         enabled: true
         setNodeId: true
         config: |
            cluster_name = "vault-integrated-storage"
            storage "raft" {
               path    = "/vault/data/"
            }
         listener "tcp" {
           address = "[::]:8200"
           cluster_address = "[::]:8201"
           tls_disable = "true"
        }
        service_registration "kubernetes" {}
EOF
```

Instalar la última versión del Helm chart de Vault con Almacenamiento Integrado:

```bash
$ helm install vault hashicorp/vault --values helm-vault-raft-values.yml
```

Esto crea tres instancias del servidor de Vault con un backend de almacenamiento integrado (Raft).

Los pods de Vault y el pod de Vault Agent Injector se despliegan en el namespace `default`.

Inicializa vault-0 con una clave compartida y un umbral de clave:

```bash
$ kubectl exec vault-0 -- vault operator init \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json > cluster-keys.json
```

El comando operator init genera una clave raíz que descompone en partes de clave -key-shares=1 y luego establece el número de partes de clave necesarias para desbloquear Vault -key-threshold=1. Estas partes de clave se escriben en la salida como claves de desbloqueo en formato JSON -format=json. Aquí la salida se redirige a un archivo llamado cluster-keys.json.

Muestra la clave de desbloqueo encontrada en cluster-keys.json:

```bash
$ jq -r ".unseal_keys_b64[]" cluster-keys.json
```

Crea una variable llamada VAULT_UNSEAL_KEY para capturar la clave de desbloqueo de Vault:

```bash
$ VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" cluster-keys.json)
```

Después de la inicialización, Vault está configurado para saber dónde y cómo acceder al almacenamiento, pero no sabe cómo desencriptar nada de él. Desbloquear es el proceso de construir la clave raíz necesaria para leer la clave de desencriptación para desencriptar los datos, permitiendo el acceso a Vault.

Desbloquea Vault que se ejecuta en el pod vault-0:

```bash
$ kubectl exec vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
```

**Operación insegura**

Proporcionar la clave de desbloqueo en la línea de comandos puede ser riesgoso porque otras aplicaciones en el host pueden registrar la actividad de la línea de comandos. Este enfoque solo se usa aquí para simplificar el proceso de desbloqueo para esta demostración.

Verifica que el estado del pod de Vault cambie de `sealed` a `unsealed`.

En este punto, puedes continuar con los otros pods de Vault en el clúster, vault-1 y vault-2.

Desbloquea vault-1:

```bash
$ kubectl exec vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY
```

Desbloquea vault-2:

```bash
$ kubectl exec vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY
```

Para configurar un secreto en Vault , necesitas iniciar sesión con el token raíz, habilitar el motor de secretos (kv-v2) y almacenar el nombre de usuario y la contraseña en la ruta definida.

Recupera el token raíz del archivo `cluster-keys.json`:

```sh
$ jq -r ".root_token" cluster-keys.json
```

Inicia una sesión interactiva en el pod `vault-0`:

```sh
$ kubectl exec --stdin=true --tty=true vault-0 -- /bin/sh
/ $
```

Inicia sesión en Vault utilizando el token raíz:

```sh
$ vault login
Token (will be hidden):
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                
token_accessor       
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

Habilita una instancia del motor de secretos `kv-v2` en la ruta `secret`:

```sh
$ vault secrets enable -path=secret kv-v2
Success! Enabled the kv-v2 secrets engine at: secret/
```

Crea un secreto en la ruta `secret/webapp/config` con un nombre de usuario y una contraseña:

```sh
$ vault kv put secret/webapp/config username="static-user" password="static-password"
====== Secret Path ======
secret/data/webapp/config

======= Metadata =======
Key                Value
---                -----
created_time       2022-06-07T05:15:19.402740412Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1
```

Verifica que el secreto esté definido en la ruta `secret/webapp/config`:

```sh
$ vault kv get secret/webapp/config
====== Secret Path ======
secret/data/webapp/config

======= Metadata =======
Key                Value
---                -----
created_time       2022-06-07T05:15:19.402740412Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1

====== Data ======
Key         Value
---         -----
password    static-password
username    static-user
```

Salimos del pod `vault-0`:

```sh
$ exit
```

Para proporcionar de manera segura acceso a los secretos de Vault a tu aplicación web, configura la autenticación de Kubernetes.

Inicia una sesión interactiva en el pod `vault-0`:

```sh
$ kubectl exec --stdin=true --tty=true vault-0 -- /bin/sh
/ $
```

Habilita el método de autenticación de Kubernetes:

```sh
$ vault auth enable kubernetes
Success! Enabled kubernetes auth method at: kubernetes/
```

Configura el método de autenticación de Kubernetes para usar la ubicación de la API de Kubernetes:

```sh
$ vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"
Success! Data written to: auth/kubernetes/config
```

Escribe la política denominada `webapp` que habilita la capacidad de lectura para los secretos en la ruta `secret/data/webapp/config`:

```sh
$ vault policy write webapp - <<EOF
path "secret/data/webapp/config" {
  capabilities = ["read"]
}
EOF
Success! Uploaded policy: webapp
```

Crea un rol de autenticación de Kubernetes denominado `webapp` que conecta el nombre de la cuenta de servicio de Kubernetes y la política `webapp`:

```sh
$ vault write auth/kubernetes/role/webapp \
        bound_service_account_names=vault \
        bound_service_account_namespaces=default \
        policies=webapp \
        ttl=24h
Success! Data written to: auth/kubernetes/role/webapp
```

Sal del pod `vault-0`:

```sh
$ exit
```

Has configurado con éxito Vault y configurado la autenticación de Kubernetes para tus aplicaciones
