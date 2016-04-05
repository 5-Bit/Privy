package main

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"fmt"
	"github.com/julienschmidt/httprouter"
	"golang.org/x/crypto/bcrypt"
	"net/http"
	// "strconv"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"

	// FIXME: This import path will currently only work on this server.
	pushNotifications "yumaikas/eaglelist/eagleslist-server/apnsdaemon"
	"yumaikas/eaglelist/eagleslist-server/templates"
	email "yumaikas/eaglelist/eagleslist-server/validation"

	_ "github.com/lib/pq"
)

// Unmarshal JSON
func decodeJSON(w http.ResponseWriter, r *http.Request, o interface{}) error {
	buf := new(bytes.Buffer)
	buf.ReadFrom(r.Body)
	err := json.Unmarshal(buf.Bytes(), o)
	if err != nil {
		fmt.Println(string(buf.Bytes()))
		fmt.Println(err)
		return err
	}
	return nil
}

func writeError(w http.ResponseWriter, Status int, message string) {
	w.Header().Set("Privy-api-error", message)
	w.WriteHeader(Status)
}

func newUser(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	if err := r.ParseForm(); err != nil {
		writeError(w, 400, "Oops! Something went wrong, please try again later.")
		return
	}
	passData, err := bcrypt.GenerateFromPassword([]byte(r.FormValue("password")), 13)
	if err != nil {
		writeError(w, 500, "Server error. That's all we know")
		return
	}
	Email := r.FormValue("email")

	var userID int
	err = db.QueryRow(`
	Insert into privy_user (email, password_hash) VALUES($1, $2) RETURNING ID
	`, Email, passData).Scan(&userID)
	if err != nil {
		fmt.Println(err)
		// TODO: Separate Unique
		writeError(w, 400, "Unable to create user")
		return
	}
	// Create UUIDs for user
	var resp = make(map[string]string)
	resp["email"] = Email
	rows, err := db.Query(` 
	Insert into privy_uuids (user_id, info_type) values 
	($1, 'basic'),
	($1, 'social'),
	($1, 'business'),
	($1, 'developer'),
	($1, 'media'),
	($1, 'blogging')
	RETURNING info_type, id;
	`, userID)
	if err != nil {
		writeError(w, 500, err.Error())
		return
	}

	defer rows.Close()
	for rows.Next() {
		var infoType string
		var uuid string
		err = rows.Scan(&infoType, &uuid)
		if err != nil {
			writeError(w, 500, err.Error()) //FIXME: DON'T DO THIS!!
			return
		}
		resp[infoType] = uuid
	}

	// Prepare for the email validation.
	validation, err1 := GenerateRandomString()
	_, err = db.Exec(`
	Insert into emailvalidation (userid, validationtoken, isvalidated) VALUES ($1, $2, false);
	`, userID, validation)
	if err != nil {
		fmt.Println(err)
		writeError(w, 500, "Unable to save email validation")
		return
	}

	// Populate the confirmation email.
	emailBody, err := templates.GetConfirmationEmail(Email, Email, validation)
	if err != nil {
		fmt.Println(err)
		writeError(w, 500, "Server email error")
		return
	}
	// Queue up the message send to be processed.
	email.SendMessage("Privy Account confirmation", emailBody, Email)

	sessionKey, err1 := GetSessionKey(userID)
	if err1 != nil {
		sessionKey = "INVALID"
	}

	resp["sessionid"] = sessionKey
	data, err := json.Marshal(resp)
	if err != nil {
		writeError(w, 500, "Server error!")
		return
	}
	w.Write(data)
}

// Authenticate User
func authUser(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	if err := r.ParseForm(); err != nil {
		writeError(w, 400, "Bad form encoding")
		return
	}
	auth := &struct {
		UserHandle string
		Password   string
	}{
		r.FormValue("email"),
		r.FormValue("password"),
	}
	var passBuf []byte
	var id int
	err := db.QueryRow(`Select password_hash, id from privy_user where email = $1`, auth.UserHandle).Scan(&passBuf, &id)
	if err == sql.ErrNoRows {
		err = bcrypt.CompareHashAndPassword(passBuf, []byte(auth.Password))
		writeError(w, 400, "User name or password not found")
		return
	}
	if err != nil {
		fmt.Println(err)
		writeError(w, 500, "Server error!")
		return
	}
	err = bcrypt.CompareHashAndPassword(passBuf, []byte(auth.Password))
	if err != nil {
		writeError(w, 400, "User name or password not found")
		return
	}

	var resp = make(map[string]string)
	resp["email"] = auth.UserHandle
	rows, err := db.Query(` 
		Select info_type, id from privy_uuids where user_id = $1;
	`, id)

	defer rows.Close()
	for rows.Next() {
		var infoType string
		var uuid string
		err = rows.Scan(&infoType, &uuid)
		if err != nil {
			writeError(w, 500, err.Error()) //FIXME: DON'T DO THIS!!
			return
		}
		resp[infoType] = uuid
	}
	sessionKey, err1 := GetSessionKey(id)

	if err1 != nil {
		fmt.Println(err1)
		writeError(w, 500, "Server error")
		return
	}
	resp["sessionid"] = sessionKey

	data, err := json.Marshal(resp)
	if err != nil {
		fmt.Println(err)
		writeError(w, 500, "Server error")
		return
	}
	w.Write(data)
}

// Push that this user has a change into somewhere....
func saveUserJSON(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	target := make(map[string]interface{})
	err := decodeJSON(w, r, &target)
	if err != nil {
		fmt.Println(err)
		writeError(w, 400, "Something went wrong")
		return
	}
	sessionID, ok := target["sessionid"].(string)
	if !ok {
		fmt.Println(err)
		writeError(w, 400, "No sesssion!")
		return
	}
	delete(target, "sessionid")
	data, err := json.Marshal(&target)
	if err != nil {
		fmt.Println(err)
		writeError(w, 500, "Something went wrong")
		return
	}

	userID, ok, err := CheckSessionsKey(sessionID)
	if !ok || err != nil {
		fmt.Println(err)
		writeError(w, 400, "Invalid auth")
		return
	}

	_, err = db.Exec(`
		Update privy_user 
		set social_information = $1::json
		where id = $2
	`, string(data), userID)
	if err != nil {
		fmt.Println(err)
		writeError(w, 500, "Unable to save information")
		return
	}
	// TODO: Diff the saved data with the existing data so we know what UUIDs to send push notifications for
	rows, err := db.Query(`
		Select distinct apns_token.apns_device_token
		from privy_uuids
		inner join subscription on subscription.uuid = privy_uuids.id
		inner join apns_token on apns_token.user_id = subscription.user_id
		where privy_uuids.user_id = $1`, userID)
	if err != nil {
		fmt.Println(err)
		writeError(w, 500, "Server error!")
		return
	}
	for rows.Next() {
		var apns string
		err := rows.Scan(&apns)
		if err != nil {
			fmt.Println(err)
			writeError(w, 500, "Server error!")
			return
		}
		pushNotifications.SendNotification(apns)
	}

	// Finish the request.
	w.WriteHeader(200)
}

func invalidateSession(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	// TODO: Implement this and route it
	return
	if err := r.ParseForm(); err != nil {
		writeError(w, 400, "Bad form encoding")
		return
	}
	// TODO: finish this code
	/*
		auth := &struct {
			SessionID string
		}{}
	*/

	_, err := db.Exec(`
	Update sessions
	set valid_til = TIMESTAMPTZ 'NOW' + INTERVAL '-1 MINUTE'
	where cookieinfo = $1`, r.FormValue("sessionid"))
	if err != nil {
		fmt.Println(err)
		writeError(w, 500, "Sever error")
		return
	}
	w.WriteHeader(204)
}

func verifyUser(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	verificationToken := p[0].Value
	var handle string
	var email string
	var userID int
	var isValidated bool
	err := db.QueryRow(`
	 Select userid, handle, email, isValidated
	 from emailvalidation 
	 inner join users on users.id = emailvalidation.userid 
	 	and validationtoken = $1;
	`, verificationToken).Scan(&userID, &handle, &email, &isValidated)
	if err == sql.ErrNoRows {
		w.WriteHeader(404)
		fmt.Fprint(w, "User not found")
		return
	}
	if isValidated {
		pageData, err := templates.GetLandingPage(handle, email)
		if err != nil {
			w.WriteHeader(500)
			fmt.Fprint(w, "unknown error........")
		}
		fmt.Fprint(w, pageData)
		return
	}
	if err != nil {
		fmt.Println(err)
		w.WriteHeader(500)
		fmt.Fprint(w, "Unknown error")
		return
	}
	_, err = db.Exec(`
	Update emailvalidation
	set 
		isValidated = true
	where userid = $1;
	`, userID)
	if err != nil {
		fmt.Println(err)
		w.WriteHeader(500)
		fmt.Fprint(w, "Unknown error..")
		return
	}
	pageData, err := templates.GetVerificationPage(handle, email)
	if err != nil {
		fmt.Println(err)
		w.WriteHeader(500)
		fmt.Fprint(w, "Unknown error....")
		return
	}
	fmt.Fprint(w, pageData)
}

type EMIT_TYPE int

const (
	EMIT_MANY EMIT_TYPE = 1
	EMIT_ONE  EMIT_TYPE = 0
)

func processPasswordReset(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	err := r.ParseForm()
	if err != nil {
		writeError(w, 500, "Server error!")
		return
	}
	changeToken := p.ByName("changetoken")
	newpass := r.FormValue("password")
	cryptPassData, err := bcrypt.GenerateFromPassword([]byte(newpass), 13)
	if err != nil {
		writeError(w, 500, "Server error!")
		return
	}
	_, err = db.Exec(`
	with reset_ids as (
		Select user_id 
		from password_reset 
		where password_reset_token = ($2::uuid))
	Update privy_user
	SET password_hash = $1
	from reset_ids
	where reset_ids.user_id = id
	`, string(cryptPassData), changeToken)
	if err != nil {
		writeError(w, 500, "Server error!")
		fmt.Println("Failure while updating password for user!", err.Error())
		return
	}
	// Redirect to another page
	http.Redirect(w, r, "https://privyapp.com/static/changedpasswordSuccess.html", http.StatusFound)
}

func showResetPage(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	changeToken := p.ByName("changetoken")
	var emailVal string
	var isStillValid bool
	err := db.QueryRow(`
	Select email, (valid_til > NOW() - INTERVAL '24 HOURS') as isStillValid
	 from privy_user
     inner join password_reset on user_id = privy_user.id
	 where password_reset_token = $1::uuid
	`, changeToken).Scan(&emailVal, &isStillValid)
	if err != nil {
		w.WriteHeader(404)
		fmt.Println(err.Error())
		return
	}
	if !isStillValid {
		w.WriteHeader(404)
		return
	}
	body, err := templates.GetPasswordResetWebPage(emailVal, changeToken)
	if err != nil {
		w.WriteHeader(500)
		fmt.Println(err.Error())
		return
	}
	// Render the body from the template to the HTML writer
	fmt.Fprint(w, body)
	return
}

func sendResetEmail(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	if err := r.ParseForm(); err != nil {
		fmt.Println(err.Error())
		w.WriteHeader(200)
		return
	}
	emailVal := r.FormValue("email")
	var userID int
	err := db.QueryRow("Select id from privy_user where email = $1", emailVal).Scan(&userID)
	if err != nil {
		fmt.Println(err.Error())
		w.WriteHeader(200)
		return
	}

	var resetUUID string
	err = db.QueryRow("Select getResetToken($1)::text", userID).Scan(&resetUUID)
	if err != nil {
		fmt.Println(err.Error())
		w.WriteHeader(200)
		return
	}
	fmt.Println(resetUUID)
	body, err := templates.GetNewPassword(emailVal, resetUUID)
	if err != nil {
		fmt.Println(err.Error())
		w.WriteHeader(200)
		return
	}
	// Attempt to send email
	email.SendMessage("Privy password reset", body, emailVal)
	w.WriteHeader(200)
}

/*
func emitUsers(w http.ResponseWriter, rows *sql.Rows, em EMIT_TYPE) {
	users := make([]User, 0)
	for rows.Next() {
		user := User{}
		rows.Scan(&user.Handle, &user.Email, &user.Bio, &user.ImageURL)
		users = append(users, user)
	}
	rows.Close()
	var data []byte
	var err error
	if em == EMIT_MANY {
		data, err = json.Marshal(struct{ Users []User }{users})
	} else {
		data, err = json.Marshal(users[0])
	}
	// TODO: clean this up.
	if err != nil {
		writeError(w, 500, "Ukown error")
		return
	}
	w.Write(data)
}
*/

// This gets the JSON for a set of UUIDs.
func getJsonForUUIDS(userID int, uuids string) ([]string, error) {
	rows, err := db.Query(`
		Select
		-- This is a drop in for json_object_agg. I need to figure out how to build that...
		     ('{' ||
				string_agg(Distinct '"' || info_type || '": '
						|| (privy_user.social_information->>info_type), ',')
			|| '}' )::json as USER_JSON

		from privy_user
		inner join privy_uuids
			on privy_user.id = privy_uuids.user_id
		inner join subscription 
			on subscription.uuid = privy_uuids.id 
			where
				privy_uuids.id::text = ANY (string_to_array($1, ','))
				and subscription.user_id = $2
		group by privy_user.id
	`, uuids, userID)
	if err != nil {
		// writeError(w, 500, "Server error")
		return nil, err
	}

	var data = make([]string, 0)

	for rows.Next() {
		var jsonVal string
		err = rows.Scan(&jsonVal)
		if err != nil {
			return nil, err
		}
		data = append(data, jsonVal)
	}
	return data, nil
}

// This gets the JSON for a set of UUIDs.
func getJsonUserSubData(userID int) ([]string, error) {
	rows, err := db.Query(`Select getUserSubData($1);`, userID)
	if err != nil {
		return nil, err
	}

	var data = make([]string, 0)

	for rows.Next() {
		var jsonVal string
		err = rows.Scan(&jsonVal)
		if err != nil {
			fmt.Println(err.Error())
			return nil, err
		}
		data = append(data, jsonVal)
	}
	return data, nil
}

// This function needs to check that each UUID is one that the user is already connected to.
func refreshUUIDList(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	fmt.Println("foo")
	if err := r.ParseForm(); err != nil {
		fmt.Println(err.Error())
		writeError(w, 400, "Bad form encoding")
		return
	}
	fmt.Println("sessionid: ", r.FormValue("sessionid"))
	userID, ok, err := CheckSessionsKey(r.FormValue("sessionid"))
	if !ok || err != nil {
		fmt.Println(err)
		writeError(w, 400, "Invalid auth token")
		return
	}
	data, err := getJsonUserSubData(userID)
	if err != nil {
		fmt.Println(err)
		writeError(w, 500, "Server error!")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprint(w, "[", strings.Join(data, ","), "]")
}

// Dis list neds to also handle subscriptions...
func lookupAndSubUUIDS(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	if err := r.ParseForm(); err != nil {
		writeError(w, 400, "Bad form encoding")
		return
	}
	uuidsList := r.FormValue("uuids")
	userID, ok, err := CheckSessionsKey(r.FormValue("sessionid"))
	if !ok || err != nil {
		fmt.Println(err)
		writeError(w, 400, "Invalid auth token")
		return
	}

	// Enforce that only one users's worth of UUIDs can be searched
	var numUsers int
	err = db.QueryRow(`
	Select Count(Distinct user_id) from privy_uuids
	inner join (
		Select regexp_split_to_table($1, ',')::uuid as id
	) as uuid_split on uuid_split.id = privy_uuids.id
	`, uuidsList).Scan(&numUsers)
	if err != nil {
		fmt.Println("SQL error: ", err.Error())
		writeError(w, 500, "Server error!")
		return
	}
	if numUsers != 1 {
		writeError(w, 400, "You can't scan more than user at a time!")
		return
	}

	// Query, args -> Result, error
	_, err = db.Exec(`
	Insert into subscription (user_id, uuid)
	Select $1, uuid_tools.id::uuid
	from (select regexp_split_to_table($2, ',') as id)  as uuid_tools
	`, userID, uuidsList)
	if err != nil {
		fmt.Println("SQL error: ", err.Error())
		writeError(w, 500, "Server error!")
		return
	}

	data, err := getJsonForUUIDS(userID, uuidsList)
	if err != nil {
		fmt.Println(err.Error())
		writeError(w, 500, "Server error!")
		return
	}

	if len(data) > 1 {
		writeError(w, 400, "Too many UUIDs")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	// This should only iterate once, but is the easiest way extract a single value
	for _, value := range data {
		fmt.Fprint(w, value)
	}
}

func registerPushNotificationClient(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	if err := r.ParseForm(); err != nil {
		writeError(w, 400, "Bad form encoding")
		return
	}
	apnsid := r.FormValue("apnsid")
	userID, ok, err := CheckSessionsKey(r.FormValue("sessionid"))
	if !ok || err != nil {
		fmt.Println(err)
		writeError(w, 400, "Invalid auth token")
		return
	}
	_, err = db.Exec("Select upsertAPNSForUser($1, $2);", userID, apnsid)
	if err != nil {
		fmt.Println("Database error: ", err.Error())
		writeError(w, 500, "Server error!")
		return
	}
	w.WriteHeader(200)
}

func getImageForUUID(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	if err := r.ParseForm(); err != nil {
		writeError(w, 400, "Bad form encoding")
		return
	}
	uuidToCheck := r.FormValue("uuid")
	userID, ok, err := CheckSessionsKey(r.FormValue("sessionid"))
	if !ok || err != nil {
		fmt.Println(err)
		writeError(w, 400, "Invalid auth token")
		return
	}
	var idToGrab int
	err = db.QueryRow(
		`Select user_id from privy_uuids 
		inner join subscription on subscription.uuid = privy_uuids.id
		where privy_uuids.id = $1::uuid
		and subscription.user_id = $2
		`,
		uuidToCheck, userID).Scan(idToGrab)
	if err == sql.ErrNoRows {
		fmt.Println("Search attempted without subscription")
		writeError(w, 404, "Image not found")
		return
	}
	if err != nil {
		fmt.Println("Database error: ", err.Error())
		writeError(w, 500, "Server error!")
		return
	}
	path := filepath.Join(config.UploadsRoot, fmt.Sprint(userID))
	if _, err := os.Stat(path + ".png"); err == nil {
		http.ServeFile(w, r, path+".png")
		return
	}
	if _, err := os.Stat(path + ".jpg"); err == nil {
		http.ServeFile(w, r, path+".jpg")
	}
	w.WriteHeader(400)
}

func saveUserImage(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	if err := r.ParseMultipartForm(1048567); err != nil {
		writeError(w, 400, "Bad form encoding")
		return
	}
	userID, ok, err := CheckSessionsKey(r.FormValue("sessionid"))
	if !ok || err != nil {
		fmt.Println(err)
		writeError(w, 400, "Invalid auth token")
		return
	}
	file, fileHeader, err := r.FormFile("picture")
	if err != nil {
		fmt.Println(err)
		writeError(w, 400, "Problem uploading image")
		return
	}
	data, err := ioutil.ReadAll(file)
	if err != nil {
		fmt.Println(err.Error())
		writeError(w, 500, "Server error!")
		return
	}
	ext := filepath.Ext(fileHeader.Filename)
	err = ioutil.WriteFile(filepath.Join(config.UploadsRoot, fmt.Sprint(userID, ".", ext)), data, os.ModePerm|0755)
	if err != nil {
		fmt.Println(err.Error())
		writeError(w, 500, "Server error!")
		return
	}
	w.WriteHeader(200)
}

func deleteUUIDs(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	if err := r.ParseForm(); err != nil {
		writeError(w, 400, "Bad form encoding")
		return
	}
	uuidsToCheck := r.FormValue("uuids")
	userID, ok, err := CheckSessionsKey(r.FormValue("sessionid"))
	if !ok || err != nil {
		fmt.Println(err)
		writeError(w, 400, "Invalid auth token")
		return
	}
	_, err = db.Exec(`Delete from subscription 
	where uuid::text = ANY(string_to_array($2, ',')) and user_id = $1`, userID, uuidsToCheck)
	if err != nil {
		writeError(w, 500, "Server error")
		return
	}

}
