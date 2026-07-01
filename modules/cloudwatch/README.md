# CloudWatch Module

Este módulo de Terraform despliega la infraestructura de **monitoreo y observabilidad** de la cuenta, mediante un conjunto de alarmas de **Amazon CloudWatch** sobre los recursos críticos de la plataforma (Auto Scaling Group, Load Balancer y RDS), y un dashboard centralizado. Todas las alarmas envían notificaciones hacia un tópico de SNS existente.

---

## Qué hace este módulo

El módulo automatiza el aprovisionamiento de la infraestructura de monitoreo de la cuenta, la cual incluye:

* **Alarma de CPU del Auto Scaling Group:** Configura un `aws_cloudwatch_metric_alarm` sobre la métrica `CPUUtilization` del namespace `AWS/EC2`, disparando una notificación cuando el promedio de CPU supera el umbral configurado durante dos períodos de evaluación consecutivos.
* **Alarma de Errores 5XX del Load Balancer:** Configura un `aws_cloudwatch_metric_alarm` sobre la métrica `HTTPCode_Target_5XX_Count` del namespace `AWS/ApplicationELB`, alertando cuando la cantidad de errores 5XX acumulados supera el umbral definido.
* **Alarma de Conexiones de RDS:** Configura un `aws_cloudwatch_metric_alarm` sobre la métrica `DatabaseConnections` del namespace `AWS/RDS`, disparando una alerta cuando el promedio de conexiones simultáneas al cluster supera el límite configurado.
* **Alarma de Almacenamiento Libre de RDS:** Configura un `aws_cloudwatch_metric_alarm` sobre la métrica `FreeStorageSpace` del namespace `AWS/RDS`, alertando cuando el espacio libre disponible en el cluster cae por debajo del umbral definido en gigabytes.
* **Dashboard Centralizado:** Crea un `aws_cloudwatch_dashboard` con nombre estandarizado, destinado a consolidar la visibilidad de los recursos monitoreados de la plataforma.

---

## Recursos utilizados

| Elemento | Tipo | Descripción |
| :--- | :--- | :--- |
| `aws_cloudwatch_metric_alarm.asg_cpu` | Recurso | Alarma sobre la utilización de CPU del Auto Scaling Group. Dispara una notificación vía SNS cuando el promedio supera el umbral configurado. |
| `aws_cloudwatch_metric_alarm.alb_5xx` | Recurso | Alarma sobre la cantidad de errores HTTP 5XX del Load Balancer. Dispara una notificación vía SNS al superar el umbral configurado. |
| `aws_cloudwatch_metric_alarm.rds_connections` | Recurso | Alarma sobre el número de conexiones simultáneas al cluster de RDS. Dispara una notificación vía SNS al superar el umbral configurado. |
| `aws_cloudwatch_metric_alarm.rds_storage` | Recurso | Alarma sobre el espacio de almacenamiento libre del cluster de RDS. Dispara una notificación vía SNS cuando el espacio libre cae por debajo del umbral configurado. |
| `aws_cloudwatch_dashboard.this` | Recurso | Dashboard centralizado de CloudWatch para la visualización de los recursos monitoreados de la plataforma. |

---

## Variables requeridas / opcionales

| Variable | Tipo | Descripción |
| :--- | :--- | :--- |
| `environment` | `string` | Entorno de despliegue. Debe ser uno de: `dev`, `staging`, `prod`. |
| `autoscaling_group_name` | `string` | Nombre del Auto Scaling Group sobre el cual se configura la alarma de CPU. |
| `asg_cpu` | `number` | Umbral de porcentaje de utilización de CPU (ej: `80`) para disparar la alarma del Auto Scaling Group. |
| `lb_arn_suffix` | `string` | ARN suffix del Load Balancer, utilizado para vincular las métricas y alarmas de CloudWatch. |
| `lb_target_group_arn_suffix` | `string` | ARN suffix del Target Group, utilizado para vincular las métricas y alarmas de CloudWatch. |
| `lb_5XX` | `number` | Cantidad máxima de errores 5XX permitidos en el Load Balancer antes de disparar la alarma. |
| `rds_cluster_identifier` | `string` | Identificador del cluster de RDS sobre el cual se configuran las alarmas de conexiones y almacenamiento. |
| `rds_connections` | `number` | Número máximo de conexiones simultáneas permitidas al cluster de RDS antes de disparar la alarma. |
| `rds_storage_free` | `number` | Espacio mínimo de almacenamiento libre en el cluster de RDS (en gigabytes) antes de disparar la alarma de bajo almacenamiento. |
| `sns_topic_arn` | `string` | ARN del tópico de SNS hacia el cual se envían las notificaciones de todas las alarmas del módulo. |

---

## Ejemplo de Uso (`environments/dev`)

A continuación se muestra cómo invocar este módulo de CloudWatch, referenciando los recursos de la plataforma y definiendo los umbrales de alerta:

```hcl
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  # General Config
  environment = var.environment

  # Auto Scaling Group
  autoscaling_group_name = module.asg.autoscaling_group_name
  asg_cpu                = 80

  # Load Balancer
  lb_arn_suffix              = module.alb.lb_arn_suffix
  lb_target_group_arn_suffix = module.alb.lb_target_group_arn_suffix
  lb_5XX                     = 50

  # RDS
  rds_cluster_identifier = module.rds_aurora.rds_cluster_identifier
  rds_connections        = 100
  rds_storage_free       = 20

  # Notifications
  sns_topic_arn = module.notifications.sns_topic_arn
}
```

---

## Decisiones de Arquitectura y Diseño

* **Cobertura de los Recursos Críticos:** Las alarmas cubren las tres capas principales de la plataforma (cómputo, red y base de datos), ofreciendo visibilidad sobre los puntos de falla más comunes en una arquitectura típica de AWS.
* **Umbral de Almacenamiento en Bytes:** La variable `rds_storage_free` se expresa en gigabytes para facilitar su uso, y el módulo aplica internamente la conversión a bytes (`× 1024 × 1024 × 1024`) que exige la métrica `FreeStorageSpace` de CloudWatch.
* **Doble Período de Evaluación:** Todas las alarmas utilizan `evaluation_periods = 2` con un `period` de 120 segundos, requiriendo que la condición se cumpla durante cuatro minutos consecutivos antes de disparar. Esto reduce la cantidad de alertas espúreas por picos transitorios.
* **Integración con SNS Desacoplada:** El módulo no crea el tópico de SNS sino que lo recibe como variable (`sns_topic_arn`), respetando el principio de responsabilidad única y permitiendo reutilizar el tópico del módulo `notifications` u otro existente.
* **Naming Standard Autocalculado:** Mediante el uso de bloques `locals`, el módulo auto-genera los nombres de todos los recursos bajo el prefijo común `${Project}-${Environment}`, manteniendo la homogeneidad en la consola de AWS y previniendo colisiones de nombres entre entornos.
