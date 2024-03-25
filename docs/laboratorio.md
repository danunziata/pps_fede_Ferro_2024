# Laboratorio

En este documento, desarrollaremos un entorno de laboratorio que sea capaz de replicar el cluster en donde iremos a trabajar de una forma mas liviana que sea capaz de soportarla nuestra maquina personal. A continuacion describiremos algunos de los software que utilizaremos para poder construir nuestro entorno de laboratorio.

## ZSH

zsh es un intérprete de comandos de Unix que ofrece funcionalidades avanzadas en comparación con otros shells comunes, como Bash (Bourne Again Shell). Zsh incluye características como completado de comandos más robusto, expansión de nombres de archivo mejorada, temas y personalización más avanzada, corrección ortográfica integrada, entre otras. Es altamente configurable y es utilizado por muchos usuarios  avanzados y desarrolladores como su shell predeterminado debido a su  potencia y flexibilidad.

Para Instalarlo simplemente ejecutamos la siguiente linea en nuestra terminal

``````bash
sudo apt-get install zsh
``````

Para ejecutarlo

``````bash
zsh
``````

En caso de que se quiera personalizar el shell se puede descargar el framework Oh My Zsh con el siguiente comando

``````bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
``````

Toda la documentación acerca de ohmyzsh se encuentra en la [wiki](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes).

## Minikube

Minikube es una herramienta de código abierto que facilita la creación y ejecución de clústeres de Kubernetes localmente en una máquina individual. En un sentido técnico, Minikube utiliza una máquina virtual para crear un entorno de clúster de Kubernetes que se ejecuta en una sola instancia de host. Utiliza tecnologías como Docker y KVM (Kernel-based Virtual Machine) para emular un entorno de múltiples nodos Kubernetes en una sola máquina física, lo que permite a los desarrolladores experimentar, probar y desarrollar aplicaciones Kubernetes sin necesidad de un entorno de producción completo. Minikube proporciona una forma rápida y conveniente de familiarizarse con Kubernetes y probar aplicaciones en un entorno de desarrollo local antes de implementarlas en un clúster de producción.

### KVM (Kernel Virtual Machine)

KVM es una solución de virtualización completa para Linux en hardware x86 que contiene extensiones de virtualización (Intel VT o AMD-V). Consiste en un módulo de kernel cargable que proporciona la infraestructura de virtualización central y un módulo específico del procesador.

Usando KVM, uno puede ejecutar múltiples máquinas virtuales ejecutando imágenes de Linux o Windows sin modificar. Cada máquina virtual tiene hardware virtualizado privado: una tarjeta de red, disco, adaptador gráfico, etc. Utilizaremos esta solucion para montar nuestro cluster.

#### Instalación 

Observar si nuestros requisitos cumplen con los requeridos.

``````bash
egrep -c '(vmx|svm)' /proc/cpuinfo # Tiene que ser un numero diferente de 0
kvm-ok # Comprueba si se puede utilizar aceleracion KVM
egrep -c ' lm ' /proc/cpuinfo # Tiene que ser un numero diferente de 0
uname -m # Tiene que ser de 64 bits (x86_64)
``````

Se instalan las siguientes librerias

```bash
sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
```

- **libvirt-bin** administra las instancias qemu y kvm usando libvirt
- **qemu-kvm** corresponde al back-end
- **ubuntu-vm-builder** es una herramienta de lineas de comando que crea maquinas virtuales
- **bridge-utils** provee un bridge entre la red y las maquinas virtuales

Se agrega el usuario a los grupos correspondientes, se necesita reiniciar el sistema despues de aplicar estas configuraciones

```bash
sudo adduser `id -un` libvirt
sudo adduser `id -un` kvm
```

Para verificar la instalacion necesitamos escribir

``````bash
virsh list --all # No nos debe dar ningun error
``````

### Kubectl

Es una herramienta de línea de comandos de Kubernetes para desplegar y gestionar aplicaciones en Kubernetes. Usando kubectl,  puedes inspeccionar recursos del clúster; crear, eliminar, y actualizar  componentes; explorar tu nuevo clúster y arrancar aplicaciones.

#### Instalación

Descargar la ultima version

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```

Instalarlo

```bash
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

Comprobar que se ha instalado de manera correcta

```bash
kubectl version --client
```

### Desplegar Kubernetes

Para comenzar, iniciaremos arrancando el cluster teniendo en cuenta los parámetros que queremos que cumpla. Para ello, propondremos la siguiente linea de comando

```bash
minikube start --driver=kvm2 --nodes="Cantidad de nodos" --memory="Cantidad de Memoria" --cpu="Cantidad de cpu"
```

A partir de aqui, nosotros podemos empezar a experimentar con la creacion de Pods que sean capaces de alojar nuestras aplicaciones.

Un Pod es un grupo de uno o más contenedores, con almacenamiento/red compartidos, y unas especificaciones de cómo ejecutar los contenedores. Los contenidos de un Pod son siempre coubicados, coprogramados y ejecutados en un contexto compartido. Un Pod modela un "host lógico" específico de la aplicación: contiene uno o más contenedores de aplicaciones relativamente entrelazados. Antes de la llegada de los contenedores, ejecutarse en la misma máquina física o virtual significaba ser ejecutado en el mismo host lógico.

### Comandos utiles

En este apartado colocaremos algunos comandos que nos seran de utilidad para poder explorar a traves de los kubernetes

```bash
# información del cluster
kubectl cluster-info 

# lista de los nodos del cluster
kubectl get nodes  

# Descripcion del Nodo
kubectl describe node "Nombre del Nodo"

# Elimina un Nodo
kubectl delete node "Nombre del Nodo"

# lista de los servicios 
kubectl get service 

# lista de los pods
kubectl get pods   

# lista de deployments 
kubectl get deployments 

# lista de namespaces
kubectl get namespaces 

# lista de los pods del namespace prueba
kubectl get pods -n prueba  

# exponer un deployment
kubectl expose deployment "Nombre del deployment" --port="Numero de Puerto" --type=NodePort 

# información detallada del pod
kubectl describe pod "Nombre del Pod"

# eliminar servicio
kubectl delete service "Nombre del Servicio"

# eliminar deployment
kubectl delete deployment "Nombre del deployment" 

# escalar a 3 replicas un deployment
kubectl scale --replicas="Cantidad de Replicas" "Deployment"-n "Nombre del Namespace"

# acceder al pod  
kubectl --namespace="nombre del namespace" exec -it "nombre del pod" bash  

# crear un secret
kubectl create secret generic "Nombre del Secret"

# aplicar el contenido del fichero
kubectl apply -f "Nombre del fichero"
```

## Despliegue de una aplicación Python

Para concluir con este entorno de laboratorio, desplegaremos una aplicacion web programada en python como es Flask para hacer uso de todo el conocimiento que vimos en este documento.

Empezaremos creando un Cluster simple de 2 nodos utilizando KVM, por el momento dejaremos el uso de nucleos y de RAM por defecto

```bash
minikube start --driver=kvm2 --nodes=2
```

Comprobamos que los nodos han sido habilitados de manera correcta

```bash
kubectl get nodes
```

Para correr la aplicacion utilizaremos el siguiente archivo deployment.yaml que cuenta con todo lo que necesitamos para ejecutar la aplicacion

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-python-service
spec:
  selector:
    app: hello-python
  ports:
  - protocol: "TCP"
    port: 6000
    targetPort: 5000
  type: LoadBalancer

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-python
spec:
  selector:
    matchLabels:
      app: hello-python
  replicas: 4
  template:
    metadata:
      labels:
        app: hello-python
    spec:
      containers:
      - name: hello-python
        image: hello-python:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 5000
```

Como se observa en este script, se estan aplicando 2 caracteristicas que distinguen a los Kubernetes:

- **Servicio LoadBalancer**: es la forma estándar de exponer un servicio a Internet. Si se desea exponer directamente un servicio, este es el método  predeterminado. Todo el tráfico en el puerto que especifique se reenviará al servicio. No hay filtrado, ni enrutamiento, etc. Esto  significa que puedes enviarle casi cualquier tipo de tráfico, como HTTP, TCP, UDP, Websockets, gRPC o lo que sea. En este caso se le expone el puerto 5000 para que pueda ser accedido de forma local por el puerto 6000.
- **Deployment**: se refiere a un objeto que describe cómo se debe implementar y actualizar una aplicación en el clúster. Proporciona un enfoque declarativo para definir el estado deseado de la aplicación y permite que Kubernetes se encargue de llevar el estado actual al estado deseado de manera eficiente y confiable. Simplifica el proceso de despliegue y actualización de aplicaciones, proporcionando una forma estandarizada y automatizada de administrar el ciclo de vida de las aplicaciones en un clúster. En este caso se hace uso de una imagen que contiene lo necesario para correr la aplicacion y ademas se crean 4 replicas, es decir que 4 pods tendran esta aplicacion.

Aplicamos el archivo con kubectl para que el cluster los ponga en marcha

```bash
kubectl apply -f deployment.yaml
```

Y listo, podemos comprar que nuestros pods estan funcionando con la aplicacion con el comando

```bash
kubectl get pods
```

Podemos entrar a la aplicacion a traves de http://localhost:6000 o podemos consultar la ip que tiene el minikube con

```bash
minikube ip
```

De esta manera, podemos probar nuestras aplicaciones de forma local para luego mandarlas posteriormente a produccion.

