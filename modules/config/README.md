# AWS Config Module

Este módulo de Terraform despliega **AWS Config** a nivel de cuenta, habilitando el grabador de configuraciones (Configuration Recorder), el canal de entrega hacia S3 y un conjunto parametrizable de reglas de cumplimiento (Config Rules) administradas por AWS. Centraliza la auditoría continua del estado de los recursos desplegados en la cuenta.

---

## Qué hace este módulo

El módulo automatiza el aprovisionamiento de la infraestructura de auditoría y cumplimiento de la cuenta, la cual incluye:

* **Grabación Integral de Recursos:** Configura un `aws_config_configuration_recorder` con `all_supported = true` e `include_global_resource_types = true`, registrando el historial de configuración de todos los tipos de recursos soportados, incluyendo recursos globales como IAM.
* **Canal de Entrega Centralizado:** Crea un `aws_config_delivery_channel` que envía snapshots periódicos de configuración hacia un bucket de S3 dedicado, con una frecuencia de entrega parametrizable.
* **Rol de Servicio Dedicado:** Aprovisiona un `aws_iam_role` con política de confianza exclusiva para el servicio `config.amazonaws.com`, combinando una policy inline de mínimo privilegio sobre el bucket de logs con el adjunto de la política administrada `AWS_ConfigRole` para los permisos de lectura de recursos.
* **Reglas de Cumplimiento Parametrizables:** Despliega un conjunto dinámico de `aws_config_config_rule` (managed rules de AWS) a partir de una lista de objetos, permitiendo inyectar reglas y sus parámetros específicos sin modificar el código del módulo.
* **Retención Automática de Logs:** Integra un `aws_s3_bucket_lifecycle_configuration` que expira automáticamente los snapshots almacenados en S3 según una política de retención configurable, o los conserva indefinidamente si así se especifica.

---

## Recursos utilizados

| Elemento | Tipo | Descripción |
| :--- | :--- | :--- |
| `aws_iam_role.this` | Recurso | Rol asumido por AWS Config para monitorear, grabar y auditar la configuración de los recursos de la cuenta. |
| `aws_iam_role_policy.this` | Recurso | Policy inline de mínimo privilegio que otorga `PutObject` y `GetBucketAcl` exclusivamente sobre el bucket de logs de Config. |
| `aws_iam_role_policy_attachment.this` | Recurso | Adjunta la política administrada `AWS_ConfigRole` necesaria para que el servicio pueda describir los recursos de la cuenta. |
| `aws_s3_bucket.this` | Recurso | Bucket de S3 que almacena de forma cruda los snapshots de configuración entregados por AWS Config. |
| `aws_s3_bucket_lifecycle_configuration.this` | Recurso | Regla de ciclo de vida que expira los snapshots almacenados según `log_retention_days`. |
| `aws_config_configuration_recorder.this` | Recurso | El grabador que define qué se audita: todos los tipos de recursos soportados, incluyendo recursos globales. |
| `aws_config_delivery_channel.this` | Recurso | El canal que define hacia dónde y con qué frecuencia se entregan los snapshots de configuración. |
| `aws_config_configuration_recorder_status.this` | Recurso | Habilita (enciende) el grabador una vez que el canal de entrega ya existe. |
| `aws_config_config_rule.this` | Recurso (for_each) | Las reglas de cumplimiento administradas por AWS, una por cada elemento de `var.config_rules`. |

---

## Variables requeridas / opcionales

| Variable | Tipo | Descripción |
| :--- | :--- | :--- |
| `environment` | `string` | Entorno de despliegue. Debe ser uno de: `dev`, `staging`, `prod`. |
| `config_rules` | `list(object({ name = string, parameters = map(string) }))` | Lista de reglas de AWS Config a crear, cada una con su nombre (source identifier de AWS) y sus parámetros propios. |
| `log_retention_days` | `number` | Días de retención de los snapshots en S3. Usar `0` para retención infinita (nunca eliminar). |
| `delivery_frequency` | `string` | Frecuencia de entrega de snapshots. Debe ser uno de: `One_Hour`, `Three_Hours`, `Six_Hours`, `Twelve_Hours`, `TwentyFour_Hours`. |

---

## Ejemplo de Uso (`environments/dev`)

A continuación se muestra cómo invocar este módulo de Config, definiendo las reglas de cumplimiento deseadas y la política de retención de logs:

```hcl
module "config" {
  source = "../../modules/config"

  # Configuracion General
  environment = var.environment

  # Politica de Retencion y Entrega
  log_retention_days = 90
  delivery_frequency  = "TwentyFour_Hours"

  # Reglas de Cumplimiento
  config_rules = [
    {
      name       = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
      parameters = {}
    },
    {
      name = "RESTRICTED_INCOMING_TRAFFIC"
      parameters = {
        blockedPort1 = "22"
      }
    },
  ]
}
```
---

## Outputs Exportados

El módulo expone salidas clave para auditoría y para integraciones con otros módulos de seguridad/cumplimiento:

* **`s3_bucket_arn`**: El ARN del bucket de S3 utilizado por AWS Config. Útil para módulos que necesiten otorgar permisos adicionales de lectura sobre los logs (por ejemplo, herramientas de SIEM o análisis forense).
* **`iam_role_arn`**: El ARN del rol IAM utilizado por AWS Config. Permite referenciarlo en políticas de otros recursos que necesiten validar o auditar qué identidad está realizando las lecturas de configuración.
* **`config_rules_names`**: La lista de nombres finales de las reglas de Config creadas, ya calculados con el prefijo del módulo. Útil para dashboards, alertas o cualquier integración que necesite referenciar las reglas por nombre.

---

## Decisiones de Arquitectura y Diseño

* **Cobertura Total de Recursos (All Supported + Global):** El recorder se configura con `all_supported = true` e `include_global_resource_types = true` para garantizar visibilidad completa sobre la cuenta, sin necesidad de mantener manualmente una lista de tipos de recursos a medida que AWS agrega nuevos servicios.
* **Orden de Activación Controlado (Dependencias Explícitas):** El módulo fuerza el orden correcto de aprovisionamiento mediante `depends_on`: primero el recorder, luego el delivery channel, y solo al final se habilita el recorder vía `aws_config_configuration_recorder_status`. Esto evita el error de AWS al intentar grabar sin un canal de entrega configurado.
* **Permisos de Mínimo Privilegio sobre S3:** La policy inline del rol no otorga acceso amplio al bucket; restringe explícitamente las acciones a `s3:PutObject` (solo dentro del prefijo del bucket) y `s3:GetBucketAcl`, delegando el resto de los permisos de lectura de recursos a la política administrada oficial `AWS_ConfigRole`.
* **Reglas como Datos, no como Código:** Las Config Rules se definen mediante `for_each` sobre `var.config_rules`, lo que permite agregar, quitar o reconfigurar reglas managed de AWS desde las variables del entorno, sin tocar el código del módulo ni generar diffs innecesarios en otros recursos.
* **Retención Configurable con Opción de Indefinida:** El lifecycle del bucket de logs activa o desactiva la regla de expiración (`Enabled`/`Disabled`) según si `log_retention_days` es mayor a cero, permitiendo tanto políticas de cumplimiento con borrado automático como retención permanente para auditorías regulatorias.
* **Naming Standard Autocalculado:** Mediante el uso de bloques `locals`, el módulo auto-genera los nombres de todos los recursos bajo el prefijo común `${Project}-${Environment}` (incluyendo el bucket, que además incorpora el `account_id` para garantizar unicidad global), manteniendo la homogeneidad en la consola de AWS y previniendo colisiones de nombres.
* **Etiquetado Consistente:** Los recursos que soportan tags (rol IAM y bucket de S3) heredan automáticamente el mapa de etiquetas gubernamentales administrado por el equipo de plataforma (`Project`, `Environment`, `ManagedBy`, `Owner`).
