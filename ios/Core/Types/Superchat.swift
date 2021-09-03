//
//  SuperChat.swift
//  ios
//
//  Created by Andrew Glaze on 8/12/21.
//

import UIKit

struct Superchat: Decodable {
    let amount: String
    let color: String
    var UIcolor: UIColor {
        switch color {
        case "blue":
            return UIColor(red: 113/255, green: 170/255, blue: 255/255, alpha: 1)
        case "lightblue":
            return UIColor(red: 32/255, green: 189/255, blue: 255/255, alpha: 1)
        case "turquoise":
            return UIColor(red: 31/255, green: 191/255, blue: 165/255, alpha: 1)
        case "yellow":
            return UIColor(red: 254/255, green: 202/255, blue: 41/255, alpha: 1)
        case "orange":
            return UIColor(red: 246/255, green: 124/255, blue: 0/255, alpha: 1)
        case "pink":
            return UIColor(red: 250/255, green: 54/255, blue: 100/255, alpha: 1)
        case "red":
            return UIColor(red: 230/255, green: 33/255, blue: 23/255, alpha: 1)
        default:
            return UIColor.clear
        }
    }
}


