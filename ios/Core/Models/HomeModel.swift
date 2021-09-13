//
//  HomeModel.swift
//  ios
//
//  Created by Mason Phillips on 3/25/21.
//

import Foundation
import RxCocoa
import RxDataSources
import RxFlow
import RxSwift

typealias Status = HoloDexResponse.Streamer.LiveState

protocol HomeModelType {
    var input: HomeModelInput { get }
    var output: HomeModelOutput { get }
}

protocol HomeModelInput {
    var refresh: BehaviorRelay<Void> { get }
    
    func loadStreamers(_ org: Organization)
}

protocol HomeModelOutput {
    var streamersDriver: Driver<HoloDexResponse> { get }
    var refreshDoneDriver: Driver<Bool> { get }
    
    func video(for section: Int, and id: Int) -> String
    func thumbnail(for section: Int, and index: Int) -> URL?
    func backupThumbnail(for section: Int, and index: Int) -> URL?
    func title(for section: Int, and index: Int) -> String?
    func description(for section: Int, and index: Int) -> String?
}

class HomeModel: BaseModel {
    let refresh = BehaviorRelay<Void>(value: ())
    
    private var streamers    = BehaviorRelay<HoloDexResponse?>(value: nil)
    private let liveStreamers    = BehaviorRelay<HoloDexResponse?>(value: nil)
    private let upStreamers    = BehaviorRelay<HoloDexResponse?>(value: nil)
    private let pastStreamers    = BehaviorRelay<HoloDexResponse?>(value: nil)
    private let refreshState = BehaviorRelay<Bool>(value: false)
    
    override init(_ services: AppServices) {
        super.init(services)
        
        refresh.subscribe(onNext: { _ in self.loadStreamers(services.settings.orgFilter) }).disposed(by: bag)
        liveStreamers.compactMap { $0 }//.distinctUntilChanged()
            .map { _ in false }
            .bind(to: refreshState)
            .disposed(by: bag)
    }
    
    func loadStreamers(_ org: Organization) {
        refreshState.accept(true)
        services.holodex.streamers(org.description, status: "live")
            .asObservable()
            .bind(to: liveStreamers)
            .disposed(by: bag)
        services.holodex.streamers(org.description, status: "upcoming")
            .asObservable()
            .bind(to: upStreamers)
            .disposed(by: bag)
        services.holodex.streamers(org.description, status: "past")
            .asObservable()
            .bind(to: pastStreamers)
            .disposed(by: bag)
        
        Observable.combineLatest(liveStreamers, upStreamers, pastStreamers)
            .asObservable()
            .map({ live, upcoming, past -> HoloDexResponse in
                var combined: [HoloDexResponse.Streamer] = []
                combined.append(contentsOf: live?.items ?? [])
                combined.append(contentsOf: upcoming?.items ?? [])
                combined.append(contentsOf: past?.items ?? [])
                return HoloDexResponse(items: combined)
            })
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
    func description(for section: Int, and index: Int) -> String? {
        let r = streamers.value?.sections()
        return r?[section].items[index].description
    }
    
    func title(for section: Int, and index: Int) -> String? {
        let r = streamers.value!.sections()
        return r[section].items[index].title
    }
    
    var streamersDriver: Driver<HoloDexResponse> {
        return streamers
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: .default())
    }
    var refreshDoneDriver: Driver<Bool> {
        return refreshState.asDriver()
    }
    
    func video(for section: Int, and index: Int) -> String {
        let r = streamers.value!.sections()
        //return "kWTVKNhRmfg"
        return r[section].items[index].id
    }
    func thumbnail(for section: Int, and index: Int) -> URL? {
        let r = streamers.value!.sections()
        return r[section].items[index].thumbnail
    }
    func backupThumbnail(for section: Int, and index: Int) -> URL? {
        let r = streamers.value!.sections()
        return r[section].items[index].backupThumbnail
    }
}

struct StreamerItemModel: SectionModelType {
    typealias Item = HoloDexResponse.Streamer
    
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

extension HoloDexResponse {
    func sections() -> [StreamerItemModel] {
        
        let l = items.filter { $0.status == .live }.sorted { $0.start_scheduled > $1.start_scheduled }
        let u = items.filter { $0.status == .upcoming }.sorted { $0.start_scheduled < $1.start_scheduled }
        let e = items.filter { $0.status == .past && $0.start_scheduled <= Date() }.sorted { $0.start_scheduled > $1.start_scheduled }
        
        var rtr: [StreamerItemModel] = []
        
        if !l.isEmpty { rtr.append(StreamerItemModel(title: Bundle.main.localizedString(forKey: "Live", value: "Live", table: "Localizeable"), items: l)) }
        if !u.isEmpty { rtr.append(StreamerItemModel(title: Bundle.main.localizedString(forKey: "Upcoming", value: "Upcoming", table: "Localizeable"), items: u)) }
        if !e.isEmpty { rtr.append(StreamerItemModel(title: Bundle.main.localizedString(forKey: "Ended", value: "Ended", table: "Localizeable"), items: e))}
        rtr.append(StreamerItemModel(title: Bundle.main.localizedString(forKey: "Stream data provided by Holodex.", value: "Stream data provided by Holodex.", table: "Localizeable"), items: []))
        
        return rtr
    }
}
