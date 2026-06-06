# AWS Auto Scaling Group (ASG) Module

Este módulo de Terraform despliega un **Auto Scaling Group (ASG)** diseñado para operar en la capa de cómputo privada, recibiendo tráfico exclusivamente desde el ALB perimetral y conectándose de forma controlada hacia la capa de datos. Automatiza el ciclo de vida de las instancias EC2 con una AMI gestionada, identidad IAM federada y una plantilla de lanzamiento reproducible.

---

## Qué hace este módulo

El módulo automatiza el aprovisionamiento de la capa de cómputo elástica, la cual incluye:

* **Cómputo Elástico y Auto-gestionado:** Despliega un `aws_autoscaling_group` con capacidad mínima, máxima y deseada configurable, distribuyendo las instancias EC2 de forma automática entre las subredes privadas para garantizar alta disponibilidad.
* **AMI Siempre Actualizada (SSM-Driven):** Resuelve dinámicamente la última AMI estable de Amazon Linux 2023 para arquitectura `arm64` a través del Parameter Store de SSM, eliminando la necesidad de hardcodear IDs de imagen y asegurando que los nuevos lanzamientos usen siempre una base actualizada.
* **Perímetro de Red Orientado a Zero Trust:** Crea un Security Group dedicado que acepta tráfico de entrada exclusivamente en el puerto `80` desde el Security Group del ALB (no desde rangos CIDR abiertos), y restringe la salida a dos flujos explícitos: el puerto `5432` hacia Aurora y el puerto `443` hacia internet para llamadas a APIs externas y actualizaciones.
* **Identidad IAM Federada (SSM Session Manager):** Provisiona un IAM Role, una policy attachment y un Instance Profile que habilitan la gestión remota de las instancias vía AWS Systems Manager, eliminando completamente la necesidad de exponer puertos SSH o administrar llaves `.pem`.
* **Launch Template Reproducible:** Encapsula la configuración de lanzamiento de cada instancia (AMI, tipo, volumen EBS, perfil IAM y Security Group) en un `aws_launch_template` versionado, garantizando reproducibilidad y facilitando los rolling updates.
* **Integración Nativa con ALB:** El ASG se registra automáticamente al Target Group del módulo de ALB a través del argumento `target_group_arns`, asegurando que cada instancia que escale horizontalmente quede disponible para recibir tráfico de forma inmediata.

---

## Recursos utilizados

| Elemento | Tipo | Descripción |
| :--- | :--- | :--- |
| `aws_security_group.this` | Recurso | Firewall de instancia: ingress restringido al SG del ALB en el puerto `80`, egress explícito a Aurora (`5432`) y a internet (`443`). |
| `aws_iam_role.this` | Recurso | Rol IAM con trust policy para `ec2.amazonaws.com`, base de la identidad federada de las instancias. |
| `aws_iam_role_policy_attachment.this` | Recurso | Adjunta la política administrada `AmazonSSMManagedInstanceCore` al rol, habilitando SSM Session Manager. |
| `aws_iam_instance_profile.this` | Recurso | Perfil de instancia que vincula el IAM Role al ciclo de vida de las instancias EC2 lanzadas por el ASG. |
| `aws_launch_template.this` | Recurso | Plantilla de lanzamiento versionada que define AMI, tipo de instancia, volumen EBS, perfil IAM y SG. |
| `aws_autoscaling_group.this` | Recurso | El plano de cómputo elástico: gestiona el ciclo de vida de las instancias, distribuye en subredes privadas y se acopla al Target Group del ALB. |
| `data.aws_ssm_parameter.amazon_linux_2023` | Data Source | Resuelve dinámicamente el ID de la AMI más reciente de Amazon Linux 2023 (`arm64`) desde el Parameter Store público de AWS. |
| `data.aws_availability_zones.available` | Data Source | Interroga las zonas de disponibilidad activas en la región para soporte de distribución multi-AZ. |

---

## Variables requeridas / opcionales

| Variable | Tipo | Descripción |
| :--- | :--- | :--- |
| `vpc_id` | `string` | ID de la VPC donde se desplegará el Security Group del ASG. |
| `subnet_private` | `list(string)` | Lista de IDs de subredes privadas donde el ASG distribuirá las instancias EC2. |
| `arn_target_group` | `string` | ARN del Target Group del ALB al que el ASG registrará automáticamente sus instancias. |
| `security_group_id_alb` | `list(string)` | Lista con el ID del Security Group del ALB, usado como fuente exclusiva del tráfico de entrada en el puerto `80`. |
| `security_group_id_aurora` | `list(string)` | Lista con el ID del Security Group de Aurora, destino autorizado del egress en el puerto `5432`. |
| `instance_type` | `string` | Tipo de instancia EC2 a lanzar (ej: `t4g.micro`, `t4g.small`). Debe ser compatible con arquitectura `arm64`. |
| `instance_volume_size` | `number` | Tamaño en GiB del volumen EBS adicional adjuntado a cada instancia. |
| `asg_desired_capacity` | `number` | Número inicial de instancias EC2 que el ASG intentará mantener en estado estable. |
| `asg_min_size` | `number` | Cantidad mínima de instancias que el ASG garantizará en todo momento, incluso durante eventos de escala. |
| `asg_max_size` | `number` | Límite superior de instancias que el ASG puede lanzar ante un evento de escalado horizontal. |
| `environment` | `string` | Nombre del entorno actual (ej: `dev`, `staging`, `prod`) utilizado para el cálculo de nombres dinámicos. |

---

## Ejemplo de Uso (`environments/dev`)

A continuación se muestra cómo invocar este módulo de ASG, inyectando las dependencias de red del VPC y conectándolo con las salidas del módulo de ALB y Aurora:

```hcl
module "asg_app_dev" {
  source = "../../modules/asg"

  # Configuración de Red
  vpc_id         = module.vpc.vpc_id
  subnet_private = module.vpc.private_subnet_ids

  # Integración con ALB
  arn_target_group      = module.alb_front_end_dev.target_group_arn
  security_group_id_alb = [module.alb_front_end_dev.security_group_id]

  # Integración con Aurora
  security_group_id_aurora = [module.aurora_dev.security_group_id]

  # Configuración de Cómputo
  instance_type        = "t4g.small"
  instance_volume_size = 20

  # Configuración de Escalado
  asg_desired_capacity = 2
  asg_min_size         = 1
  asg_max_size         = 4

  environment = "dev"
}
```

---

## Outputs  (Salidas)
En esta arquitectura el modulo `asg` no necesita exponer outputs.
Es un consumidor de outputs de otros módulos (`alb`, `rds-aurora`, `vpc`, `kms`), no un proveedor.

---

## Decisiones de Arquitectura y Diseño

* **Acceso Sin SSH (SSM Session Manager):** Las instancias no exponen el puerto `22` ni requieren key pairs. El acceso operativo se canaliza íntegramente a través de AWS Systems Manager vía el Instance Profile IAM adjunto, reduciendo la superficie de ataque y eliminando la gestión de credenciales SSH.
* **AMI Dinámica vía SSM Parameter Store:** En lugar de hardcodear un `ami-xxxxxxxx` que queda obsoleto con cada patch de seguridad, el módulo resuelve en tiempo de plan el ID de la última AMI de Amazon Linux 2023 `arm64` disponible en la región. Esto garantiza que cualquier nuevo lanzamiento use una base de imagen actualizada sin cambios de código.
* **Ingress Orientado a Security Group (No CIDR):** La regla de entrada del puerto `80` referencia el Security Group del ALB como fuente en lugar de un bloque CIDR. Esto asegura que únicamente el tráfico que provenga del ALB sea aceptado, incluso si las IPs privadas del balanceador cambian por un reemplazo de infraestructura.
* **Naming Standard Autocalculado:** Mediante bloques `locals`, el módulo auto-genera los nombres de todos los recursos (Security Group, Launch Template, ASG, IAM Role e Instance Profile) bajo el prefijo común `${Project}-${Environment}`, manteniendo homogeneidad en la consola de AWS y previniendo colisiones entre entornos.
* **Propagación de Tags a Instancias:** El bloque `dynamic "tag"` dentro del `aws_autoscaling_group` itera sobre el mapa `local.common_tags` con `propagate_at_launch = true`, asegurando que cada instancia EC2 lanzada herede automáticamente las etiquetas de gobierno (`Project`, `Environment`, `ManagedBy`, `Owner`) sin configuración adicional.
* **Arquitectura `arm64` (Graviton):** La AMI seleccionada y los tipos de instancia objetivo corresponden a la arquitectura `arm64`, alineándose con instancias Graviton de AWS que ofrecen mejor relación precio-rendimiento para cargas de trabajo de aplicación sostenidas.
