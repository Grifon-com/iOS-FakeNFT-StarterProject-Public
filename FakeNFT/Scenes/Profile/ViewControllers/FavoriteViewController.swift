//
//  FavoriteViewController.swift
//  FakeNFT
//
//  Created by Григорий Машук on 26.02.24.
//

import UIKit

protocol FavoriteViewControllerDelegate: AnyObject {
    func updateProfileForLikes(vc: UIViewController)
}

// MARK: - FavoriteViewController
final class FavoriteViewController: UIViewController, ErrorView, LoadingView {
    private enum ConstansFavorite {
        static let cellCount: Int = 2
        static let cellSpacing = CGFloat(7)
        static let heightCell = CGFloat(90)
        static let cellWidth = CGFloat(168)
    }
    
    weak var delegate: FavoriteViewControllerDelegate?
    private let viewModel: FavoriteViewModelProtocol
    
    private lazy var nftCollectionView: FavoritesCollectionView = {
        let nftCollectionView = сreateTrackerCollectionView()
        nftCollectionView.translatesAutoresizingMaskIntoConstraints = false
        nftCollectionView.alwaysBounceVertical = false
        nftCollectionView.backgroundColor = .clear
        nftCollectionView.register(FavoriteCollectionCell.self,
                                   forCellWithReuseIdentifier: "\(FavoriteCollectionCell.self)")
        nftCollectionView.delegate = self
        nftCollectionView.dataSource = self
        
        return nftCollectionView
    }()
    
    lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.color = .blackUniversal
        
        return activityIndicator
    }()
    
    private lazy var emptyNftLabel: UILabel = {
        let emptyNftLabel = UILabel()
        emptyNftLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyNftLabel.backgroundColor = .clear
        emptyNftLabel.font = .bodyBold
        emptyNftLabel.text = ConstLocalizable.favoriteVcEmpty
        
        return emptyNftLabel
    }()
    
    init(viewModel: FavoriteViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .whiteUniversal
        view.accessibilityIdentifier = "FavoriteView"
        setupUIItem()
        bind()
        viewModel.loadNftLikes()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let delegate else { return }
        delegate.updateProfileForLikes(vc: self)
    }
}

private extension FavoriteViewController {
    // MARK: - private func
    @objc
    func leftBarButtonItemTap() {
        dismiss(animated: true)
    }
    
    func bind() {
        guard let viewModel = viewModel as? FavoriteViewModel else { return }
        viewModel.$state.bind { [weak self] state in
            guard let self else { return }
            switch state {
            case .initial:
                assertionFailure("can't move to initial state")
            case .loading, .update:
                isUserInterecrion(flag: false)
            case .failed(let error):
                let errorModel = viewModel.makeErrorModel(error: error)
                self.showError(errorModel)
            case .data:
                if viewModel.likesNft.isEmpty { showStabLabel() }
                guard let indexPath = viewModel.likeIndexPath else {
                    nftCollectionView.reloadData()
                    isUserInterecrion(flag: true)
                    return
                }
                nftCollectionView.performBatchUpdates {
                    self.nftCollectionView.deleteItems(at: [indexPath])
                }
                isUserInterecrion(flag: true)
            }
        }
    }
    
    func isUserInterecrion(flag: Bool) {
        flag ? self.hideLoading() : self.showLoading()
        self.navigationController?.navigationBar.isUserInteractionEnabled = flag
    }
    
    func showStabLabel() {
        setupEmptyLabel()
        view.layoutIfNeeded()
    }
    
    func сreateTrackerCollectionView() -> FavoritesCollectionView {
        let params = GeometricParams(cellCount: ConstansFavorite.cellCount,
                                     leftInset: 16,
                                     rightInset: 16,
                                     cellSpacing: 8)
        let layout = UICollectionViewFlowLayout()
        let trackerCollectionView = FavoritesCollectionView(frame: .zero,
                                                            collectionViewLayout: layout,
                                                            params: params)
        return trackerCollectionView
    }
    
    func setupNavigationBar() {
        guard let navBar = navigationController?.navigationBar,
              let topItem = navBar.topItem
        else { return }
        topItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: ImagesName.backwardProfile.rawValue),
            style: .plain, target: self,
            action: #selector(leftBarButtonItemTap))
        topItem.leftBarButtonItem?.tintColor = .blackUniversal
        navBar.backgroundColor = .clear
        navigationItem.titleView?.tintColor = .blackUniversal
        navigationItem.title = ConstLocalizable.favoriteHeader
        navigationController?.navigationBar.barTintColor = .white
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.blackUniversal]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
    
    func setupUIItem() {
        guard let viewModel = viewModel as? FavoriteViewModel else { return }
        setupCollectionView()
        setupNavigationBar()
        if !viewModel.likesId.isEmpty {
            setupCollectionView()
            setupActivityIndicator()
            return
        }
        setupEmptyLabel()
    }
    
    func setupCollectionView() {
        view.addSubview(nftCollectionView)
        NSLayoutConstraint.activate([
            nftCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            nftCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nftCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nftCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.constraintCenters(to: view)
    }
    
    func setupEmptyLabel() {
        view.addSubview(emptyNftLabel)
        NSLayoutConstraint.activate([
            emptyNftLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyNftLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// MARK: - UICollectionViewDataSource
extension FavoriteViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        guard let viewModel = viewModel as? FavoriteViewModel else { return .zero }
        
        return Int(viewModel.likesNft.count)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "\(FavoriteCollectionCell.self)",
            for: indexPath) as? FavoriteCollectionCell
        else { return UICollectionViewCell() }
        cell.delegate = self
        cell.config(model: viewModel.createCellModel(index: indexPath.row))
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FavoriteViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sizeCell = CGSize(width: ConstansFavorite.cellWidth,
                              height: ConstansFavorite.heightCell)
        return sizeCell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: nftCollectionView.params.leftInset,
                     bottom: 0, right: nftCollectionView.params.rightInset)
    }
}
// MARK: - UICollectionViewDelegate
extension FavoriteViewController: UICollectionViewDelegate {}

// MARK: - ProfileVCFavoriteDelegate
extension FavoriteViewController: ProfileVCFavoriteDelegate {
    func setLikesId(model: Profile, vc: UIViewController) {
        viewModel.setLikesId(likesId: model.likes)
    }
}

// MARK: - FavoriteCollectionCellDelegate
extension FavoriteViewController: FavoriteCollectionCellDelegate {
    func likeTap(_ cell: UICollectionViewCell) {
        guard let cell = cell as? FavoriteCollectionCell,
              let indexPath = nftCollectionView.indexPath(for: cell)
        else { return }
        viewModel.setLikeIndexPath(indexPath: indexPath)
        viewModel.setCurrentLikeId(index: indexPath.row)
        viewModel.likes()
    }
}
