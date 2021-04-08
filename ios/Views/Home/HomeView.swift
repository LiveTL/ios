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

class HomeView: BaseController {
    var rightButton: UIBarButtonItem {
        let b = UIBarButtonItem(title: "cogs", style: .plain, target: self, action: #selector(settings))
        b.setTitleTextAttributes([.font: UIFont(name: "FontAwesome5Pro-Solid", size: 20)!], for: .normal)
        b.setTitleTextAttributes([.font: UIFont(name: "FontAwesome5Pro-Solid", size: 20)!], for: .highlighted)
        return b
    }

    let refresh = UIRefreshControl()
    let table = UITableView(frame: .zero, style: .insetGrouped)
    
    let model: HomeModelType
    
    override init(_ stepper: Stepper, _ services: AppServices) {
        model = HomeModel(services)
        super.init(stepper, services)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = rightButton
        
        let dataSource = RxTableViewSectionedReloadDataSource<StreamerItemModel> { _, table, index, item -> UITableViewCell in
            let cell = table.dequeueReusableCell(withIdentifier: StreamerCell.identifier, for: index)
            (cell as? StreamerCell)?.configure(with: item)
            return cell
        }
        dataSource.titleForHeaderInSection = { source, index -> String in
            source.sectionModels[index].title
        }
        
        refresh.rx.controlEvent(.valueChanged).bind(to: model.input.refresh).disposed(by: bag)
        model.output.refreshDoneDriver.drive(refresh.rx.isRefreshing).disposed(by: bag)
//        table.refreshControl = refresh
        
        table.rx.setDelegate(self).disposed(by: bag)
        table.register(StreamerCell.self, forCellReuseIdentifier: StreamerCell.identifier)
        model.output.streamersDriver
            .map { $0.sections() }
            .drive(table.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        view.addSubview(table)
        
        model.input.loadStreamers()
    }
    
    @objc func settings() {
        stepper.steps.accept(AppStep.settings)
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
