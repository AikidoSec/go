// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import "C"

//export Add
func Add(a, b int32) int32 { return a + b }

func main() {}
