// TODO: Separate routes out into other fuctions and so on.
package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"github.com/gorilla/handlers"
	"github.com/julienschmidt/httprouter"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	_ "time"

	_ "github.com/lib/pq"
)

var (
	db     *sql.DB
	config = struct {
		StaticRoot  string `json:"staticRoot"`
		Cert        string `json:"cert"`
		Key         string `json:"key"`
		DbUserName  string `json:"dbUserName`
		DbPass      string `json:"dbPass"`
		UploadsRoot string `json:"uploadsRoot"`
	}{}
)

func init() {
	var err error
	die := func(err error) {
		if err != nil {
			panic(err)
		}
	}
	// Load configuration from json.
	data, err := ioutil.ReadFile("config.json")
	die(err)
	err = json.Unmarshal(data, &config)
	fmt.Println(config)
	die(err)
	connString := fmt.Sprint("user=", config.DbUserName, " password=", config.DbPass, " dbname=privy")
	db, err = sql.Open("postgres", connString)
	die(err)
	die(db.Ping())
}

type User struct {
	Handle   string
	Email    string
	Bio      string
	ImageURL string
}

func main() {
	// Set up the routes
	router := httprouter.New()
	fmt.Println(config)
	fmt.Println("Starting server")
	router.ServeFiles("/static/*filepath", http.Dir(config.StaticRoot))
	router.GET("/verify/:verifyToken", verifyUser)

	router.POST("/users/new", newUser)
	router.POST("/users/login", authUser)
	//router.GET("/users/auth", checkAuth)     // TODO: Build method here.
	router.GET("/users/info", lookupAndSubUUIDS)
	router.GET("/users/refresh", refreshUUIDList)
	router.DELETE("/users/subscription", deleteUUIDs)
	router.POST("/users/registerapnsclient", registerPushNotificationClient)
	router.POST("/users/info", saveUserJSON)
	router.POST("/users/resetpassword", sendResetEmail)
	router.POST("/users/image", saveUserImage)
	router.GET("/users/image", getImageForUUID)
	router.GET("/resetpassword/:changetoken", showResetPage)
	router.POST("/resetpassword/:changetoken", processPasswordReset)
	router.POST("/users/logout", invalidateSession)

	server := handlers.CombinedLoggingHandler(os.Stdout, router)

	//log.Fatal(http.ListenAndServeTLS(":8080", config.Cert, config.Key, server))
	log.Fatal(http.ListenAndServe(":8080", server))
}

func index(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	fmt.Fprint(w, `Privy is KLOAST`)
}
