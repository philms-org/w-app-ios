
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

    // MARK: - UICollectionViewDataSource / Delegate (banner carousel)

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { bannnerArray.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeBannerCell", for: indexPath)
        (cell as? HomeBannerCell)?.updateCell(customCell: bannnerArray[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == bannerCollectionView, bannerCollectionView.frame.width > 0 else { return }
        pageControl.currentPage = Int(round(scrollView.contentOffset.x / bannerCollectionView.frame.width))
    }

    // MARK: - UITableViewDataSource / Delegate

    func arrayFor(_ tableView: UITableView) -> [CustomCell] {
        if tableView == mostVistedTableView { return mostVistedArray }
        if tableView == lastVisitedTableView { return lastVisitedArray }
        return newAddedArray
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        arrayFor(tableView).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HomeLocationCell", for: indexPath) as? HomeLocationCell else { return UITableViewCell() }
        cell.updateCell(customCell: arrayFor(tableView)[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 100 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openSingleLocation(customCell: arrayFor(tableView)[indexPath.row])
    }

    // MARK: - Data

    func request() {
        Task { [weak self] in
            guard let self else { return }
            do {
                async let venuesTask = WAPData.shared.fetchVenues()
                async let bannersTask = WAPData.shared.fetchBanners()
                async let mostVisitedTask = WAPData.shared.fetchMostVisited()
                async let lastVisitedTask = WAPData.shared.fetchLastVisited()

                let venues = try await venuesTask
                // Banner/most-visited/last-visited are best-effort -- a failure in
                // any one of them (e.g. not signed in yet for last-visited) shouldn't
                // block the rest of the screen from showing.
                let banners = (try? await bannersTask) ?? []
                let mostVisited = (try? await mostVisitedTask) ?? []
                let lastVisited = (try? await lastVisitedTask) ?? []

                await MainActor.run {
                    // Images aren't fetched here (no imageView set on these CustomCells),
                    // same simplification already accepted for newAddedArray -- cells
                    // render with blank images until a real image-loading pass is added.
                    self.bannnerArray = banners.map { CustomCell(string1: $0.id, string2: $0.locationId ?? "") }
                    self.bannerView.isHidden = self.bannnerArray.isEmpty
                    self.pageControl.numberOfPages = self.bannnerArray.count
                    self.bannerCollectionView.reloadData()

                    self.newAddedArray = venues.map { CustomCell(string1: $0.id, string2: $0.name, string3: $0.description ?? "") }
                    self.newAddedView.isHidden = self.newAddedArray.isEmpty
                    self.newAddedTableViewHeight.constant = CGFloat.greatestFiniteMagnitude
                    self.newAddedTableView.reloadData()

                    self.mostVistedArray = mostVisited.map { CustomCell(string1: $0.id, string2: $0.name, string3: $0.description ?? "") }
                    self.mostVistedView.isHidden = self.mostVistedArray.isEmpty
                    self.mostVistedTableViewHeight.constant = CGFloat.greatestFiniteMagnitude
                    self.mostVistedTableView.reloadData()

                    self.lastVisitedArray = lastVisited.map { CustomCell(string1: $0.id, string2: $0.name, string3: $0.description ?? "") }
                    self.lastVisitedView.isHidden = self.lastVisitedArray.isEmpty
                    self.lastVisitedTableViewHeight.constant = CGFloat.greatestFiniteMagnitude
                    self.lastVisitedTableView.reloadData()

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
        bannnerArray = []
        newAddedArray = []
        mostVistedArray = []
        lastVisitedArray = []
        bannerCollectionView.reloadData()
        newAddedTableView.reloadData()
        mostVistedTableView.reloadData()
        lastVisitedTableView.reloadData()
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
