# Autentificación

La autenticación es un componente crítico en la seguridad de sistemas informáticos, ya que garantiza que los usuarios que intentan acceder a un sistema son quienes dicen ser. En un mundo cada vez más conectado y digitalizado, la protección de la identidad y los datos se vuelve fundamental. La autenticación efectiva no solo implica verificar las credenciales de un usuario, como nombres de usuario y contraseñas, sino también emplear técnicas avanzadas para prevenir el acceso no autorizado.

Este apartado explorará diversas estrategias de autenticación desde una perspectiva de seguridad, en este caso se analiza la implementacion de un sistema que ya contiene toda la logica necesaria para soportar distintos metodos de autentifacacion y es capaz de integrar con multiples aplicaciones.

## Authentik

Authentik es un proveedor de identidad de código abierto, centrado en la flexibilidad y versatilidad. Con Authentik, los administradores de sitios web, desarrolladores de aplicaciones e ingenieros de seguridad tienen una solución confiable y segura para la autenticación en casi cualquier tipo de entorno. Hay acciones sólidas de recuperación disponibles para los usuarios y aplicaciones, incluida la gestión de perfiles de usuario y contraseñas. Puedes editar, desactivar o incluso suplantar un perfil de usuario rápidamente, y establecer una nueva contraseña para nuevos usuarios o restablecer una contraseña existente.

Puedes utilizar Authentik en un entorno existente para agregar soporte para nuevos protocolos, por lo que introducir Authentik en tu pila tecnológica actual no presenta desafíos de reestructuración. Admitimos todos los proveedores principales, como OAuth2, SAML, LDAP y SCIM, para que puedas elegir el protocolo que necesitas para cada aplicación.

El producto Authentik proporciona las siguientes consolas:

- Interfaz de administración: una herramienta visual para la creación y gestión de usuarios y grupos, tokens y credenciales, integraciones de aplicaciones, eventos y los Flows que definen procesos de inicio de sesión y autenticación estándar y personalizables. Los paneles visuales fáciles de leer muestran el estado del sistema, los inicios de sesión recientes y eventos de autenticación, y el uso de la aplicación.
- Interfaz de usuario: esta vista de consola en Authentik muestra todas las aplicaciones e integraciones en las que has implementado Authentik. Haz clic en la aplicación a la que deseas acceder para abrirla, o profundiza para editar su configuración en la interfaz de administración.
- Flows: Los Flows son los pasos por los cuales ocurren las diversas Etapas de un proceso de inicio de sesión y autenticación. Una etapa representa un solo paso de verificación o lógica en el proceso de inicio de sesión. Authentik permite la personalización y definición exacta de estos flujos.

### Integración con Grafana

Para probar la aplicacion y evaluar futuras implementaciones, se ha puesto a prueba con una simple integracion con grafana. La instalacion consta de los siguientes comandos, los archivos utilizados estaran en `src/dev/`

```sh
minikube start --driver=kvm2 --memory=3g  

# Authentik Instalation

helm repo add authentik https://charts.goauthentik.io
helm repo update
helm upgrade --install authentik authentik/authentik -f authentik-values.yaml

# Authentik Service

export POD_AUTHENTIK=$(kubectl get pods -l "app.kubernetes.io/component=server" -o jsonpath="{.items[0].metadata.name}")
kubectl label pod $POD_AUTHENTIK app=authentik
kubectl apply -f authentik-service.yaml
minikube service authentik-service
```

Para ingresar al servicio, tendremos que entrar con el link correspondiente al puerto 443 ya que utilizaremos el protocolo https. Nuestras credenciales de ingreso es Usuario: akadmin, contraseña: prueba123

Una vez a dentro de la interfaz crearemos un nuevo proveedor para nuestra aplicacion, en donde seleccionaremos OAuth2/OpenID Provider y el resto se coloca por default. Como Redirect URI colocamos `http://localhost:3000/login/generic_oauth`

Con eso vamos a crear la aplicacion y le colocaremos un slug a eleccion. Para mas informacion, [dirigirse a la documentación oficial de Authentik](https://docs.goauthentik.io/integrations/services/grafana/)

Con todos estos datos que nos da la plataforma, los anotamos en `grafana-values.yaml` en el apartado grafana.ini

```yaml
grafana.ini:
    paths:
      data: /var/lib/grafana/
      logs: /var/log/grafana
      plugins: /var/lib/grafana/plugins
      provisioning: /etc/grafana/provisioning
    analytics:
      check_for_updates: true
    log:
      mode: console
    grafana_net:
      url: https://grafana.net
    server:
      domain: localhost
    auth:
        signout_redirect_url: ""
        oauth_auto_login: true
    auth.generic_oauth:
        name: authentik
        enabled: true
        client_id: ""
        client_secret: ""
        scopes: "openid profile email"
        auth_url: ""
        token_url: ""
        api_url: ""
        # Optionally map user groups to Grafana roles
        role_attribute_path: contains(groups[*], 'authentik Admins') && 'Admin' || contains(groups[*], 'Grafana Editors') && 'Editor' || 'Viewer'
        tls_skip_verify_insecure: true
    cookie_samesite: none
    cookie_secure: false
```

Los valores en blanco seran rellenados con los datos provistos. Una vez finalizado se guarda y procede a instalar Grafana

```sh
# Grafana Instalation

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
helm install my-grafana grafana/grafana --namespace monitoring

# Una vez instalado y funcionando, se le aplica las modificaciones realizadas anteriormente

helm upgrade my-grafana grafana/grafana -f grafana-values.yaml -n monitoring

# Exponemos el Servicio

export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=my-grafana" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace monitoring port-forward $POD_NAME 3000
```

ingresamos con el localhost:3000 y se vera en funcionamiento

### Integración con la plataforma de Monitoreo

Para lograr el mismo resultado llegado en la seccion anterior pero con la utilizacion de nuestra ya implementada plataforma de monitoreo. Utilizaremos el script `authentication.sh` que se encuentra en `src/dev` que se encargara de la instalacion de Authentik.

Una vez creado toda la configuracion de nuestro proveedor y aplicacion, instalamos nuestro stack de monitoreo ejecutando `monitoring.sh`.

En este caso la configuracion tiene que ser colocado en el configmap `ConfigMap-grafana.yaml` que tendra este formato:

```yaml
  data:
    grafana.ini: |
      [analytics]
      check_for_updates = true
      [grafana_net]
      url = https://grafana.net
      [log]
      mode = console
      [paths]
      data = /var/lib/grafana/
      logs = /var/log/grafana
      plugins = /var/lib/grafana/plugins
      provisioning = /etc/grafana/provisioning
      [server]
      domain = localhost
      [auth]
      signout_redirect_url = https://authentik.company/application/o/<Slug of the application from above>/end-session/
      oauth_auto_login = true
      [auth.generic_oauth]
      name = authentik
      enabled = true
      client_id = <Client ID from above>
      client_secret = <Client Secret from above>
      scopes = openid email profile
      auth_url = https://authentik.company/application/o/authorize/
      token_url = https://authentik.company/application/o/token/
      api_url = https://authentik.company/application/o/userinfo/
      role_attribute_path = contains(groups, 'authentik Admins') && 'Admin' || contains(groups, 'Grafana Editors') && 'Editor' || 'Viewer'
      tls_skip_verify_insecure = true
      [security]
      cookie_samesite = none
      cookie_secure = false
```

Esta informacion tiene que ser colocada en el configmap que se encuentra en el cluster por lo tanto lo editaremos el configmap y pondremos lo escrito anteriormente:

```sh
kubectl edit cm loki-grafana -n loki
```

Tenemos que borrar el pod para que la configuracion se ejecute

```sh
kubectl delete pod <nombre del pod> -n loki
```

Veremos el resultado final ingresando a http::/localhost:3000