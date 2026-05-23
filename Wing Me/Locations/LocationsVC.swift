
import UIKit
import GoogleMaps
import CoreLocation
import GoogleMapsUtils

class LocationsVC: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate, GMSMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var processingView: UIViewDesignable!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var locationsView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noPermissionView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    let locationManager = CLLocationManager()
    
    var categoriesArray: [CustomCell] = []
    var visibleCategoriesArray: [CustomCell] = []
    
    var locationsArray: [CustomCell] = []
    var searchArray: [CustomCell] = []
    
    var delegate: MainVC!
    var accurateLocation: CLLocation?
    var timer: Timer!
    
    var lastCategory = Int()
    var lastVisibleCategory = Int()
    
    var longitude = Double()
    var latitude = Double()
    var allowed = Bool()
    var isList = Bool()
    var once = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
        searchTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        if #available(iOS 14.0, *) {
            if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                requestPermission()
            }
        } else {
            noPermissionView.isHidden = true
            requestPermission()
        }
        processingView.isHidden = true
        setList()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            allowed = true
            
            locationManager.requestAlwaysAuthorization()
            
            noPermissionView.isHidden = true
            indicator.startAnimating()
            setTimer()
        } else if status == .authorizedAlways {
            if allowed {
                return
            }
            noPermissionView.isHidden = true
            indicator.startAnimating()
            setTimer()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = getBestAccuracy(locations: locations) else {
            return
        }
        longitude = location.coordinate.longitude
        latitude = location.coordinate.latitude
        
        let accuracy: Double = 40
        
        if location.horizontalAccuracy <= accuracy && location.verticalAccuracy <= accuracy {
            processingView.isHidden = true
            accurateLocation = location
            checkLocation()
        } else if let location = mapView.myLocation, location.horizontalAccuracy <= accuracy, location.verticalAccuracy <= accuracy {
            processingView.isHidden = true
            accurateLocation = location
            checkLocation()
        } else {
            processingView.isHidden = false
        }
        if once {
            return
        }
        let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16)
        mapView.camera = camera
        
        once = true
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        indicator.stopAnimating()
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        guard let id = marker.snippet else {
            return false
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "SingleLocationVC") as? SingleLocationVC {
            viewController.id = id
            delegate.present(viewController, animated: true, completion: nil)
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isList {
            return visibleCategoriesArray.count
        } else {
            return categoriesArray.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isList {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
            cell.updateCell(customCell: visibleCategoriesArray[indexPath.row])
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
            cell.updateCell(customCell: categoriesArray[indexPath.row])
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if isList {
            let fontAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)]
            let width = (visibleCategoriesArray[indexPath.row].string2 as NSString).size(withAttributes: fontAttributes).width
            return CGSize(width: width + 50, height: collectionView.frame.height)
        } else {
            let fontAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)]
            let width = (categoriesArray[indexPath.row].string2 as NSString).size(withAttributes: fontAttributes).width
            return CGSize(width: width + 50, height: collectionView.frame.height)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isList {
            visibleCategoriesArray[lastVisibleCategory].isSelected = false
            visibleCategoriesArray[indexPath.row].isSelected = true
            lastVisibleCategory = indexPath.row
            collectionView.reloadData()
            
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            
            setSearchArray()
            
            if !searchArray.isEmpty {
                tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
        } else {
            categoriesArray[lastCategory].isSelected = false
            categoriesArray[indexPath.row].isSelected = true
            lastCategory = indexPath.row
            collectionView.reloadData()
            
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            
            mapView.clear()
            setMapIcons()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath) as! LocationCell
        cell.updateCell(customCell: searchArray[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let customCell = searchArray[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "SingleLocationVC") as? SingleLocationVC {
            viewController.id = customCell.string1
            delegate.present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func requestPermission(_ sender: UIButton) {
        requestPermission()
    }
    
    @IBAction func viewList(_ sender: UIButton) {
        visibleCategoriesArray = []
        
        lastVisibleCategory = 0
        
        let region = self.mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(region: region)
        
        for category in categoriesArray {
            var locationsArray: [CustomCell] = []
            
            for each in category.array {
                let isLatitude = each.latitude > bounds.southWest.latitude && each.latitude < bounds.northEast.latitude
                let isLongitude = each.longitude > bounds.southWest.longitude && each.longitude < bounds.northEast.longitude
                
                if isLatitude && isLongitude {
                    locationsArray.append(each)
                }
            }
            if !locationsArray.isEmpty {
                visibleCategoriesArray.append(CustomCell.init(string1: category.string1,
                                                              string2: category.string2,
                                                              isSelected: visibleCategoriesArray.isEmpty,
                                                              count: category.count,
                                                              array: locationsArray))
            }
        }
        isList = true
        locationsView.isHidden = false
        
        setSearchArray()
        
        collectionView.reloadData()
        tableView.reloadData()
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            self.locationsView.transform = .identity
        }, completion: nil)
    }
    
    @IBAction func viewMap(_ sender: UIButton) {
        isList = false
        collectionView.reloadData()
        tableView.reloadData()
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: {
            self.locationsView.transform = CGAffineTransform(translationX: 0, y: self.locationsView.frame.height)
        }, completion: nil)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        setSearchArray()
    }
    
    func setSearchArray() {
        if visibleCategoriesArray.isEmpty {
            searchArray = []
            return
        }
        if searchTextField.getText().isEmpty {
            searchArray = visibleCategoriesArray[lastVisibleCategory].array
        } else {
            searchArray = []
            
            for each in visibleCategoriesArray[lastVisibleCategory].array {
                if each.string2.lowercased().starts(with: searchTextField.getText().lowercased()) {
                    searchArray.append(each)
                }
            }
        }
        tableView.reloadSections([0], with: .automatic)
    }
    
    func setList() {
        locationsView.isHidden = true
        locationsView.transform = CGAffineTransform(translationX: 0, y: locationsView.frame.height)
    }
    
    func requestPermission() {
        if CLLocationManager.locationServicesEnabled() {
            if #available(iOS 14.0, *) {
                if locationManager.authorizationStatus == .denied {
                    if let bundleId = Bundle.main.bundleIdentifier, let url = URL(string: "\(UIApplication.openSettingsURLString)&path=LOCATION/\(bundleId)") {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            }
            locationManager.delegate = self
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.requestWhenInUseAuthorization()
        } else {
            locationManager.startUpdatingLocation()
        }
    }
    
    func setTimer() {
        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(request), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: .common)
        
        request()
    }
    
    @objc func request() {
        let token = UserDefaults.getString(key: "Token")
        
        if token.isEmpty {
            timer.invalidate()
            return
        }
        let path = "get_location_category.php"
        
        let params: NSDictionary = [
            "language": Strings.language
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        indicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? [NSDictionary] {
            categoriesArray = []
            locationsArray = []
            
            var totalCount = 0
            
            for each in message {
                var array: [CustomCell] = []
                var count = 0
                
                if let location = each["location"] as? [NSDictionary] {
                    for each in location {
                        let customCell = getLocation(dictionary: each, tableView: tableView)
                        array.append(customCell)
                        count += customCell.count
                        locationsArray.append(customCell)
                    }
                }
                totalCount += count
                
                categoriesArray.append(CustomCell.init(string1: each.getString(key: "Id"),
                                                       string2: each.getString(key: "name"),
                                                       isSelected: false,
                                                       count: count,
                                                       array: array))
            }
            categoriesArray.insert(CustomCell.init(string1: "",
                                                   string2: "All",
                                                   isSelected: true,
                                                   count: totalCount,
                                                   array: locationsArray), at: 0)
            
            searchArray = locationsArray
            setMap()
            collectionView.reloadData()
            tableView.reloadData()
        }
    }
    
    func getLocation(dictionary: NSDictionary, tableView: UITableView) -> CustomCell {
        let imageView = UIImageView()
        imageView.imageFromServerURL(urlString: dictionary.getString(key: "image"),
                                     tableView: tableView)
        
        let customCell = CustomCell.init(imageView: imageView,
                                         string1: dictionary.getString(key: "Id"),
                                         string2: dictionary.getString(key: "name"),
                                         string3: dictionary.getString(key: "description"),
                                         latitude: dictionary.getDouble(key: "google_latitude"),
                                         longitude: dictionary.getDouble(key: "google_longitude"),
                                         count: dictionary.getInt(key: "user_count"),
                                         radius: dictionary.getDouble(key: "radius"))
        
        return customCell
    }
    
    func setMap() {
        mapView.isMyLocationEnabled = true
        
        do {
            mapView.mapStyle = try GMSMapStyle(jsonString: MapStyle.kMapStyle)
        } catch {}
        
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.startUpdatingLocation()
        
        if categoriesArray.isEmpty {
            return
        }
        setMapIcons()
    }
    
    func setMapIcons() {
        mapView.clear()
        
        let locations = categoriesArray[lastCategory].array!
        
        for each in locations {
            let location = CLLocationCoordinate2D(latitude: each.latitude, longitude: each.longitude)
            
            let marker = GMSMarker()
            marker.position = location
            marker.title = each.string2
            marker.snippet = each.string1
            marker.icon = imageWithImage(image: UIImage(named: "icon_pin")!, scaledToSize: CGSize(width: 60, height: 60))
            marker.map = mapView
            
            if Constants.beta {
                let circle = GMSCircle()
                circle.position = location
                circle.radius = each.radius + 10
                circle.strokeWidth = 2
                circle.strokeColor = Colors.blue
                circle.map = mapView
            }
            if each.count > 0 {
                let heatmapLayer = GMUHeatmapTileLayer()
                let gradientColors: [UIColor] = [Colors.blue]
                
                var gradientStartPoints: [NSNumber] = []
                
                if each.count <= 2 {
                    gradientStartPoints = [0.2]
                } else if each.count <= 4 {
                    gradientStartPoints = [0.4]
                } else if each.count <= 8 {
                    gradientStartPoints = [0.6]
                } else if each.count <= 16 {
                    gradientStartPoints = [0.8]
                } else {
                    gradientStartPoints = [1.0]
                }
                heatmapLayer.weightedData = [GMUWeightedLatLng(coordinate: CLLocationCoordinate2DMake(each.latitude, each.longitude), intensity: 1.0)]
                heatmapLayer.gradient = GMUGradient(colors: gradientColors, startPoints: gradientStartPoints, colorMapSize: 256)
                heatmapLayer.radius = 100
                heatmapLayer.opacity = 0.6
                heatmapLayer.map = mapView
            }
        }
    }
    
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
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
    
    func checkLocation() {
        let token = UserDefaults.getString(key: "Token")
        let locationID = UserDefaults.getString(key: "LocationID")
        
        if token.isEmpty {
            return
        }
        if locationID.contains("Event") {
            return
        }
        guard let location = accurateLocation else {
            return
        }
        var locations: [CustomCell] = []
        
        if appDelegate.inLocation {
            let accuracy = sqrt(pow(location.horizontalAccuracy, 2) + pow(location.verticalAccuracy, 2))
            
            for each in locationsArray {
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
                appDelegate.inLocation = false
                delegate.hideLocation()
                
                UserDefaults.standard.removeObject(forKey: "LocationID")
                UserDefaults.standard.removeObject(forKey: "LocationName")
                UserDefaults.standard.removeObject(forKey: "LastLocationAlert")
                UserDefaults.standard.removeObject(forKey: "LastLocationNotification")
            } else {
                let locationID = UserDefaults.getString(key: "LastLocationAlert")
                
                if !locations.contains(where: {
                    customCell in
                    customCell.string1 == locationID
                }) {
                    delegate.hideLocation()
                    
                    if appDelegate.isBackground {
                        sendNotification(array: locations)
                    }
                    showAlert(array: locations)
                    
                    UserDefaults.standard.removeObject(forKey: "LocationID")
                    UserDefaults.standard.removeObject(forKey: "LocationName")
                }
            }
        } else {
            for each in locationsArray {
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
                appDelegate.inLocation = true
                
                let locationID = UserDefaults.getString(key: "LocationID")
                let locationName = UserDefaults.getString(key: "LocationName")
                
                if locations.contains(where: {
                    customCell in
                    customCell.string1 == locationID
                }) {
                    let customCell = CustomCell.init(string1: locationID,
                                                     string2: locationName)
                    delegate.wingMe(customCell)
                } else {
                    delegate.hideLocation()
                    
                    if appDelegate.isBackground {
                        sendNotification(array: locations)
                    }
                    showAlert(array: locations)
                    
                    UserDefaults.standard.removeObject(forKey: "LocationID")
                    UserDefaults.standard.removeObject(forKey: "LocationName")
                }
            }
        }
    }
    
    func sendNotification(array: [CustomCell]) {
        for each in array {
            let notificationCenter = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = "New Wing Me Location"
            content.body = "Have you been to \(each.string2!)"
            let request = UNNotificationRequest(identifier: "Identifier", content: content, trigger: nil)
            notificationCenter.add(request, withCompletionHandler: nil)
        }
    }
    
    func showAlert(array: [CustomCell]) {
        let alertTitle = "Greetings \(UserDefaults.getString(key: "FirstName"))"
        
        if array.count > 1 {
            let alertBody = "You have entered a Wing Me location, may I wing you?"
            let alert = UIAlertController(title: alertTitle, message: alertBody, preferredStyle: .alert)
            
            for each in array {
                UserDefaults.standard.set(each.string1, forKey: "LastLocationAlert")
                UserDefaults.standard.set(each.string1, forKey: "LastLocationNotification")
                
                alert.addAction(UIAlertAction(title: "Wing me into \(each.string2!)", style: .default, handler: {
                    _ in
                    self.delegate.wingMe(each)
                    self.delegate.selectTab(tag: 3)
                }))
            }
            alert.addAction(UIAlertAction(title: Strings.maybeLater, style: .destructive, handler: nil))
            delegate.present(alert, animated: true, completion: nil)
        } else {
            guard let customCell = array.first else {
                return
            }
            UserDefaults.standard.set(customCell.string1, forKey: "LastLocationAlert")
            UserDefaults.standard.set(customCell.string1, forKey: "LastLocationNotification")
            
            let alertBody = "You have entered a Wing Me location, may I wing you into \(customCell.string2!)?"
            let alert = UIAlertController(title: alertTitle, message: alertBody, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Strings.maybeLater, style: .destructive, handler: nil))
            
            alert.addAction(UIAlertAction(title: "Wing me", style: .default, handler: {
                _ in
                self.delegate.wingMe(customCell)
                self.delegate.selectTab(tag: 3)
            }))
            delegate.present(alert, animated: true, completion: nil)
        }
    }
}
