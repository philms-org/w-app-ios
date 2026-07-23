
import UIKit
import GoogleMaps
import CoreLocation
import GoogleMapsUtils

class LocationsVC: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate, GMSMapViewDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource {

    @IBOutlet weak var processingView: UIViewDesignable!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var locationsView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noPermissionView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    let locationManager = CLLocationManager()

    var venues: [WAPVenue] = []
    var filteredVenues: [WAPVenue] = []

    var delegate: MainVC!
    var accurateLocation: CLLocation?
    var timer: Timer!

    var longitude = Double()
    var latitude = Double()
    var allowed = Bool()
    var isList = Bool()
    var once = Bool()

    override func viewDidLoad() {
        super.viewDidLoad()
        setKeyboard()
        collectionView.isHidden = true
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

    // MARK: - UITableViewDataSource / Delegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredVenues.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath) as? LocationCell else {
            return UITableViewCell()
        }
        cell.updateCell(venue: filteredVenues[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let venue = filteredVenues[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "SingleLocationVC") as? SingleLocationVC {
            viewController.id = venue.id
            delegate.present(viewController, animated: true, completion: nil)
        }
    }

    // MARK: - Category chips (collectionView is hidden; no backing data yet)

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath)
    }

    // MARK: - IBActions

    @IBAction func requestPermission(_ sender: UIButton) {
        requestPermission()
    }

    @IBAction func viewList(_ sender: UIButton) {
        isList = true
        locationsView.isHidden = false
        tableView.reloadData()

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            self.locationsView.transform = .identity
        }, completion: nil)
    }

    @IBAction func viewMap(_ sender: UIButton) {
        isList = false
        tableView.reloadData()

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: {
            self.locationsView.transform = CGAffineTransform(translationX: 0, y: self.locationsView.frame.height)
        }, completion: nil)
    }

    // MARK: - Search

    @objc func textFieldDidChange(_ textField: UITextField) {
        let query = (textField.text ?? "").lowercased()
        filteredVenues = query.isEmpty ? venues : venues.filter {
            $0.name.lowercased().contains(query) ||
            ($0.address?.lowercased().contains(query) ?? false)
        }
        tableView.reloadData()
    }

    // MARK: - Setup

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
        setMap()
        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(request), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: .common)
        request()
    }

    // MARK: - Data

    @objc func request() {
        guard WAPAuth.currentUserID != nil else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let fetched = try await WAPData.shared.fetchVenues()
                await MainActor.run {
                    self.venues = fetched
                    self.filteredVenues = fetched
                    self.tableView.reloadData()
                    self.addMapMarkers()
                    self.indicator.stopAnimating()
                }
            } catch {
                await MainActor.run {
                    self.indicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Map

    func setMap() {
        mapView.isMyLocationEnabled = true

        do {
            mapView.mapStyle = try GMSMapStyle(jsonString: MapStyle.kMapStyle)
        } catch {}

        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.startUpdatingLocation()
    }

    private func addMapMarkers() {
        mapView.clear()
        for venue in venues {
            guard let lat = venue.lat, let lng = venue.lng else { continue }
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            marker.title = venue.name
            marker.snippet = venue.id
            if let pin = UIImage(named: "icon_pin") {
                marker.icon = imageWithImage(image: pin, scaledToSize: CGSize(width: 60, height: 60))
            }
            marker.map = mapView
        }
    }

    func imageWithImage(image: UIImage, scaledToSize newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
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

    // MARK: - Geofence

    func checkLocation() {
        guard WAPAuth.currentUserID != nil else { return }
        let locationID = UserDefaults.getString(key: "LocationID")
        if locationID.contains("Event") { return }
        guard let loc = accurateLocation else { return }

        let userCoord = CLLocation(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
        let accuracy = sqrt(pow(loc.horizontalAccuracy, 2) + pow(loc.verticalAccuracy, 2))

        var nearby: [WAPVenue] = []
        for venue in venues {
            guard let lat = venue.lat, let lng = venue.lng else { continue }
            let radius = Double(venue.geofenceRadiusMeters ?? 50)
            let dist = userCoord.distance(from: CLLocation(latitude: lat, longitude: lng))
            if dist <= radius + (accuracy < 20 ? 20 : accuracy) {
                nearby.append(venue)
            }
        }

        if appDelegate.inLocation {
            if nearby.isEmpty {
                appDelegate.inLocation = false
                delegate.hideLocation()
                ["LocationID", "LocationName", "LastLocationAlert", "LastLocationNotification"]
                    .forEach { UserDefaults.standard.removeObject(forKey: $0) }
            } else {
                let lastID = UserDefaults.getString(key: "LastLocationAlert")
                if !nearby.contains(where: { $0.id == lastID }) {
                    delegate.hideLocation()
                    if appDelegate.isBackground { sendNotification(venues: nearby) }
                    showVenueAlert(venues: nearby)
                    UserDefaults.standard.removeObject(forKey: "LocationID")
                    UserDefaults.standard.removeObject(forKey: "LocationName")
                }
            }
        } else {
            if !nearby.isEmpty {
                appDelegate.inLocation = true
                let storedID = UserDefaults.getString(key: "LocationID")
                if nearby.contains(where: { $0.id == storedID }) {
                    let name = UserDefaults.getString(key: "LocationName")
                    delegate.wingIn(CustomCell(string1: storedID, string2: name))
                } else {
                    delegate.hideLocation()
                    if appDelegate.isBackground { sendNotification(venues: nearby) }
                    showVenueAlert(venues: nearby)
                    UserDefaults.standard.removeObject(forKey: "LocationID")
                    UserDefaults.standard.removeObject(forKey: "LocationName")
                }
            } else {
                ["LocationID", "LocationName", "LastLocationAlert", "LastLocationNotification"]
                    .forEach { UserDefaults.standard.removeObject(forKey: $0) }
            }
        }
    }

    func sendNotification(venues: [WAPVenue]) {
        for venue in venues {
            let notificationCenter = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = "New W App Location"
            content.body = "Have you been to \(venue.name)"
            let request = UNNotificationRequest(identifier: "Identifier", content: content, trigger: nil)
            notificationCenter.add(request, withCompletionHandler: nil)
        }
    }

    func showVenueAlert(venues: [WAPVenue]) {
        let alertTitle = "Greetings \(UserDefaults.getString(key: "FirstName"))"

        if venues.count > 1 {
            let alertBody = "You're near a W App location. Wing in?"
            let alert = UIAlertController(title: alertTitle, message: alertBody, preferredStyle: .alert)

            for venue in venues {
                UserDefaults.standard.set(venue.id, forKey: "LastLocationAlert")
                UserDefaults.standard.set(venue.id, forKey: "LastLocationNotification")

                alert.addAction(UIAlertAction(title: "Join \(venue.name)", style: .default, handler: { [weak self] _ in
                    guard let self else { return }
                    self.delegate.wingIn(CustomCell(string1: venue.id, string2: venue.name))
                    self.delegate.selectTab(tag: 3)
                }))
            }
            alert.addAction(UIAlertAction(title: Strings.maybeLater, style: .destructive, handler: nil))
            delegate.present(alert, animated: true, completion: nil)
        } else {
            guard let venue = venues.first else { return }
            UserDefaults.standard.set(venue.id, forKey: "LastLocationAlert")
            UserDefaults.standard.set(venue.id, forKey: "LastLocationNotification")

            let alertBody = "You're near \(venue.name)?"
            let alert = UIAlertController(title: alertTitle, message: alertBody, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Strings.maybeLater, style: .destructive, handler: nil))

            alert.addAction(UIAlertAction(title: "Wing in", style: .default, handler: { [weak self] _ in
                guard let self else { return }
                self.delegate.wingIn(CustomCell(string1: venue.id, string2: venue.name))
                self.delegate.selectTab(tag: 3)
            }))
            delegate.present(alert, animated: true, completion: nil)
        }
    }
}
