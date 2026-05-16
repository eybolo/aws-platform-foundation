# Decisions

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



