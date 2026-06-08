# AWS Aurora PostgreSQL Module

Este módulo de Terraform despliega un clúster de base de datos relacional **Amazon Aurora compatible con PostgreSQL**. Está diseñado para entornos de alta disponibilidad, implementando cifrado en reposo forzado mediante claves KMS y gestionando el ciclo de vida de las credenciales de forma segura a través de AWS Secrets Manager.

---

## Qué hace este módulo

El módulo automatiza el aprovisionamiento de una infraestructura de base de datos robusta que incluye:

* **Alta Disponibilidad de Cómputo:** Despliega un clúster de Aurora con topología multi-zona de disponibilidad (restringido dinámicamente a 2 AZs) y permite escalar horizontalmente la cantidad de instancias de lectura/escritura mediante variables.
* **Seguridad de Red Aislada:** Crea un grupo de subredes de datos (`aws_db_subnet_group`) y un Security Group dedicado que restringe el tráfico entrante de base de datos (puerto `5432`) exclusivamente a los rangos CIDR privados definidos.
* **Gestión Segura de Credenciales (Zero-Cleartext):** Genera una contraseña maestra aleatoria fuerte y la inyecta directamente en un secreto de AWS Secrets Manager junto con el endpoint, puerto, base de datos y usuario. Ninguna credencial queda expuesta en texto plano en las salidas.
* **Cifrado Mandatorio:** Fuerza el cifrado en reposo del almacenamiento del clúster utilizando una clave administrada por el cliente (KMS Customer Managed Key) provista externamente.

---

## Recursos y Datos utilizados

| Elemento | Tipo | Descripción |
| :--- | :--- | :--- |
| `data.aws_availability_zones.available` | Data Source | Obtiene las zonas de disponibilidad activas en la región para la distribución de los nodos. |
| `aws_db_subnet_group.this` | Recurso | Agrupa las subredes de datos donde se alojarán las interfaces de red del clúster. |
| `aws_security_group.this` | Recurso | Define el perímetro de red para el puerto `5432` y permite salida libre hacia cualquier destino. |
| `random_password.master_password_aurora` | Recurso | Genera un string seguro y aleatorio de 16 caracteres con caracteres especiales para el rol maestro. |
| `aws_secretsmanager_secret.this` | Recurso | Crea el contenedor del secreto en Secrets Manager cifrado con la llave KMS del módulo. |
| `aws_secretsmanager_secret_version.this` | Recurso | Almacena el payload JSON con los datos de conexión y credenciales de acceso al clúster. |
| `aws_rds_cluster.this` | Recurso | El plano de control y almacenamiento del clúster de Aurora PostgreSQL. |
| `aws_rds_cluster_instance.this` | Recurso | Instancia o instancias de cómputo asociadas al clúster (Writer / Readers). |

---

## Variables requeridas / opcionales

| Variable | Tipo | Descripción |
| :--- | :--- | :--- |
| `vpc_id` | `string` | ID de la VPC donde se desplegarán el Security Group y los recursos de red. |
| `subnets_ids_data` | `list(string)` | Lista de IDs de subredes destinadas a los datos para el DB Subnet Group. |
| `subnets_cidrs_private` | `list(string)` | Lista de bloques CIDR privados autorizados a conectarse al puerto `5432`. |
| `key_arn` | `string` | ARN de la clave KMS (Customer Managed Key) utilizada para cifrar el clúster y el secreto. |
| `database_name` | `string` | Nombre de la base de datos inicial que se creará de forma predeterminada al levantar el clúster. |
| `master_username` | `string` | Nombre del usuario administrador maestro de la base de datos. |
| `engine_version` | `string` | Versión específica de Aurora PostgreSQL a desplegar (ej: `15.4`, `16.1`). |
| `instance_count` | `number` | Cantidad de instancias de cómputo a crear dentro del clúster (mínimo `1`). |
| `instance_class` | `string` | Tipo de instancia de AWS para los nodos del clúster (ej: `db.r6g.large`). |

---

## Ejemplo de Uso (`environments/dev`)

A continuación se muestra cómo invocar este módulo desde un directorio de entorno, abstrayendo la complejidad de la red y el cifrado mediante inyección de variables dinámicas:

```hcl
module "rds_aurora" {
  source = "../../modules/rds-aurora"

  # Configuración General
  environment           = var.environment

  # Configuración de Red
  vpc_id                = module.vpc.vpc_id
  subnets_ids_data      = module.vpc.subnet_data_id
  subnets_cidrs_private = module.vpc.subnet_private_cidr

  # Seguridad y Cifrado
  key_arn = module.kms.key_arn

  # Configuración del Motor
  engine_version  = var.engine_version
  database_name   = var.database_name
  master_username = var.master_username

  # Dimensionamiento del Cómputo
  instance_count = var.instance_count
  instance_class = var.instance_class
}
```

---

## Estructura del Secreto en Secrets Manager

El secreto generado exporta los datos necesarios para que las aplicaciones de la organización se conecten de forma nativa sin configuraciones manuales:

```json
{
  "host": "cluster-identifier.cluster-custom.region.rds.amazonaws.com",
  "port": 5432,
  "dbname": "nombre_db",
  "username": "admin_user",
  "password": "ejemplo_password_aleatorio"
}
```

---

## Outputs
 
El módulo expone salidas clave para acoplar las capas de cómputo y seguridad sin generar dependencias duras en el código:
 
* **`endpoint`**: El endpoint writer del clúster Aurora. Consumido por las instancias EC2 del ASG para establecer la conexión a la base de datos, típicamente inyectado vía variable de entorno o referenciado desde el secreto en Secrets Manager.
* **`security_group_id`**: El ID del Security Group del clúster. Requerido por el módulo de ASG para crear la regla de egress cruzada que autoriza el tráfico de salida de las instancias EC2 en el puerto `5432` exclusivamente hacia este recurso.
* **`secretsmanager_secret_arn`**: El ARN del secreto generado en Secrets Manager. Debe ser adjuntado como permiso en la policy IAM de las instancias EC2 del ASG para que puedan recuperar las credenciales de conexión (`host`, `port`, `dbname`, `username`, `password`) en tiempo de ejecución, sin exponer valores en texto plano.

---

## Decisiones de Arquitectura y Diseño

* **Aislamiento Multi-AZ Controlado:** Para optimizar costos y asegurar resiliencia básica, la función `slice` limita el despliegue del almacenamiento a exactamente **2 zonas de disponibilidad**, utilizando la metadata dinámica provista por el AWS Provider.
* **Inmutabilidad y Cifrado de Secretos:** La versión del secreto (`aws_secretsmanager_secret_version`) se acopla dinámicamente a los atributos del recurso `aws_rds_cluster`. Esto asegura que cualquier rotación o recreación se refleje en Secrets Manager en un solo paso atómico.
* **Esquema de Respaldo Conservador:** El clúster se inicializa con una ventana de retención de backups fijos de 5 días y una ventana de mantenimiento automatizado establecida en horas de baja actividad regional (`07:00-09:00 UTC`).
* **Etiquetado Consistente:** Al igual que el resto de la infraestructura, todos los recursos creados (red, cómputo, seguridad y secretos) heredan un mapa de `local.common_tags` para garantizar el cumplimiento de las políticas de gobierno y tracking de costos de la organización.
