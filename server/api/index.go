package handler

import (
	"net/http"

	appserver "crm-server/pkg/server"
)

func Handler(w http.ResponseWriter, r *http.Request) {
	appserver.NewRouter().ServeHTTP(w, r)
}
