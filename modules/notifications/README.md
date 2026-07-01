# Notifications Module

Este módulo de Terraform despliega la infraestructura base de **notificaciones** de la cuenta, mediante un tópico de **Amazon SNS** y una suscripción por correo electrónico. Centraliza el envío de alertas e infraestructura de notificación para que otros módulos de la plataforma puedan publicar mensajes hacia un único punto.

---

## Qué hace este módulo

El módulo automatiza el aprovisionamiento de la infraestructura de notificaciones de la cuenta, la cual incluye:

* **Tópico SNS Centralizado:** Crea un `aws_sns_topic` con nombre estandarizado, pensado como punto único de publicación para notificaciones y alertas de infraestructura.
* **Suscripción por Email:** Configura un `aws_sns_topic_subscription` con protocolo `email`, suscribiendo una dirección de correo configurable para la recepción de las notificaciones del tópico.

---

## Recursos utilizados

| Elemento | Tipo | Descripción |
| :--- | :--- | :--- |
| `aws_sns_topic.this` | Recurso | Tópico de SNS utilizado como canal centralizado para el envío de notificaciones y alertas de infraestructura. |
| `aws_sns_topic_subscription.this` | Recurso | Suscripción por correo electrónico al tópico de SNS, encargada de recibir las notificaciones publicadas. |

---

## Variables requeridas / opcionales

| Variable | Tipo | Descripción |
| :--- | :--- | :--- |
| `environment` | `string` | Entorno de despliegue. Debe ser uno de: `dev`, `staging`, `prod`. |
| `email_sns` | `string` | Dirección de correo electrónico que se suscribe al tópico de SNS para recibir las notificaciones. |

---

## Ejemplo de Uso (`environments/dev`)

A continuación se muestra cómo invocar este módulo de Notifications, definiendo el correo que recibirá las alertas:

```hcl
module "notifications" {
  source = "../../modules/notifications"

  # General Config
  environment = var.environment

  # Notification Subscription
  email_sns = "alertas-infra@miempresa.com"
}
```
---

## Outputs Exportados

El módulo expone una salida clave para integraciones con otros módulos de la plataforma:

* **`sns_topic_arn`**: El ARN del tópico de SNS utilizado para enviar notificaciones y alertas de infraestructura. Útil para módulos que necesiten publicar eventos hacia este tópico (por ejemplo, CloudWatch Alarms, AWS Config, o pipelines de CI/CD).

---

## Decisiones de Arquitectura y Diseño

* **Tópico Único como Punto Central:** Se utiliza un único tópico de SNS por entorno como canal centralizado de notificaciones, simplificando la integración de otros módulos que necesiten publicar alertas.
* **Suscripción por Email:** Se eligió el protocolo `email` para la suscripción inicial por simplicidad operativa, dejando la puerta abierta a sumar otros protocolos (SMS, Lambda, SQS) en el futuro.
* **Naming Standard Autocalculado:** Mediante el uso de bloques `locals`, el módulo auto-genera el nombre del tópico bajo el prefijo común `${Project}-${Environment}`, manteniendo la homogeneidad en la consola de AWS y previniendo colisiones de nombres.
* **Etiquetado Consistente:** El tópico de SNS hereda automáticamente el mapa de etiquetas gubernamentales administrado por el equipo de plataforma (`Project`, `Environment`, `ManagedBy`, `Owner`).
