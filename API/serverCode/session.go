package main

import (
	"crypto/rand"
	"database/sql"
	"fmt"

	_ "github.com/lib/pq"
)

func GenerateRandomString() (token string, err error) {
	var b [16]byte
	num, err := rand.Read(b[:])
	if num != 16 || err != nil {
		return "", err
	}
	uuid := fmt.Sprintf("%x%x%x%x%x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:])
	return uuid, err
}

// This function does its darndest to generate a session key if one doesn't exist
// and then return that session.
func GetSessionKey(userID int) (string, error) {
	var key string
	var isStillValid bool
	// If the key is still valid
	err := db.QueryRow(`
	Select cookieInfo, (valid_til > TIMESTAMPTZ 'NOW') 
	from sessions where userID = $1;`, userID).Scan(&key, &isStillValid)
	if isStillValid {
		return key, nil
	}
	// If the user doesn't have any Sessions yet.
	if err == sql.ErrNoRows {
		key, _ = GenerateRandomString()
		_, err = db.Exec(`
		Insert into sessions (userID, cookieInfo, valid_til)
		VALUES ($1, $2, DATE 'NOW' + INTERVAL '1 WEEK');
		`, userID, key)
		if err != nil {
			fmt.Println(err)
			return "", err
		}
	}
	if err != nil {
		fmt.Println(err)
		return "", err
	}

	// Update an out of date session
	key, _ = GenerateRandomString()
	_, err = db.Exec(`
	Update sessions 
	set 
		cookieInfo = $1,
		valid_til = TIMESTAMPTZ 'NOW' + INTERVAL '1 WEEK'
	where userID = $2`, key, userID)
	if err != nil {
		fmt.Println(err)
		return "", err
	}
	return key, nil
}

// Return userID, if the session is still valid, and any errors we found.
func CheckSessionsKey(key string) (int, bool, error) {
	var isStillValid bool
	var userID int
	err := db.QueryRow(`
	Select userID, cookieInfo, (valid_til > TIMESTAMPTZ 'NOW') 
	from sessions where cookieInfo = $1`, key).Scan(&userID, &key, &isStillValid)
	if err != nil {
		return -1, false, err
	}
	return userID, isStillValid, nil
	// If the user doesn't have any Sessions yet.
}
