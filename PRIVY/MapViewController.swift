//
//  MapViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 4/6/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit
import MapKit

final class MapViewController: UIViewController {
    @IBOutlet private weak var mapView: MKMapView!

    var allUsers = [HistoryUser]()
    var currentUserIndex: Int?
    private var currentUserAnnotation: MKPointAnnotation?

    override func viewDidLoad() {
        super.viewDidLoad()

        if allUsers.count == 1 {
            title = "Showing \(allUsers.count) contact"
        } else {
            title = "Showing \(allUsers.count) contacts"
        }

        for (index, user) in allUsers.enumerate() where user.location != nil && user.location!.latitude != nil && user.location!.longitude != nil {
            let annotation = MKPointAnnotation()

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
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        var zoomRect = MKMapRectNull

        for view in views where view.annotation != nil {
            if view.annotation === currentUserAnnotation {
                mapView.selectAnnotation(view.annotation!, animated: true)
            }

            let point = MKMapPointForCoordinate(view.annotation!.coordinate)
            let pointRect = MKMapRectMake(point.x, point.y, 0.1, 0.1)
            zoomRect = MKMapRectUnion(zoomRect, pointRect)
        }

        mapView.setVisibleMapRect(zoomRect, animated: true)
    }
}
