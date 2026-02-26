// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

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
