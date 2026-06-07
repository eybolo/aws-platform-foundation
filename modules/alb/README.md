# AWS Application Load Balancer (ALB) Module

Este módulo de Terraform despliega un **Application Load Balancer (ALB)** de cara al público (público/externo) diseñado para recibir tráfico seguro y distribuirlo de forma eficiente hacia las capas de aplicación internas. Implementa políticas de seguridad SSL de última generación y centraliza el ruteo hacia grupos de destino dinámicos como Auto Scaling Groups (ASG).

---

## Qué hace este módulo

El módulo automatiza el aprovisionamiento de la infraestructura de balanceo perimetral, la cual incluye:

* **Terminación SSL/TLS de Vanguardia:** Configura un Listener HTTPS seguro en el puerto `443` forzando el uso de políticas criptográficas modernas y seguras (incluyendo mitigación post-cuántica), abstrayendo el descifrado del tráfico antes de llegar al backend.
* **Perímetro de Red Controlado (Stateful):** Crea un Security Group dedicado que expone de forma pública únicamente el puerto `443` (`0.0.0.0/0`) y restringe de forma estricta la salida (egress) en el puerto `80` únicamente hacia los bloques CIDR privados autorizados.
* **Abstracción del Ruteo a Backend:** Configura un Target Group optimizado para balancear tráfico a nivel de instancias (`target_type = "instance"`), exponiendo los datos necesarios para que el módulo de cómputo (ASG) registre sus instancias EC2 automáticamente.
* **Trazabilidad y Auditoría:** Integra de forma nativa la recolección de `access_logs` del balanceador hacia un bucket de S3 centralizado para auditorías de tráfico, troubleshooting y análisis de patrones de acceso.

---

## Recursos utilizados

| Elemento | Tipo | Descripción |
| :--- | :--- | :--- |
| `aws_security_group.this` | Recurso | Define las reglas de firewall perimetral (Ingress `443` e Inbound restringido a la red interna en el puerto `80`). |
| `aws_lb.this` | Recurso | El plano de datos del Application Load Balancer configurado como externo y enlazado a las subredes públicas. |
| `aws_lb_target_group.this` | Recurso | El grupo lógico que define cómo procesar y controlar la salud de las instancias destino en el backend. |
| `aws_lb_listener.this` | Recurso | El listener que escucha activamente tráfico HTTPS, asocia el certificado y delega el flujo al Target Group. |

---

## Variables requeridas / opcionales

| Variable | Tipo | Descripción |
| :--- | :--- | :--- |
| `vpc_id` | `string` | ID de la VPC donde se desplegarán el Security Group y el Target Group. |
| `subnets_ids_public` | `list(string)` | Lista de IDs de subredes públicas donde se va a alojar el Load Balancer para dar cara a internet. |
| `subnets_cidrs_private` | `list(string)` | Lista de bloques CIDR de la capa privada (app) autorizados a recibir el tráfico de salida del ALB. |
| `certificate_arn` | `string` | ARN del certificado SSL/TLS (ACM) requerido para securizar el listener HTTPS. |
| `access_logs_s3` | `string` | Nombre del bucket de S3 donde se almacenarán de forma cruda los access logs del balanceador. |
| `environment` | `string` | Nombre del entorno actual (ej: `dev`, `staging`, `prod`) utilizado para el cálculo de nombres dinámicos. |

---

## Ejemplo de Uso (`environments/dev`)

A continuación se muestra cómo invocar este módulo de ALB, inyectando las dependencias de red de la VPC y conectándolo con tu estrategia de certificados:

```hcl
module "alb" {
  source = "../../modules/alb"
  
  # Configuracion General
  environment           = var.environment

  # Configuración de Red
  vpc_id                = module.vpc.vpc_id
  subnets_ids_public    = module.vpc.subnet_public_id
  subnets_cidrs_private = module.vpc.subnet_private_cidr

  # Seguridad y Certificados
  certificate_arn       = var.certificate_arn
  access_logs_s3        = var.access_logs_s3
}
```
---

## Outputs Exportados (Integración con ASG)

El módulo expone salidas clave para acoplar la capa de escalado automático (Auto Scaling Group) sin generar acoplamiento duro en el código:

* **`target_group_arn`**: El identificador único que requiere el recurso `aws_autoscaling_group` dentro de su argumento `target_group_arns` para auto-registrar las instancias EC2 a medida que escalan.
* **`security_group_id`**: El ID del grupo de seguridad del balanceador. Esencial para que el Security Group de las instancias del ASG pueda crear una regla de entrada (Ingress) cruzada que solo acepte tráfico si proviene de este ALB.

---

## Decisiones de Arquitectura y Diseño

* **Endurecimiento Cifrado (Post-Quantum TLS):** Se fuerza de forma explícita la política de seguridad `ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09`. Esto mitiga los riesgos de degradación de protocolos obsoletos (bloqueando TLS 1.0 y 1.1) e introduce soporte de vanguardia para algoritmos híbridos post-cuánticos.
* **Naming Standard Autocalculado:** Mediante el uso de bloques `locals`, el módulo auto-genera los nombres de todos los recursos bajo el prefijo común `${Project}-${Environment}`, manteniendo la homogeneidad en la consola de AWS y previniendo colisiones de nombres.
* **Egress Restringido (Least Privilege):** El firewall de salida del balanceador no queda abierto a internet (`0.0.0.0/0`). Está restringido por diseño para hablar exclusivamente con el puerto `80` de los rangos CIDR de las subredes de aplicación privadas, disminuyendo el radio de la superficie de ataque.
* **Etiquetado Consistente:** Todos los recursos creados (Load Balancer, Listener, Target Group y Security Group) heredan automáticamente el mapa de etiquetas gubernamentales administrado por el equipo de plataforma (`Project`, `Environment`, `ManagedBy`, `Owner`).