import UIKit
import SPDiffable
import BlockiesSwift
import NativeUIKit
import SFSymbols

class ApproveSendTransactionController: SPDiffableTableController {
    
    // MARK: - Data
    
    private let priceService = PriceService.shared
    private let ethereum = Ethereum.shared
    
    private var transaction: Transaction
    private let chain: EthereumChain
    private let address: String
    private let peerMeta: PeerMeta?
    private let approveCompletion: (ApproveSendTransactionController, Bool) -> Void
    
    // MARK: - Views
    
    let toolBarView = NativeLargeSmallActionToolBarView().do {
        $0.actionButton.set(
            title: Texts.Wallet.Operation.approve_transaction,
            icon: UIImage(SFSymbol.checkmark.circleFill),
            colorise: .init(content: .custom(.white), background: .tint)
        )
        $0.secondActionButton.setTitle(Texts.Shared.cancel)
    }
    
    // MARK: - Init
    
    init(transaction: Transaction, chain: EthereumChain, address: String, peerMeta: PeerMeta?, approveCompletion: @escaping (ApproveSendTransactionController, Bool) -> Void) {
        self.transaction = transaction
        self.chain = chain
        self.address = address
        self.peerMeta = peerMeta
        self.approveCompletion = approveCompletion
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = Texts.Wallet.Operation.approve_transaction
        navigationItem.largeTitleDisplayMode = .never
        
        toolBarView.actionButton.addAction(.init(handler: { _ in
            self.toolBarView.setLoading(true)
            AuthService.auth(cancelble: true, on: self) { authed in
                if authed {
                    self.approveCompletion(self, true)
                } else {
                    self.toolBarView.setLoading(false)
                }
            }
        }), for: .touchUpInside)
        
        toolBarView.secondActionButton.addAction(.init(handler: { _ in
            self.approveCompletion(self, false)
        }), for: .touchUpInside)
        
        configureDiffable(sections: content, cellProviders: [.rowDetailMultiLines] + SPDiffableTableDataSource.CellProvider.default, headerFooterProviders: [.largeHeader])
        
        if let navigationController = self.navigationController as? NativeNavigationController {
            navigationController.mimicrateToolBarView = self.toolBarView
        }
        
        toolBarView.setLoading(true)
        observeEthereumValues()
    }
    
    private func observeEthereumValues() {
        ethereum.prepareTransaction(transaction, chain: chain) { [weak self] updated in
            guard let self = self else { return }
            self.transaction = updated
            self.diffableDataSource?.set(self.content, animated: true, completion: nil)
            self.toolBarView.setLoading(!self.transaction.hasFee)
        }
    }
    
    // MARK: - Diffable
    
    enum Item: String {
        
        case website
        case address
        case value
        case fee
        case gas
        
        var id: String { rawValue }
    }
    
    internal var content: [SPDiffableSection] {
        
        var items: [SPDiffableItem] = [
            SPDiffableTableRow(
                id: Item.website.id,
                text: Texts.Wallet.Operation.approve_transaction_website,
                detail:  peerMeta?.name ?? "Unknow",
                icon: nil,
                accessoryType: .none,
                selectionStyle: .none,
                action: nil
            )
        ]
        
        if let value = transaction.valueWithSymbol(chain: chain, ethPrice: priceService.currentPrice, withLabel: true) {
            items.append(
                SPDiffableTableRow(
                    id: Item.value.id,
                    text: Texts.Wallet.Operation.approve_transaction_value,
                    detail: value,
                    icon: nil,
                    accessoryType: .none,
                    selectionStyle: .none,
                    action: nil
                )
            )
        }
        
        items.append(
            SPDiffableTableRow(
                id: Item.fee.id,
                text: Texts.Wallet.Operation.approve_transaction_fee,
                detail: transaction.feeWithSymbol(chain: chain, ethPrice: priceService.currentPrice),
                icon: nil,
                accessoryType: .none,
                selectionStyle: .none,
                action: nil
            )
        )
        
        items.append(
            SPDiffableTableRow(
                id: Item.gas.id,
                text: Texts.Wallet.Operation.approve_transaction_gas,
                detail: transaction.gasPriceWithLabel(chain: chain),
                icon: nil,
                accessoryType: .none,
                selectionStyle: .none,
                action: nil
            )
        )
        
        return [
            .init(
                id: "address",
                header: NativeLargeHeaderItem(title: Texts.Wallet.address),
                footer: SPDiffableTextHeaderFooter(text: Texts.Wallet.Operation.approve_transaction_address_description),
                items: [
                    SPDiffableTableRow(
                        id: Item.address.id,
                        text: address,
                        detail: nil,
                        icon: Blockies(seed: address.lowercased()).createImage(),
                        accessoryType: .none,
                        selectionStyle: .none,
                        action: nil
                    )
                ]
            ),
            .init(
                id: "data",
                header: NativeLargeHeaderItem(title: Texts.Wallet.Operation.approve_transaction_details_header),
                footer: SPDiffableTextHeaderFooter(text: Texts.Wallet.Operation.approve_transaction_details_footer),
                items: items
            )
        ]
    }
}
