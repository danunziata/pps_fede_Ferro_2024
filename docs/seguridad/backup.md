# Copias de Seguridad

En el ámbito de la computación en la nube y la gestión de contenedores, Kubernetes se ha consolidado como una plataforma líder para la orquestación de contenedores. Sin embargo, junto con su adopción, surge la necesidad crítica de proteger los datos y garantizar la continuidad del negocio a través de estrategias robustas de copias de seguridad (backup).

Las copias de seguridad son esenciales en un entorno de Kubernetes por varias razones. Primero, protegen contra la pérdida de datos que puede ocurrir debido a fallos de hardware, errores humanos o ataques maliciosos. En caso de un desastre mayor, como una falla del centro de datos o un ataque de ransomware, las copias de seguridad permiten la recuperación rápida y eficiente de la infraestructura y los datos. Además, durante las migraciones entre clústeres de Kubernetes o las actualizaciones de la infraestructura, las copias de seguridad son fundamentales para revertir cambios en caso de problemas. Cumplir con los requisitos normativos de diversas industrias que obligan a mantener copias de seguridad periódicas y seguras también es una razón importante para su implementación.

En esta oportunidad, utilizaremos el software Velero que se va a encargar de toda la infraestructura de backup con un servidor minIO

## Velero

Velero (anteriormente Heptio Ark) te proporciona herramientas para hacer copias de seguridad y restaurar los recursos de tu clúster de Kubernetes y volúmenes persistentes. Puedes ejecutar Velero con un proveedor de nube o en instalaciones locales. Velero te permite:

- Hacer copias de seguridad de tu clúster y restaurarlas en caso de pérdida.
- Migrar recursos de clústeres a otros clústeres.
- Replicar tu clúster de producción a clústeres de desarrollo y prueba.

Velero consta de:

- Un servidor que se ejecuta en tu clúster.
- Un cliente de línea de comandos que se ejecuta localmente.

Cada operación de Velero – copia de seguridad bajo demanda, copia de seguridad programada, restauración – es un recurso personalizado, definido con una Definición de Recurso Personalizado (CRD) de Kubernetes y almacenado en etcd. Velero también incluye controladores que procesan los recursos personalizados para realizar copias de seguridad, restauraciones y todas las operaciones relacionadas.

Puedes hacer copias de seguridad o restaurar todos los objetos en tu clúster, o puedes filtrar objetos por tipo, namespace y/o etiqueta.

Velero es ideal para casos de uso de recuperación ante desastres, así como para hacer snapshots del estado de tu aplicación antes de realizar operaciones del sistema en tu clúster, como actualizaciones.

## Implementación

La implementacion se realizara con un cluster k3s, se utiliza unicamente para entornos de prueba y entornos de desarrollo, para entornos de produccion utilizamos los servicios que ofrecen las plataformas cloud.

### Instalación

#### Velero CLI

```sh
wget https://github.com/vmware-tanzu/velero/releases/download/v1.13.2/velero-v1.13.2-linux-amd64.tar.gz
tar -xvf velero-v1.13.2-linux-amd64.tar.gz
sudo mv velero-v1.13.2-linux-amd64/velero /usr/local/bin
rm -rf velero-v1.13.2-linux-amd64
```

#### MinIO

Colocamos las credenciales que vamos a usar para entrar al servidor de minIO

```sh
vi credentials-velero
```

```
[default]
aws_access_key_id = minio
aws_secret_access_key = minio123
```

```sh
kubectl apply -f minio.yaml
```

#### Inicialización

Tenemos que tener acceso con el usuario cluster-admin (buscarlo en el directorio`/etc/rancher/k3s/k3s.yaml` del nodo)

```sh
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.2.1 \
    --bucket velero \
    --secret-file ./credentials-velero \
    --use-volume-snapshots=false \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio.velero.svc:9000
```

### Configuración

Creamos un backup de forma regular de todo el cluster

```sh
velero schedule create regular --schedule="@every 6h"
```

Para restaurar a partir del backup

```sh
velero restore create --from-backup regular
```