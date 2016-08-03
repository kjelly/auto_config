package main

import (
	"crypto/md5"
	"fmt"
	"io"
	"io/ioutil"
	"os"
)

func main() {
	cpuinfo, err := ioutil.ReadFile("/etc/machine-id")
	if err != nil {
		fmt.Print("888")
		return
	}
	h := md5.New()
	io.WriteString(h, string(cpuinfo))
	sum := h.Sum(nil)
	if len(os.Args) > 1 {
		for i, val := range sum {
			sum[i] = 255 - val
		}
	}
	output := fmt.Sprintf("%x", sum[0:2])
	fmt.Print(output[0:3])
}
