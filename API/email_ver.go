package main

import (
	"bytes"
	"html/template"
)

var innerTemp = `
<html>
    <title>Verification Complete</title>
    <body bgcolor="#ECEEF3">
        <font face="Verdana">
            <font color="#235FBE">
                <h1>Verification complete</h1>
            </font>
            <font color="032155">
                <p>Hello 

                    <b>{{ .UserName }}</b>,

                </p>
                <p>Thank you for registering for an account with Privy. The email

                    <b>{{ .Email }}</b>
                    has successfully been verified with our server.

                </p>
                <p>You may now generate your own QR code and trade contact information with other Privy users!</p>
            </body>
        </font>
    </html>`

var alreadySignedUpTemp = `
<!DOCTYPE html>
<html>
    <title>User already signed up.</title>
    <body bgcolor="#ECEEF3">
        <font face="Verdana">
            <font color="#235FBE">
                <h1>Verification already completed</h1>
            </font>
            <font color="032155">
                <p>
                    <b>{{ .UserName }}</b>,

                </p>
                <p>You have already verified

                    <b>{{ .Email }}</b>
on our server.

                </p>
                <p>You may now generate your own QR code and trade contact information with other Privy users!</p>
            </body>
        </font>
    </html>`

var verificationPageTemp *template.Template
var landingPageTemp *template.Template

func init() {
	verificationPageTemp = template.Must(template.New("verificationPage").Parse(innerTemp))
	landingPageTemp = template.Must(template.New("landingPage").Parse(alreadySignedUpTemp))
}

type landingPageData struct {
	UserName, Email string
}

func GetVerificationPage(userName, email string) (string, error) {
	buf := new(bytes.Buffer)
	err := verificationPageTemp.Execute(buf, &landingPageData{userName, email})
	return string(buf.Bytes()), err
}

func GetLandingPage(userName, email string) (string, error) {
	buf := new(bytes.Buffer)
	err := landingPageTemp.Execute(buf, &landingPageData{userName, email})
	return string(buf.Bytes()), err
}
