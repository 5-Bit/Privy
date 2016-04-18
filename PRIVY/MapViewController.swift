//
//  MapViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 4/6/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit
import MapKit

final class UserAnnotation: MKPointAnnotation {
    var user: HistoryUser!
}

final class MapViewController: UIViewController {
    @IBOutlet private weak var mapView: MKMapView!

    var allUsers = [HistoryUser]()
    var currentUserIndex: Int?
    private var currentUserAnnotation: MKPointAnnotation?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "Back",
            style: .Plain,
            target: nil,
            action: nil
        )

        if allUsers.count == 1 {
            title = "Showing \(allUsers.count) contact"
        } else {
            title = "Showing \(allUsers.count) contacts"
        }

        for (index, user) in allUsers.enumerate() where user.location != nil && user.location!.latitude != nil && user.location!.longitude != nil {
            let annotation = UserAnnotation()
            annotation.user = user

            annotation.coordinate = CLLocationCoordinate2D(
                latitude: user.location!.latitude!,
                longitude: user.location!.longitude!
            )

            var names = [String?]()
            names.append(user.basic.firstName)
            names.append(user.basic.lastName)

            annotation.title = names.flatMap({ $0 }).joinWithSeparator(" ")

            if let currentUser = currentUserIndex where index == currentUser {
                currentUserAnnotation = annotation
            }

            mapView.addAnnotation(annotation)
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let destination = segue.destinationViewController as? HistoryUserViewController,
            user = (sender as? UserAnnotation)?.user else {
                return
        }

        destination.allUsers = allUsers
        destination.userIndex = allUsers.indexOf { $0 == user }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        for view in views where view.annotation != nil {
            if view.annotation !== currentUserAnnotation {
                continue
            }

            mapView.setVisibleMapRect(
                MKMapRect(
                    origin: MKMapPointForCoordinate(
                        view.annotation!.coordinate
                    ),
                    size: MKMapSize(
                        width: Double(mapView.bounds.width),
                        height: Double(mapView.bounds.height)
                    )
                ),
                animated: true
            )
        }
    }

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        performSegueWithIdentifier("showUserFromPin", sender: view.annotation)
    }
}
