# hugo-tools/lib/utils.sh

fatal() {
  echo "❌ [ERROR] $1" >&2
  exit 1
}
