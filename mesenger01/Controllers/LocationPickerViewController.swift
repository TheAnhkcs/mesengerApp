//
//  LocationPickerViewController.swift
//  mesenger01
//
//  Created by hoang the anh on 03/06/2023.
//

import UIKit
import CoreLocation
import MapKit

class LocationPickerViewController: UIViewController {

    public var completion: ((CLLocationCoordinate2D)-> Void)?
    private var coordinates: CLLocationCoordinate2D?
    private var isPickable = true
    private let map: MKMapView = {
       let map = MKMapView()
        
        
        return map
    }()
    
    init(coordinate: CLLocationCoordinate2D?) {
        self.coordinates = coordinate
        self.isPickable = false
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        view.backgroundColor = .systemBackground
        if isPickable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendButtonTapped))
            map.isUserInteractionEnabled = true
            
            let guesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap))
            guesture.numberOfTouchesRequired = 1
            guesture.numberOfTapsRequired = 1
            map.addGestureRecognizer(guesture)
        }
        else {
            // just showinglocation
            guard let coordinates = coordinates else {
                return
            }

            let pin = MKPointAnnotation()
            pin.coordinate = self.coordinates!
           
            map.addAnnotation(pin)
        }
        view.addSubview(map)
        
    }
    

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
       
        map.frame = view.bounds
    }
    
    @objc private func sendButtonTapped() {
        guard let coordinate = coordinates else {
            return
        }
        navigationController?.popViewController(animated: true)
        self.completion?(coordinate)
    }
    
    @objc private func didTapMap(_ guesture: UITapGestureRecognizer) {
        let locationView = guesture.location(in: map)
        self.coordinates = map.convert(locationView, toCoordinateFrom: map)
        
        for anotation in map.annotations {
            map.removeAnnotation(anotation)
        }
        
        // drop a pin on that location
        let pin = MKPointAnnotation()
        pin.coordinate = self.coordinates!
       
        map.addAnnotation(pin)
    }

}
