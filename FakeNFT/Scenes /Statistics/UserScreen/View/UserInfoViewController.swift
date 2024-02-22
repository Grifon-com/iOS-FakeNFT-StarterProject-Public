import UIKit

final class UserInfoViewController: UIViewController {
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.segmentActive
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        return label
    }()

    private let userDescription: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.segmentActive
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let userWebsiteButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.borderColor = UIColor.segmentActive.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 16
        button.setTitle("Перейти на сайт пользователя", for: .normal) // TODO: add localization
        button.setTitleColor(UIColor.segmentActive, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        button.backgroundColor = UIColor.whiteModeThemes
        return button
    }()

    init(user: User) {
        usernameLabel.text = user.username
        userDescription.text = user.description
        avatarImageView.image = user.avatar
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupNavBar()
        setupAvatarImageView()
        setupUsernameLabel()
        setupUserDescription()
        setupUserWebsiteButton()
    }

    private func setupUsernameLabel() {
        view.addSubview(usernameLabel)
        NSLayoutConstraint.activate([
            usernameLabel.leadingAnchor.constraint(
                equalTo: avatarImageView.trailingAnchor,
                constant: Constants.defaultInset
            ),
            usernameLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constants.defaultInset
            ),
            usernameLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: Constants.defaultElementSpacing
            )
        ])
    }

    private func setupUserDescription() {
        view.addSubview(userDescription)
        NSLayoutConstraint.activate([
            userDescription.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.defaultInset),
            userDescription.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.defaultInset),
            userDescription.topAnchor.constraint(
                equalTo: usernameLabel.bottomAnchor,
                constant: Constants.defaultElementSpacing
            )
        ])
    }

    private func setupNavBar() {
        let backButton = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)
        backButton.tintColor = UIColor.segmentActive
        navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
    }

    private func setupAvatarImageView() {
        view.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.heightAnchor.constraint(equalToConstant: Constants.userAvatarHeight),
            avatarImageView.widthAnchor.constraint(equalToConstant: Constants.userAvatarWidth),
            avatarImageView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Constants.defaultInset
            ),
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
    }

    private func setupUserWebsiteButton() {
        view.addSubview(userWebsiteButton)
        NSLayoutConstraint.activate([
            userWebsiteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.defaultInset),
            userWebsiteButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constants.defaultInset
            ),
            userWebsiteButton.topAnchor.constraint(equalTo: userDescription.bottomAnchor, constant: 28),
            userWebsiteButton.heightAnchor.constraint(equalToConstant: Constants.userWebsiteButtonHeight)
        ])
    }
}

private enum Constants {
    static let userAvatarHeight: CGFloat = 70
    static let userAvatarWidth: CGFloat = 70
    static let defaultInset: CGFloat = 16
    static let defaultElementSpacing: CGFloat = 41
    static let userWebsiteButtonHeight: CGFloat = 40
}
