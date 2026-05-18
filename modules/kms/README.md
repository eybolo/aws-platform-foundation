# AWS KMS (Key Management Service) Module

Este módulo de Terraform despliega una clave administrada por el cliente (**Customer Managed Key**) en AWS KMS. Está diseñado para centralizar la gestión de cifrado e implementar una política de clave altamente dinámica y segura mediante el uso de *Service Principals* condicionales.

---

## Qué hace este módulo

El módulo automatiza la creación y configuración de una clave criptográfica que incluye:

* **Cifrado Personalizado:** Creación de una llave KMS con soporte opcional para multi-región y rotación automática.
* **Política de Clave Dinámica:** * Garantiza el acceso total de administración a la cuenta raíz de AWS (`root`) para evitar bloqueos.
  * Inyecta permisos dinámicos a servicios de AWS (*Service Principals*) basándose en un mapa de configuraciones, eliminando la necesidad de escribir múltiples bloques de políticas a mano.
* **Seguridad por Contexto:** Limita el uso de la llave únicamente a los recursos que coincidan con la región, cuenta y servicio especificados, evitando ataques de suplantación de identidad (*confused deputy*).

---

## Recursos y Datos utilizados

| Elemento | Tipo | Descripción |
| :--- | :--- | :--- |
| `data.aws_caller_identity.current` | Data Source | Obtiene el ID de la cuenta de AWS actual para las políticas de IAM. |
| `data.aws_region.current` | Data Source | Obtiene la región activa para validar el origen de las peticiones. |
| `aws_kms_key.this` | Recurso | La clave KMS principal configurada con políticas dinámicas y etiquetas. |

---

## Variables requeridas / opcionales

| Variable | Tipo | Descripción |
| :--- | :--- | :--- |
| `environment` | `string` | Nombre del entorno (utilizado en prefijos, tags y control de ciclo de vida). |
| `multi_region` | `bool` | Define si la llave KMS será réplica-multi-región (`true` o `false`). |
| `enable_key_rotation` | `bool` | Habilita la rotación anual automática del material criptográfico de la llave. |
| `service_name` | `string` | Nombre del servicio de AWS que generará los recursos de origen (ej: `s3`, `sns`, `rds`). |
| `service_principals` | `map(object)` | Mapa de servicios autorizados y sus acciones permitidas. Estructura esperada detallada abajo. |

### Estructura de la variable `service_principals`

Esta variable te permite pasar múltiples servicios con sus respectivos permisos de forma limpia utilizando bloques `for`:

```hcl
variable "service_principals" {
  type = map(object({
    actions = list(string)
  }))
  default = {
    "s3.amazonaws.com" = {
      actions = ["kms:Decrypt", "kms:GenerateDataKey*"]
    }
  }
}
```

## Outputs (Salidas)

* **`key_id`**: El identificador único global de la llave KMS creada.
* **`key_arn`**: El Amazon Resource Name (ARN) de la llave, necesario para configurar el cifrado en otros módulos (S3, EBS, RDS, CloudWatch, etc.).

## Decisiones de Arquitectura y Diseño

* **Mitigación de Confused Deputy:** La política de la clave no otorga permisos abiertos a los servicios de AWS. Utiliza de forma obligatoria una condición `ArnLike` contra el `aws:SourceArn`, asegurando que el servicio solo pueda usar la llave si el recurso origen pertenece estrictamente a la misma cuenta y región.
* **Formateo de SIDs:** Dado que los identificadores de declaración de políticas (`Sid`) en AWS no permiten caracteres especiales como puntos, el código reemplaza automáticamente los puntos de los Service Principals (ej: `s3.amazonaws.com` se transforma internamente en `AllowUsageTo-s3amazonawscom`).
* **Etiquetado Consistente:** Al igual que el resto de la infraestructura, hereda un mapa de `local.common_tags` para garantizar el cumplimiento de las políticas de gobierno y tracking de costos de la organización.
