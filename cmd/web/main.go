package main

import (
	"log"
	"net/http"

	"github.com/mcgigglepop/cloud-nexus/pkg/config"
	"github.com/mcgigglepop/cloud-nexus/pkg/handlers"
	"github.com/mcgigglepop/cloud-nexus/pkg/render"
)

const portNumber = ":8080"

func main() {
	var app config.AppConfig
	tc, err := render.CreateTemplateCache()
	if err != nil {
		log.Fatal("cannot create template cache")
	}

	app.TemplateCache = tc

	render.NewTemplates(&app)

	http.HandleFunc("/", handlers.Home)
	http.HandleFunc("/about", handlers.About)

	_ = http.ListenAndServe(portNumber, nil)

}
