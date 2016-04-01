package email

import (
	"testing"
	"time"
)

func TestEmailSend(t *testing.T) {
	SendMessage("A test email", "yumaikas94@gmail.com")
	time.Sleep(1 * time.Second)
}
