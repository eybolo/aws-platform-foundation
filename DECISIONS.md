# Decisions

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
