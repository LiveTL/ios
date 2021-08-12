//
//  StreamTable.swift
//  ios
//
//  Created by Mason Phillips on 4/5/21.
//

import UIKit
import RxCocoa
import RxSwift

class ChatTable: UITableView {
    let emptyRelay   = BehaviorRelay<Bool>(value: true)
    let loadingRelay = BehaviorRelay<Bool>(value: true)
    
    let loadingView = LoadingView()
    let emptyView = UILabel()
    
    let bag = DisposeBag()
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        
        emptyView.text = Bundle.main.localizedString(forKey: "No messages yet", value: "No messages yet", table: "Localizeable")
        emptyView.textAlignment = .center
        emptyView.textColor = .secondaryLabel
        
        register(UINib(nibName: "ChatCell", bundle: nil), forCellReuseIdentifier: ChatCell.identifier)
        separatorStyle = .none
        estimatedRowHeight = 500
        rowHeight = Self.automaticDimension
        
        Observable.combineLatest(loadingRelay, emptyRelay).subscribe(onNext: { (loading, empty) in
            DispatchQueue.main.async {
                if loading {
                    self.backgroundView = self.loadingView
                } else if !loading && empty {
                    self.backgroundView = self.emptyView
                } else {
                    self.backgroundView = nil
                }
                
                self.setNeedsLayout()
            }
        }).disposed(by: bag)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if loadingView.superview == self {
            loadingView.fillSuperview()
        }
        if emptyView.superview == self {
            emptyView.fillSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}

class LoadingView: UIView {
    let label = UILabel()
    let loading = UIActivityIndicatorView(style: .medium)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        label.text = Bundle.main.localizedString(forKey: "Loading chat...", value: "Loading chat...", table: "Localizeable")
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        addSubview(label)
        
        loading.startAnimating()
        addSubview(loading)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        loading.anchorInCenter(width: 50, height: 50)
        label.alignAndFillWidth(align: .underCentered, relativeTo: loading, padding: 5, height: 18)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}
