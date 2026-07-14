
import UIKit
import SafariServices

class SingleLocationVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var bannerView: UIView!
    @IBOutlet weak var bannerLabel: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var bookingView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var bannerArray: [BannerStruct] = []
    
    var id = String()
    var whatsappURL = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.isHidden = true
        bannerView.isHidden = true
        bookingView.isHidden = true
        indicator.startAnimating()
        loadVenue()
    }

    func loadVenue() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let venue = try await WAPData.shared.fetchVenue(id: id)
                await MainActor.run {
                    self.nameLabel.text = venue.name
                    self.addressLabel.text = venue.address ?? ""
                    let city = venue.city ?? ""
                    self.cityLabel.text = city
                    self.detailsLabel.text = venue.address ?? ""

                    if let imageURL = venue.bannerImage, !imageURL.isEmpty {
                        let imageView = UIImageView()
                        imageView.imageFromServerURL(urlString: imageURL, collectionView: self.collectionView)
                        self.bannerArray = [BannerStruct(imageView: imageView, title: venue.name, url: "", blurred: false)]
                        self.collectionView.reloadData()
                        self.pageControl.numberOfPages = 0
                        self.updateUI(item: self.bannerArray[0])
                    }
                    self.indicator.stopAnimating()
                    self.scrollView.isHidden = false
                }
            } catch {
                await MainActor.run {
                    self.indicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bannerArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LocationBannerCell", for: indexPath) as! LocationBannerCell
        cell.updateCell(item: bannerArray[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = bannerArray[indexPath.row]
        
        if item.url.isEmpty {
            if !item.blurred, let image = item.imageView.image {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let viewController = storyboard.instantiateViewController(withIdentifier: "FullImageVC") as? FullImageVC {
                    viewController.image = image
                    viewController.modalTransitionStyle = .crossDissolve
                    viewController.modalPresentationStyle = .overFullScreen
                    present(viewController, animated: true, completion: nil)
                }
            }
        } else if let encodedURL = (item.url).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let url = URL(string: encodedURL) {
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = true
                
                let viewController = SFSafariViewController(url: url, configuration: config)
                present(viewController, animated: true)
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let collectionView = scrollView as? UICollectionView {
            let index = Int(collectionView.contentOffset.x/collectionView.frame.width)
            pageControl.currentPage = index
            
            let item = bannerArray[index]
            updateUI(item: item)
        }
    }
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func share(_ sender: UIButton) {
        let url = ""
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = sender
        activity.popoverPresentationController?.sourceRect = sender.bounds
        activity.popoverPresentationController?.permittedArrowDirections = .up
        present(activity, animated: true, completion: nil)
    }
    
    @IBAction func book(_ sender: UIButton) {
        if let encodedURL = (whatsappURL).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let url = URL(string: encodedURL) {
                UIApplication.shared.open(url, options: [:])
            }
        }
    }
    
    func updateUI(item: BannerStruct) {
        if item.blurred || item.title.isEmpty {
            bannerView.isHidden = true
        } else {
            bannerView.isHidden = false
            bannerLabel.text = item.title
        }
    }
    
}
