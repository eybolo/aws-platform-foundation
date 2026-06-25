# AWS GuardDuty Module

Este módulo de Terraform despliega **Amazon GuardDuty** a nivel de cuenta, habilitando la detección inteligente de amenazas mediante el análisis continuo de fuentes de datos como logs de red, eventos de API y actividad de S3. Permite activar de forma selectiva features adicionales de protección según las necesidades del entorno.

---

## Qué hace este módulo

El módulo automatiza el aprovisionamiento de la infraestructura de detección de amenazas de la cuenta, la cual incluye:

* **Detector Central Habilitado:** Crea y habilita un `aws_guardduty_detector`, el componente raíz que activa el análisis continuo de GuardDuty sobre la cuenta, con una frecuencia de publicación de hallazgos (findings) parametrizable.
* **Monitoreo de Eventos de Datos S3 (Opcional):** Habilita el feature `S3_DATA_EVENTS`, permitiendo a GuardDuty inspeccionar operaciones a nivel de objeto (lecturas/escrituras) sobre los buckets de S3 para detectar patrones de acceso anómalos o potencialmente maliciosos.
* **Protección contra Malware en EBS (Opcional):** Habilita el feature `EBS_MALWARE_PROTECTION`, que dispara automáticamente un escaneo de malware sobre los volúmenes EBS asociados a instancias EC2 cuando se detecta comportamiento sospechoso.
* **Activación Selectiva por Feature:** Cada feature adicional (S3, EBS) se controla de forma independiente mediante variables booleanas, permitiendo habilitar únicamente las capacidades que el entorno necesita sin incurrir en costos de features no utilizados.

---

## Recursos utilizados

| Elemento | Tipo | Descripción |
| :--- | :--- | :--- |
| `aws_guardduty_detector.this` | Recurso | El detector raíz de GuardDuty, habilitado a nivel de cuenta con su frecuencia de publicación de findings. |
| `aws_guardduty_detector_feature.s3_data_events` | Recurso | Feature que activa/desactiva el monitoreo de eventos de datos de S3 sobre el detector. |
| `aws_guardduty_detector_feature.ebs_malware_protection` | Recurso | Feature que activa/desactiva el escaneo de malware en volúmenes EBS sobre el detector. |

---

## Variables requeridas / opcionales

| Variable | Tipo | Descripción |
| :--- | :--- | :--- |
| `environment` | `string` | Entorno de despliegue. Debe ser uno de: `dev`, `staging`, `prod`. |
| `finding_publishing_frequency` | `string` | Frecuencia con la que GuardDuty publica los findings. Debe ser uno de: `FIFTEEN_MINUTES`, `ONE_HOUR`, `SIX_HOURS`. |
| `s3_data_events` | `bool` | Controla si GuardDuty monitorea eventos de datos de S3 como fuente para detectar amenazas dentro de los buckets. |
| `ebs_malware_protection` | `bool` | Controla si se habilita Malware Protection para escanear automáticamente volúmenes EBS ante comportamiento sospechoso. |

---

## Ejemplo de Uso (`environments/dev`)

A continuación se muestra cómo invocar este módulo de GuardDuty, definiendo la frecuencia de findings y qué features adicionales activar:

```hcl
module "guardduty" {
  source = "../../modules/guardduty"

  # General Config
  environment = var.environment

  # Frequency of Publication of Findings
  finding_publishing_frequency = "ONE_HOUR"

  # Additional Features
  s3_data_events         = true
  ebs_malware_protection = true
}
```
---

## Outputs Exportados

El módulo expone una salida clave para integración con otros módulos de seguridad y observabilidad:

* **`guardduty_detector_id`**: El identificador único del detector de GuardDuty. Esencial para que otros recursos o módulos (por ejemplo, integraciones con EventBridge, Security Hub, o reglas adicionales de threat intel) puedan referenciar el detector ya existente sin necesidad de duplicarlo.

---

## Decisiones de Arquitectura y Diseño

* **Detector Único por Cuenta:** GuardDuty permite un único detector activo por cuenta y región, por lo que el módulo modela este recurso como un singleton (`aws_guardduty_detector.this`), evitando configuraciones que generen conflictos al intentar crear detectores duplicados.
* **Features como Componentes Independientes:** En lugar de activar todas las capacidades de GuardDuty por defecto, cada feature se modela como un recurso `aws_guardduty_detector_feature` separado y condicionado por su propia variable booleana. Esto da control granular por entorno (por ejemplo, activar Malware Protection solo en `prod` para optimizar costos en `dev`/`staging`).
* **Costo Controlado por Diseño:** Tanto el monitoreo de eventos S3 como la protección de malware en EBS incrementan el costo de GuardDuty según volumen de datos analizado. Exponerlos como variables explícitas obliga a una decisión consciente por entorno en lugar de heredar configuraciones costosas por defecto.
* **Frecuencia de Findings Parametrizable:** La variable `finding_publishing_frequency` permite ajustar qué tan rápido se entregan los hallazgos a destinos como EventBridge, balanceando entre necesidad de respuesta casi en tiempo real (`FIFTEEN_MINUTES`) y reducción de ruido/costos en entornos no productivos (`SIX_HOURS`).
* **Etiquetado Consistente:** El detector hereda automáticamente el mapa de etiquetas gubernamentales administrado por el equipo de plataforma (`Project`, `Environment`, `ManagedBy`, `Owner`).