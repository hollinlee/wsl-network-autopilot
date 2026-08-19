#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BIN=$ROOT/bin/wsl-network
TMP=${TMPDIR:-/tmp}/wsl-network-test.$$
trap 'rm -rf "$TMP"' EXIT INT TERM
mkdir -p "$TMP"

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_contains() {
    printf '%s' "$1" | grep -F "$2" >/dev/null || fail "missing: $2"
}

cat > "$TMP/auto.conf" <<'EOF'
PROXY_MODE=auto
PROXY_PORT=7897
NO_PROXY_LIST='localhost,1.1.1.3'
AUTH_PROVIDER=none
EOF

output=$(WSL_NETWORK_CONFIG="$TMP/auto.conf" WSL_WINDOWS_HOST=172.20.0.1 \
    WSL_PROXY_PROBE=success "$BIN" env)
assert_contains "$output" "HTTP_PROXY='http://172.20.0.1:7897'"
assert_contains "$output" "NO_PROXY='localhost,1.1.1.3'"

cat > "$TMP/quote.conf" <<'EOF'
PROXY_MODE=off
NO_PROXY_LIST="local'host"
EOF
output=$(WSL_NETWORK_CONFIG="$TMP/quote.conf" "$BIN" env)
# Evaluate in an isolated shell to prove generated output remains valid shell syntax.
evaluated=$(sh -c "$output; printf '%s' \"\$NO_PROXY\"")
[ "$evaluated" = "local'host" ] || fail 'shell output did not preserve a single quote'

output=$(WSL_NETWORK_CONFIG="$TMP/auto.conf" WSL_WINDOWS_HOST=172.20.0.1 \
    WSL_PROXY_PROBE=failure "$BIN" env)
assert_contains "$output" 'unset HTTP_PROXY HTTPS_PROXY ALL_PROXY'
if printf '%s' "$output" | grep -F 'export HTTP_PROXY=' >/dev/null; then
    fail 'auto mode exported an unreachable proxy'
fi

cat > "$TMP/off.conf" <<'EOF'
PROXY_MODE=off
AUTH_PROVIDER=none
EOF
output=$(WSL_NETWORK_CONFIG="$TMP/off.conf" "$BIN" env)
if printf '%s' "$output" | grep -F 'export HTTP_PROXY=' >/dev/null; then
    fail 'off mode exported a proxy'
fi

cat > "$TMP/command.conf" <<EOF
CONNECTIVITY_URL='http://127.0.0.1:1/unreachable'
AUTH_PROVIDER=command
AUTH_COMMAND='printf auth-ran'
EOF
output=$(WSL_NETWORK_CONFIG="$TMP/command.conf" "$BIN" check)
[ "$output" = auth-ran ] || fail 'custom auth provider did not run'

printf '%s\n' 'All tests passed.'
