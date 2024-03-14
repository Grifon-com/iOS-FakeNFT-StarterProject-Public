//
//  MyNFTViewController.swift
//  FakeNFT
//
//  Created by Григорий Машук on 17.02.24.
//

import UIKit

protocol MyNFTViewControllerDlegate: AnyObject {
    func updateProfileForMyNft(vc: UIViewController)
}

// MARK: - MyNFTViewController
final class MyNFTViewController: UIViewController, ErrorView, LoadingView {
    private enum ConstMyNFTVC {
        static let heightCell = CGFloat(140)
    }
    
    weak var delegate: MyNFTViewControllerDlegate?
    lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.color = .blackUniversal
        
        return activityIndicator
    }()
    
    private let viewModel: MyNftViewModelProtocol
    
    private lazy var myNFTTable: UITableView = {
        let myNFTTable = UITableView()
        myNFTTable.dataSource = self
        myNFTTable.delegate = self
        myNFTTable.translatesAutoresizingMaskIntoConstraints = false
        myNFTTable.backgroundColor = .clear
        myNFTTable.separatorColor = .clear
        myNFTTable.allowsMultipleSelection = false
        myNFTTable.isUserInteractionEnabled = true
        myNFTTable.register(MyNFTTableCell.self,
                            forCellReuseIdentifier: "\(MyNFTTableCell.self)")
        
        return myNFTTable
    }()
    
    private lazy var empryNftLabel = UILabel()
    
    init(viewModel: MyNftViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "MyNftView"
        bind()
        viewModel.loadMyNFT()
        view.backgroundColor = .whiteUniversal
        setupUIItem()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let delegate else { return }
        delegate.updateProfileForMyNft(vc: self)
    }
}

private extension MyNFTViewController {
    // MARK: - private func
    func bind() {
        guard let viewModel = viewModel as? MyNftViewModel else { return }
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
                if viewModel.isUpdate,
                   let indexPath = viewModel.likeIndexPath,
                   let cell = getCell(indexPath: indexPath) {
                    cell.likeButttonPulse(flag: false)
                    myNFTTable.performBatchUpdates {
                        self.myNFTTable.reloadRows(at: [indexPath], with: .automatic)
                    }
                }
                if viewModel.isUpdate, let indexPath = viewModel.likeIndexPath {
                    myNFTTable.reloadRows(at: [indexPath], with: .automatic)
                    isUserInterecrion(flag: true)
                    return
                }
                self.myNFTTable.reloadData()
                myNFTTable.scrollToRow(at: IndexPath(row: .zero, section: .zero),
                                       at: .bottom, animated: true)
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
    
    func setupUIItem() {
        setupNavigationBar()
        addSubViews()
        !viewModel.getListMyNft().isEmpty ? setupEmptyLabel() : setupConstraint()
    }
    
    func setupNavigationBar() {
        guard let navBar = navigationController?.navigationBar,
              let topItem = navBar.topItem
        else { return }
        topItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: ImagesName.sortProfile.rawValue),
                                                     style: .plain, target: self,
                                                     action: #selector(rightBarButtonItemTap))
        topItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: ImagesName.backwardProfile.rawValue),
                                                    style: .plain, target: self,
                                                    action: #selector(leftBarButtonItemTap))
        topItem.leftBarButtonItem?.tintColor = .blackUniversal
        topItem.rightBarButtonItem?.tintColor = .blackUniversal
        navBar.backgroundColor = .clear
        navigationItem.titleView?.tintColor = .blackUniversal
        navigationItem.title = ConstLocalizable.myNFTProfile
        self.navigationController?.navigationBar.barTintColor = .white
        
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.blackUniversal]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
    
    @objc
    func rightBarButtonItemTap() {
        present(createAlert(), animated: true)
    }
    
    @objc
    func leftBarButtonItemTap() {
        dismiss(animated: true)
    }
    
    func createAlert() -> UIAlertController {
        let alertController = UIAlertController(title: ConstLocalizable.myNftVcSortName,
                                                message: nil,
                                                preferredStyle: .actionSheet)
        let actionSortByPrice = UIAlertAction(title: ConstLocalizable.myNftVcByPrice,
                                              style: .default) { [weak self] _ in
            guard let self else { return }
            self.actionAlert(state: .price)
        }
        let actionSortByRating = UIAlertAction(title: ConstLocalizable.myNftVcByRating,
                                               style: .default) { [weak self] _ in
            guard let self else { return }
            self.actionAlert(state: .rating)
        }
        let actionSortByName = UIAlertAction(title: ConstLocalizable.myNftVcByName,
                                             style: .default) { [weak self] _ in
            guard let self else { return }
            self.actionAlert(state: .name)
        }
        let actionClose = UIAlertAction(title: ConstLocalizable.myNftVcClose,
                                        style: .cancel)
        [actionSortByPrice,
         actionSortByRating,
         actionSortByName,
         actionClose].forEach {
            alertController.addAction($0)
        }
        return alertController
    }
    
    func actionAlert(state: SortState) {
        guard let viewModel = viewModel as? MyNftViewModel else { return }
        viewModel.isUpdate = false
        viewModel.setSortState(state: state)
        viewModel.loadMyNFT()
    }
    
    func getCell(indexPath: IndexPath) -> MyNFTTableCell? {
        guard let cell = myNFTTable.cellForRow(at: indexPath) as? MyNFTTableCell
        else { return nil }
        return cell
    }
    
    func setupConstraint() {
        activityIndicator.constraintCenters(to: view)
        NSLayoutConstraint.activate([
            myNFTTable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            myNFTTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            myNFTTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            myNFTTable.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    func addSubViews() {
        view.addSubview(myNFTTable)
        view.addSubview(activityIndicator)
    }
    
    func setupEmptyLabel() {
        view.addSubview(empryNftLabel)
        empryNftLabel.translatesAutoresizingMaskIntoConstraints = false
        empryNftLabel.backgroundColor = .clear
        empryNftLabel.font = .bodyBold
        empryNftLabel.text = ConstLocalizable.myNftVcEmpty
        NSLayoutConstraint.activate([
            empryNftLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            empryNftLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource
extension MyNFTViewController: UITableViewDelegate {}

// MARK: - UITableViewDataSource
extension MyNFTViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.getListMyNft().count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        ConstMyNFTVC.heightCell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(MyNFTTableCell.self)") as? MyNFTTableCell,
              let viewModel = viewModel as? MyNftViewModel
        else { return UITableViewCell() }
        cell.delegate = self
        cell.config(model: viewModel.getListMyNft()[indexPath.row])
        let isLike = viewModel.nftIsLike(index: indexPath.row)
        cell.like(flag: isLike)
        
        return cell
    }
}

// MARK: - MyNFTTableCellDelegate
extension MyNFTViewController: MyNFTTableCellDelegate {
    func likeTap(_ cell: UITableViewCell) {
        guard let myNftCell = cell as? MyNFTTableCell,
              let viewModel = viewModel as? MyNftViewModel,
              let indexPath = myNFTTable.indexPath(for: myNftCell)
        else { return }
        viewModel.setLikeIndexPathAndUpdateId(indexPath)
        let isLike = viewModel.nftIsLike(index: indexPath.row)
        viewModel.updateNft(flag: !isLike)
        viewModel.setUpdateId(index: indexPath.row)
    }
}

// MARK: - ProfileVCMyNftDelegate
extension MyNFTViewController: ProfileVCMyNftDelegate {
    func setProfile(model: Profile?, vc: UIViewController) {
        viewModel.saveProfile(profile: model)
    }
}
