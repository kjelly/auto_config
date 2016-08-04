package main

import (
	"fmt"
	"os"
	"strings"
)

func main() {
	path := os.Args[1]
	parts := strings.Split(path, "/")
	if len(parts) < 4 {
		fmt.Printf(strings.Join(parts, "/"))
		return
	}
	parts[len(parts)-4] = fmt.Sprintf("[ %s ]", parts[len(parts)-4])
	if len(parts) < 6 {
		fmt.Printf(strings.Join(parts, "/"))
		return
	}
	parts[len(parts)-6] = fmt.Sprintf("[ %s ]", parts[len(parts)-6])
	fmt.Printf(strings.Join(parts, "/"))
}
