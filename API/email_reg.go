package main

import (
	"bytes"
	"html/template"
)

var emailVerificationTemplate = `<html>
    <title>Privy Verification</title>
    <body bgcolor="#ECEEF3">
        <font face="Verdana">
            <font color="#235FBE">
                <h1>Welcome to Privy</h1>
            </font>
            <font color="032155">
                <p>Greetings 

                    <b>{{ .UserName }}</b>,

                </p>
                <p>You have registered for a Privy account using the email

                    <b>{{ .Email }}</b>.

                </p>
                <p> Please click on the following link or copy and paste it into your browser to complete the email verification process:

                    <b>
                        {{ .LinkID }}
                    </b>
                </p>
                <p>Once the verification process is complete, you will be able to trade contact information with other Privy users.</p>
            </body>
        </font>
    </html>`

var emailT *template.Template

func init() {
	emailT = template.Must(template.New("email").Parse(emailVerificationTemplate))
}

func GetConfirmationEmail(username, email, linkID string) (string, error) {
	buf := new(bytes.Buffer)
	err := emailT.Execute(buf, &struct {
		UserName string
		Email    string
		LinkID   string
	}{
		username, email, linkID,
	})
	return string(buf.Bytes()), err
}
