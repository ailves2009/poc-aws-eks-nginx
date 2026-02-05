#!/usr/bin/env bash
set -euo pipefail

# copy-s3-crossregion.sh
# Server-side copy objects from SRC bucket (possibly in other region) to DST bucket.
# Features:
#  - pagination of source list
#  - parallel copy via xargs
#  - retries with linear backoff
#  - logs failed keys to a file
#  - resume failed keys mode

usage() {
  cat <<EOF
Usage: $0 --src-bucket SRC --dst-bucket DST [options]

Options:
  --src-region REGION      Source bucket region (default: eu-west-3)
  --dst-region REGION      Destination bucket region (default: eu-west-1)
  --profile PROFILE        AWS CLI profile to use (default: ae-dev-client)
  --prefix PREFIX          Only operate on objects with this prefix
  --concurrency N          Parallel copy concurrency (default: 5)
  --dry-run                Show what would be copied
  --retries N              Number of retries for copy (default: 3)
  --backoff SEC            Base backoff seconds between retries (default: 2)
  --failed-log FILE        File to append permanently failed keys (default: failed-keys.txt)
  --resume-failed          Read failed-log and retry only those keys
  --max-keys N             Page size for list-objects-v2 (default: 1000)
  -h, --help               Show this help
EOF
}

# defaults
SRC_BUCKET=""
DST_BUCKET=""
SRC_REGION="eu-west-3"
DST_REGION="eu-west-1"
PROFILE="ae-dev-client"
PREFIX=""
CONCURRENCY=5
DRY_RUN=false
RETRIES=3
BACKOFF=2
FAILED_LOG="failed-keys.txt"
RESUME_FAILED=false
MAX_KEYS=1000

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --src-bucket) SRC_BUCKET="$2"; shift 2;;
    --dst-bucket) DST_BUCKET="$2"; shift 2;;
    --src-region) SRC_REGION="$2"; shift 2;;
    --dst-region) DST_REGION="$2"; shift 2;;
    --profile) PROFILE="$2"; shift 2;;
    --prefix) PREFIX="$2"; shift 2;;
    --concurrency) CONCURRENCY="$2"; shift 2;;
    --dry-run) DRY_RUN=true; shift;;
    --retries) RETRIES="$2"; shift 2;;
    --backoff) BACKOFF="$2"; shift 2;;
    --failed-log) FAILED_LOG="$2"; shift 2;;
    --resume-failed) RESUME_FAILED=true; shift;;
    --max-keys) MAX_KEYS="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

if [[ -z "$SRC_BUCKET" || -z "$DST_BUCKET" ]]; then
  echo "Please provide --src-bucket and --dst-bucket" >&2
  usage
  exit 2
fi

echo "Source: $SRC_BUCKET ($SRC_REGION)"
echo "Dest:   $DST_BUCKET ($DST_REGION)"
echo "Prefix: '${PREFIX:-(all)}', profile: $PROFILE, concurrency: $CONCURRENCY, dry-run: $DRY_RUN"
echo "Retries: $RETRIES, backoff: $BACKOFF, failed-log: $FAILED_LOG"
echo

# helper: percent-encode key for CopySource
encode_key() {
  python3 - <<PY
import sys, urllib.parse
s=sys.stdin.read().rstrip('\n')
print(urllib.parse.quote(s, safe='/'))
PY
}

copy_one() {
  local KEY="$1"
  # Do NOT pre-URL-encode the key for --copy-source: the AWS CLI / botocore will handle encoding;
  # pre-encoding caused double-encoding (% -> %25) and NoSuchKey errors.
  local ENC
  ENC="$KEY"
  if [[ "$DRY_RUN" == true ]]; then
    echo "DRY: copy s3://$SRC_BUCKET/$KEY  -> s3://$DST_BUCKET/$KEY"
    return 0
  fi

  local attempt=0
  while (( attempt < RETRIES )); do
    attempt=$((attempt+1))
    # quick HEAD check to ensure source object exists and is accessible
    if ! aws --profile "$PROFILE" --region "$SRC_REGION" s3api head-object --bucket "$SRC_BUCKET" --key "$KEY" >/dev/null 2>&1; then
      echo "WARN: source object missing or inaccessible for $KEY (HEAD failed)"
      # no point retrying if source is missing; record and return
      echo "FAILED: $KEY (HEAD_FAILED)"
      printf '%s | HEAD_FAILED\n' "$KEY" >> "$FAILED_LOG"
      return 1
    fi
    # perform copy and capture any aws CLI stderr for diagnostics
    # show the copy-source we will use (helpful for debugging)
    echo "DEBUG: using copy-source: $SRC_BUCKET/$ENC"
    aws_out=$(aws --profile "$PROFILE" --region "$DST_REGION" s3api copy-object \
      --bucket "$DST_BUCKET" --key "$KEY" --copy-source "$SRC_BUCKET/$ENC" --acl bucket-owner-full-control 2>&1)
    rc=$?
    if [[ $rc -eq 0 ]]; then
      echo "OK: $KEY"
      return 0
    else
      echo "WARN: copy failed for $KEY (attempt $attempt/$RETRIES)"
      echo "DEBUG: aws error: $aws_out"
      if (( attempt < RETRIES )); then
        sleep_time=$(( BACKOFF * attempt ))
        echo "INFO: sleeping ${sleep_time}s before retry"
        sleep $sleep_time
      fi
    fi
  done

  echo "FAILED: $KEY"
  # append timestamped failure and last aws error for later inspection
  printf '%s | %s | %s\n' "$(date --iso-8601=seconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)" "$KEY" "$aws_out" >> "$FAILED_LOG"
  return 1
}

export -f copy_one encode_key
export SRC_BUCKET DST_BUCKET SRC_REGION DST_REGION PROFILE DRY_RUN RETRIES BACKOFF FAILED_LOG

# Resume failed mode: read the failed log and process only those keys
if [[ "$RESUME_FAILED" == true ]]; then
  echo "Resuming failed keys from $FAILED_LOG"
  if [[ ! -f "$FAILED_LOG" ]]; then
    echo "No failed log found at $FAILED_LOG" >&2
    exit 1
  fi
  KEYS=$(cat "$FAILED_LOG")
  if command -v xargs >/dev/null 2>&1; then
    printf '%s\n' "$KEYS" | xargs -n1 -P "$CONCURRENCY" -I{} bash -c 'copy_one "$@"' _ {}
  else
    while read -r k; do copy_one "$k"; done <<<"$KEYS"
  fi
  echo "Resume run completed. See $FAILED_LOG for persistent failures."
  exit 0
fi

# Normal mode: paginate through source bucket
CONT_TOKEN=""
while :; do
  if [[ -z "$CONT_TOKEN" ]]; then
    RESP=$(aws --profile "$PROFILE" --region "$SRC_REGION" s3api list-objects-v2 --bucket "$SRC_BUCKET" ${PREFIX:+--prefix "$PREFIX"} --max-keys $MAX_KEYS --output json)
  else
    # Use the API ContinuationToken parameter (aws CLI flag --continuation-token) rather than
    # the paginator control --starting-token which can conflict with CLI pagination settings.
    RESP=$(aws --profile "$PROFILE" --region "$SRC_REGION" s3api list-objects-v2 --bucket "$SRC_BUCKET" ${PREFIX:+--prefix "$PREFIX"} --max-keys $MAX_KEYS --continuation-token "$CONT_TOKEN" --output json)
  fi

  KEYS=$(printf '%s' "$RESP" | jq -r '.Contents[]?.Key' || true)
  if [[ -z "$KEYS" ]]; then
    echo "No more keys in this page."
  else
    if command -v xargs >/dev/null 2>&1; then
      printf '%s\n' "$KEYS" | xargs -n1 -P "$CONCURRENCY" -I{} bash -c 'copy_one "$@"' _ {}
    else
      while read -r k; do copy_one "$k"; done <<<"$KEYS"
    fi
  fi

  IS_TRUNC=$(printf '%s' "$RESP" | jq -r '.IsTruncated')
  if [[ "$IS_TRUNC" == "true" ]]; then
    CONT_TOKEN=$(printf '%s' "$RESP" | jq -r '.NextContinuationToken // empty')
    if [[ -z "$CONT_TOKEN" ]]; then
      echo "Response truncated but no next token found — stopping." >&2
      break
    fi
  else
    break
  fi
done

echo "Done." 