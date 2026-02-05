#!/bin/bash
# /modules/vpn/generate-client-cert.sh

set -e

# Параметры
CLIENT_NAME="${1:-client1}"
REGION="${2:-eu-west-3}"
AWS_PROFILE="${3:-ae-tst-prd-target}"

echo "Generating client certificate for: $CLIENT_NAME"
echo "Using AWS Profile: $AWS_PROFILE"

# Проверяем, что скрипт запущен из директории VPN
if [[ ! -f "terragrunt.hcl" ]]; then
  echo "❌ Error: This script must be run from the VPN environment directory (envs/prd/tst/vpn)"
  echo "Current directory: $(pwd)"
  exit 1
fi

# Создаем структуру папок
echo "Creating directory structure..."
mkdir -p ./clients/keys
mkdir -p ./clients/ovpn

# Получаем данные из Terraform outputs
echo "Getting VPN configuration from Terraform outputs..."
ROOT_CERT=$(AWS_PROFILE=$AWS_PROFILE terragrunt output -raw client_vpn_root_certificate)
VPN_ENDPOINT=$(AWS_PROFILE=$AWS_PROFILE terragrunt output -raw vpn_dns_endpoint)
VALIDITY_DAYS=$(AWS_PROFILE=$AWS_PROFILE terragrunt output -raw client_cert_validity_days 2>/dev/null || echo "365")

# Сохраняем корневой сертификат
echo "$ROOT_CERT" > ./clients/keys/ca.crt

# 1. Создаем private key для клиента
echo "Generating client private key..."
openssl genrsa -out "./clients/keys/${CLIENT_NAME}.key" 2048

# 2. Создаем Certificate Signing Request (CSR)
echo "Creating certificate signing request..."
openssl req -new \
  -key "./clients/keys/${CLIENT_NAME}.key" \
  -out "./clients/keys/${CLIENT_NAME}.csr" \
  -subj "/CN=${CLIENT_NAME}/O=EchoTwin/OU=VPN-Clients/C=AE"

# 3. Создаем конфигурацию для клиентского сертификата
cat > "./clients/keys/${CLIENT_NAME}.conf" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF

# 4. Получаем приватный ключ корневого CA из Terraform
echo "Getting CA private key from Terraform..."
CA_PRIVATE_KEY=$(AWS_PROFILE=ae-tst-prd-target terragrunt output -raw client_vpn_root_private_key)

# Сохраняем приватный ключ CA во временный файл
echo "$CA_PRIVATE_KEY" > "./clients/keys/ca.key"

# Устанавливаем правильные права доступа на приватный ключ CA
chmod 600 "./clients/keys/ca.key"

# 5. Подписываем сертификат корневым CA (ПРАВИЛЬНЫЙ подход)
echo "✅ Signing client certificate with root CA..."
openssl x509 -req \
  -in "./clients/keys/${CLIENT_NAME}.csr" \
  -CA "./clients/keys/ca.crt" \
  -CAkey "./clients/keys/ca.key" \
  -CAcreateserial \
  -out "./clients/keys/${CLIENT_NAME}.crt" \
  -days "$VALIDITY_DAYS" \
  -extensions v3_req \
  -extfile "./clients/keys/${CLIENT_NAME}.conf"

# Удаляем временный приватный ключ CA (безопасность)
rm "./clients/keys/ca.key"

# 6. Завершение
echo "✅ Client certificate generated and signed by CA successfully!"
echo ""
echo "📁 Files created:"
echo "  📋 Certificate files:"
echo "    - ./clients/keys/${CLIENT_NAME}.key (private key)"
echo "    - ./clients/keys/${CLIENT_NAME}.crt (client certificate - signed by CA)"
echo "    - ./clients/keys/ca.crt (root CA certificate)"
echo ""
echo "🔍 Certificate verification:"
# Проверим, что сертификат правильно подписан
openssl verify -CAfile "./clients/keys/ca.crt" "./clients/keys/${CLIENT_NAME}.crt" && echo "✅ Certificate validation: SUCCESS" || echo "❌ Certificate validation: FAILED"
echo ""
echo "� Next steps:"
echo "1. Скачайте Client configuration из AWS Console и сохраните как client.ovpn"
echo "2. Запустите: ./create-ovpn-config.sh ${CLIENT_NAME}"
echo "3. Импортируйте ./clients/ovpn/${CLIENT_NAME}.ovpn в OpenVPN клиент"
echo ""
echo "🔍 Важно:"
echo "  - Используйте ./create-ovpn-config.sh для создания полного .ovpn файла"
echo "  - Скрипт заменит Amazon CA на ваш custom CA"

# Cleanup временных файлов
rm "./clients/keys/${CLIENT_NAME}.csr" "./clients/keys/${CLIENT_NAME}.conf"

echo ""
echo "🧹 Cleanup completed"
