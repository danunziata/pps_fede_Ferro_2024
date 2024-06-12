# Exposición de Servicios

Kubernetes, una plataforma de orquestación de contenedores de código abierto, ha revolucionado la forma en que desplegamos, gestionamos y escalamos aplicaciones. Uno de los conceptos clave en Kubernetes es la exposición de servicios, lo que permite que las aplicaciones dentro del clúster sean accesibles tanto interna como externamente.

## Traefik

Traefik es un router de borde de código abierto que hace que publicar tus servicios sea una experiencia mas sencilla. Recibe solicitudes en nombre de tu sistema y averigua qué componentes son responsables de manejarlas.

Lo que distingue a Traefik, además de sus numerosas características, es que descubre automáticamente la configuración correcta para tus servicios. La magia ocurre cuando Traefik inspecciona tu infraestructura, donde encuentra información relevante y descubre qué servicio maneja cada solicitud.

Traefik es compatible de forma nativa con todas las principales tecnologías de clúster, como Kubernetes, Docker, Docker Swarm, AWS, y la lista continúa; y puede manejar muchas al mismo tiempo.

Con Traefik, no es necesario mantener y sincronizar un archivo de configuración separado: todo sucede automáticamente, en tiempo real (sin reinicios, sin interrupciones de conexión). Con Traefik, dedicas tiempo a desarrollar e implementar nuevas características en tu sistema, no a configurar y mantener su estado de funcionamiento.

### Instalación

Traefik utiliza la API de Kubernetes para descubrir servicios en ejecución.

Para usar la API de Kubernetes, Traefik necesita algunos permisos. Este mecanismo de permisos se basa en roles definidos por el administrador del clúster. El rol se asigna a una cuenta utilizada por una aplicación, en este caso, Traefik Proxy.

El primer paso es crear el rol. El recurso ClusterRole enumera los recursos y acciones disponibles para el rol. En un archivo llamado `00-role.yml`, coloca el siguiente ClusterRole:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: traefik-role
rules:
  - apiGroups:
      - ""
    resources:
      - services
      - endpoints
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
      - networking.k8s.io
    resources:
      - ingresses
      - ingressclasses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
    resources:
      - ingresses/status
    verbs:
      - update
```

Este archivo define un ClusterRole llamado `traefik-role` que especifica los recursos y acciones que Traefik puede realizar.

El siguiente paso es crear una cuenta de servicio dedicada para Traefik. En un archivo llamado `00-account.yml`, coloca el siguiente recurso ServiceAccount:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: traefik-account
```

Y luego, vincula el rol a la cuenta para aplicar los permisos y reglas a esta última. En un archivo llamado `01-role-binding.yml`, coloca el siguiente recurso ClusterRoleBinding:

```yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: traefik-role-binding

roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik-role
subjects:
  - kind: ServiceAccount
    name: traefik-account
    namespace: default # Este tutorial usa el namespace "default" de K8s
```

Estos archivos configuran una cuenta de servicio para Traefik y le asignan los permisos necesarios a través de un rol en Kubernetes.

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: traefik-deployment
  labels:
    app: traefik

spec:
  replicas: 1
  selector:
    matchLabels:
      app: traefik
  template:
    metadata:
      labels:
        app: traefik
    spec:
      serviceAccountName: traefik-account
      containers:
        - name: traefik
          image: traefik:v3.0
          args:
            - --api.insecure
            - --providers.kubernetesingress
          ports:
            - name: web
              containerPort: 80
            - name: dashboard
              containerPort: 8080
```

Para gestionar la escalabilidad, un Deployment puede crear múltiples contenedores, llamados Pods. Cada Pod se configura siguiendo el campo `spec` en el Deployment. Dado que un Deployment puede ejecutar múltiples Pods de Traefik Proxy, se requiere un componente para reenviar el tráfico a cualquiera de las instancias: es decir, un Service.

Crea un archivo llamado `02-traefik-services.yml` y añade los dos recursos Service siguientes:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: traefik
spec:
  selector:
    app: traefik
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
    - protocol: TCP
      port: 443
      targetPort: 443

---
apiVersion: v1
kind: Service
metadata:
  name: traefik-admin
spec:
  selector:
    app: traefik
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
```

Estos servicios configuran los puertos necesarios para el tráfico HTTP/HTTPS (puertos 80 y 443) y el puerto de administración de Traefik (puerto 8080). El selector asegura que el tráfico se dirija a los Pods etiquetados con `app: traefik`.

### Exponer un Servicio

IngressRoute es una extensión personalizada de Traefik que proporciona una mayor flexibilidad y control sobre la forma en que se enrutan las solicitudes en un clúster de Kubernetes. A diferencia del recurso Ingress estándar de Kubernetes, IngressRoute permite una configuración más detallada y avanzada, incluyendo características como el enrutamiento basado en cabeceras, la autenticación y la integración con middleware.

La estructura del IngressRoute es la siguiente

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: <Nombre del IngressRoute>
  namespace: <Nombre del namespace>
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`<dominio a asignar del servicio>`)
      kind: Rule
      services:
        - name: <Nombre del Servicio>
          port: <Puerto del Servicio>
```

