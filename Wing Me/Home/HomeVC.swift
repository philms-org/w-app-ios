
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
        bannerView.isHidden = true
        eventsView.isHidden = true
        mostVistedView.isHidden = true
        lastVisitedView.isHidden = true

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

    // MARK: - UICollectionViewDataSource / Delegate (bannerView hidden — stubs only)

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 0 }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: "HomeBannerCell", for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }

    // MARK: - UITableViewDataSource / Delegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView == newAddedTableView ? newAddedArray.count : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HomeLocationCell", for: indexPath) as? HomeLocationCell else { return UITableViewCell() }
        cell.updateCell(customCell: newAddedArray[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 100 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView == newAddedTableView else { return }
        openSingleLocation(customCell: newAddedArray[indexPath.row])
    }

    // MARK: - Data

    func request() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let venues = try await WAPData.shared.fetchVenues()
                await MainActor.run {
                    self.newAddedArray = venues.map { CustomCell(string1: $0.id, string2: $0.name) }
                    self.newAddedView.isHidden = self.newAddedArray.isEmpty
                    self.newAddedTableViewHeight.constant = CGFloat.greatestFiniteMagnitude
                    self.newAddedTableView.reloadData()
                    self.indicator.stopAnimating()
                    self.scrollView.isHidden = false
                    self.viewDidLayoutSubviews()
                }
            } catch {
                await MainActor.run {
                    self.indicator.stopAnimating()
                    AlertClass().showErrorAlert(delegate: self, message: error.localizedDescription)
                }
            }
        }
    }

    @objc func refresh() {
        scrollView.isHidden = true
        newAddedArray = []
        newAddedTableView.reloadData()
        refreshControl.endRefreshing()
        indicator.startAnimating()
        request()
    }

    func openSingleLocation(customCell: CustomCell) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "SingleLocationVC") as? SingleLocationVC {
            vc.id = customCell.string1
            present(vc, animated: true)
        }
    }
}
