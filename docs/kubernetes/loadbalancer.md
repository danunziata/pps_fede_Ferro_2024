# Balanceador de Carga

Un Load Balancer (balanceador de carga) es un dispositivo o servicio que distribuye el tráfico de red o las solicitudes de aplicación entre varios servidores, asegurando que no se sobrecargue un único servidor. Esto mejora la disponibilidad y la confiabilidad de las aplicaciones al distribuir la carga de trabajo, y puede mejorar el rendimiento general al optimizar el uso de los recursos.

## MetalLB

Kubernetes no ofrece una implementación de balanceadores de carga de red (Servicios de tipo LoadBalancer) para clústeres bare-metal. Las implementaciones de balanceadores de carga de red que Kubernetes incluye son solo código auxiliar que se conecta a varias plataformas de IaaS (GCP, AWS, Azure…). Si no estás ejecutando en una plataforma de IaaS compatible (GCP, AWS, Azure…), los LoadBalancers permanecerán en estado "pending" indefinidamente cuando se creen.

Los operadores de clústeres en metal desnudo tienen dos herramientas menores para llevar el tráfico de usuarios a sus clústeres, los servicios "NodePort" y "externalIPs". Ambas opciones tienen desventajas significativas para el uso en producción, lo que convierte a los clústeres en metal desnudo en ciudadanos de segunda clase en el ecosistema de Kubernetes.

MetalLB tiene como objetivo corregir este desequilibrio al ofrecer una implementación de balanceador de carga de red que se integra con el equipo de red estándar, para que los servicios externos en clústeres en metal desnudo también "funcionen" tanto como sea posible.

### Instalación

Se instala con el siguiente comando

```sh
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
```

Esto desplegará MetalLB en tu clúster, bajo el namespace metallb-system. Los componentes en el manifiesto son:

- El deployment `metallb-system/controller`. Este es el controlador de todo el clúster que maneja las asignaciones de direcciones IP.
- El daemonset `metallb-system/speaker`. Este es el componente que utiliza el/los protocolo(s) de tu elección para hacer que los servicios sean accesibles.
- Cuentas de servicio para el controlador y el speaker, junto con los permisos RBAC que los componentes necesitan para funcionar.

El manifiesto de instalación no incluye un archivo de configuración. Los componentes de MetalLB aún se iniciarán, pero permanecerán inactivos hasta que comiences a desplegar recursos.

### Uso

Se empieza declarando las ips que seran asignadas al LoadBalancer

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: <Nombre del Pool>
  namespace: metallb-system
spec:
  addresses:
  - <Direcciones IP>
```

Anunciamos nuestras IPs con la configuracion Layer 2. El modo Layer 2 es el más sencillo de configurar: en muchos casos, no necesitas ninguna configuración específica de protocolo, solo direcciones IP. El modo Layer 2 no requiere que las IP estén vinculadas a las interfaces de red de tus nodos de trabajo. Funciona respondiendo a las solicitudes ARP en tu red local directamente, para proporcionar la dirección MAC de la máquina a los clientes.

```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: <Nombre del Anuncio>
  namespace: metallb-system
```

