

import Foundation
import UIKit
import PromiseKit
import CoreLocation

private let errorColor = UIColor(red: 0.96, green: 0.667, blue: 0.690, alpha: 1)
private let oneHour: TimeInterval = 3600 //Seconds per hour


class WeatherViewController: UIViewController {
  
  @IBOutlet weak var placeLabel: UILabel! 
  @IBOutlet weak var tempLabel: UILabel!
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var conditionLabel: UILabel!
  
  let weatherAPI = WeatherHelper()
  let locationHelper = LocationHelper()
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    updateWithCurrentLocation()
  }
  
  private func updateWithCurrentLocation() {
    
    _ = locationHelper.getLocation().then { placemark in
      self.handleLocation(placemark: placemark)
      }.catch { error in
        self.tempLabel.text = "--"
        self.placeLabel.text = "--"
        switch error {
        case is CLError where (error as! CLError).code == CLError.Code.denied:
          self.conditionLabel.text = "Enable Location Permissions in Settings"
          self.conditionLabel.textColor = UIColor.white
        default:
          self.conditionLabel.text = error.localizedDescription
          self.conditionLabel.textColor = errorColor
        }
    }
    
    _ = after(interval: oneHour).then {
      self.updateWithCurrentLocation()
    }
  }
  
  fileprivate func handleMockLocation() {
    self.handleLocation(city: "Athens", state: "Greece", latitude: 37.966667, longitude: 23.716667)
  }
  
  
  func handleLocation(placemark: CLPlacemark) {
    handleLocation(city: placemark.locality,
                   state: placemark.administrativeArea,
                   latitude:  placemark.location!.coordinate.latitude,
                   longitude: placemark.location!.coordinate.longitude)
  }
  
  func handleLocation(city: String?, state: String?,
                      latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
    if let city = city, let state = state {
      self.placeLabel.text = "\(city), \(state)"
    }
    
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    
    _ = weatherAPI.getWeather(latitude: latitude, longitude: longitude).then { weather -> Promise<UIImage> in
      self.updateUIWithWeather(weather: weather)
      return self.weatherAPI.getIcon(named: weather.iconName)
      
      }.then(on: DispatchQueue.main) { icon -> Void in
        self.iconImageView.image = icon
        
      }.catch { error in
        self.tempLabel.text = "--"
        self.conditionLabel.text = error.localizedDescription
        self.conditionLabel.textColor = errorColor
        
      }.always {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
  }

  private func updateUIWithWeather(weather: WeatherHelper.Weather) {
    let tempMeasurement = Measurement(value: weather.tempInK, unit: UnitTemperature.kelvin)
    let formatter = MeasurementFormatter()
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .none
    formatter.numberFormatter = numberFormatter
    let tempStr = formatter.string(from: tempMeasurement)
    self.tempLabel.text = tempStr
    self.conditionLabel.text = weather.text
    self.conditionLabel.textColor = UIColor.white
  }
  
  
}


// MARK: - UITextFieldDelegate

extension WeatherViewController: UITextFieldDelegate {
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    
    textField.resignFirstResponder()
    
    guard let text = textField.text else { return true }
    _ = locationHelper.searchForPlacemark(text: text).then { placemark -> Void in
      self.handleLocation(placemark: placemark)
    }
    return true
  }
  
}
