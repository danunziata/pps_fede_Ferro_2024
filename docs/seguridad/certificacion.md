# Certificación

Un certificado SSL es un certificado digital que autentica la identidad de un sitio web y habilita una conexión cifrada. La sigla SSL significa Secure Sockets Layer (Capa de sockets seguros), un protocolo de seguridad que crea un enlace cifrado entre un servidor web y un navegador web.

Las empresas y las organizaciones deben agregar certificados SSL a sus sitios web para proteger las transacciones en línea y mantener la privacidad y seguridad de la información del cliente.

En resumen: el certificado SSL mantiene seguras las conexiones a Internet y evita que los delincuentes lean o modifiquen la información transferida entre dos sistemas. Cuando veas un ícono de candado junto a la URL en la barra de direcciones, significa que hay un certificado SSL que protege el sitio web que estás visitando.

Desde su creación hace aproximadamente 25 años, ha habido varias versiones del protocolo SSL, las cuales en algún momento se encontraron con problemas de seguridad. Posteriormente, se lanzó una versión renovada y con un nuevo nombre: TLS (Transport Layer Security, Seguridad de capa de transporte), que sigue en uso actualmente. Sin embargo, las iniciales SSL se mantuvieron, por lo que la nueva versión del protocolo se sigue llamando con el nombre antiguo.

Los certificados SSL se pueden obtener directamente de una autoridad de certificación (Certificate Authority, CA). Las autoridades de certificados, a veces también conocidas como autoridades de certificación, emiten millones de certificados SSL cada año. Cumplen una función fundamental en el funcionamiento de Internet y en la manera en que se garantizan las interacciones transparentes y de confianza en línea.

## Implementación

Como en este caso queremos implementar un entorno de prueba, utilizaremos un esquema en donde traefik le va a pedir los certificados a un ACME (Automatic Certificate Management Environment). Estos certificados no son oficiales por lo tanto debe utilizarse unicamente en entorno de prueba.

#### Pebble

Pebble es un servidor ACME como Lets Encrypt que provee certificados TLS a clientes ACME que son capaz de controlar un nombre de dominio.

Para instarlo, simplemente se ejecutando los siguientes comandos

```sh
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update
helm install pebble jupyterhub/pebble --values pebble-values.yaml -n kube-system    
```

#### Traefik

El archivo `traefik-values.yaml` se colocara en el directorio`/var/lib/rancher/k3s/server/manifests`y se reiniciara el nodo

```sh
$ sudo cat /var/lib/rancher/k3s/server/manifests/traefik-config.yaml
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    additionalArguments:
      - --certificatesresolvers.pebble.acme.tlschallenge=true
      - --certificatesresolvers.pebble.acme.email=test@hello.com
      - --certificatesresolvers.pebble.acme.storage=/data/acme.json
      - --certificatesresolvers.pebble.acme.caserver=https://pebble/dir
    volumes:
      - name: pebble
        mountPath: "/certs"
        type: configMap
    env:
      - name: LEGO_CA_CERTIFICATES
        value: "/certs/root-cert.pem"
$ systemctl stop k3s
$ systemctl start k3s
```

A partir de aqui, podemos aplicar nuestro ingress con los siguientes parametros

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: <Nombre del Ingress>
  namespace: <Namespace del ingress>
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`<Dominio del Servicio>`)
      kind: Rule
      services:
        - name: <Nombre del Servicio>
          port: <Puerto del Servicio>
  tls:
    certResolver: pebble
```

