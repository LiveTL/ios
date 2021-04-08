//
//  ChatCell.swift
//  ios
//
//  Created by Mason Phillips on 4/4/21.
//

import UIKit

class ChatCell: UITableViewCell {
    static let identifier: String = "chatCell"

    @IBOutlet weak var author   : UILabel!
    @IBOutlet weak var message  : UILabel!
    @IBOutlet weak var timestamp: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(_ item: DisplayableMessage) {
        author.text = item.displayAuthor
        timestamp.text = item.displayTimestamp
        
        let fullMessage = NSMutableAttributedString()
        
        for m in item.displayMessage {
            switch m {
            case .text(let s):
                let am = NSAttributedString(string: s)
                fullMessage.append(am)
            case .emote(let u):
                let html = " <img src=\"\(u.absoluteString)\" /> "
                let data = Data(html.utf8)
                
                let string = try! NSAttributedString(data: data, options: [
                    .documentType: NSAttributedString.DocumentType.html
                ], documentAttributes: nil)
                
                fullMessage.append(string)
            }
        }
        
        message.attributedText = fullMessage
    }
}
