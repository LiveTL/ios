//
//  MchadRoom.swift
//  ios
//
//  Created by Andrew Glaze on 8/24/21.
//

import Foundation

struct MchadRoom: Decodable {
    let Room: String?
    let Link: String?
    let Nick: String?
    let EntryPass: Bool?
    let Empty: Bool?
    let Pass: Bool?
    let StreamLink: String?
    let Tags: String
    let ExtShare: Bool?
    let Downloadable: Bool?
}

struct MchadScript: Decodable {
    let Stime: Date
    let Stext: String
    let CC: String?
    let OC: String?
}