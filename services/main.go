package main

import (
	"net/http"
	"os"

	"github.com/labstack/echo/v4"
)

func main() {
	port := os.Getenv("PORT")

	if port == "" {
		port = "3030"
	}

	// only to check if database is conected
	db := GetDB()
	db.Close()

	e := echo.New()

	e.GET("/", func(c echo.Context) error {
		return c.String(http.StatusOK, "Hello, World!")
	})
	e.GET("/healthcheck", func(c echo.Context) error {
		return c.String(http.StatusOK, "pass")
	})
	e.GET("/api/pet/:name", GetPet)

	e.Logger.Fatal(e.Start(":" + port))
}
