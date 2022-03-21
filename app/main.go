package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/", func(rw http.ResponseWriter, r *http.Request) {
		log.Println("Handle request")

		fmt.Fprintf(rw, "Hello World")
	})

	log.Println("Starting server, listening on port 3000")
	http.ListenAndServe("0.0.0.0:3000", nil)
}
