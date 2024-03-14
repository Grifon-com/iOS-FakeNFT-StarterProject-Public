//
//  CollectionViewController.swift
//  FakeNFT
//
//  Created by Uliana Lukash on 04.03.2024.
//

import UIKit
import Kingfisher
import StoreKit

final class CollectionViewController: UIViewController, LoadingView, ErrorView {

    // MARK: - Public Properties

    private let viewModel: CollectionViewModelProtocol
    private let collectionId: String

    // MARK: - Private Properties

    private let widthParameters = CollectionParameters(
        cellsNumber: 3,
        leftInset: 0,
        rightInset: 0,
        interCellSpacing: 10
    )

    lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.color = .blackUniversal

        return activityIndicator
    }()

    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return imageView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textAlignment = .left
        label.textColor = UIColor.segmentActive
        return label
    }()

    private lazy var authorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor.segmentActive
        return label
    }()

    private lazy var authorNameLabel: UIButton = {
        let button = UIButton()
        button.setTitleColor(.blueUniversal, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .regular)
        button.addTarget(self, action: #selector(didTapAuthorName), for: .touchUpInside)
        return button
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor.segmentActive
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private lazy var nftCollection: UICollectionView = {
        let collection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.scrollDirection = .vertical
        collection.collectionViewLayout = flowLayout
        collection.register(NftCollectionCell.self)
        collection.backgroundColor = .clear
        return collection
    }()

    private lazy var scrollView = UIScrollView()
    private lazy var scrollViewContent = UIView()

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .segmentActive
        self.navigationController?.navigationBar.topItem?.title = ""

        view.backgroundColor = UIColor.whiteModeThemes

        SKStoreReviewController.requestReview()
        setUp()
        bind()
        nftCollection.dataSource = self
        nftCollection.delegate = self
        viewModel.setStateLoading()
    }

    init(viewModel: CollectionViewModelProtocol, collectionId: String) {
        self.viewModel = viewModel
        self.collectionId = collectionId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - ViewModel

    private func bind() {

        guard let viewModel = viewModel as? CollectionViewModel else { return }
        viewModel.$state.bind { [weak self] state in
            guard let self else { return }
            switch state {
            case .initial:
                assertionFailure("Cannot move to initial state")
            case .loading:
                self.showLoading()
                viewModel.loadCollection(withId: collectionId)
            case .update:
                self.showLoading()
                self.nftCollection.reloadData()
                self.hideLoading()
            case .failed(let error):
                self.hideLoading()
                let errorModel = viewModel.makeErrorModel(error: error)
                self.showError(errorModel)
            case .data:
                self.hideLoading()
                self.configure()
                self.nftCollection.reloadData()
            }
        }
    }

    // MARK: - Private Methods

    private func configure() {
        setCoverOfCollection(viewModel.collection?.cover)
        setLabels()
    }

    private func setUp() {

        [scrollView, activityIndicator].forEach {
            view.addSubview($0)
            $0.backgroundColor = .clear
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        scrollView.addSubview(scrollViewContent)
        scrollView.constraintEdges(to: view)
        activityIndicator.constraintCenters(to: view)
        scrollViewContent.translatesAutoresizingMaskIntoConstraints = false
        [coverImageView, nameLabel, authorLabel, authorNameLabel, descriptionLabel, nftCollection].forEach {
            scrollViewContent.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        setConstraints()
    }

    private func setConstraints() {

        NSLayoutConstraint.activate([
            scrollViewContent.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: -100),
            scrollViewContent.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            scrollViewContent.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            scrollViewContent.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            scrollViewContent.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            scrollViewContent.heightAnchor.constraint(equalToConstant: 1000),

            coverImageView.topAnchor.constraint(equalTo: scrollViewContent.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: scrollViewContent.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: scrollViewContent.trailingAnchor),

            nameLabel.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: scrollViewContent.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: scrollViewContent.trailingAnchor, constant: -16),
            nameLabel.heightAnchor.constraint(equalToConstant: 28),

            authorLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            authorLabel.leadingAnchor.constraint(equalTo: scrollViewContent.leadingAnchor, constant: 16),
            authorLabel.widthAnchor.constraint(equalToConstant: 112),
            authorLabel.heightAnchor.constraint(equalToConstant: 28),

            authorNameLabel.leadingAnchor.constraint(equalTo: authorLabel.trailingAnchor, constant: 4),
            authorNameLabel.heightAnchor.constraint(equalToConstant: 28),
            authorNameLabel.centerYAnchor.constraint(equalTo: authorLabel.centerYAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor),
            descriptionLabel.leadingAnchor.constraint(equalTo: scrollViewContent.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: scrollViewContent.trailingAnchor, constant: -16),

            nftCollection.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            nftCollection.leadingAnchor.constraint(equalTo: scrollViewContent.leadingAnchor, constant: 16),
            nftCollection.trailingAnchor.constraint(equalTo: scrollViewContent.trailingAnchor, constant: -16),
            nftCollection.bottomAnchor.constraint(equalTo: scrollViewContent.bottomAnchor)
        ])
    }

    private func setCoverOfCollection(_ coverURL: String?) {
        guard let urlString = coverURL else { return }
        let url = URL(string: urlString)
        let processor = ResizingImageProcessor(referenceSize: CGSize(width: coverImageView.bounds.width, height: 325), mode: .aspectFill)
        coverImageView.kf.indicatorType = .activity
        coverImageView.kf.setImage(
            with: url,
            options: [

                .processor(processor)
            ]) { result in
                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    print("Job failed: \(error.localizedDescription)")
                }
            }
    }

    private func setLabels() {
        guard let collection = viewModel.collection else { return }
        nameLabel.text = collection.name
        descriptionLabel.text = collection.description
        authorLabel.text = NSLocalizedString("Collection author:", comment: "")
        authorNameLabel.setTitle(collection.author, for: .normal)
    }

    // MARK: - @objc Methods

    @objc private func didTapAuthorName() {

        /*        Запрос колекции из АПИшки возвращает коллекцию,
         где в поле автор указано только его имя. Из двух вариантов:
         подтягивать всех пользователей и фильтровать по этому имени,
         чтоб найти таки его ссылку на сайт, или натолкать рандомных
         ссылок, наставник сказал лучше уж рандомных ссылок, поэтому
         вот так... Надеюсь, в скором времени бэк доведут до ума))))
         */

        let url = URL(string: "https://practicum.yandex.ru/ios-developer")!
        let viewController = AuthorViewController(url: url)
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .fullScreen
        self.present(navigationController, animated: true, completion: nil)
    }
 }

 extension CollectionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.nfts?.count ?? 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

            let cell = collectionView.dequeueReusableCell(indexPath: indexPath) as NftCollectionCell
            guard let nft = viewModel.nfts?[indexPath.row], let isLiked = viewModel.isLiked(nft: nft.id),
                  let isInCart = viewModel.isInCart(nft: nft.id) else { return UICollectionViewCell() }
            cell.delegate = self
            cell.configure(nft: nft, isLiked: isLiked, isInCart: isInCart)
            return cell
        }
 }

 extension CollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let availableWidth = collectionView.bounds.width - widthParameters.widthInsets
        let cellWidth = availableWidth / CGFloat(widthParameters.cellsNumber)
        return CGSize(width: cellWidth, height: 192)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(top: 4, left: widthParameters.leftInset, bottom: 4, right: widthParameters.rightInset)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let id = viewModel.nfts?[indexPath.row].id else { return }

        let viewController = NftViewController(
            viewModel: NftViewModel(
                currencyService: CurrenciesServiceImpl(
                    networkClient: DefaultNetworkClient(),
                    storage: CurrenciesStorageImpl()),
                nftService: NftServiceImpl(
                    networkClient: DefaultNetworkClient(),
                    storage: NftStorageImpl()),
                profileService: ProfileServiceImpl(
                    networkClient: DefaultNetworkClient(),
                    storage: ProfileStorageImpl()),
                orderService: OrderServiceImpl(
                    networkClient: DefaultNetworkClient(),
                    storage: OrderStorageImpl())),
            nftId: id)
        self.navigationController?.pushViewController(viewController, animated: true)
    }

 }

 extension CollectionViewController: NftCollectionCellDelegate {

    func reloadTable() {
        self.nftCollection.reloadData()
    }
    func didTapLikeFor(nft id: String) {
        viewModel.didTapLikeFor(nft: id)
    }

    func didTapCartFor(nft id: String) {
        viewModel.didTapCartFor(nft: id)
    }

}
