//
//  AppDelegate.swift
//  CheckWeather
//
//  Created by TTN on 24/04/18.
//  Copyright © 2018 Developer. All rights reserved.
//


import Foundation
import CoreLocation
import PromiseKit


class LocationHelper  {
  let coder = CLGeocoder()
  
  func getLocation() -> Promise<CLPlacemark> {    
    return CLLocationManager.promise().then { location in
      return self.coder.reverseGeocode(location: location)
    }
  }
  
  func searchForPlacemark(text: String) -> Promise<CLPlacemark> {
    return CLGeocoder().geocode(text)
  }
  
}
