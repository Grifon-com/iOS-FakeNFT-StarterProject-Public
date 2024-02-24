//
//  PaymentViewModel.swift
//  FakeNFT
//
//  Created by Ivan Cherkashin on 22.02.2024.
//

import Foundation

protocol PaymentViewModelProtocol {
    var onChange: (() -> Void)? { get set }
    var onLoad: ((Bool) -> Void)? { get set }
    var currency: [CurrenciesModel] { get }
    var idCurrency: String { get set }
    var currencyName: String { get set }
    var checkBool: Bool { get set }
    func loadCurrency()
    func paymentAttempt()
}

final class PaymentViewModel: PaymentViewModelProtocol {
    
    // MARK: - Public Properties
    
    var onChange: (() -> Void)?
    var onLoad: ((Bool) -> Void)?
    var idCurrency: String = ""
    var currencyName: String = ""
    var checkBool: Bool = false
    
    // MARK: - Private Properties
    
    private let service: PaymentServiceProtocol
    private(set) var currency: [CurrenciesModel] = [] {
        didSet {
            onChange?()
        }
    }
    
    // MARK: - Initializers
    
    init(service: PaymentServiceProtocol) {
        self.service = service
    }
    
    // MARK: - Public Methods
    
    func loadCurrency() {
        service.loadByPayment { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let arrayPay):
                DispatchQueue.main.async {
                    self.currency = arrayPay
                }
            case .failure(let error):
                print("Failed to load currency: \(error.localizedDescription)")
            }
        }
    }
    
    func paymentAttempt() {
        onLoad?(true)
        var checkBoolValue = false
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        service.loadByOrderPayment(by: idCurrency) { [weak self] result in
            guard let self = self else { return }
            defer { dispatchGroup.leave() }
            
            switch result {
            case .success(let model):
                checkBoolValue = model.success && model.id == self.currencyName
            case .failure(let error):
                print("Failed to process payment: \(error.localizedDescription)")
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.checkBool = checkBoolValue
            self.onLoad?(false)
        }
    }
}
