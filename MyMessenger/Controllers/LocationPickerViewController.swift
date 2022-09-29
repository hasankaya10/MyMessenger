//
//  LocationPickerViewController.swift
//  MyMessenger
//
//  Created by Hasan Kaya on 16.09.2022.
//

import UIKit
import CoreLocation
import MapKit
/// controller that allows you to pick location in map or see the location in map in sent message
class LocationPickerViewController: UIViewController, MKMapViewDelegate {
    public var completion : ((CLLocationCoordinate2D) -> Void)?
    private var coordinates : CLLocationCoordinate2D?
    private var isPickable = true
    let pin = MKPointAnnotation()
    private var map : MKMapView = {
       let map = MKMapView()
        return map
    }()
    init(coordinates : CLLocationCoordinate2D?,isPickable: Bool) {
        self.coordinates = coordinates
        self.isPickable = isPickable
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        map.delegate = self
        view.backgroundColor = .systemBackground
        print(isPickable)
        if isPickable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendButtonTapped))
            map.isUserInteractionEnabled = true
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didtapMap(_:)))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            map.addGestureRecognizer(gesture)
        }
        else {
            // just show the location
            guard let coordinates = self.coordinates else {
                return
            }
            pin.coordinate = coordinates
            pin.title = "Konum"
            pin.subtitle = "Burası"
            map.addAnnotation(pin)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            
            let region = MKCoordinateRegion(center: coordinates, span: span)
            map.setRegion(region, animated: true)
        }
       
        view.addSubview(map)
        
    }
    @objc func sendButtonTapped(){
        guard let coordinates = coordinates else {
            return
        }
        completion?(coordinates)
        navigationController?.popViewController(animated: true)
    }
    @objc func didtapMap(_ gesture: UITapGestureRecognizer){
        let locationInView = gesture.location(in: map)
        let coordinates = map.convert(locationInView, toCoordinateFrom: map)
        self.coordinates = coordinates
        // drop a pin that location
        for annotation in map.annotations {
            map.removeAnnotation(annotation)
        }
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        map.addAnnotation(pin)
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "MyAnnotation"
        var pinView = map.dequeueReusableAnnotationView(withIdentifier: reuseId)
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                       pinView?.canShowCallout = true
                       let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
                       pinView?.tintColor = .red
                       pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        return pinView
        
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if !isPickable {
            guard let coordinates = coordinates else {
                return
            }
            
            let requestLocation = CLLocation(latitude: coordinates.latitude, longitude:coordinates.longitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placeMarkDizisi, hata in
                if let placemarks = placeMarkDizisi {
                    if placemarks.count > 0 {
                        let yeniPlaceMark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: yeniPlaceMark)
                        item.name = "Gönderilen Konum"
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }}
    
    
    
    

    

}
