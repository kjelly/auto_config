package main

import (
	"crypto/md5"
	"fmt"
	"io"
	"os"
)

func main() {
	path := os.Args[1]
	h := md5.New()
	io.WriteString(h, path)
	sum := h.Sum(nil)
	if len(os.Args) > 2 {
		for i, val := range sum {
			sum[i] = val ^ 15
		}
	}
	output := fmt.Sprintf("%x", sum[0:2])
	fmt.Print(output[0:3])
}
