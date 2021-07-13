//
//  HomeView.swift
//  ios
//
//  Created by Mason Phillips on 3/25/21.
//

import UIKit
import Neon
import RxCocoa
import RxDataSources
import RxFlow
import RxSwift
import SCLAlertView
import Network

class HomeView: BaseController {
    var rightButton: UIBarButtonItem {
        let b = UIBarButtonItem(title: "cogs", style: .plain, target: self, action: #selector(settings))
        b.setTitleTextAttributes([.font: UIFont(name: "FontAwesome5Pro-Solid", size: 20)!], for: .normal)
        b.setTitleTextAttributes([.font: UIFont(name: "FontAwesome5Pro-Solid", size: 20)!], for: .highlighted)
        return b
    }
    
    var leftButton: UIBarButtonItem {
        let b = UIBarButtonItem(title: "filter", style: .plain, target: self, action: #selector(orgFilter))
        b.setTitleTextAttributes([.font: UIFont(name: "FontAwesome5Pro-Solid", size: 20)!], for: .normal)
        b.setTitleTextAttributes([.font: UIFont(name: "FontAwesome5Pro-Solid", size: 20)!], for: .highlighted)
        return b
    }

    let refresh = UIRefreshControl()
    let table = UITableView(frame: .zero, style: .insetGrouped)
    
    let model: HomeModelType
    let services: AppServices
    
    override init(_ stepper: Stepper, _ services: AppServices) {
        model = HomeModel(services)
        self.services = services
        super.init(stepper, services)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self,
                                                selector: #selector(checkPasteboard),
                                                name: UIApplication.willEnterForegroundNotification,
                                                object: nil)
        
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = rightButton
        navigationItem.leftBarButtonItem = leftButton
        
        let dataSource = RxTableViewSectionedReloadDataSource<StreamerItemModel> { _, table, index, item -> UITableViewCell in
            let cell = table.dequeueReusableCell(withIdentifier: StreamerCell.identifier, for: index)
            (cell as? StreamerCell)?.configure(with: item, services: self.services)
            return cell
        }
        dataSource.titleForHeaderInSection = { source, index -> String in
            source.sectionModels[index].title
        }
        
        refresh.rx.controlEvent(.valueChanged).bind(to: model.input.refresh).disposed(by: bag)
        model.output.refreshDoneDriver.drive(refresh.rx.isRefreshing).disposed(by: bag)
        
        table.rx.setDelegate(self).disposed(by: bag)
        table.register(StreamerCell.self, forCellReuseIdentifier: StreamerCell.identifier)
        model.output.streamersDriver
            .map { $0.sections() }
            .drive(table.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        view.addSubview(table)
        
        model.input.loadStreamers(services.settings.orgFilter)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkPasteboard()
    }
    
    @objc func checkPasteboard() {
        guard (model as? HomeModel)?.services.settings.clipboard ?? false else { return }
        
        let pasteboard = UIPasteboard.general.urls ?? []
            
        for url in pasteboard {
            if let url = URLComponents(url: url, resolvingAgainstBaseURL: false), (url.host == "youtube.com" || url.host == "youtu.be") {
                let alert = SCLAlertView()
                
                alert.addButton("Let's Go!") {
                    let final: String
                    
                    if let id = url.queryItems?.filter({ $0.name == "v" }).first?.value {
                        final = id
                    } else {
                        final = url.path.replacingOccurrences(of: "/", with: "")
                    }
                    
                    self.stepper.steps.accept(AppStep.view(final))
                }
                
                alert.showInfo("Youtube Link Detected!",
                               subTitle: "We detected a Youtube link in your clipboard. Would you like to access this stream?")
            }
        }
    }
    
    @objc func settings() {
        stepper.steps.accept(AppStep.settings)
    }
    
    @objc func orgFilter() {
        stepper.steps.accept(AppStep.filter)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        table.fillSuperview(left: 5, right: 5, top: 15, bottom: 5)
    }
}

extension HomeView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vid = model.output.video(for: indexPath.section, and: indexPath.row)
        stepper.steps.accept(AppStep.view(vid))
    }
}
