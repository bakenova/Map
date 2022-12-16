//
//  ViewController.swift
//  Map
//
//  Created by Arailym on 20.03.2022.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var distanceLabel: UILabel!
    
    let locationManager = CLLocationManager()
    var userLocation = CLLocation()
    var followMe = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        
        //gesture recognizer
        let mapDragRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.didDragMap))
        mapDragRecognizer.delegate = self
        mapView.addGestureRecognizer(mapDragRecognizer)
        
        let lat: CLLocationDegrees = 37.957666
        let long: CLLocationDegrees = -122.0323133
        
        //annotation on the map
        let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, long)
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = "Destination"
        annotation.subtitle = "Here you go"
        mapView.addAnnotation(annotation)
        
        //long press
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressAction))
        longPress.minimumPressDuration = 2
        mapView.addGestureRecognizer(longPress)
        
        mapView.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        userLocation = locations[0]
        
        if followMe {
            let latDelta: CLLocationDegrees = 0.01
            let longDelta: CLLocationDegrees = 0.01
            
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
            
            let region = MKCoordinateRegion(center: userLocation.coordinate, span: span)
            
            mapView.setRegion(region, animated: true)
        }
    }

    @IBAction func showMe(_ sender: Any) {
        followMe = true
    }
    
    @objc func didDragMap(gestureRecognizer: UIGestureRecognizer){
        if (gestureRecognizer.state == UIGestureRecognizer.State.began){
            followMe = false
            print("Map drag began")
        }
        if (gestureRecognizer.state == UIGestureRecognizer.State.ended){
            print("Map drag ended")
        }
    }
    
    @objc func longPressAction(gestureRecognizer: UIGestureRecognizer){
        print("gesture recognizer")
        
        let touchPoint = gestureRecognizer.location(in: mapView)
        let newCoor: CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoor
        annotation.title = "Destination"
        annotation.subtitle = "subtitle"
        mapView.addAnnotation(annotation)
    }
    
    //MARK: - MapView delegate
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print(view.annotation?.title as Any)
        
        let location: CLLocation = CLLocation(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)
        let meters: CLLocationDistance = location.distance(from: userLocation)
        distanceLabel.text = String(format: "Distance: %.2f m", meters)
        
        //Routing
        //1
        let sourceLocation = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let destinationLocation = CLLocationCoordinate2D(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)
        
        //2
        let sourcePlacemark = MKPlacemark(coordinate: sourceLocation, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationLocation, addressDictionary: nil)
        
        //3
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        //4
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile
        
        //Calculate the direction
        let directions = MKDirections(request: directionRequest)
        
        //5
        directions.calculate {
            (response, error) -> Void in
            
            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }
                return
            }
            
            let route = response.routes[0]
            self.mapView.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 4.0
        
        return renderer
    }
}

