# Security Notifications Module

Este módulo de Terraform despliega la infraestructura de **notificaciones de seguridad** de la cuenta, mediante reglas de **Amazon EventBridge** que capturan hallazgos de **GuardDuty** y **Security Hub** y los enrutan hacia un tópico de SNS existente. Centraliza la detección y el enrutamiento de eventos de seguridad críticos sin necesidad de crear infraestructura de mensajería propia.

---

## Qué hace este módulo

El módulo automatiza el aprovisionamiento de las reglas de enrutamiento de eventos de seguridad de la cuenta, las cuales incluyen:

* **Regla de EventBridge para GuardDuty:** Crea un `aws_cloudwatch_event_rule` que captura eventos del source `aws.guardduty` de tipo `GuardDuty Finding`, filtrando únicamente los hallazgos cuya severidad sea mayor o igual al umbral mínimo configurado.
* **Target de GuardDuty hacia SNS:** Configura un `aws_cloudwatch_event_target` que enruta los hallazgos de GuardDuty capturados por la regla hacia el tópico de SNS indicado.
* **Regla de EventBridge para Security Hub:** Crea un `aws_cloudwatch_event_rule` que captura eventos del source `aws.securityhub` de tipo `Security Hub Findings - Imported`, filtrando únicamente los hallazgos cuya severidad normalizada sea mayor o igual al umbral mínimo configurado.
* **Target de Security Hub hacia SNS:** Configura un `aws_cloudwatch_event_target` que enruta los hallazgos de Security Hub capturados por la regla hacia el tópico de SNS indicado.

---

## Recursos utilizados

| Elemento | Tipo | Descripción |
| :--- | :--- | :--- |
| `aws_cloudwatch_event_rule.guardduty_rule` | Recurso | Regla de EventBridge que captura hallazgos de GuardDuty iguales o superiores al umbral de severidad configurado. |
| `aws_cloudwatch_event_target.guardduty_target` | Recurso | Target que enruta los hallazgos de GuardDuty capturados hacia el tópico de SNS. |
| `aws_cloudwatch_event_rule.securityhub_rule` | Recurso | Regla de EventBridge que captura hallazgos importados de Security Hub iguales o superiores al umbral de severidad configurado. |
| `aws_cloudwatch_event_target.securityhub_target` | Recurso | Target que enruta los hallazgos de Security Hub capturados hacia el tópico de SNS. |

---

## Variables requeridas / opcionales

| Variable | Tipo | Descripción |
| :--- | :--- | :--- |
| `environment` | `string` | Entorno de despliegue. Debe ser uno de: `dev`, `staging`, `prod`. |
| `sns_topic_arn` | `string` | ARN del tópico de SNS hacia el cual se enrutan los hallazgos de seguridad capturados por las reglas de EventBridge. |
| `minimum_severity` | `number` | Nivel mínimo de severidad (1 a 10) que deben alcanzar los hallazgos de GuardDuty y Security Hub para ser capturados y notificados. |

---

## Ejemplo de Uso (`environments/dev`)

A continuación se muestra cómo invocar este módulo de Security Notifications, referenciando el tópico de SNS del módulo `notifications` y definiendo el umbral de severidad:

```hcl
module "security_notifications" {
  source = "../../modules/security-notifications"

  # General Config
  environment = var.environment

  # Severity threshold
  minimum_severity = 4

  # Notifications
  sns_topic_arn = module.notifications.sns_topic_arn
}
```

---

## Decisiones de Arquitectura y Diseño

* **Filtrado por Severidad en el Event Pattern:** El umbral mínimo se aplica directamente en el `event_pattern` de la regla de EventBridge mediante un filtro numérico (`>=`), evitando que hallazgos de baja severidad lleguen al tópico de SNS y reduciendo el ruido de notificaciones.
* **Cobertura de las Dos Fuentes de Seguridad Principales:** El módulo cubre tanto GuardDuty (detección de amenazas basada en comportamiento) como Security Hub (agregador de hallazgos de múltiples servicios de seguridad de AWS), ofreciendo visibilidad unificada sobre el posture de seguridad de la cuenta.
* **Integración con SNS Desacoplada:** El módulo no crea el tópico de SNS sino que lo recibe como variable (`sns_topic_arn`), respetando el principio de responsabilidad única y permitiendo reutilizar el tópico del módulo `notifications` u otro existente.
* **Naming Standard Autocalculado:** Mediante el uso de bloques `locals`, el módulo auto-genera los nombres de las reglas bajo el prefijo común `${Project}-${Environment}`, manteniendo la homogeneidad en la consola de AWS y previniendo colisiones de nombres entre entornos.
