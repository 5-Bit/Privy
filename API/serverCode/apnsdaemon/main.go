package apnsdaemon

import (
	"fmt"
	apns "github.com/anachronistic/apns"
	"time"
)

var removeAPNSFromStore func(apns string) error = nil

func SetAPNSRemovalDelegate(funcToCall func(apns string) error) {
	removeAPNSFromStore = funcToCall
}

// TODO: Possibly queue APNS removals to allow db to catch up
func removeAPNSID(apns string) {
	if removeAPNSFromStore != nil {
		err := removeAPNSFromStore(apns)
		if err != nil {
			fmt.Println("Error removing APNS from db:", err)
		}
	} else {
		fmt.Println("Cannot remove APNS token at this time")
	}
}

func listenForFeedback(client *apns.Client) {
	go client.ListenForFeedback()
	for {
		select {
		case resp := <-apns.FeedbackChannel:
			removeAPNSID(resp.DeviceToken)
			fmt.Println("Removing device token ", resp.DeviceToken)
			// todo: Send that this APNS token should not get notifciations
		case <-apns.ShutdownChannel:
			break
		}
	}
}

func SendNotification(apnsID string) {
	apnsBuffer <- apnsID
}

var apnsBuffer = make(chan string, 200)

// TODO: Batch this better!
func daemon() {
	checkFeedback := time.NewTicker(30 * time.Second)
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
		case <-checkFeedback.C:
			go listenForFeedback(client)
		}
	}
}

func init() {
	go daemon()
}
