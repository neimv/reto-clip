package main

import (
	"database/sql"
	"fmt"
	"os"

	_ "github.com/go-sql-driver/mysql"
)

func GetDB() *sql.DB {
	sqlConnect := os.Getenv("SQLCONNECT")

	if sqlConnect == "" {
		sqlConnect = "root:example@/reto"
	}

	db, err := sql.Open("mysql", sqlConnect)
	if err != nil {
		fmt.Println("Database is not connect")
		panic(err.Error()) // Just for example purpose. You should use proper error handling instead of panic
	}

	// Open doesn't open a connection. Validate DSN data:
	err = db.Ping()
	if err != nil {
		fmt.Println("Ping failed")
		panic(err.Error()) // proper error handling instead of panic in your app
	}

	return db
}
