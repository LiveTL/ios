//
//  HomeModel.swift
//  ios
//
//  Created by Mason Phillips on 3/25/21.
//

import Foundation
import RxCocoa
import RxFlow
import RxSwift
import RxDataSources

typealias Status = HTResponse.Streamer.LiveState

protocol HomeModelType {
    var input : HomeModelInput  { get }
    var output: HomeModelOutput { get }
}
protocol HomeModelInput {
    var refresh: BehaviorRelay<Void> { get }
    
    func loadStreamers(_ org: Organization)
}
protocol HomeModelOutput {
    var streamersDriver  : Driver<HTResponse> { get }
    var refreshDoneDriver: Driver<Bool>       { get }
    
    func video(for section: Int, and id: Int) -> String
}

class HomeModel: BaseModel {
    let refresh = BehaviorRelay<Void>(value: ())
    
    private let streamers    = BehaviorRelay<HTResponse?>(value: nil)
    private let refreshState = BehaviorRelay<Bool>(value: false)
    
    override init(_ services: AppServices) {
        super.init(services)
        
        refresh.subscribe(onNext: { _ in self.loadStreamers(services.settings.orgFilter) }).disposed(by: bag)
        streamers.compactMap { $0 }.distinctUntilChanged()
            .map { _ in false }
            .bind(to: refreshState)
            .disposed(by: bag)
    }
    
    func loadStreamers(_ org: Organization) {
        refreshState.accept(true)
        services.holodex.streamers(org.description)
            .asObservable()
            .bind(to: streamers)
            .disposed(by: bag)
    }
}

extension HomeModel: HomeModelType {
    var input : HomeModelInput  { self }
    var output: HomeModelOutput { self }
}

extension HomeModel: HomeModelInput {}
extension HomeModel: HomeModelOutput {
    var streamersDriver: Driver<HTResponse> {
        return streamers
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: .default())
    }
    var refreshDoneDriver: Driver<Bool> {
        return refreshState.asDriver()
    }
    
    func video(for section: Int, and index: Int) -> String {
        let r = streamers.value!.sections()
        return r[section].items[index].id
    }
}

struct StreamerItemModel: SectionModelType {
    typealias Item = HTResponse.Streamer
    
    var title: String
    var items: [Item]
    
    init(original: StreamerItemModel, items: [Self.Item]) {
        self = original
        self.items = items
    }
    
    init(title: String, items: [Self.Item]) {
        self.title = title
        self.items = items
    }
}

extension HTResponse {
    func sections() -> [StreamerItemModel] {
        
        
        let l = items.filter() {
            s in if s.status == .live {
                return true
            }
        return false
        }.sorted { $0.start_scheduled > $1.start_scheduled }
        
        let u = items.filter() {
            s in if s.status == .upcoming {
                return true
                
            }
        return false
        }.sorted { $0.start_scheduled < $1.start_scheduled }
        
        let e = items.filter() {
            s in if s.status == .past {
                return true
                
            }
        return false
        }.sorted { $0.start_scheduled < $1.start_scheduled }
        
        var rtr: [StreamerItemModel] = []
        
        if !l.isEmpty { rtr.append(StreamerItemModel(title: "Live", items: l)) }
        if !u.isEmpty { rtr.append(StreamerItemModel(title: "Upcoming", items: u)) }
        if !e.isEmpty { rtr.append(StreamerItemModel(title: "Ended", items: e))}
        rtr.append(StreamerItemModel(title: "Stream data provided by Holodex. Results capped at 50.", items: []))
        
        return rtr
    }
}
