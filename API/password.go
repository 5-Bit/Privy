package main

import (
    "bytes"
    "html/template"
)

var passwordRecoveryTemp = `<html>
    <title>Privy Password Support</title>
    <body bgcolor="#ECEEF3">
        <font face="Verdana">
            <font color="#235FBE">
                <h1>Privy Password Recovery</h1>
            </font>
            <font color="032155">
                <p>Hello

                    <b>{{ .UserName }}</b>,

                </p>
                <p>A password change has been requested to the account associated with the email

                    <b>{{ .Email }}</b>.

                </p>
                <p>Use the following key as a temporary password:

                    <p>
                        <b>@ABCD1234</b>
                    </p>
                </p>
                <p>Once you have logged in, please change your password to complete the Privy password recovery process.</p>
                <p>Recommended security tips:

                    <br>- Never share your password with anyone.

                        <br>- Use a combination of upper and lowercase letters as well as numbers to create a password that is hard to guess.

                            <br>- Change your passwords regularly, and never use the same password for multiple sites.

                            </p>
                        </body>
                    </font>
                </html>`

var passwordRecovery *template.Template

func init() {
    passwordRecovery = template.Must(template.New("password").Parse(passwordRecoveryTemp))
}

type passwordData struct {
    UserName, Email string
}

func GetNewPassword(username, email string) (string, error) {
    buf := new(bytes.Buffer)
    err := passwordRecovery.Execute(buf, &passwordData{username, email})
    return string(buf.Bytes()), err
}