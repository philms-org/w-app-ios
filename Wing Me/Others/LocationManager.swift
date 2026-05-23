
import UIKit
import CoreLocation

extension AppDelegate: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = getBestAccuracy(locations: locations) else {
            return
        }
        longitude = location.coordinate.longitude
        latitude = location.coordinate.latitude
        
        let accuracy: Double = 60
        
        if location.horizontalAccuracy <= accuracy && location.verticalAccuracy <= accuracy {
            checkLocation(location: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager?.stopUpdatingLocation()
    }
    
    func getLocations() {
        let url = URL(string: Constants.url + "get_location_category.php")!
        let postString = "language=\(Strings.language)"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: .utf8)
        
        if let token = UserDefaults.standard.object(forKey: "Token") as? String {
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            
            guard let data = data, error == nil else {
                let delay = DispatchTime.now() + 2
                DispatchQueue.main.asyncAfter(deadline: delay, execute: {
                    self.locationsError()
                })
                return
            }
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as AnyObject {
                DispatchQueue.main.async {
                    print(jsonObject)
                    self.locationsSuccess(jsonObject: jsonObject)
                }
            } else {
                let responseString = String(data: data, encoding: .utf8)
                print(responseString as AnyObject)
            }
        }
        task.resume()
    }
    
    func locationsError() {
        request()
    }
    
    func locationsSuccess(jsonObject: AnyObject) {
        if let error = jsonObject["error"] as? String {
            if error == "0" {
                if let message = jsonObject["message"] as? [NSDictionary] {
                    for each in message {
                        if let location = each["location"] as? [NSDictionary] {
                            for each in location {
                                array.append(CustomCell.init(string1: each.getString(key: "Id"),
                                                             string2: each.getString(key: "name"),
                                                             string3: each.getString(key: "description"),
                                                             latitude: each.getDouble(key: "google_latitude"),
                                                             longitude: each.getDouble(key: "google_longitude"),
                                                             radius: each.getDouble(key: "radius")))
                            }
                        }
                    }
                    if array.isEmpty {
                        return
                    }
                    locationManager?.startMonitoringSignificantLocationChanges()
                }
            }
        }
    }
    
    func getBestAccuracy(locations: [CLLocation]) -> CLLocation? {
        guard let firstLocation = locations.first else {
            return nil
        }
        let accuracy = sqrt(pow(firstLocation.horizontalAccuracy, 2) + pow(firstLocation.verticalAccuracy, 2))
        
        var minAccuracy = accuracy
        var bestLoccation = firstLocation
        
        for each in locations {
            let accuracy = sqrt(pow(each.horizontalAccuracy, 2) + pow(each.verticalAccuracy, 2))
            
            if accuracy < minAccuracy {
                minAccuracy = accuracy
                bestLoccation = each
            }
        }
        return bestLoccation
    }
    
    func checkLocation(location: CLLocation) {
        let token = UserDefaults.getString(key: "Token")
        let locationID = UserDefaults.getString(key: "LocationID")
        
        if token.isEmpty {
            return
        }
        if locationID.contains("Event") {
            return
        }
        var locations: [CustomCell] = []
        
        if inLocation {
            let accuracy = sqrt(pow(location.horizontalAccuracy, 2) + pow(location.verticalAccuracy, 2))
            
            for each in array {
                let userCoordinates = CLLocation(latitude: latitude, longitude: longitude)
                let locationCoordinates = CLLocation(latitude: each.latitude, longitude: each.longitude)
                let distance = userCoordinates.distance(from: locationCoordinates)
                
                if accuracy < 20 {
                    if distance <= each.radius + 20 {
                        locations.append(each)
                    }
                } else {
                    if distance <= each.radius + accuracy {
                        locations.append(each)
                    }
                }
            }
            if locations.isEmpty {
                inLocation = false
                
                UserDefaults.standard.removeObject(forKey: "LocationID")
                UserDefaults.standard.removeObject(forKey: "LocationName")
                UserDefaults.standard.removeObject(forKey: "LastLocationAlert")
                UserDefaults.standard.removeObject(forKey: "LastLocationNotification")
            } else {
                let locationID = UserDefaults.getString(key: "LastLocationNotification")
                
                if !locations.contains(where: {
                    customCell in
                    customCell.string1 == locationID
                }) {
                    sendNotification(array: locations)
                    
                    UserDefaults.standard.removeObject(forKey: "LocationID")
                    UserDefaults.standard.removeObject(forKey: "LocationName")
                }
            }
        } else {
            for each in array {
                let userCoordinates = CLLocation(latitude: latitude, longitude: longitude)
                let locationCoordinates = CLLocation(latitude: each.latitude, longitude: each.longitude)
                let distance = userCoordinates.distance(from: locationCoordinates)
                
                if distance <= each.radius + 10 {
                    locations.append(each)
                }
            }
            if locations.isEmpty {
                UserDefaults.standard.removeObject(forKey: "LocationID")
                UserDefaults.standard.removeObject(forKey: "LocationName")
                UserDefaults.standard.removeObject(forKey: "LastLocationAlert")
                UserDefaults.standard.removeObject(forKey: "LastLocationNotification")
            } else {
                inLocation = true
                
                let locationID = UserDefaults.getString(key: "LocationID")
                
                if locations.contains(where: {
                    customCell in
                    customCell.string1 == locationID
                }) {
                    
                } else {
                    sendNotification(array: locations)
                }
            }
        }
    }
    
    func sendNotification(array: [CustomCell]) {
        for each in array {
            UserDefaults.standard.removeObject(forKey: "LastLocationAlert")
            UserDefaults.standard.set(each.string1, forKey: "LastLocationNotification")
            
            let notificationCenter = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = "New Wing Me Location"
            content.body = "Have you been to \(each.string2!)"
            let request = UNNotificationRequest(identifier: "Identifier", content: content, trigger: nil)
            notificationCenter.add(request, withCompletionHandler: nil)
        }
    }
}
