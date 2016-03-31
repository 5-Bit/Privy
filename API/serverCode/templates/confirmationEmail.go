package templates

import (
	"bytes"
	"html/template"
)

var emailVerificationTemplate = `<html>
    <title>Eagleslist Verification</title>
    <body bgcolor="#ECEEF3">
        <font face="Verdana">
            <font color="#00885A">
                <h1>Welcome to Eagleslist</h1>
            </font>
            <font color="00287A">
                <p>Greetings 
            
                    <b>{{ .UserName }}</b>,
        
                </p>
                <p>You have registered for an Eagleslist account using the email 
            
                    <b>{{ .Email }}</b>.
        
                </p>
                <p> Please click on the following link or copy and paste it into your browser to complete the email verification process:
            
                    <b>
					<a href="https://sourcekitserviceterminated.com/verify/{{ .LinkID }}">Verify my account.</a>
                    </b>
                </p>
                <p>You may begin creating posts and replying to other listings once your verification is complete.</p>
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
