//
//  BasketTableViewCell.swift
//  FakeNFT
//
//  Created by Ivan Cherkashin on 10.02.2024.
//

import Kingfisher
import UIKit

protocol BasketTableViewCellDelegate: AnyObject {
    func deleteButtonClicked(image: UIImage, id: String)
}

final class BasketTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    
    static let identifier = "BasketTableViewCell"
    
    weak var delegate: BasketTableViewCellDelegate?
    
    private var idNftToDelete: String?
    
    private let imageNFT: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameNFTLabel: UILabel = {
        let label = UILabel()
        label.textColor = .segmentActive
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let ratingNFTImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let stubNFTLabel: UILabel = {
        let label = UILabel()
        label.textColor = .segmentActive
        label.text = ConstLocalizable.basketPrice
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let quantityNFTLabel: UILabel = {
        let label = UILabel()
        label.textColor = .segmentActive
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let deleteNFTButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "deleteCard"), for: .normal)
        button.tintColor = .segmentActive
        button.addTarget(nil, action: #selector(didTapDeleteButton), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initializers
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    
    func configure(with nft: Nft) {
        setupNftData(nft)
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        contentView.backgroundColor = .systemBackground
        addSubviews()
        setupConstraints()
    }
    
    private func addSubviews() {
        [imageNFT, nameNFTLabel, ratingNFTImage, stubNFTLabel, quantityNFTLabel, deleteNFTButton].forEach { contentView.addSubview($0) }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            imageNFT.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            imageNFT.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            imageNFT.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            imageNFT.widthAnchor.constraint(equalToConstant: 108),
            imageNFT.heightAnchor.constraint(equalTo: imageNFT.widthAnchor),
            
            nameNFTLabel.leadingAnchor.constraint(equalTo: imageNFT.trailingAnchor, constant: 20),
            nameNFTLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            
            ratingNFTImage.leadingAnchor.constraint(equalTo: imageNFT.trailingAnchor, constant: 20),
            ratingNFTImage.topAnchor.constraint(equalTo: nameNFTLabel.bottomAnchor, constant: 4),
            ratingNFTImage.widthAnchor.constraint(equalToConstant: 68),
            ratingNFTImage.heightAnchor.constraint(equalToConstant: 12),
            
            stubNFTLabel.leadingAnchor.constraint(equalTo: imageNFT.trailingAnchor, constant: 20),
            stubNFTLabel.topAnchor.constraint(equalTo: ratingNFTImage.bottomAnchor, constant: 12),
            
            quantityNFTLabel.leadingAnchor.constraint(equalTo: imageNFT.trailingAnchor, constant: 20),
            quantityNFTLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            
            deleteNFTButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deleteNFTButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            deleteNFTButton.widthAnchor.constraint(equalToConstant: 40),
            deleteNFTButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupNftData(_ nft: Nft) {
        let url = URL(string: nft.images.first!)
        imageNFT.kf.setImage(with: url, placeholder: UIImage(named: "Placeholder"), options: [.transition(.fade(1))])
        nameNFTLabel.text = nft.name
        let formattedPrice = String(format: "%.2f", nft.price).replacingOccurrences(of: ".", with: ",")
        quantityNFTLabel.text = "\(formattedPrice) ETH"
        idNftToDelete = nft.id
        setupRatingImage(for: nft.rating)
    }
    
    private func setupRatingImage(for rating: Int) {
        let ratingImageName: String
        switch rating {
            case 0: ratingImageName = "raiting0Stub"
            case 1..<100: ratingImageName = "raiting1Stub"
            case 100..<300: ratingImageName = "raiting2Stub"
            case 300..<500: ratingImageName = "raiting3Stub"
            case 500..<700: ratingImageName = "raiting4Stub"
            case 700..<900: ratingImageName = "raiting5Stub"
            default: ratingImageName = "raiting5Stub"
        }
        ratingNFTImage.image = UIImage(named: ratingImageName)
    }
    
    @objc private func didTapDeleteButton() {
        guard let image = imageNFT.image else { return }
        guard let id = idNftToDelete else { return }
        delegate?.deleteButtonClicked(image: image, id: id)
    }
}
