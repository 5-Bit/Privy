package templates

import (
	"bytes"
	"html/template"
)

var passwordRecoveryWebPageTemp = `
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
  <head>
    <meta http-equiv="content-type" content="text/html;charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1.0"/>
    <title>Privy - Reset Password</title>

    <!-- CSS  -->
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <link href="/static/css/materialize.min.css" type="text/css" rel="stylesheet" media="screen,projection"/>
    <link href="/static/css/style.css" type="text/css" rel="stylesheet" media="screen,projection"/>
  </head>
  <body>
    <nav class="blue">
      <div class="nav-wrapper">
        <a class="brand-logo center">Privy Password Reset</a>
      </div>
    </nav>

	<div class="container">
      <p class="flow-text">Hello <b>{{ .Email }}</b>,</p>

      <p class="flow-text">A password reset has been requested on your Privy account.</p>

      <p class="flow-text">Please enter your new password in the following text field. After you have finished, confirm it by re-entering your password in the second text field. Passwords must be at least 8 characters in length.</p>

      <div class="row">
	  <form name="frm" method="post" 
	  action="https://privyapp.com/resetpassword/{{ .ChangeToken }}" class="col s12">
          <div class="row">
            <div class="input-field col s12">
              <input id="password" type="password" name="password" class="validate">
              <label for="password">Enter Password</label>
            </div>
          </div>

          <div class="row">
            <div class="input-field col s12">
              <input id="confirmpassword" type="password" name="confirmpassword" class="validate">
              <label for="confirmpassword">Re-enter Password</label>
            </div>
          </div>

          <input type="submit" value="Submit" onclick="return val();" class="waves-effect waves-light btn blue lighten-1"/>

          <input type="reset" value="Reset" class="waves-effect waves-light btn blue lighten-1"/>
        </form>
      </div>
    </div>

    <!--  Scripts-->
    <script src="https://code.jquery.com/jquery-2.1.1.min.js"></script>
    <script src="/static/js/materialize.js"></script>
    <script src="/static/js/init.js"></script>
    <script type="text/javascript">
    function val(){
      if (frm.password.value == "") {
        alert("Please enter a password.");
        frm.password.focus();
        return false;
      }
      if ((frm.password.value).length < 8) {
        alert("Password must be at least 8 characters.");
        frm.password.focus();
        return false;
      }
      if (frm.confirmpassword.value == "") {
        alert("Please confirm your password.");
        return false;
      }
      if (frm.confirmpassword.value != frm.password.value) {
          alert("Password fields do not match.");
          return false;
      }
      return true;
    }
    </script>
  </body>
</html>
`

var passwordResetWebPage *template.Template

func init() {
	passwordResetWebPage = template.Must(template.New("password").Parse(passwordRecoveryWebPageTemp))
}

type passwordResetWebPageData struct {
	Email, ChangeToken string
}

func GetPasswordResetWebPage(email, changeToken string) (string, error) {
	buf := new(bytes.Buffer)
	err := passwordResetWebPage.Execute(buf, &passwordResetWebPageData{email, changeToken})
	return string(buf.Bytes()), err
}
