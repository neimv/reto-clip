package main

import (
	"net/http"

	"github.com/labstack/echo/v4"
)

func GetPet(c echo.Context) error {
	var pet Pet
	var petR PetResponse
	petName := c.Param("name")
	selectData := "SELECT name, owner, species FROM pet WHERE name = ?"

	db := GetDB()
	defer db.Close()

	stmtOut, err := db.Prepare(selectData)
	if err != nil {
		panic(err.Error())
	}

	err = stmtOut.QueryRow(petName).Scan(&pet.Name, &pet.Owner, &pet.Species)
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "pet not found")
	}

	petR.Name = pet.Name
	petR.Owner = pet.Owner
	petR.Species = true

	if pet.Species != "" {
		petR.Species = false
	}

	return c.JSON(http.StatusOK, petR)
}
