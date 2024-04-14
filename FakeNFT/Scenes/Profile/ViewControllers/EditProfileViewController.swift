//
//  EditProfileViewController.swift
//  FakeNFT
//
//  Created by Григорий Машук on 10.02.24.
//

import UIKit

protocol EditProfileVCDelegate: AnyObject {
    func update(profile: ProfileUIModel)
}

// MARK: - EditProfileViewController
final class EditProfileViewController: UIViewController {
    private enum ConstansEditVC: String {
        static let editButtonSize = CGSize(width: 42, height: 42)
        static let editImageViewSize = CGSize(width: 70, height: 70)
        static let editImageViewAlphaComponent = CGFloat(0.6)
        static let spacingStackView = CGFloat(22)
        static let textViewLineSpacing = CGFloat(5)
        static let textFieldCornerRadius = CGFloat(12)
        static let paddingTextView = UIEdgeInsets(top: 11, left: 12, bottom: 11, right: 0)
        static let editLabelNumberOfLines = 2
        static let numberOfTapsRequired = 1
        case close
    }
    
    weak var delegate: EditProfileVCDelegate?
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        scrollView.backgroundColor = .clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        return scrollView
    }()
    
    private lazy var exitButton: UIButton = {
        let exitButton = UIButton(frame: CGRect(origin: .zero,
                                                size: ConstansEditVC.editButtonSize))
        exitButton.addTarget(nil, action: #selector(didTapExitButton), for: .touchUpInside)
        exitButton.backgroundColor = .clear
        exitButton.tintColor = .blackUniversal
        exitButton.setImage(UIImage(named: ConstansEditVC.close.rawValue),
                            for: .normal)
        
        return exitButton
    }()
    
    private lazy var userImageView: UserImageView = {
        let userImageView = UserImageView(image: nil)
        let userImageModel = UserImageModel(url: nil)
        userImageView.config(with: userImageModel)
        userImageView.backgroundColor = .clear
        
        return userImageView
    }()
    
    private lazy var userImageEditLabelView: UILabel = {
        let userImageEditLabelView = UILabel(
            frame: CGRect(origin: .zero, size: ConstansEditVC.editImageViewSize))
        userImageEditLabelView.text = ConstLocalizable.editUserImage
        userImageEditLabelView.backgroundColor =
            .blackUniversal.withAlphaComponent(ConstansEditVC.editImageViewAlphaComponent)
        userImageEditLabelView.numberOfLines = ConstansEditVC.editLabelNumberOfLines
        userImageEditLabelView.textAlignment = .center
        userImageEditLabelView.textColor = .whiteUniversal
        userImageEditLabelView.font = .headline6
        userImageEditLabelView.frame = userImageView.frame
        
        return userImageEditLabelView
    }()
    
    private lazy var editLoadImageButton: UIButton = {
        let editLoadImageButton = UIButton()
        editLoadImageButton.backgroundColor = .clear
        editLoadImageButton.titleLabel?.font = .bodyRegular
        editLoadImageButton.setTitle( ConstLocalizable.editVCLoadImage, for: .normal)
        editLoadImageButton.addTarget(nil, action: #selector(editLoadImageButtonTap), for: .touchUpInside)
        editLoadImageButton.setTitleColor(.blackUniversal, for: .normal)
        editLoadImageButton.titleLabel?.textAlignment = .center
        editLoadImageButton.isHidden = true
        
        return editLoadImageButton
    }()
    
    private lazy var editImageLinkLabel: UILabel = {
        let editImageLinkLabel = UILabel()
        editImageLinkLabel.backgroundColor = .clear
        editImageLinkLabel.text = ConstLocalizable.editImageLink
        editImageLinkLabel.textColor = .blackUniversal
        editImageLinkLabel.isHidden = true
        
        return editImageLinkLabel
    }()
    
    private lazy var editImageLinkTextField: UITextField = {
        let editImageLinkTextField = TextField()
        editImageLinkTextField.layer.cornerRadius = ConstansEditVC.textFieldCornerRadius
        editImageLinkTextField.layer.masksToBounds = true
        editImageLinkTextField.textColor = .blackUniversal
        editImageLinkTextField.backgroundColor = .segmentInactive
        editImageLinkTextField.isHidden = true
        
        return editImageLinkTextField
    }()
    
    private lazy var verticalStackView: UIStackView = {
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = ConstansEditVC.spacingStackView
        verticalStackView.backgroundColor = .clear
        
        return verticalStackView
    }()
    
    private lazy var nameLabelView: UILabel = {
        let nameLabelView = UILabel()
        nameLabelView.backgroundColor = .clear
        nameLabelView.text = ConstLocalizable.editName
        
        return nameLabelView
    }()
    
    private lazy var nameTextField: UITextField = {
        let nameTextField = TextField()
        
        return nameTextField
    }()
    
    private lazy var descriptionLabelView: UILabel = {
        let descriptionLabelView = UILabel()
        descriptionLabelView.backgroundColor = .clear
        descriptionLabelView.text = ConstLocalizable.editDescription
        
        return descriptionLabelView
    }()
    
    private lazy var descriptionTextView: UITextView = {
        let descriptionTextView = UITextView()
        descriptionTextView.setPadding(insets: ConstansEditVC.paddingTextView)
        descriptionTextView.resignFirstResponder()
        descriptionTextView.textAlignment = .left
        descriptionTextView.layer.cornerRadius = ConstansEditVC.textFieldCornerRadius
        descriptionTextView.layer.masksToBounds = true
        descriptionTextView.layoutManager.delegate = self
        descriptionTextView.font = .bodyRegular
        descriptionTextView.textColor = .segmentActive
        descriptionTextView.backgroundColor = .segmentInactive
        
        return descriptionTextView
    }()
    
    private lazy var linkLabelView: UILabel = {
        let linkLabelView = UILabel()
        linkLabelView.backgroundColor = .clear
        linkLabelView.text = ConstLocalizable.editLink
        
        return linkLabelView
    }()
    
    private lazy var linkTextField: UITextField = {
        let linkTextField = TextField()
        
        return linkTextField
    }()
    
    init(delegate: EditProfileVCDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "EditView"
        hideKeyboardWhenTappedAround()
        view.backgroundColor = .whiteUniversal
        setupUIItem()
        scrollView.contentSize = CGSize(width: view.frame.width, height: view.frame.height)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

private extension EditProfileViewController {
    // MARK: - @objc function
    @objc
    func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        if var keyboardFrame: CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardFrame = self.view.convert(keyboardFrame, from: nil)
            var contentInset: UIEdgeInsets = self.scrollView.contentInset
            contentInset.bottom = keyboardFrame.size.height + 70
            scrollView.contentInset = contentInset
        }
    }
    
    @objc
    func keyboardWillHide(notification: NSNotification) {
        let contentInset: UIEdgeInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
    }
    
    @objc
    func didTapExitButton() {
        guard let name = nameTextField.text,
              let link = linkTextField.text,
              let urlString = editImageLinkTextField.text,
              let delegate
        else { return }
        let profileUIModel = ProfileUIModel(avatar: URL(string: urlString),
                                            name: name,
                                            description: descriptionTextView.text,
                                            link: link)
        delegate.update(profile: profileUIModel)
        dismiss(animated: true)
    }
    
    @objc
    func userImageTapped(_ sender: UITapGestureRecognizer) {
        editLoadImageButton.isHidden = false
    }
    
    @objc
    func editLoadImageButtonTap(_ sender: UITapGestureRecognizer) {
        editImageLinkLabel.isEnabled = false
        editImageLinkTextField.isHidden = false
        editLoadImageButton.isHidden = true
    }
    
    func setupUserImageTap() {
        let labelTap = UITapGestureRecognizer(target: self, action: #selector(self.userImageTapped(_:)))
        labelTap.numberOfTapsRequired = ConstansEditVC.numberOfTapsRequired
        self.userImageView.isUserInteractionEnabled = true
        self.userImageView.addGestureRecognizer(labelTap)
    }
    
    func displayProfile(model: ProfileUIModel) {
        userImageView.config(with: UserImageModel(url: model.avatar))
        editImageLinkTextField.text = model.avatar?.absoluteString
        nameTextField.text = model.name
        descriptionTextView.text = model.description
        linkTextField.text = model.link
    }
    
    // MARK: - Setup UIItem
    func setupUIItem() {
        userImageView.addSubview(userImageEditLabelView)
        setupScrollView()
        setupStackView()
        setupUserImageTap()
        setupConstraints()
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            exitButton.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            exitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            userImageView.topAnchor.constraint(equalTo: exitButton.bottomAnchor, constant: 22),
            userImageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            userImageView.heightAnchor.constraint(equalToConstant: 70),
            userImageView.widthAnchor.constraint(equalToConstant: 70),
            editLoadImageButton.topAnchor.constraint(equalTo: userImageView.bottomAnchor, constant: 15),
            editLoadImageButton.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            editImageLinkTextField.heightAnchor.constraint(equalToConstant: 44),
            nameTextField.heightAnchor.constraint(equalToConstant: 44),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 132),
            linkTextField.heightAnchor.constraint(equalToConstant: 44),
            verticalStackView.topAnchor.constraint(equalTo: editLoadImageButton.bottomAnchor, constant: -14),
            verticalStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            verticalStackView.widthAnchor.constraint(equalToConstant: view.frame.width - 32),
            verticalStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])
        let customSpacing = CGFloat(13)
        verticalStackView.setCustomSpacing(customSpacing, after: nameLabelView)
        verticalStackView.setCustomSpacing(customSpacing, after: descriptionLabelView)
        verticalStackView.setCustomSpacing(customSpacing, after: linkLabelView)
    }
    
    func setupScrollView() {
        view.addSubview(scrollView)
        [exitButton,
         userImageView,
         editLoadImageButton,
         editImageLinkLabel,
         editImageLinkTextField,
         verticalStackView].forEach {
            scrollView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    func setupStackView() {
        [editImageLinkLabel,
         editImageLinkTextField,
         nameLabelView,
         nameTextField,
         descriptionLabelView,
         descriptionTextView,
         linkLabelView,
         linkTextField].forEach {
            verticalStackView.addArrangedSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        [editImageLinkTextField, nameTextField,
         linkTextField ].forEach {
            $0.layer.cornerRadius = ConstansEditVC.textFieldCornerRadius
            $0.layer.masksToBounds = true
            $0.textColor = .segmentActive
            $0.backgroundColor = .segmentInactive
        }
        
        [editImageLinkLabel,
         nameLabelView,
         descriptionLabelView,
         linkLabelView].forEach {
            $0.font = .headline3
            $0.textColor = .blackUniversal
            $0.textAlignment = .left
        }
    }
}

// MARK: - NSLayoutManagerDelegate
extension EditProfileViewController: NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager,
                       lineSpacingAfterGlyphAt glyphIndex: Int,
                       withProposedLineFragmentRect rect: CGRect) -> CGFloat {
        ConstansEditVC.textViewLineSpacing
    }
}

// MARK: - ProfileVCDelegate
extension EditProfileViewController: ProfileVCEditDelegate {
    func setDataUI(model: ProfileUIModel) {
        displayProfile(model: model)
    }
}
