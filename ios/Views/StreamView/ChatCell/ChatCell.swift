//
//  ChatCell.swift
//  ios
//
//  Created by Mason Phillips on 4/4/21.
//

import FontAwesome_swift
import UIKit

class ChatCell: UITableViewCell {
    static let identifier: String = "chatCell"

    @IBOutlet var author: UILabel!
    @IBOutlet var message: UILabel!
    @IBOutlet var timestamp: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(_ item: DisplayableMessage, useTimestamps: Bool) {
        author.text = item.displayAuthor
        timestamp.text = useTimestamps ? item.displayTimestamp : ""
        
        if item.superchatData != nil {
            // print(item.superchatData)
            timestamp.text = item.superchatData?.amount
            timestamp.font = .boldSystemFont(ofSize: 17)
            timestamp.textColor = .label
            contentView.layer.cornerRadius = 10
            contentView.backgroundColor = item.superchatData?.UIcolor
        }
        
        if item.isMember {
            author.textColor = UIColor(red: 44/255, green: 166/255, blue: 63/255, alpha: 1)
        }
        if item.isMod {
            print("mod")
            author.textColor = UIColor(red: 99/255, green: 118/255, blue: 254/255, alpha: 1)
        }
        
        let fullMessage = NSMutableAttributedString()
        
        for m in item.displayMessage {
            switch m {
            case .text(let s):
                let am = NSAttributedString(string: s)
                fullMessage.append(am)
            case .emote(let u):
                let html = " <img src=\"\(u.absoluteString)\" /> "
                let data = Data(html.utf8)
                
                do {
                    let string = try NSAttributedString(data: data, options: [
                        .documentType: NSAttributedString.DocumentType.html
                    ], documentAttributes: nil)
                    
                    fullMessage.append(string)
                } catch {
                    // print("Hmm..., emote NSAttributedString failed. Must be on macOS.")
                }
            }
        }
        
        message.attributedText = fullMessage
    }
}
