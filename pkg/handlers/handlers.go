package handlers

import (
	"net/http"

	"github.com/mcgigglepop/cloud-nexus/pkg/render"
)

// home
func Home(w http.ResponseWriter, r *http.Request) {
	render.RenderTemplate(w, "home.page.tmpl")
}

// about
func About(w http.ResponseWriter, r *http.Request) {
	render.RenderTemplate(w, "about.page.tmpl")
}
