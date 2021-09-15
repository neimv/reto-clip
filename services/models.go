package main

type Pet struct {
	Name    string `json:"name"`
	Owner   string `json:"owner"`
	Species string `json:"species"`
	Sex     string `json:"sex"`
}

type PetResponse struct {
	Name    string `json:"name"`
	Owner   string `json:"owner"`
	Species bool   `json:"species"`
}
