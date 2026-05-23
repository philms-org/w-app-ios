
import UIKit

class HomeVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var bannerView: UIView!
    @IBOutlet weak var bannerCollectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var eventsView: UIView!
    @IBOutlet weak var eventsTableView: UITableView!
    @IBOutlet weak var eventsTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var newAddedView: UIView!
    @IBOutlet weak var newAddedTableView: UITableView!
    @IBOutlet weak var newAddedTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var mostVistedView: UIView!
    @IBOutlet weak var mostVistedTableView: UITableView!
    @IBOutlet weak var mostVistedTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var lastVisitedView: UIView!
    @IBOutlet weak var lastVisitedTableView: UITableView!
    @IBOutlet weak var lastVisitedTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    let refreshControl = UIRefreshControl()
    
    var delegate: MainVC!
    
    var bannnerArray: [CustomCell] = []
    var eventsArray: [EventStruct] = []
    var newAddedArray: [CustomCell] = []
    var mostVistedArray: [CustomCell] = []
    var lastVisitedArray: [CustomCell] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.isHidden = true
        
        refreshControl.tintColor = Colors.blue
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        scrollView.addSubview(refreshControl)
        
        request()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        eventsTableView.layoutIfNeeded()
        eventsTableViewHeight.constant = eventsTableView.contentSize.height
        
        newAddedTableView.layoutIfNeeded()
        newAddedTableViewHeight.constant = newAddedTableView.contentSize.height
        
        mostVistedTableView.layoutIfNeeded()
        mostVistedTableViewHeight.constant = mostVistedTableView.contentSize.height
        
        lastVisitedTableView.layoutIfNeeded()
        lastVisitedTableViewHeight.constant = lastVisitedTableView.contentSize.height
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bannnerArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeBannerCell", for: indexPath) as! HomeBannerCell
        cell.updateCell(customCell: bannnerArray[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let customCell = bannnerArray[indexPath.row]
        let id = customCell.string1!
        let link = customCell.string2!
        
        if !id.isEmpty && id != "0" {
            openSingleLocation(customCell: customCell)
        } else if !link.isEmpty {
            if let encodedURL = (link).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                if let url = URL(string: encodedURL) {
                    UIApplication.shared.open(url, options: [:])
                }
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let collectionView = scrollView as? UICollectionView {
            pageControl.currentPage = Int(collectionView.contentOffset.x/collectionView.frame.width)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == eventsTableView {
            return eventsArray.count
        } else if tableView == newAddedTableView {
            return newAddedArray.count
        } else if tableView == mostVistedTableView {
            return mostVistedArray.count
        } else {
            return lastVisitedArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == eventsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventCell
            cell.updateCell(item: eventsArray[indexPath.row])
            return cell
        } else if tableView == newAddedTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HomeLocationCell", for: indexPath) as! HomeLocationCell
            cell.updateCell(customCell: newAddedArray[indexPath.row])
            return cell
        } else if tableView == mostVistedTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HomeLocationCell", for: indexPath) as! HomeLocationCell
            cell.updateCell(customCell: mostVistedArray[indexPath.row])
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HomeLocationCell", for: indexPath) as! HomeLocationCell
            cell.updateCell(customCell: lastVisitedArray[indexPath.row])
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == eventsTableView {
            let width = tableView.frame.width - 40
            let height = width * 1/2 + 20
            return height
        } else {
            return 100
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == eventsTableView {
            guard let cell = tableView.cellForRow(at: indexPath) else {
                return
            }
            let item = eventsArray[indexPath.row]
            
            let actionSheet = UIAlertController(title: "", message: Strings.optionTitle, preferredStyle: .actionSheet)
            
            actionSheet.addAction(UIAlertAction(title: "Wing me into \(item.title)", style: .default) {
                _ in
//                if appDelegate.inLocation {
//                    AlertClass().showWarningAlert(delegate: self, message: Strings.alertWingout)
//                    return
//                }
                let customCell = CustomCell(string1: "Event_\(item.id)", string2: item.title)
                self.delegate.wingMe(customCell)
                self.delegate.selectTab(tag: 3)
            })
            
            actionSheet.addAction(UIAlertAction(title: Strings.optionCancel, style: .cancel))
            
            actionSheet.popoverPresentationController?.sourceView = cell
            actionSheet.popoverPresentationController?.sourceRect = cell.bounds
            actionSheet.popoverPresentationController?.permittedArrowDirections = .up
            present(actionSheet, animated: true, completion: nil)
        } else if tableView == newAddedTableView {
            let customCell = newAddedArray[indexPath.row]
            openSingleLocation(customCell: customCell)
        } else if tableView == mostVistedTableView {
            let customCell = mostVistedArray[indexPath.row]
            openSingleLocation(customCell: customCell)
        } else {
            let customCell = lastVisitedArray[indexPath.row]
            openSingleLocation(customCell: customCell)
        }
    }
    
    func openSingleLocation(customCell: CustomCell) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "SingleLocationVC") as? SingleLocationVC {
            viewController.id = customCell.string1
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @objc func refresh() {
        scrollView.isHidden = true
        
        bannnerArray = []
        eventsArray = []
        newAddedArray = []
        mostVistedArray = []
        lastVisitedArray = []
        
        bannerCollectionView.reloadData()
        eventsTableView.reloadData()
        newAddedTableView.reloadData()
        mostVistedTableView.reloadData()
        lastVisitedTableView.reloadData()
        
        refreshControl.endRefreshing()
        indicator.startAnimating()
        request()
    }
    
    func request() {
        let path = "get_home.php"
        
        let params: NSDictionary = [
            "language": Strings.language
        ]
        
        params.request(delegate: self, path: path, stopLoading: stopLoading, requestSuccess: requestSuccess)
    }
    
    func stopLoading() {
        indicator.stopAnimating()
    }
    
    func requestSuccess(jsonObject: AnyObject) {
        if let message = jsonObject["message"] as? NSDictionary {
            if let banner = message["banner"] as? [NSDictionary] {
                for each in banner {
                    let imageView = UIImageView()
                    imageView.imageFromServerURL(urlString: each.getString(key: "image"),
                                                 collectionView: bannerCollectionView)
                    
                    bannnerArray.append(CustomCell.init(imageView: imageView,
                                                        string1: each.getString(key: "location_Id"),
                                                        string2: each.getString(key: "link")))
                }
            }
            bannerView.isHidden = bannnerArray.isEmpty
            pageControl.numberOfPages = bannnerArray.count
            bannerCollectionView.reloadData()
            
            if let events = message["events"] as? [NSDictionary] {
                for each in events {
                    let imageView = UIImageView()
                    imageView.imageFromServerURL(urlString: each.getString(key: "image"),
                                                 tableView: eventsTableView)
                    
                    let start_date = each.getString(key: "start_date")
                    let end_date = each.getString(key: "end_date")
                    
                    var startDate = ""
                    var endDate = ""
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    
                    if let date = dateFormatter.date(from: start_date) {
                        dateFormatter.dateFormat = "EEEE dd MMM"
                        startDate = dateFormatter.string(from: date)
                    }
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    
                    if let date = dateFormatter.date(from: end_date) {
                        dateFormatter.dateFormat = "EEEE dd MMM"
                        endDate = dateFormatter.string(from: date)
                    }
                    eventsArray.append(EventStruct(imageView: imageView,
                                                   id: each.getString(key: "Id"),
                                                   title: each.getString(key: "title"),
                                                   details: each.getString(key: "description"),
                                                   startDate: startDate,
                                                   endDate: endDate,
                                                   status: "Active"))
                }
            }
            eventsView.isHidden = eventsArray.isEmpty
            eventsTableViewHeight.constant = CGFloat.greatestFiniteMagnitude
            eventsTableView.reloadData()
            
            if let new_locations = message["new_locations"] as? [NSDictionary] {
                for each in new_locations {
                    let customCell = getLocation(dictionary: each, tableView: newAddedTableView)
                    newAddedArray.append(customCell)
                }
            }
            newAddedView.isHidden = newAddedArray.isEmpty
            newAddedTableViewHeight.constant = CGFloat.greatestFiniteMagnitude
            newAddedTableView.reloadData()
            
            if let most_visited = message["most_visited"] as? [NSDictionary] {
                for each in most_visited {
                    let customCell = getLocation(dictionary: each, tableView: mostVistedTableView)
                    mostVistedArray.append(customCell)
                }
            }
            mostVistedView.isHidden = mostVistedArray.isEmpty
            mostVistedTableViewHeight.constant = CGFloat.greatestFiniteMagnitude
            mostVistedTableView.reloadData()
            
            if let last_visited = message["last_visited"] as? [NSDictionary] {
                for each in last_visited {
                    let customCell = getLocation(dictionary: each, tableView: lastVisitedTableView)
                    lastVisitedArray.append(customCell)
                }
            }
            lastVisitedView.isHidden = lastVisitedArray.isEmpty
            lastVisitedTableViewHeight.constant = CGFloat.greatestFiniteMagnitude
            lastVisitedTableView.reloadData()
            
            scrollView.isHidden = false
            viewDidLayoutSubviews()
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
                                         radius: dictionary.getDouble(key: "radius"))
        
        return customCell
    }
}
