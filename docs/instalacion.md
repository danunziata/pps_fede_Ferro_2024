# Instalación

Este documento explica cómo configurar un entorno de virtualización utilizando KVM y Multipass, diseñada específicamente para instalar Kubernetes utilizando la tecnología k3s.

## KVM

Las máquinas virtuales basadas en el kernel (KVM) son una tecnología de virtualizaciónopen source integrada a Linux®. Con ellas, puede transformar Linux en un hipervisor que permite que una máquina host ejecute varios entornos virtuales aislados llamados máquinas virtuales (VM) o guests. 

Las KVM convierten Linux en un hipervisor de tipo 1. Todos los hipervisores necesitan algunos elementos del sistema operativo (por ejemplo, el administrador de memoria, el programador de procesos, la stack de entrada o salida [E/S], los controladores de dispositivos, el administrador de seguridad y la stack de red, entre otros) para ejecutar las máquinas virtuales. Las KVM tienen todos estos elementos porque forman parte del kernel de Linux. Cada máquina virtual se implementa como un proceso habitual de Linux, el cual se programa con la herramienta estándar de Linux para este fin, e incluye sistemas virtuales de hardware exclusivos, como la tarjeta de red, el adaptador gráfico, las CPU, la memoria y los discos.

### Instalación

```sh
sudo apt update
sudo apt install cpu-checker
kvm-ok							                                         # Comprueba si la virtualizacion esta habilitada
sudo apt install qemu-kvm libvirt-bin bridge-utils virtinst virt-manager # Instala las librerias necesarias
sudo usermod -aG kvm,libvirt $USER 										 # Agrupa un par de grupos a un usuario
sudo systemctl is-active libvirtd										 # "active" si esta todo activado
```

## Multipass

Multipass es un gestor de máquinas virtuales (VM) ligero para Linux, Windows y macOS. Está diseñado para desarrolladores que desean un entorno Ubuntu fresco con un solo comando. Utiliza KVM en Linux, Hyper-V en Windows y QEMU en macOS para ejecutar la VM con una sobrecarga mínima. También puede usar VirtualBox en Windows y macOS. Multipass obtendrá las imágenes por ti y las mantendrá actualizadas.

Dado que admite metadatos para cloud-init, puedes simular un pequeño despliegue en la nube en tu laptop o estación de trabajo.

### Instalación

```sh
sudo apt update
sudo apt install snapd
sudo snap install multipass
```

## Creación de Instancias

Los nodos en Kubernetes son simplemente máquinas virtuales que trabajan en sincronización. Para nuestro clúster, crearemos 3 máquinas virtuales, cada una con 2 CPU, 2 GB de RAM y 4 GB de almacenamiento.

### Claves SSH

Crea una clave privada/pública con el siguiente comando:

```sh
ssh-keygen
```

Esto creará los archivos mencionados anteriormente en tu sistema. Copia el contenido de `~/.ssh/id_rsa.pub` con:

```sh
cat ~/.ssh/id_rsa.pub
```

### Creando el archivo de configuración

Crea un archivo llamado `multipass.yaml` y coloca tu clave pública en `ssh-rsa`.

#### multipass.yaml

```
yaml
ssh_authorized_keys:
  - ssh-rsa <añade-tu-clave-pública>
```

Este archivo de configuración asegura que la clave pública se almacene en la máquina virtual una vez creada. Crearemos nuestras máquinas virtuales con nombres adecuados basados en los roles que les asignaremos (master/worker).

### Inicialización

```sh
multipass launch jammy --cpus 2 --mem 2G --disk 4G --name master-node --cloud-init multipass.yaml
multipass launch jammy --cpus 2 --mem 2G --disk 4G --name agent-worker --cloud-init multipass.yaml
```

En términos de K3s, un nodo maestro se llama "server" y el resto de los nodos se llaman "agents". Los agentes son simplemente los nodos que se añaden al nodo maestro; pueden ser otro nodo maestro o un nodo trabajador.

## k3sup

k3sup es una utilidad ligera para pasar de cero a KUBECONFIG con k3s en cualquier máquina virtual local o remota. Todo lo que necesitas es acceso SSH y el binario de k3sup para obtener acceso a kubectl de inmediato.

Esta herramienta utiliza SSH para instalar k3s en un host Linux remoto. También puedes usarla para unir hosts Linux existentes a un clúster k3s como agentes. Primero, k3s se instala utilizando el script de utilidad de Rancher, junto con una flag para la IP pública de tu host para que TLS funcione correctamente. Luego, se obtiene y actualiza el archivo kubeconfig en el servidor para que puedas conectarte desde tu laptop usando kubectl.

k3sup se desarrolló para automatizar lo que puede ser un proceso muy manual y confuso para muchos desarrolladores, que ya están cortos de tiempo. Una vez que has provisionado una VM con tu herramienta favorita, k3sup significa que solo estás a 60 segundos de ejecutar `kubectl get pods` en tu propia computadora. Si estás en una computadora local, puedes omitir SSH con `k3sup install --local`.

### Instalación

```sh
curl -sLS https://get.k3sup.dev | sh
sudo install k3sup /usr/local/bin/
```

### Añadiendo Kubernetes con k3sup

Ahora que tenemos nuestras VMs listas, instalemos Kubernetes en ellas. Primero, crearemos un nodo maestro para configurar un plano de control.

#### Añadiendo un nodo maestro

Necesitaremos la IP y el nombre de usuario de nuestra máquina virtual para conectarnos por SSH e instalar Kubernetes. Ejecuta `multipass ls` y toma nota de la IP del `master-node`. Todos los nombres de usuario para las VMs son `ubuntu` por defecto.

```sh
k3sup install --ip <IP> --user ubuntu --k3s-extra-args "--cluster-init"
export KUBECONFIG=<kubeconfig path>
```

Pasamos `--k3s-extra-args "--cluster-init"` para asegurarnos de que este nodo esté preparado para conectarse con otro nodo maestro, de lo contrario, podría causar errores.

Una vez instalado, descarga el archivo `kubeconfig` en el directorio donde ejecutaste tu comando. Puedes configurar la variable de entorno `KUBECONFIG` con la ruta al archivo `kubeconfig` recientemente descargado.

Ahora puedes usar `kubectl get nodes` para ver los nodos en tu clúster.

#### Añadiendo un nodo trabajador

Finalmente, tenemos que configurar nuestro nodo trabajador donde desplegaremos nuestras aplicaciones y servicios.

Para esto, toma la IP del `agent-worker` y pasa el mismo comando que antes, pero sin la bandera `--server`.

```sh
$ k3sup join --ip <IP-del-agent-worker> --user ubuntu --server-ip <IP-del-master-node> --server-user ubuntu
```

Ahora, si ejecutas `kubectl get nodes`, encontrarás dos nodos maestros y un único nodo trabajador que componen tu configuración de clúster multinodo. Puedes crear nuevas VMs y agregar más nodos maestros o trabajadores dependiendo de cómo planees utilizar tu clúster.

## Referencias

https://github.com/canonical/multipass

https://github.com/alexellis/k3sup

https://yankeexe.medium.com/setting-up-multi-node-kubernetes-cluster-with-k3s-and-multipass-d4efed47fed5

https://billtcheng2013.medium.com/multi-node-kubernetes-cluster-setup-using-multipass-k3s-up-to-date-e0c61645e265