# AWS Networking Module (VPC)

Este módulo de Terraform despliega una arquitectura de red en AWS siguiendo el estándar de segmentación de tres capas (Pública, Privada y Datos), optimizado para seguridad, alta disponibilidad y observabilidad.

## 🚀 Qué hace este módulo

El módulo automatiza la creación de una infraestructura de red completa (VPC) que incluye:

*   **Segmentación de Red:** División lógica en 3 niveles de subredes (Public, Private, Data) distribuidas en múltiples Zonas de Disponibilidad (AZs).
*   **Conectividad:** 
    *   Salida directa a Internet para recursos públicos vía **Internet Gateway**.
    *   Salida segura para recursos privados vía **NAT Gateway** (con IP Elástica dedicada).
*   **Observabilidad:** Implementación de **VPC Flow Logs** para auditoría de tráfico, con almacenamiento automático en **CloudWatch Logs**.
*   **Gestión de Accesos:** Creación de los roles y políticas de IAM necesarios para el funcionamiento de los logs de flujo.

---

## 🏗️ Recursos creados

| Recurso | Descripción |
| :--- | :--- |
| `aws_vpc` | Red principal con soporte de DNS habilitado. |
| `aws_internet_gateway` | Punto de enlace para el tráfico público. |
| `aws_subnet` | Subredes segmentadas por función (3 tipos por AZ). |
| `aws_nat_gateway` | Puerta de salida para subredes privadas (localizada en `public_subnet[0]`). |
| `aws_eip` | IP Estática (Elastic IP) para el NAT Gateway. |
| `aws_route_table` | Tablas de ruteo específicas para cada nivel de seguridad. |
| `aws_flow_log` | Activación de captura de tráfico IP (Aceptado/Rechazado). |
| `aws_cloudwatch_log_group` | Repositorio para los logs de tráfico. |
| `aws_iam_role` | Rol de servicio para `vpc-flow-logs.amazonaws.com`. |

---

## ⚙️ Variables requeridas

| Variable | Tipo | Descripción |
| :--- | :--- | :--- |
| `vpc_cidr` | `string` | Rango CIDR principal (ej: `10.0.0.0/16`). |
| `subnet_public` | `list(string)` | Lista de rangos para subredes públicas. |
| `subnet_private` | `list(string)` | Lista de rangos para subredes de aplicación. |
| `subnet_data` | `list(string)` | Lista de rangos para subredes de base de datos. |
| `availability_zones` | `list(string)` | Zonas donde se desplegarán los recursos. |
| `environment` | `string` | Nombre del entorno (utilizado en prefijos y logs). |

---

## 📤 Outputs (Salidas)

*   **`vpc_id`**: ID de la VPC para uso en otros módulos (Security Groups, EC2).
*   **`public_subnet_ids`**: Lista de IDs de subredes públicas.
*   **`private_subnet_ids`**: Lista de IDs de subredes privadas.
*   **`data_subnet_ids`**: Lista de IDs de subredes de datos.
*   **`nat_gateway_ip`**: IP pública del NAT Gateway para configuraciones externas.

---

## 📝 Pendientes / Decisiones de Arquitectura

*   **Costos vs. Disponibilidad:** Actualmente se despliega **un único NAT Gateway** en la primera subred pública para minimizar costos mensuales. Para producción crítica, se recomienda modificar el código para tener un NAT Gateway por cada Zona de Disponibilidad.
*   **Seguridad de Capa Data:** Las subredes de datos (`subnet_data`) no poseen ruteo hacia el NAT Gateway ni al IGW por diseño, garantizando un aislamiento total de las bases de datos hacia el exterior.
*   **Cifrado KMS:** El Log Group de CloudWatch utiliza el cifrado por defecto de AWS. El soporte para llaves **KMS Customer Managed** se añadirá una vez que el módulo global de KMS esté disponible.
*   **Etiquetado:** Se utiliza un bloque de `locals` para asegurar que todos los recursos cumplan con los estándares de etiquetado de la organización.

### ⚠️ Restricción Crítica de Consistencia

Para asegurar el correcto despliegue de la infraestructura, las siguientes variables **deben tener exactamente el mismo largo**:

*   `subnet_public`
*   `subnet_private`
*   `subnet_data`
*   `availability_zones`

**Razón:** El módulo utiliza un índice compartido (`count.index`) para distribuir las subredes entre las zonas de disponibilidad declaradas. Si las listas no son consistentes, Terraform lanzará un error de `index out of range` durante el plan o el apply. Es responsabilidad del usuario (caller) garantizar que cada rango CIDR tenga su correspondiente zona asignada.
