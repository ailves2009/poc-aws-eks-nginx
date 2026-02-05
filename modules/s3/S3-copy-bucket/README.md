# Копирование объектов между S3 бакетами (server-side copy)

Этот документ описывает процесс массового серверного копирования объектов из одного S3 бакета в другой (в том числе между регионами и аккаунтами), инструменты, команды и распространённые ошибки.

Файлы:
- `modules/s3/S3-copy-bucket/copy-s3-crossregion.sh` — основной помощник (Bash). Скрипт выполняет постраничный обход исходного бакета, параллельные `copy-object` вызовы на стороне AWS (данные не проходят через локальную машину), логирует ошибки и поддерживает режим возобновления для неудачных ключей.
- `modules/s3/variables.tf`, `modules/s3/replication.tf` — Terraform-модуль предметной области (настройки репликации, переменные). README описывает только рабочие способы миграции существующих объектов (скрипт) и кратко упоминает CRR/Terraform.

Кратко о подходе
- Для уже существующих объектов CRR (Cross-Region Replication) не ретроактивен — полезно включить CRR для будущих объектов, но исторические объекты необходимо перенести вручную.
- Скрипт делает server-side copy (S3 CopyObject) от имени AWS клиента: объект копируется напрямую из исходного бакета в целевой без передачи локально.

Требования и предварительные условия
- Установлен aws-cli v2 и `jq`.
- Наличие профиля AWS CLI с правами на чтение исходного бакета и запись в целевой (пример профиля: `ae-dev-client`).
- На целевом бакете разрешено `PutObject` (и `PutObjectAcl` / `bucket-owner-full-control` если требуется смена владельца).
- Если объекты зашифрованы с SSE-KMS — нужно настроить KMS key policy, чтобы роль/пользователь мог провести Copy (Decrypt/GenerateDataKey и т.д.).

Кому нужны какие права (минимум)
- профиль/учётная запись, которая запускает скрипт (читает исход):
  - `s3:ListBucket` (на префикс/бакет)
  - `s3:GetObject` (на исходные ключи)
- профиль/учётная запись, которая выполняет copy в целевой (чаще та же):
  - `s3:PutObject` и `s3:PutObjectAcl` на целевой бакет
  - при использовании `--expected-source-bucket-owner` возможно дополнительно

Где находится скрипт
`modules/s3/S3-copy-bucket/copy-s3-crossregion.sh`

Основные режимы запуска (примеры)

1) Dry-run (покажет, что будет копироваться, ничего не меняет):
```bash
./modules/s3/S3-copy-bucket/copy-s3-crossregion.sh \
  --src-bucket echotwin-dmt-dev-detections \
  --dst-bucket tst-plt-detections \
  --src-region eu-west-3 --dst-region eu-west-1 \
  --profile ae-dev-client --prefix 'best/' --concurrency 5 --dry-run
```

2) Полный прогон (умеренная параллельность, увеличенное число попыток):
```bash
FAILED_LOG="failed-keys.$(date +%Y%m%dT%H%M%S).txt"

./modules/s3/S3-copy-bucket/copy-s3-crossregion.sh \
  --src-bucket echotwin-dmt-dev-detections \
  --dst-bucket tst-plt-detections \
  --src-region eu-west-3 --dst-region eu-west-1 \
  --profile ae-dev-client --prefix 'best/' \
  --concurrency 5 --retries 5 --backoff 5 \
  --failed-log "$FAILED_LOG"
```

3) Повтор только по неудачным ключам (resume):
```bash
./modules/s3/S3-copy-bucket/copy-s3-crossregion.sh --resume-failed --failed-log "$FAILED_LOG" \
  --src-bucket echotwin-dmt-dev-detections --dst-bucket tst-plt-detections \
  --src-region eu-west-3 --dst-region eu-west-1 --profile ae-dev-client --concurrency 4
```

Параметры скрипта (кратко)
- `--src-bucket` — исходный бакет
- `--dst-bucket` — целевой бакет
- `--src-region`, `--dst-region` — регионы (указывать, если разные)
- `--profile` — aws-cli профиль
- `--prefix` — ограничить копирование указанным префиксом
- `--concurrency` — параллельность копий (по умолчанию 5)
- `--dry-run` — показать операции, не выполнять их
- `--retries` — число попыток для каждого объекта (по умолчанию 3)
- `--backoff` — базовый backoff в секундах (линейный умножается на номер попытки)
- `--failed-log` — файл, в который добавляются устойчиво упавшие ключи (по умолчанию `failed-keys.txt`)
- `--resume-failed` — прочитать `failed-log` и попытаться снова только те ключи
- `--max-keys` — размер страницы для `list-objects-v2` (по умолчанию 1000)

Формат `failed-log`
- По умолчанию старые записи могут просто содержать ключи (plain keys). Новые записи записываются в формате:
  `TIMESTAMP | KEY | AWS_ERROR_MESSAGE`
- Пример:
  `2025-10-21T22:52:01+0000 | best/date=20250703/.../best_data.parquet | botocore.errorfactory.NoSuchKey: ...`

Типовые проблемы и их решения

- NoSuchKey / Invalid copy source object key
  - Причина: двойное URL-кодирование ключа (например, вы вручную заменяли `=` → `%3D` и SDK кодировал повторно). Решение: передавайте в `--copy-source` исходный (raw) ключ — AWS CLI / botocore сам корректно закодирует его один раз. Скрипт уже настроен так.

- HEAD_FAILED / 404 на HEAD
  - Причина: объект реально отсутствует (возможно удалён позже, либо race condition при листинге). Решение: проверить листинг `list-objects-v2` и игнорировать такие ключи.

- AccessDenied
  - Причина: недостаточные права на `GetObject` в исходном бакете или `PutObject` в целевом. Решение: поправить IAM/bucket policy или выполнить копию с другой роли/профиля. Для cross-account часто используют роль репликации или временные credentials с правильными policy.

- KMS / SSE-KMS ошибки
  - Причина: объект зашифрован KMS (SSE-KMS). При CopyObject вызывающий роль должен иметь права на использование KMS-ключа (Decrypt/GenerateDataKey). Решение: отредактировать KMS key policy, добавить целевую роль/профиль.

- Пагинация — "Cannot specify --no-paginate along with pagination arguments"
  - Причина: конфликт параметров пагинации AWS CLI. Скрипт использует `--continuation-token` теперь, это устраняет ошибку. Если вы видите предупреждение — обновите aws-cli либо используйте исправлённую версию скрипта.

Отладка конкретного ключа (шаги)
1) Возьмите ключ из `failed-keys.txt` или из `list-objects-v2`.
2) Выполните HEAD:
```bash
aws --profile ae-dev-client --region eu-west-3 s3api head-object --bucket echotwin-dmt-dev-detections --key "<KEY>" || true
```
3) Если HEAD успешен, попробуйте один `copy-object` и сохраните вывод:
```bash
ENC=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1], safe='/'))" "<KEY>")
aws --profile ae-dev-client --region eu-west-1 s3api copy-object \
  --bucket tst-plt-detections --key "<KEY>" --copy-source "echotwin-dmt-dev-detections/${KEY}" --acl bucket-owner-full-control 2>&1 | tee copy-debug.txt
```
Примечание: в большинстве случаев лучше передавать raw `KEY` в `--copy-source` (см. раздел выше).

Очистка / фильтрация `failed-keys.txt`
Если вы хотите удалить из лога ключи, которые уже присутствуют в destination, выполните:
```bash
awk '{print}' failed-keys.txt | while read -r k; do
  if aws --profile ae-dev-client --region eu-west-1 s3api head-object --bucket tst-stg-detections --key "$k" >/dev/null 2>&1; then
    echo "Skipping (exists): $k"
  else
    echo "$k"
  fi
done > failed-keys.filtered.txt

mv failed-keys.filtered.txt failed-keys.txt
```

Идемпотентность (рекомендация)
- Можно улучшить скрипт чтобы перед `copy-object` делать `head-object` в destination и сравнивать `ETag`/`ContentLength`. Если совпадает — пропускать запись. Это экономит запросы и время. (Реализация не включена по умолчанию, но её легко добавить.)

Рекомендации по параметрам
- `--concurrency`: уменьшайте при частых transient errors (rate limits). Начните с 4–5, увеличьте до 10 только при стабильности.
- `--retries` и `--backoff`: при рантаймах сети/инфраструктуры увеличьте (например `--retries 5 --backoff 5`). Скрипт использует линейный backoff.

CRR / Terraform (быстро)
- Для новых объектов используйте Cross-Region Replication (CRR) с IAM ролью репликации (source bucket replication configuration) и политикой на destination bucket, позволяющей S3 service `PutObject` от имени source role.
- В `modules/s3` Terraform-модуле есть переменные `replication_enabled`, `source_replication_role_arn`, `allow_source_put`, `source_put_principal`. Управляйте этим через Terragrunt/Terraform чтобы настроить постоянную CRR.

Полезные команды
- Список ключей по префиксу:
```bash
aws --profile ae-dev-client --region eu-west-3 s3api list-objects-v2 --bucket echotwin-dmt-dev-detections --prefix 'best/date=20250703/' --output json | jq -r '.Contents[]?.Key'
```
- Проверить конкретный объект в destination:
```bash
aws --profile ae-dev-client --region eu-west-1 s3api head-object --bucket tst-stg-detections --key '<KEY>' || true
```

Заключение
- Скрипт `modules/s3/S3-copy-bucket/copy-s3-crossregion.sh` позволяет быстро и надёжно перенести существующие объекты между бакетами/регионами. Перед запуском большого переноса — сделайте dry-run и тест на небольшом префиксе. Если хотите, я могу: добавить idempotency (HEAD в destination и сравнение ETag), убрать постоянный debug-вывод (только по флагу `--debug`) или помочь сформировать IAM/KMS политики для полного absence ошибок.

Если нужен пример политики или помощь с Terraform/Terragrunt — напишите, что у вас есть (профили/ARN/какие аккаунты участвуют) и я подготовлю конкретные policy JSON или TF-шаблон.

---
README сгенерирован автоматически в рамках инфраструктурного репозитория. Если нужно расширить раздел "решение ошибок" или добавить примеры для S3 Batch Operations — добавлю по запросу.
