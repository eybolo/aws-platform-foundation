# Runbook

Registro de problemas técnicos resueltos durante el proyecto: síntoma, causa raíz y solución.
Pensado para resolver en minutos un problema ya visto, no para volver a investigarlo desde cero.

A diferencia de `DECISIONS.md` (que registra decisiones de arquitectura y el *por qué* de un diseño),
este documento registra *errores concretos* y cómo se solucionaron.

---

## [AWS Config] Policy managed con nombre incorrecto

**Síntoma:**
`terraform apply` falla con error de policy no encontrada al intentar adjuntar 
la managed policy de Config al rol IAM.

**Causa raíz:**
La AWS Managed Policy se llama `AWS_ConfigRole` (con guion bajo, desde 2022), 
no `AWSConfigRole` (nombre viejo deprecado). Usar el nombre viejo genera un error 
de ARN inválido.

**Solución:**
Usar el ARN correcto:
```hcl
policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
```

---

## [AWS Config] Error al activar el recorder sin Delivery Channel

**Síntoma:**
`terraform apply` falla al intentar habilitar `aws_config_configuration_recorder_status` 
con un error de la API de AWS indicando que no existe un canal de entrega configurado.

**Causa raíz:**
AWS exige que el Delivery Channel exista **antes** de poder activar el recorder. 
Como no hay referencia de atributo entre ambos resources, Terraform no infiere 
el orden automáticamente.

**Solución:**
Agregar `depends_on` explícito en `aws_config_configuration_recorder_status`:
```hcl
depends_on = [aws_config_delivery_channel.this]
```

---

## [ALB] Access Denied al habilitar access_logs en S3

**Síntoma:**
`terraform apply` falla con:
```
InvalidConfigurationRequest: Access Denied for bucket: <bucket-name>. Please check S3bucket permission
```

**Causa raíz:**
El ALB en regiones "legacy" (anteriores a agosto 2022, incluye `us-east-1`) no usa el principal
moderno `delivery.logs.amazonaws.com` para escribir logs en S3. Requiere el account ID específico
del servicio de Elastic Load Balancing para esa región, como principal tipo `"AWS"`.

**Solución:**
Bucket policy con dos statements:
1. `s3:PutObject` sobre `${bucket_arn}/AWSLogs/${account_id}/*`, con
   `Principal.AWS = "arn:aws:iam::127311923021:root"` (ID para `us-east-1`) y `Condition` exigiendo
   `s3:x-amz-acl = bucket-owner-full-control`.
2. `s3:GetBucketAcl` sobre el bucket en sí (sin `/*`), mismo principal.

**Referencia:**
https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
(Los account IDs varían por región — verificar la tabla en el link antes de copiar el ID.)

**Nota:**
No usar `delivery.logs.amazonaws.com` para ALB en regiones legacy — ese principal es para
VPC Flow Logs, CloudTrail, etc., no para ELB clásico/ALB en `us-east-1`.

---

## [RDS Aurora] Error al destruir: final_snapshot_identifier is required

**Síntoma:**
`terraform destroy` falla con:
```
Error: RDS Cluster final_snapshot_identifier is required when skip_final_snapshot is false
```

**Causa raíz:**
Por defecto, Aurora exige un snapshot final antes de poder eliminar un cluster, salvo que se indique
explícitamente lo contrario.

**Solución:**
Agregar al recurso `aws_rds_cluster`:
```hcl
skip_final_snapshot = true
```
Solo para entornos de dev/test. En producción, evaluar si conviene generar el snapshot final en vez
de saltarlo.

**Nota importante:**
Si el cluster ya fue creado *sin* este argumento, agregarlo al código no alcanza — hay que correr
`terraform apply` primero para que el cambio se aplique al recurso existente (un `update in-place`),
y solo después intentar el `destroy`. Si el cluster ya fue borrado manualmente desde la consola,
limpiar el state con `terraform state rm <recurso>` antes de reintentar.

---

## [Secrets Manager] No se puede crear un secret: ya está "scheduled for deletion"

**Síntoma:**
```
InvalidRequestException: You can't create this secret because a secret with this name is already
scheduled for deletion.
```

**Causa raíz:**
AWS Secrets Manager no borra un secret inmediatamente — lo marca para borrado con un período de
recuperación (7 días por defecto). Mientras ese período no termine, no se puede crear un secret
nuevo con el mismo nombre.

**Solución:**
Forzar el borrado inmediato:
```bash
aws secretsmanager delete-secret \
  --secret-id "<nombre-del-secret>" \
  --force-delete-without-recovery
```
Después, reintentar `terraform apply`.

**Nota:**
Pasa siempre que se hace `destroy` y `apply` en el mismo entorno en un lapso corto de tiempo
(por ejemplo, para frenar costos un fin de semana y volver a levantar el lunes). Es esperable, no
es un error de configuración.

---

## [CloudWatch] Log group ya existe al recrear infraestructura

**Síntoma:**
```
ResourceAlreadyExistsException: The specified log group already exists
```

**Causa raíz:**
Un `terraform destroy` anterior no eliminó el log group (porque falló antes de llegar a ese recurso,
o porque quedó fuera del state por algún motivo), pero el recurso sigue existiendo en AWS.

**Solución:**
Importar el recurso existente al state en lugar de intentar crearlo de nuevo:
```bash
terraform import module.vpc.aws_cloudwatch_log_group.vpc_flow_logs /aws/vpc/flow-logs-dev
```
Ajustar el nombre del módulo/recurso y el log group según corresponda.

---

## [RDS Aurora] terraform plan quiere reemplazar el cluster por availability_zones

**Síntoma:**
`terraform plan` marca `aws_rds_cluster` y sus instancias para destruir y recrear
(`-/+ resource`), con el atributo `availability_zones` marcado como `# forces replacement`,
sin que se haya cambiado nada manualmente.

**Causa raíz:**
`availability_zones` se calculaba con `slice(data.aws_availability_zones.available.names, 0, 2)`.
El orden en que AWS devuelve esa lista no está garantizado de ser estable entre llamadas al data
source, por lo que Terraform puede detectar una diferencia respecto al state guardado y considerar
que el recurso cambió.

**Solución:**
1. Ordenar el resultado para que sea determinístico:
   ```hcl
   availability_zones = sort(slice(data.aws_availability_zones.available.names, 0, 2))
   ```
2. Como salvaguarda adicional (por si en el futuro AWS agrega/quita una AZ en la región), agregar:
   ```hcl
   lifecycle {
     ignore_changes = [availability_zones]
   }
   ```

**Nota:**
El `lifecycle` no soluciona el problema de fondo, es una protección extra. El `sort()` es la
solución real para el caso común. Ver `DECISIONS.md` para el razonamiento completo.

---

## [S3] terraform destroy falla: BucketNotEmpty

**Síntoma:**
```
Error: deleting S3 Bucket (...): operation error S3: DeleteBucket, ... BucketNotEmpty:
The bucket you tried to delete is not empty
```

**Causa raíz:**
Terraform no borra objetos dentro de un bucket S3 por seguridad — solo borra el bucket si está
vacío. Si el bucket acumuló logs u otros objetos (por ejemplo, access logs del ALB), el `destroy`
falla.

**Solución:**
Vaciar el bucket manualmente antes de destruir:
```bash
aws s3 rm s3://<nombre-del-bucket> --recursive
```
Después, reintentar `terraform destroy`.

---

## [AWS CLI] UnrecognizedClientException / security token invalid

**Síntoma:**
Comandos del AWS CLI fallan con:
```
An error occurred (UnrecognizedClientException) when calling the <Operation>:
The security token included in the request is invalid.
```
... a pesar de haber corrido `aws configure` con credenciales que se ven correctas.

**Causa raíz:**
Variables de entorno (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`) tienen
prioridad sobre el archivo `~/.aws/credentials`. Si quedaron seteadas de una sesión anterior
(credenciales viejas, rotadas, o de otra cuenta), el CLI las usa en lugar de las del archivo de
configuración, sin avisar.

**Solución:**
```bash
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
aws configure list   # confirmar que ahora lee del archivo de config, no de env vars
```

**Nota:**
Si tenés más de un access key activo en IAM, desactivar/eliminar el que no se usa para evitar esta
confusión a futuro.

---

## [Terraform] name supera el límite de caracteres de AWS

**Síntoma:**
```
Error: "name" cannot be longer than 32 characters
```
(en `aws_lb_target_group`, pero aplica a cualquier recurso con límite de nombre).

**Causa raíz:**
El `name_prefix` estándar del proyecto (`${Project}-${Environment}`) más el sufijo del recurso
supera el límite que AWS impone a ese recurso específico (varía según el tipo de recurso).

**Solución:**
Crear un `local` adicional con una versión abreviada del prefijo, solo para los recursos que lo
necesiten:
```hcl
name_prefix_short = "aws-plt-fnd-${var.environment}"
```
Usar el prefijo corto únicamente donde el límite de AWS lo exija, manteniendo el prefijo largo en
el resto para legibilidad.

---

## [Terraform/IAM] Acceso a servicios AWS desde un Security Group: por SG en vez de CIDR

**Caso, no error:** patrón a reutilizar.

**Contexto:**
Para permitir tráfico entre dos recursos propios (por ejemplo, ASG → ALB, o ASG → RDS), es mejor
referenciar el Security Group del recurso destino en lugar de su rango de IPs (CIDR).

**Por qué:**
Un CIDR es una dirección de red que puede cambiar si el recurso se recrea. Un Security Group es una
identidad estable — si el ALB cambia de IP, la regla basada en su SG sigue funcionando sin
modificaciones.

**Cómo:**
```hcl
ingress {
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_groups = [var.security_group_id_alb]  # en vez de cidr_blocks
}
```