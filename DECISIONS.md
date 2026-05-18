# Decisions

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



