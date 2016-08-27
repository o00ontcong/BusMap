//
//  ViewController.swift
//  BusMap
//
//  Created by MAC on 11/07/2016.
//  Copyright © 2016 o00ontcong. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation

class ViewController: UIViewController, GMSMapViewDelegate,  UISearchBarDelegate, LocateOnTheMap {
    
    var locationManager = CLLocationManager()
    
    var didFindMyLocation = false
    
    var mapTasks = MapTasks()
    
    var locationMarker: GMSMarker!
    
    var originMarker: GMSMarker!
    
    var destinationMarker: GMSMarker!
    
    var routePolyline: GMSPolyline!
    
    var markersArray: Array<GMSMarker> = []
    
    var waypointsArray: Array<String> = []
    
    var travelMode = TravelModes.driving
    
    var searchResultController: SearchResultsController!
    var resultsArray = [String]()
    
    @IBOutlet weak var btnBusShow: UIButton!
    var busShow : Bool = false
    @IBAction func abtnBusShow(sender: AnyObject) {
        if busShow == false {
            busShow = true
            btnBusShow.setImage(UIImage(named: "busOn"), forState: .Normal)
        }
        else {
            busShow = false
            btnBusShow.setImage(UIImage(named: "busOff"), forState: .Normal)
        }
        
    }
    
    @IBAction func abtnDirection(sender: AnyObject) {
        let addressAlert = UIAlertController(title: "Create Route", message: "Connect locations with a route:", preferredStyle: UIAlertControllerStyle.Alert)
        
        addressAlert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Origin?"
        }
        
        addressAlert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Destination?"
        }
        
        
        let createRouteAction = UIAlertAction(title: "Create Route", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            if self.routePolyline != nil {
                self.clearRoute()
                self.waypointsArray.removeAll(keepCapacity: false)
            }
            
            let origin : String! = (addressAlert.textFields![0] ).text
            let destination : String! = (addressAlert.textFields![1] ).text
            
            self.mapTasks.getDirections(origin, destination: destination, waypoints: nil, travelMode: self.travelMode, completionHandler: { (status, success) -> Void in
                if success {
                    self.configureMapAndMarkersForRoute()
                    self.drawRoute()
                    self.displayRouteInfo()
                }
                else {
                    print("view direction status: \(status)")
                }
            })
        }
        
        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
            
        }
        
        addressAlert.addAction(createRouteAction)
        addressAlert.addAction(closeAction)
        
        presentViewController(addressAlert, animated: true, completion: nil)
    }
    
    
    @IBOutlet weak var viewMap: GMSMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let camera: GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(10.762124, longitude: 106.682897, zoom: 15)
        viewMap.camera = camera
        viewMap.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.New, context: nil)
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        searchResultController = SearchResultsController()
        searchResultController.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func showAlertWithMessage(message: String) {
        let alertController = UIAlertController(title: "GMapsDemo", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
            
        }
        
        alertController.addAction(closeAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: router
    
    func configureMapAndMarkersForRoute() {
        viewMap.camera = GMSCameraPosition.cameraWithTarget(mapTasks.originCoordinate, zoom: 9.0)
        
        originMarker = GMSMarker(position: self.mapTasks.originCoordinate)
        originMarker.map = self.viewMap
        originMarker.icon = GMSMarker.markerImageWithColor(UIColor.greenColor())
        originMarker.title = self.mapTasks.originAddress
        
        destinationMarker = GMSMarker(position: self.mapTasks.destinationCoordinate)
        destinationMarker.map = self.viewMap
        destinationMarker.icon = GMSMarker.markerImageWithColor(UIColor.redColor())
        destinationMarker.title = self.mapTasks.destinationAddress
        
        
        if waypointsArray.count > 0 {
            for waypoint in waypointsArray {
                let lat: Double = (waypoint.componentsSeparatedByString(",")[0] as NSString).doubleValue
                let lng: Double = (waypoint.componentsSeparatedByString(",")[1] as NSString).doubleValue
                
                let marker = GMSMarker(position: CLLocationCoordinate2DMake(lat, lng))
                marker.map = viewMap
                marker.icon = GMSMarker.markerImageWithColor(UIColor.purpleColor())
                
                markersArray.append(marker)
            }
        }
    }
    
    
    func drawRoute() {
        let route = mapTasks.overviewPolyline["points"] as! String
        
        let path: GMSPath = GMSPath(fromEncodedPath: route)!
        routePolyline = GMSPolyline(path: path)
        routePolyline.map = viewMap
    }
    
    
    func displayRouteInfo() {
        print("mapTasks: \(mapTasks.totalDistance + "\n" + mapTasks.totalDuration)")
    }
    
    
    func clearRoute() {
        originMarker.map = nil
        destinationMarker.map = nil
        routePolyline.map = nil
        
        originMarker = nil
        destinationMarker = nil
        routePolyline = nil
        
        if markersArray.count > 0 {
            for marker in markersArray {
                marker.map = nil
            }
            
            markersArray.removeAll(keepCapacity: false)
        }
    }
    
    
    func recreateRoute() {
        if routePolyline != nil {
            clearRoute()
            
            mapTasks.getDirections(mapTasks.originAddress, destination: mapTasks.destinationAddress, waypoints: waypointsArray, travelMode: travelMode, completionHandler: { (status, success) -> Void in
                
                if success {
                    self.configureMapAndMarkersForRoute()
                    self.drawRoute()
                    self.displayRouteInfo()
                }
                else {
                    print("recreateRoute status: \(status)")
                }
            })
        }
    }
    
    
    //MARK: search
    
    @IBAction func abtnSearch(sender: AnyObject) {
        
        let searchController = UISearchController(searchResultsController: searchResultController)
        searchController.searchBar.delegate = self
        self.presentViewController(searchController, animated: true, completion: nil)
        
    }
    func locateWithLongitude(lon: Double, andLatitude lat: Double, andTitle title: String) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            let position = CLLocationCoordinate2DMake(lat, lon)
            //            let marker = GMSMarker(position: position)
            
            let camera = GMSCameraPosition.cameraWithLatitude(lat, longitude: lon, zoom: 14)
            self.viewMap.camera = camera
            

            if (self.locationMarker != nil){
                self.locationMarker.map = nil
            }
            self.locationMarker = GMSMarker(position: position)
            self.locationMarker.title = "Address : \(title)"
            self.locationMarker.map = self.viewMap
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        let placeClient = GMSPlacesClient()
        placeClient.autocompleteQuery(searchText, bounds: nil, filter: nil) { (results, error: NSError?) -> Void in
            
            self.resultsArray.removeAll()
            if results == nil {
                return
            }
            
            for result in results! {
                if let result: GMSAutocompletePrediction = result  {
                    self.resultsArray.append(result.attributedFullText.string)
                }
            }
            
            self.searchResultController.reloadDataWithArray(self.resultsArray)
            
        }
    }
    
    
}

extension ViewController : CLLocationManagerDelegate {
    
    
    

    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
            viewMap.myLocationEnabled = true
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if !didFindMyLocation {
            let myLocation : CLLocation = change![NSKeyValueChangeNewKey] as! CLLocation
            viewMap.camera = GMSCameraPosition.cameraWithTarget(myLocation.coordinate, zoom: 15)
            viewMap.settings.myLocationButton = true
            
            didFindMyLocation = true
        }
    }
}


