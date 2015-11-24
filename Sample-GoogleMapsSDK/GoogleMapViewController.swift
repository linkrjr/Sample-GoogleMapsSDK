//
//  ViewController.swift
//  Sample-GoogleMapsSDK
//
//  Created by Ronaldo GomesJr on 9/11/2015.
//  Copyright © 2015 TechnophileIT. All rights reserved.
//

import UIKit
import GoogleMaps

class GoogleMapViewController: UIViewController, GMSMapViewDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {

    private var mapView:GMSMapView!
    private let locationManager:CLLocationManager = CLLocationManager()
    private var markers = Set<GMSMarker>()
    private var currentLocationMarker:UIImageView!
    private var locationSearchField:UISearchBar!
    private var searchResultsTableView:UITableView!
    
    private var searchResults:[AnyObject]? = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillAppear:", name:UIKeyboardWillShowNotification, object: nil)
        
        self.locationManager.requestAlwaysAuthorization()
        
        let camera = GMSCameraPosition.cameraWithLatitude(-33.85772, longitude: 151.20464, zoom: 14, bearing: 0, viewingAngle: 0)
        
        self.mapView = GMSMapView.mapWithFrame(self.view.bounds, camera: camera)
        self.mapView.mapType = kGMSTypeNormal
        self.mapView.myLocationEnabled = true
        self.mapView.setMinZoom(15.0, maxZoom: 20.0)
        
        self.mapView.settings.compassButton = true
        self.mapView.settings.myLocationButton = true
        self.mapView.delegate = self
        
        self.view.addSubview(self.mapView)
    
        self.locationSearchField = UISearchBar()
        self.locationSearchField.delegate = self
        self.locationSearchField.showsBookmarkButton = false
        self.locationSearchField.showsSearchResultsButton = false
        self.locationSearchField.returnKeyType = UIReturnKeyType.Done
        self.locationSearchField.translatesAutoresizingMaskIntoConstraints = false
        self.locationSearchField.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(self.locationSearchField)
        
        self.currentLocationMarker = UIImageView(image: UIImage(named: "currentLocationMarker"))
        self.currentLocationMarker.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.currentLocationMarker)

        self.searchResultsTableView = UITableView()
        self.searchResultsTableView.delegate = self
        self.searchResultsTableView.dataSource = self
        self.searchResultsTableView.translatesAutoresizingMaskIntoConstraints = false
        self.searchResultsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.searchResultsTableView.hidden = true
        self.view.addSubview(self.searchResultsTableView)
        
        self.setupConstraints()
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.mapView.padding = UIEdgeInsetsMake(self.topLayoutGuide.length + 5.0, 0, self.bottomLayoutGuide.length + 50.0, 0)
        
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func mapView(mapView: GMSMapView!, markerInfoWindow marker: GMSMarker!) -> UIView! {
        let infoView = UIView()
        infoView.frame = CGRectMake(0, 0, 200, 70)
        infoView.backgroundColor = UIColor.grayColor()
        
        let label = UILabel()
        label.frame = CGRectMake(14, 11, 175, 16)
        label.text = marker.title
        
        infoView.addSubview(label)
        
        return infoView
    }

    func mapView(mapView: GMSMapView!, didTapInfoWindowOfMarker marker: GMSMarker!) {
        
        let alertVC = UIAlertController(title: "Test", message: "Displayed after tapping Info view", preferredStyle: .Alert)
        
        let closeButton = UIAlertAction(title: "Close", style: UIAlertActionStyle.Default, handler: nil)
        alertVC.addAction(closeButton)
        
        self.presentViewController(alertVC, animated: true, completion: nil)
    }
    
    private func setupConstraints() {
        let views = ["currentLocationMarker": self.currentLocationMarker, "locationSearchField": self.locationSearchField, "searchResultsTableView": self.searchResultsTableView]
        let currentLocationMarkerHeight = self.currentLocationMarker.frame.size.height
        
        self.view.addConstraint(NSLayoutConstraint(item: self.currentLocationMarker, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: (currentLocationMarkerHeight/2)*(-1)))
        
        self.view.addConstraint(NSLayoutConstraint(item: self.currentLocationMarker, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0))

        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[locationSearchField]|", options: NSLayoutFormatOptions.AlignAllTop, metrics: nil, views: views))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[locationSearchField]-8-[searchResultsTableView(300)]", options: NSLayoutFormatOptions.AlignAllLeft, metrics: nil, views: views))

        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-8-[searchResultsTableView]-8-|", options: .AlignAllLeft, metrics: nil, views: views))
    }
    
    func mapView(mapView: GMSMapView!, didChangeCameraPosition position: GMSCameraPosition!) {
        
    }
    
    func mapView(mapView: GMSMapView!, idleAtCameraPosition position: GMSCameraPosition!) {
        let center = mapView.center
        
        let coordinate = mapView.projection.coordinateForPoint(center)

        let geocoder = GMSGeocoder()
        
        geocoder.reverseGeocodeCoordinate(coordinate) { (response:GMSReverseGeocodeResponse!, error:NSError!) -> Void in
            self.locationSearchField.text = response.firstResult().thoroughfare
        }
        
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        GMSPlacesClient.sharedClient().autocompleteQuery(searchText, bounds: nil, filter: nil) { (results:[AnyObject]?, error:NSError?) -> Void in
            self.searchResults = results
            if self.searchResults?.count > 0 {
                self.searchResultsTableView.hidden = false
                self.searchResultsTableView.reloadData()
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) 
        
        let address = self.searchResults![indexPath.row] as! GMSAutocompletePrediction
        
        cell.textLabel?.text = address.attributedFullText.string
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let prediction = self.searchResults![indexPath.row] as! GMSAutocompletePrediction
        
        GMSPlacesClient.sharedClient().lookUpPlaceID(prediction.placeID) { (place:GMSPlace?, error:NSError?) -> Void in
            if let place = place {
                self.setupMarker(place)
                
                self.searchResults? = []
                self.searchResultsTableView.hidden = true
            }
        }
        
    }
    
    func keyboardWillAppear(notification:NSNotification) {
        
    }
    
    private func setupMarker(place:GMSPlace) {
        
        let cameraUpdate = GMSCameraUpdate.setTarget(place.coordinate)
        self.mapView.animateWithCameraUpdate(cameraUpdate)
        
//        let marker = GMSMarker(position: place.coordinate)
//        marker.title = place.name
//        marker.map = self.mapView
        
    }
    
}


func unless(@autoclosure test: () -> Bool, action: () -> ()) {
    if !test() { action() }
}



