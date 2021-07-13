//
//  Organizations.swift
//  ios
//
//  Created by Andrew Glaze on 7/12/21.
//

import Foundation

enum Organization: String, CustomStringConvertible, CaseIterable {
    var description: String {
        switch self {
        case .all:
            return "All Vtubers"
        case .Hololive:
            return "Hololive"
        case .Nijisanji:
            return "Nijisanji"
        case .Independents:
            return "Independents"
        case .AogiriHighSchool:
            return "Aogiri Highschool"
        case .AtelierLive:
            return "Atelier Live"
        case .Chukorara:
            return "Chukorara"
        case .ElieneFamily:
            return "Eliene Family"
        case .HoshimeguriGakuen:
            return "Hoshimeguri Gakuen"
        case .Iridori:
            return "Iridori"
        case .KAMITSUBAKI:
            return "KAMITSUBAKI"
        case .KizunaAi:
            return "Kizuna Ai Inc."
        case .Marbl_s:
            return "Marbl_s"
        case .Masquerade:
            return "Masquerade"
        case .NoriPro:
            return "Nori Pro"
        case .RiotMusic:
            return "Riot Music"
        case .Tsunderia:
            return "Tsunderia"
        case .UnrealNightGirls:
            return "Unreal Night Girls"
        case .VDimensionCreators:
            return "V Dimension.Creators"
        case .VOICEORE:
            return "VOICE-ORE"
        case .Xencount:
            return "X enc'ount"
        case .YuniCreate:
            return "YuniCreate"
        case .inc774:
            return "774inc"
        case .dotLIVE:
            return ".LIVE"
        case .MAHA5:
            return "MAHA5"
        case .PRISM:
            return "PRISM"
        case .ProPro:
            return "ProPro"
        case .ReACT:
            return "ReACT"
        case .ViViD:
            return "ViViD"
        case .VOMS:
            return "VOMS"
        case .VShojo:
            return "VShojo"
        case .VSpo:
            return "VSpo"
        case .WACTOR:
            return "WACTOR"
        }
    }
    
    case all, Hololive, Nijisanji, Independents, AogiriHighSchool, AtelierLive, Chukorara, ElieneFamily, HoshimeguriGakuen, Iridori, KAMITSUBAKI, KizunaAi, Marbl_s, Masquerade, NoriPro, RiotMusic, Tsunderia, UnrealNightGirls, VDimensionCreators, VOICEORE, Xencount, YuniCreate, inc774, dotLIVE, MAHA5, PRISM, ProPro, ReACT, ViViD, VOMS, VShojo, VSpo, WACTOR
}
