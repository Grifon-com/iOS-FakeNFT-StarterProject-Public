//
//  ProfileViewController.swift
//  FakeNFT
//
//  Created by Григорий Машук on 9.02.24.
//

import UIKit
import Kingfisher

protocol ProfileVCEditDelegate: AnyObject {
    func setDataUI(model: ProfileUIModel)
}

protocol ProfileVCMyNftDelegate: AnyObject {
    func setProfile(model: Profile?, vc: UIViewController)
}

protocol ProfileVCFavoriteDelegate: AnyObject {
    func setLikesId(model: Profile, vc: UIViewController)
}

// MARK: - ProfileViewController
final class ProfileViewController: UIViewController, ErrorView, LoadingView {
    private enum ConstantsProfileVC: String {
        static let assertionMEssage = "can't move to initial state"
        static let horisontalStackSpacing = CGFloat(20)
        static let verticalStackSpacing = CGFloat(20)
        static let textViewLineSpacing = CGFloat(3)
        static let userImageSize = CGFloat(70)
        static let paddingTextView = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
        static let heigtTableCell = CGFloat(54)
        static let countCellTableView = 3
        static let maxHeightTextView = CGFloat(100)
        case editProfile
    }
    
    private var router: Router?
    weak var editDelegate: ProfileVCEditDelegate?
    weak var myNftDelegate: ProfileVCMyNftDelegate?
    weak var favoriteDelegate: ProfileVCFavoriteDelegate?
    private var textHeightConstraint: NSLayoutConstraint?
    private let viewModel: ProfileViewModelProtocol
    
    private lazy var editProfileButton: UIButton = {
        let editProfileButton = UIButton()
        editProfileButton.accessibilityIdentifier = "editProfileButton"
        editProfileButton.addTarget(nil, action: #selector(self.didEditTap), for: .touchUpInside)
        editProfileButton.setImage(UIImage(named: ConstantsProfileVC.editProfile.rawValue),
                                   for: .normal)
        
        return editProfileButton
    }()
    
    private lazy var horisontalStackView: UIStackView = {
        let horisontalStackView = UIStackView()
        horisontalStackView.axis = .horizontal
        horisontalStackView.spacing = ConstantsProfileVC.horisontalStackSpacing
        
        return horisontalStackView
    }()
    
    private lazy var userImageView: UserImageView = {
        let userImageView = UserImageView(image: nil)
        let userImageModel = UserImageModel(url: nil)
        userImageView.config(with: userImageModel)
        
        return userImageView
    }()
    
    private lazy var fullNameLabelView: UILabel = {
        let fullNameLabelView = UILabel()
        fullNameLabelView.textAlignment = .left
        fullNameLabelView.font = .headline3
        fullNameLabelView.textColor = .blackUniversal
        
        return fullNameLabelView
    }()
    
    private lazy var verticalStackView: UIStackView = {
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = ConstantsProfileVC.verticalStackSpacing
        
        return verticalStackView
    }()
    
    private lazy var descriptionTextView: UITextView = {
        let descriptionTextView = UITextView()
        descriptionTextView.delegate = self
        descriptionTextView.isEditable = false
        descriptionTextView.setPadding(insets: ConstantsProfileVC.paddingTextView)
        descriptionTextView.textAlignment = .left
        descriptionTextView.layoutManager.delegate = self
        descriptionTextView.font = .caption2
        descriptionTextView.textColor = .blackUniversal
        
        return descriptionTextView
    }()
    
    private lazy var linkLabelView: UILabel = {
        let linkLabelView = UILabel()
        linkLabelView.font = .caption1
        linkLabelView.textColor = .blueUniversal
        return linkLabelView
    }()
    
    private lazy var nftTableView: UITableView = {
        let nftTableView = UITableView()
        nftTableView.accessibilityIdentifier = "ProfileTable"
        nftTableView.translatesAutoresizingMaskIntoConstraints = false
        nftTableView.backgroundColor = .clear
        nftTableView.separatorStyle = .none
        nftTableView.isScrollEnabled = false
        nftTableView.register(ProfileTableViewCell.self,
                              forCellReuseIdentifier: "\(ProfileTableViewCell.self)")
        nftTableView.delegate = self
        nftTableView.dataSource = self
        
        return nftTableView
    }()
    
    lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.color = .blackUniversal
        
        return activityIndicator
    }()
    
    // MARK: - Init
    init(viewModel: ProfileViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "ProfileView"
        router = Router(sourceViewController: self)
        view.backgroundColor = .whiteUniversal
        bind()
        setupUIItem()
        viewModel.setStateLoading()
    }
}

private extension ProfileViewController {
    // MARK: - private function
    func bind() {
        guard let viewModel = viewModel as? ProfileViewModel else { return }
        viewModel.$state.bind { [weak self] state in
            guard let self else { return }
            switch state {
            case .initial:
                assertionFailure(ConstantsProfileVC.assertionMEssage)
            case .loading:
                self.isUserInterecrion(flag: false)
                viewModel.loadProfile(id: "1")
            case .update:
                self.isUserInterecrion(flag: false)
            case .failed(let error):
                self.hideLoading()
                let errorModel = viewModel.makeErrorModel(error: error)
                self.showError(errorModel)
            case .data(let profile):
                let profileUIModel = viewModel.makeProfileUIModel(networkModel: profile)
                viewModel.setProfileUIModel(model: profileUIModel)
                viewModel.setProfileID(id: profile.id)
                let cellModel = viewModel.makeTableCellModel(networkModel: profile)
                viewModel.setCellModel(cellModel: cellModel)
                self.displayProfile(model: profileUIModel)
                self.adjustTextViewHeight()
                self.isUserInterecrion(flag: true)
            }
        }
        viewModel.$cellModel.bind { [weak self] _ in
            guard let self else { return }
            self.nftTableView.reloadData()
        }
    }
    
    func isUserInterecrion(flag: Bool) {
        flag ? self.hideLoading() : self.showLoading()
        view.isUserInteractionEnabled = flag
    }
    
    @objc
    func didEditTap() {
        let editVC = EditProfileViewController(delegate: self)
        self.editDelegate = editVC
        editVC.modalPresentationStyle = .formSheet
        present(editVC, animated: true) { [weak self] in
            guard let self,
                  let model = self.viewModel.getProfileUIModel() else { return }
            self.editDelegate?.setDataUI(model: model)
        }
    }
    
    func displayProfile(model: ProfileUIModel) {
        userImageView.config(with: UserImageModel(url: model.avatar))
        fullNameLabelView.text = viewModel.stringClear(str: model.name)
        descriptionTextView.text = viewModel.stringClear(str: model.description)
        linkLabelView.text = viewModel.stringClear(str: model.link)
    }
    
    func displayMyNft() {
        guard let router,
              let profile = viewModel.getProfile()
        else { return }
        router.showMyNft(profile: profile)
    }
    
    func displayFavoriteNft() {
        guard let profile = viewModel.getProfile(),
              let router
        else { return }
        router.showFavarite()
        favoriteDelegate?.setLikesId(model: profile, vc: self)
    }
    
    func displayWebView() {
        guard let request = viewModel.createRequest(
            WebViewConfiguration.baseUrlSring),
            let router
        else { return }
        router.showWebView(request: request)
    }
    
    func adjustTextViewHeight() {
        let fixedWidth = descriptionTextView.frame.size.width
        let newSize = descriptionTextView.sizeThatFits(CGSize(
            width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        if newSize.height > 100 {
            descriptionTextView.isScrollEnabled = true
            textHeightConstraint?.constant = 100
        } else {
            descriptionTextView.isScrollEnabled = false
            textHeightConstraint?.constant = newSize.height
        }
        view.layoutIfNeeded()
    }
    
    // MARK: - setupUI function
    func setupUIItem() {
        addSubViewsAndBackColor()
        setupConstraint()
    }
    
    func setupConstraint() {
        verticalStackView.setCustomSpacing(20, after: horisontalStackView)
        NSLayoutConstraint.activate([
            editProfileButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -9),
            editProfileButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            userImageView.leadingAnchor.constraint(equalTo: horisontalStackView.leadingAnchor),
            userImageView.widthAnchor.constraint(equalToConstant: ConstantsProfileVC.userImageSize),
            userImageView.heightAnchor.constraint(equalToConstant: ConstantsProfileVC.userImageSize),
            
            verticalStackView.topAnchor.constraint(equalTo: editProfileButton.bottomAnchor,
                                                   constant: 20),
            verticalStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                       constant: 16),
            verticalStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                        constant: -16),
            
            descriptionTextView.bottomAnchor.constraint(equalTo: linkLabelView.topAnchor),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 72),
            descriptionTextView.leadingAnchor.constraint(equalTo: verticalStackView.leadingAnchor),
            
            linkLabelView.heightAnchor.constraint(equalToConstant: 38),
            
            nftTableView.topAnchor.constraint(equalTo: verticalStackView.bottomAnchor, constant: 40),
            nftTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nftTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nftTableView.heightAnchor.constraint(equalToConstant: CGFloat(ConstantsProfileVC.countCellTableView)
                                                 * ConstantsProfileVC.heigtTableCell),
            
            descriptionTextView.heightAnchor.constraint(equalToConstant: ConstantsProfileVC.maxHeightTextView)
        ])
        activityIndicator.constraintCenters(to: view)
    }
    
    func addSubViewsAndBackColor() {
        [userImageView, fullNameLabelView].forEach {
            horisontalStackView.addArrangedSubview($0)
            $0.backgroundColor = .clear
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        [horisontalStackView,
         descriptionTextView,
         linkLabelView].forEach {
            verticalStackView.addArrangedSubview($0)
            $0.backgroundColor = .clear
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        [activityIndicator, nftTableView,
         verticalStackView, editProfileButton].forEach {
            view.addSubview($0)
            $0.backgroundColor = .clear
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
}

// MARK: - NSLayoutManagerDelegate
extension ProfileViewController: NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager,
                       lineSpacingAfterGlyphAt glyphIndex: Int,
                       withProposedLineFragmentRect rect: CGRect) -> CGFloat {
        ConstantsProfileVC.textViewLineSpacing
    }
}

// MARK: - UITableViewDelegate
extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == CountProfileCell.one.rawValue {
            displayMyNft()
        }
        if indexPath.row == CountProfileCell.two.rawValue {
            displayFavoriteNft()
        }
        if indexPath.row == CountProfileCell.three.rawValue {
            displayWebView()
        }
    }
}

// MARK: - UITableViewDataSource
extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Int(ConstantsProfileVC.countCellTableView)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        ConstantsProfileVC.heigtTableCell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "\(ProfileTableViewCell.self)") as? ProfileTableViewCell,
              let viewModel = viewModel as? ProfileViewModel
        else { return UITableViewCell()}
        let cellModel = viewModel.cellModel
        switch indexPath.row {
        case 0:
            cell.accessibilityIdentifier = "MyNftCell"
            let text = viewModel.createTextCell(text: ConstLocalizable.profileCellMyNFT,
                                                count: cellModel.countNFT)
            let profileCellModel = ProfileCellModel(text: text)
            cell.config(with: profileCellModel)
        case 1:
            cell.accessibilityIdentifier = "FavoriteCell"
            let text = viewModel.createTextCell(text: ConstLocalizable.profileCellFavoritesNFT,
                                                count: cellModel.countFavoritesNFT)
            let profileCellModel = ProfileCellModel(text: text)
            cell.config(with: profileCellModel)
        case 2:
            cell.accessibilityIdentifier = "DevelopCell"
            let profileCellModel = ProfileCellModel(text: ConstLocalizable.profileCellDeveloper )
            cell.config(with: profileCellModel)
        default:
            assertionFailure("")
        }
        return cell
    }
}

// MARK: - EditProfileVCDelegate
extension ProfileViewController: EditProfileVCDelegate {
    func update(profile: ProfileUIModel) {
        viewModel.updateProfile(newModel: profile)
    }
}

// MARK: - UITextViewDelegate
extension ProfileViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.adjustTextViewHeight()
    }
}

// MARK: - MyNFTViewControllerDlegate
extension ProfileViewController: MyNFTViewControllerDlegate {
    func updateProfileForMyNft(vc: UIViewController) {
        viewModel.loadProfile(id: "1")
        viewModel.setStateLoading()
    }
}

// MARK: - FavoriteViewControllerDelegate
extension ProfileViewController: FavoriteViewControllerDelegate {
    func updateProfileForLikes(vc: UIViewController) {
        viewModel.loadProfile(id: "1")
        viewModel.setStateLoading()
    }
}
