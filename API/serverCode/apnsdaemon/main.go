package apnsdaemon

import (
	"fmt"
	apns "github.com/anachronistic/apns"
	// "time"
)

func SendNotification(apnsID string) {
	apnsBuffer <- apnsID
}

var apnsBuffer = make(chan string, 200)

// TODO: Batch this better!
func daemon() {
	// checkFeedback := time.NewTicker(30 * time.Minute)
	payload := apns.NewPayload()
	payload.Alert = "One of your contacts updated their information"
	payload.Badge = 1
	payload.Sound = "bingbong.aiff"
	client := apns.NewClient("gateway.sandbox.push.apple.com:2195", "certificate.pem", "apnsKey.unencrypted.pem")
	for {
		select {
		case apnsID := <-apnsBuffer:
			pn := apns.NewPushNotification()
			pn.DeviceToken = apnsID
			pn.AddPayload(payload)
			resp := client.Send(pn)
			fmt.Println("Sending notification")
			if resp.Error != nil {
				fmt.Println("Failed to send push notification:", resp.Error)
			}
			// TODO:
			/*
				go client.ListenForFeedback()
				for {
					select {
					case resp := <-client.FeedbackChannel:

					}
				}
			*/
		}
	}
}
func sendAPSNRequest(apnsID string) {

}

func init() {
	go daemon()
}
