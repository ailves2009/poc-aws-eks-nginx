# AWS Client VPN Setup
## создаёт в AWS ресурс Client VPN Endpoint (aws_ec2_client_vpn_endpoint.this). Кратко — он:

Прописывает параметры VPN‑эндоинта: описание, ARN серверного сертификата (ACM), параметры аутентификации (здесь — сертификатная аутентификация с указанием ARN CA), CIDR для клиентов, split‑tunnel, связанный VPC, DNS‑серверы, протокол (UDP), опции логирования и теги.
Делает доступным идентификатор энпоинта (this.id), который затем используется в следующих ресурсах в этом модуле:
aws_ec2_client_vpn_network_association — ассоциирует эндоинт с указанными подсетями;
aws_ec2_client_vpn_authorization_rule — добавляет правило авторизации для доступа к целевой сети (authorized_cidr).
В комментариях показан альтернативный вариант динамической конфигурации authentication_options (закомментирован).

## Итог: этот блок создаёт и настраивает клиентский VPN‑эндоинт в AWS и обеспечивает данные для дальнейшей привязки и правил доступа.


## Архитектура

```
[Client] → [AWS Client VPN] → [VPC Private Subnets] → [RDS]
```

## Компоненты

1. **AWS Private Certificate Authority (PCA)** - для выпуска сертификатов
2. **Server Certificate** - для VPN endpoint (в ACM)
3. **Client Certificates** - для аутентификации пользователей

## Развертывание

### 1. Создание инфраструктуры

```bash
cd /path/to/envs/prd/tst/vpn
AWS_PROFILE=ae-prod-tst-init terragrunt plan
AWS_PROFILE=ae-prod-tst-init terragrunt apply
```

### 2. Генерация клиентских сертификатов

```bash
cd /path/to/modules/vpn
./generate-client-cert.sh client1 eu-west-3 ae-prod-tst-init
```

### 3. Настройка клиента

1. **Скачать конфигурацию VPN** из AWS Console:
   - AWS Console → VPC → Client VPN Endpoints 
   - Select your endpoint → Download Client Configuration

2. **Добавить сертификаты в .ovpn файл**:
   ```
   <cert>
   -----BEGIN CERTIFICATE-----
   [содержимое client1.crt]
   -----END CERTIFICATE-----
   </cert>

   <key>
   -----BEGIN PRIVATE KEY-----
   [содержимое client1.key]
   -----END PRIVATE KEY-----
   </key>

   <ca>
   -----BEGIN CERTIFICATE-----
   [содержимое ca.crt]
   -----END CERTIFICATE-----
   </ca>
   ```

3. **Импорт в OpenVPN клиент**

## Подключение к RDS

После подключения к VPN:

```bash
# RDS будет доступен через приватный IP
psql -h tst-etl-db.cvmqeiie65gy.eu-west-3.rds.amazonaws.com \
     -U username \
     -d echotwin \
     -p 5432
```

## Безопасность

- **Client CIDR**: `10.9.0.0/16` (отличается от VPC CIDR `10.0.0.0/16`)
- **Authorized CIDR**: `10.0.0.0/16` (доступ ко всей VPC)
- **DNS**: AWS DNS (`10.0.0.2`) для разрешения имен RDS
- **Split Tunnel**: включен (только VPC трафик через VPN)

## Управление сертификатами

### Отзыв сертификата клиента
```bash
aws acm-pca revoke-certificate \
  --certificate-authority-arn arn:aws:acm-pca:... \
  --certificate-serial-number <serial> \
  --revocation-reason KEY_COMPROMISE
```

### Список выпущенных сертификатов
```bash
aws acm-pca list-certificates \
  --certificate-authority-arn arn:aws:acm-pca:...
```

## Мониторинг

- **CloudWatch Logs**: подключения и аутентификация
- **VPC Flow Logs**: сетевой трафик через VPN
- **CloudTrail**: API calls для управления сертификатами

## Стоимость

- **AWS Private CA**: ~$400/месяц за активную CA
- **Client VPN Endpoint**: ~$0.05/час + $0.03 за подключение/час
- **Server Certificate**: бесплатно (ACM)
