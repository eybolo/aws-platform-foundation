# Decisions

## [Fase 5] Protección contra PRs de forks externos (repo público)
El repo es público → cualquiera puede forkear y abrir PR contra main, 
disparando el workflow con un token OIDC válido (sub: repo:.../pull_request).
Mitigación: activar "Require approval for first-time contributors" en 
Settings → Actions → General, para que PRs externos no corran el 
workflow automáticamente sin revisión manual.

## [Fase 5] terraform-validate.yml — diseño del pipeline

- Trigger: `pull_request` (types: opened, synchronize, reopened) contra `main`.
- Doble `terraform init`: primero con `-backend=false` (providers/módulos, 
  sin credenciales AWS) para que `fmt`/`validate` corran sin exponer 
  credenciales; segundo init real (con backend S3) recién después de 
  `configure-aws-credentials`, para minimizar el tiempo de vida de las 
  credenciales en el runner.
- Auth vía OIDC (rol de Fase 1), sin access keys de larga duración.

## [Fase 5 — CI/CD] Alcance de multi-cuenta y permisos IAM

**Fecha:** 2026-07-06

### Contexto
El roadmap original (documento Proyecto 3) ubicaba "multi-cuenta" dentro 
del scope del Proyecto 1. Ese roadmap se armó antes de iniciar el 
Proyecto 1, sin experiencia práctica todavía.

### Decisión
- Multi-cuenta / AWS Organizations queda **fuera de scope** de los 
  Proyectos 1, 2 y 3. Se implementará como proyecto propio, posterior 
  al Proyecto 3, una vez dominada la plataforma base (Terraform, EKS, 
  Crossplane/Backstage).
- Proyectos 1, 2 y 3 se construyen en **una sola cuenta AWS**.
- El aislamiento entre teams en el Proyecto 3 se resuelve a nivel de 
  Kubernetes (namespaces + ResourceQuota + NetworkPolicy), no a nivel 
  de cuenta AWS.

### Deuda técnica conocida (Proyecto 1)
- El rol IAM del workflow de **validación** (GitHub Actions, PRs) usa 
  la managed policy `ReadOnlyAccess`.
- Esto viola *least privilege* a nivel de alcance: no está acotado por 
  proyecto, porque las condition keys de tags (`aws:ResourceTag/...`) 
  no aplican sobre acciones `Describe*`/`List*` cuyo "Resource type" 
  soportado es wildcard (`*`), no ARNs puntuales.
- Mitigación real de este límite: solo se resuelve con separación de 
  cuentas AWS (pendiente, ver punto anterior). Por ahora se acepta el 
  riesgo dentro de una única cuenta de desarrollo.

### Razón
Priorizar dominar cada capa (IaC → EKS/GitOps → IDP) antes de sumar la 
meta-estructura de organización de cuentas, evitando resolver dos 
problemas de diseño grandes en simultáneo.
## Ampliación de Fase 4 — Módulos notifications y security-notifications
Se agregaron dos módulos fuera del plan original: `notifications` (SNS Topic centralizado) 
y `security-notifications` (EventBridge rules para GuardDuty y Security Hub). 
Razón: se identificó que sin estas piezas, los findings de seguridad no tenían 
canal de notificación — solo eran visibles en consola.

## Pendiente refactor
Migrar name_prefix/common_tags a modules/tags compartido, y centralizar cálculo 
de nombres de recursos (buckets, etc) en locals.tf en lugar de interpolación inline 
en main.tf. Aplicar también description en roles IAM. 
Aplica a: vpc, kms, alb, asg, rds-aurora.

## Pendiente — CloudWatch Dashboard 
Body del dashboard definido visualmente en consola de AWS una vez que la infraestructura esté corriendo. Copiar JSON resultante desde "Actions → View/Edit source" y pegarlo en modules/cloudwatch/main.tf.

## Deuda técnica — Constraint de versión Terraform (`~>` → `>=`)
Corregir ~> 1.7 a >= 1.7 en los módulos anteriores vpc, kms, alb, asg, rds-aurora.

## Multi-región (futuro)
Si se agrega una segunda región a la Landing Zone, include_global_resource_types debe quedar true solo en us-east-1 (región principal). En cualquier región adicional, debe ser false, para evitar duplicar el registro de recursos globales (IAM, Route53, etc).

## Pendiente refactor
Migrar name_prefix/common_tags a modules/tags compartido, y centralizar cálculo de nombres de recursos (buckets, etc) en locals.tf en lugar de interpolación inline en main.tf. Aplica a: vpc, kms, alb, asg, rds-aurora.

## Deuda técnica / Decisión de arquitectura — modules/tags:
Se identificó duplicación de common_tags/name_prefix en cada módulo. Pendiente: evaluar creación de módulo modules/tags (solo locals/outputs, sin recursos) para centralizar esto.

## Deuda técnica / Decisión de arquitectura — rds-aurora:
Se agregó lifecycle { ignore_changes = [availability_zones] } al recurso aws_rds_cluster. El atributo availability_zones se calcula dinámicamente con sort(slice(data.aws_availability_zones.available.names, 0, 2)). Aunque el sort() asegura un orden estable mientras la región tenga las mismas AZs disponibles, si AWS agrega o remueve una zona de disponibilidad en el futuro, el resultado del slice podría cambiar y forzar el reemplazo completo del cluster (con pérdida de datos en producción si no hay snapshot). El lifecycle evita ese reemplazo automático ante cambios en este atributo específico, priorizando la estabilidad del cluster sobre la actualización automática de AZs.

## Crear un dominio real y Certificado ACM
Queda pendiente crear un dominio real para utilizarlo en produccion y certificado ACM. Por el momento estamos usando uno falso.

## Deuda técnica: El security group de Aurora tiene egress abierto a 0.
0.0.0/0 para permitir acceso a Secrets Manager y KMS. Solución correcta: crear VPC Endpoints para ambos servicios y restringir egress solo a la VPC.

## Criterios de Configuración y Gestión de Parámetros
Para mantener el módulo limpio, predecible y seguro entre diferentes entornos (Dev, Staging, Prod), aplicamos estrictamente las siguientes tres reglas:

1. **Fijo en todos los entornos -> Hardcodeado**
   Si un parámetro no debe cambiar independientemente de dónde se despliegue (por ejemplo, el tipo de motor `engine = "aurora-postgresql"`), se escribe directamente en el recurso. No se expone como variable para evitar errores de configuración.

2. **Cambia entre entornos -> Variable**
   Si el valor depende del entorno (por ejemplo, `cluster_identifier`, la cantidad de instancias, o la VPC/Subnets), se define mandatoriamente como una variable en `variables.tf`.

3. **Sensible o generado -> Delegado a otro recurso**
   Cualquier dato confidencial (como contraseñas) o que deba ser dinámico no se pasa por variables en texto plano. Se delega su ciclo de vida a recursos específicos como `random_password`, `aws_kms_key` o `aws_secretsmanager_secret`.

## Deshabilitar Multi-Región en llaves KMS (multi_region = false)
Toda nuestra infraestructura actual corre centralizada en la región us-east-1. Activar llaves 
multi-región duplica los costos de KMS innecesariamente y aumenta la superficie de exposición 
del material criptográfico. Se establece 'false' como estándar; solo se evaluará cambiarlo 
si implementamos una estrategia de Disaster Recovery (DR) activo-activo en otra región.

## Una llave KMS (CMK) por servicio en vez de una única global
Una sola llave crea un radio de impacto (blast radius) total si se compromete.
Tener una llave por servicio aplica el principio de menor privilegio: si vulneran
la llave de CloudWatch, no pueden descifrar los discos EBS ni las bases de datos.
Además, evita políticas de acceso gigantescas y confusas en una sola llave.

## Una llave KMS (CMK) por servicio en vez de una única global
Una sola llave crea un radio de impacto (blast radius) total si se  compromete.

## Los modulos reutilizables no llevan variables defaults
Los modulos que son reutilizable no van a llevar variables de red
para forzar al caller a ser explicito.

## GitHub Actions usa OIDC en vez de claves IAM
Las claves IAM son credenciales permanentes — si se filtran, 
cualquiera puede usarlas indefinidamente.
OIDC no tiene credenciales permanentes — GitHub demuestra 
su identidad con un token firmado y AWS emite credenciales 
temporales que duran solo minutos.

## Bootstrap usa SSE-S3 en vez de KMS
El bucket del state necesita existir antes que Terraform.
Las CMKs las crea Terraform, por lo tanto no pueden existir
antes del bootstrap — problema del huevo y la gallina.
Excepción controlada y documentada. Todo lo demás usa KMS CMK.
