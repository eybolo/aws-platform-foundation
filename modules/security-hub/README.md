# AWS Security Hub Module

Este módulo de Terraform habilita **AWS Security Hub** a nivel de cuenta y suscribe la cuenta a un conjunto parametrizable de estándares de seguridad (Security Standards) de AWS. Centraliza la activación del servicio de agregación de hallazgos de seguridad sin imponer estándares ni controles por defecto.

---

## Qué hace este módulo

El módulo automatiza el aprovisionamiento de la infraestructura base de Security Hub en la cuenta, la cual incluye:

* **Activación Controlada del Servicio:** Configura un `aws_securityhub_account` con `enable_default_standards = false` y `auto_enable_controls = false`, habilitando Security Hub sin activar automáticamente estándares ni controles, dejando esa decisión explícitamente en manos del consumidor del módulo.
* **Suscripción a Estándares Parametrizable:** Despliega un conjunto dinámico de `aws_securityhub_standards_subscription` a partir de una lista de ARNs, permitiendo suscribir la cuenta a uno o varios estándares (por ejemplo, CIS, AWS Foundational Security Best Practices, PCI DSS) sin modificar el código del módulo.
* **Orden de Activación Controlado:** Fuerza mediante `depends_on` que las suscripciones a estándares se creen únicamente después de que la cuenta de Security Hub ya esté habilitada, evitando errores de dependencia en el aprovisionamiento.

---

## Recursos utilizados

| Elemento | Tipo | Descripción |
| :--- | :--- | :--- |
| `aws_securityhub_account.this` | Recurso | Habilita Security Hub en la cuenta, sin estándares ni controles automáticos por defecto. |
| `aws_securityhub_standards_subscription.this` | Recurso (for_each) | Suscribe la cuenta a cada estándar de seguridad indicado en `var.standards_arn`. |

---

## Variables requeridas / opcionales

| Variable | Tipo | Descripción |
| :--- | :--- | :--- |
| `standards_arn` | `list(string)` | Lista de ARNs de los estándares de Security Hub a habilitar en la cuenta. |

---

## Ejemplo de Uso (`environments/dev`)

A continuación se muestra cómo invocar este módulo de Security Hub, definiendo los estándares de seguridad a suscribir:

```hcl
module "security_hub" {
  source = "../../modules/security-hub"

# Standards Security
  standards_arn = [
    "arn:aws:securityhub:::standards/aws-foundational-security-best-practices/v/1.0.0",
    "arn:aws:securityhub:::standards/cis-aws-foundations-benchmark/v/1.4.0",
  ]
}
```
---

## Decisiones de Arquitectura y Diseño

* **Activación sin Estándares ni Controles Automáticos:** Se opta deliberadamente por `enable_default_standards = false` y `auto_enable_controls = false` para evitar que AWS suscriba estándares no solicitados o habilite controles que generen hallazgos y costos no previstos al momento de activar el servicio.
* **Estándares como Datos, no como Código:** Las suscripciones a estándares se definen mediante `for_each` sobre `var.standards_arn`, lo que permite agregar, quitar o reconfigurar los estándares habilitados desde las variables del entorno, sin tocar el código del módulo ni generar diffs innecesarios en otros recursos.
* **Orden de Activación Controlado (Dependencias Explícitas):** El módulo fuerza el orden correcto de aprovisionamiento mediante `depends_on`, garantizando que la cuenta de Security Hub exista antes de intentar suscribir cualquier estándar.
* **Módulo Mínimo y Desacoplado:** A diferencia de otros módulos de cumplimiento, este módulo no gestiona naming estandarizado, locals ni outputs, ya que su única responsabilidad es la activación del servicio y la suscripción a estándares; cualquier integración adicional (por ejemplo, referenciar el ARN de la cuenta de Security Hub desde otros módulos) debe resolverse fuera de este módulo.
 