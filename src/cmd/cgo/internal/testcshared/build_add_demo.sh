#!/usr/bin/env bash
set -euo pipefail

# Builds a tiny Go c-shared library exporting Add(int32, int32) and a C loader
# that dlopen/dlsym loads Add and prints the result. Artifacts are persistent.
#
# Usage:
#   ./build_add_demo.sh [output-dir]
#
# Environment overrides:
#   GOROOT=/path/to/go-tree
#   CC=clang|gcc

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../../../../.." && pwd)"

GOROOT="${GOROOT:-$REPO_ROOT}"
GO="${GO:-$GOROOT/bin/go}"
CC_BIN="${CC:-cc}"

OUT_DIR="${1:-$SCRIPT_DIR/_demo_add}"
mkdir -p "$OUT_DIR"

GO_SRC="$OUT_DIR/libadd.go"
C_SRC="$OUT_DIR/main_add.c"
SO="$OUT_DIR/libadd.so"
LOADER="$OUT_DIR/loader"

cat >"$GO_SRC" <<'EOF'
package main
import "C"

//export Add
func Add(a, b int32) int32 { return a + b }

func main() {}
EOF

cat >"$C_SRC" <<'EOF'
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>

typedef int32_t (*add_fn_t)(int32_t, int32_t);

int main(int argc, char** argv) {
  if (argc < 2) {
    fprintf(stderr, "usage: %s <shared-lib>\n", argv[0]);
    return 2;
  }

  void* handle = dlopen(argv[1], RTLD_LAZY | RTLD_GLOBAL);
  if (!handle) {
    fprintf(stderr, "ERROR: failed to open the shared library: %s\n", dlerror());
    return 2;
  }

  add_fn_t add = (add_fn_t)dlsym(handle, "Add");
  if (!add) {
    fprintf(stderr, "ERROR: missing Add: %s\n", dlerror());
    return 1;
  }

  printf("%d\n", add(19, 23));
  return 0;
}
EOF

echo "+ building Go shared library: $SO"
GOROOT="$GOROOT" GO111MODULE=off "$GO" build -buildmode=c-shared -o "$SO" "$GO_SRC"

echo "+ building C loader: $LOADER"
"$CC_BIN" -o "$LOADER" "$C_SRC" -ldl

echo "+ running loader"
"$LOADER" "$SO"

if command -v readelf >/dev/null 2>&1; then
  echo "+ relocations (TLS/TLSDESC) in $SO"
  readelf -Wr "$SO" | grep -E 'TLSDESC|TLS' || true
else
  echo "readelf not found; skipping relocation dump"
fi

cat <<EOF

Artifacts:
  $SO
  $LOADER
  $GO_SRC
  $C_SRC
EOF
