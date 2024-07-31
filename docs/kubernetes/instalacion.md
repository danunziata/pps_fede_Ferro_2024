# Instalación

En este documento, desarrollaremos dos entornos totalmente diferentes que pueden ser utilizados para replicar el clúster en el que trabajaremos, de una forma más liviana y que pueda ser soportada por nuestra máquina personal.

El primer entorno de desarrollo estará centrado en replicar el clúster de una forma liviana, permitiendo que nuestra máquina personal pueda soportarlo sin problemas. En este caso utilizaremos minikube que es una de las herramientas mas facil de implementar y utilizar a la hora de hacer nuestro primer acercamiento a Kubernetes

El segundo entorno de laboratorio se configurará utilizando KVM y Multipass, diseñado específicamente para instalar Kubernetes utilizando la tecnología k3s. Este método proporciona una solución eficiente y manejable para desplegar Kubernetes en un entorno de virtualización. Tiene una mejor aproximacion a las implementaciones reales.

## Prerequesitos

### ZSH

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

### KVM

Las máquinas virtuales basadas en el kernel (KVM) son una tecnología de virtualizaciónopen source integrada a Linux®. Con ellas, puede transformar Linux en un hipervisor que permite que una máquina host ejecute varios entornos virtuales aislados llamados máquinas virtuales (VM) o guests. 

Las KVM convierten Linux en un hipervisor de tipo 1. Todos los hipervisores necesitan algunos elementos del sistema operativo (por ejemplo, el administrador de memoria, el programador de procesos, la stack de entrada o salida [E/S], los controladores de dispositivos, el administrador de seguridad y la stack de red, entre otros) para ejecutar las máquinas virtuales. Las KVM tienen todos estos elementos porque forman parte del kernel de Linux. Cada máquina virtual se implementa como un proceso habitual de Linux, el cual se programa con la herramienta estándar de Linux para este fin, e incluye sistemas virtuales de hardware exclusivos, como la tarjeta de red, el adaptador gráfico, las CPU, la memoria y los discos.

**Instalación**

```sh
sudo apt update
sudo apt install cpu-checker
kvm-ok							                                         # Comprueba si la virtualizacion esta habilitada
sudo apt install qemu-kvm libvirt-bin bridge-utils virtinst virt-manager # Instala las librerias necesarias
sudo usermod -aG kvm,libvirt $USER 										 # Agrupa un par de grupos a un usuario
sudo systemctl is-active libvirtd										 # "active" si esta todo activado
```

### Kubectl

Es una herramienta de línea de comandos de Kubernetes para desplegar y gestionar aplicaciones en Kubernetes. Usando kubectl, puedes inspeccionar recursos del clúster; crear, eliminar, y actualizar  componentes; explorar tu nuevo clúster y arrancar aplicaciones.

**Instalación**

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

## Desarrollo

Minikube es una herramienta de código abierto que facilita la creación y ejecución de clústeres de Kubernetes localmente en una máquina individual. En un sentido técnico, Minikube utiliza una máquina virtual para crear un entorno de clúster de Kubernetes que se ejecuta en una sola instancia de host. Utiliza tecnologías como Docker y KVM (Kernel-based Virtual Machine) para emular un entorno de múltiples nodos Kubernetes en una sola máquina física, lo que permite a los desarrolladores experimentar, probar y desarrollar aplicaciones Kubernetes sin necesidad de un entorno de producción completo. Minikube proporciona una forma rápida y conveniente de familiarizarse con Kubernetes y probar aplicaciones en un entorno de desarrollo local antes de implementarlas en un clúster de producción.

### Instalación

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
```

### Creacion de Cluster

Para comenzar, iniciaremos arrancando el cluster teniendo en cuenta los parámetros que queremos que cumpla. Para ello, propondremos la siguiente linea de comando

```bash
minikube start --driver=kvm2 --nodes="Cantidad de nodos" --memory="Cantidad de Memoria" --cpu="Cantidad de cpu"
```

A partir de aqui, nosotros podemos empezar a experimentar con la creacion de Pods que sean capaces de alojar nuestras aplicaciones.

Un Pod es un grupo de uno o más contenedores, con almacenamiento/red compartidos, y unas especificaciones de cómo ejecutar los contenedores. Los contenidos de un Pod son siempre coubicados, coprogramados y ejecutados en un contexto compartido. Un Pod modela un "host lógico" específico de la aplicación: contiene uno o más contenedores de aplicaciones relativamente entrelazados. Antes de la llegada de los contenedores, ejecutarse en la misma máquina física o virtual significaba ser ejecutado en el mismo host lógico.

### Despliegue de una aplicación Python

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

## Laboratorio



### Multipass

Multipass es un gestor de máquinas virtuales (VM) ligero para Linux, Windows y macOS. Está diseñado para desarrolladores que desean un entorno Ubuntu fresco con un solo comando. Utiliza KVM en Linux, Hyper-V en Windows y QEMU en macOS para ejecutar la VM con una sobrecarga mínima. También puede usar VirtualBox en Windows y macOS. Multipass obtendrá las imágenes por ti y las mantendrá actualizadas.

Dado que admite metadatos para cloud-init, puedes simular un pequeño despliegue en la nube en tu laptop o estación de trabajo.

**Instalación**

```sh
sudo apt update
sudo apt install snapd
sudo snap install multipass
```

### Creación de Instancias

Los nodos en Kubernetes son simplemente máquinas virtuales que trabajan en sincronización. Para nuestro clúster, crearemos 3 máquinas virtuales, cada una con 2 CPU, 2 GB de RAM y 4 GB de almacenamiento.

#### Claves SSH

Crea una clave privada/pública con el siguiente comando:

```sh
ssh-keygen
```

Esto creará los archivos mencionados anteriormente en tu sistema. Copia el contenido de `~/.ssh/id_rsa.pub` con:

```sh
cat ~/.ssh/id_rsa.pub
```

#### Creando el archivo de configuración

Crea un archivo llamado `multipass.yaml` y coloca tu clave pública en `ssh-rsa`.

**multipass.yaml**

```
yaml
ssh_authorized_keys:
  - ssh-rsa <añade-tu-clave-pública>
```

Este archivo de configuración asegura que la clave pública se almacene en la máquina virtual una vez creada. Crearemos nuestras máquinas virtuales con nombres adecuados basados en los roles que les asignaremos (master/worker).

#### Inicialización

```sh
multipass launch jammy --cpus 2 --mem 2G --disk 4G --name master-node --cloud-init multipass.yaml
multipass launch jammy --cpus 2 --mem 2G --disk 4G --name agent-worker --cloud-init multipass.yaml
```

En términos de K3s, un nodo maestro se llama "server" y el resto de los nodos se llaman "agents". Los agentes son simplemente los nodos que se añaden al nodo maestro; pueden ser otro nodo maestro o un nodo trabajador.

### k3sup

k3sup es una utilidad ligera para pasar de cero a KUBECONFIG con k3s en cualquier máquina virtual local o remota. Todo lo que necesitas es acceso SSH y el binario de k3sup para obtener acceso a kubectl de inmediato.

Esta herramienta utiliza SSH para instalar k3s en un host Linux remoto. También puedes usarla para unir hosts Linux existentes a un clúster k3s como agentes. Primero, k3s se instala utilizando el script de utilidad de Rancher, junto con una flag para la IP pública de tu host para que TLS funcione correctamente. Luego, se obtiene y actualiza el archivo kubeconfig en el servidor para que puedas conectarte desde tu laptop usando kubectl.

k3sup se desarrolló para automatizar lo que puede ser un proceso muy manual y confuso para muchos desarrolladores, que ya están cortos de tiempo. Una vez que has provisionado una VM con tu herramienta favorita, k3sup significa que solo estás a 60 segundos de ejecutar `kubectl get pods` en tu propia computadora. Si estás en una computadora local, puedes omitir SSH con `k3sup install --local`.

### Instalación

```sh
curl -sLS https://get.k3sup.dev | sh
sudo install k3sup /usr/local/bin/
```

### Añadiendo nodos con k3sup

Ahora que tenemos nuestras VMs listas, instalemos Kubernetes en ellas. Primero, crearemos un nodo maestro para configurar un plano de control.

#### Nodo maestro

Necesitaremos la IP y el nombre de usuario de nuestra máquina virtual para conectarnos por SSH e instalar Kubernetes. Ejecuta `multipass ls` y toma nota de la IP del `master-node`. Todos los nombres de usuario para las VMs son `ubuntu` por defecto.

```sh
k3sup install --ip <IP> --user ubuntu --k3s-extra-args "--cluster-init"
export KUBECONFIG=<kubeconfig path>
```

Pasamos `--k3s-extra-args "--cluster-init"` para asegurarnos de que este nodo esté preparado para conectarse con otro nodo maestro, de lo contrario, podría causar errores.

Una vez instalado, descarga el archivo `kubeconfig` en el directorio donde ejecutaste tu comando. Puedes configurar la variable de entorno `KUBECONFIG` con la ruta al archivo `kubeconfig` recientemente descargado.

Ahora puedes usar `kubectl get nodes` para ver los nodos en tu clúster.

#### Nodo worker

Finalmente, tenemos que configurar nuestro nodo trabajador donde desplegaremos nuestras aplicaciones y servicios.

Para esto, toma la IP del `agent-worker` y pasa el mismo comando que antes, pero sin la bandera `--server`.

```sh
$ k3sup join --ip <IP-del-agent-worker> --user ubuntu --server-ip <IP-del-master-node> --server-user ubuntu
```

Ahora, si ejecutas `kubectl get nodes`, encontrarás dos nodos maestros y un único nodo trabajador que componen tu configuración de clúster multinodo. Puedes crear nuevas VMs y agregar más nodos maestros o trabajadores dependiendo de cómo planees utilizar tu clúster.

## Referencias

[oh my zsh!](https://ohmyz.sh/)

[Linux KVM](https://linux-kvm.org/page/Main_Page)

[Minikube Documentación Oficial](https://minikube.sigs.k8s.io/docs/)

[Multipass Github Oficial](https://github.com/canonical/multipass)

[k3sup Github Oficial](https://github.com/alexellis/k3sup)

[Setting up multi-node Kubernetes cluster locally with K3s and Multipass](https://yankeexe.medium.com/setting-up-multi-node-kubernetes-cluster-with-k3s-and-multipass-d4efed47fed5)

[Multi-node Kubernetes cluster setup using Multipass/k3s](https://billtcheng2013.medium.com/multi-node-kubernetes-cluster-setup-using-multipass-k3s-up-to-date-e0c61645e265)