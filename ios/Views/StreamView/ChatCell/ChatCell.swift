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
        if item.isMchad {
            timestamp.text = "Mchad"
        }
        
        // This should reset the cell, so we aviod duplicate superchats and members
        timestamp.font = .systemFont(ofSize: 17)
        timestamp.textColor = .secondaryLabel
        contentView.layer.cornerRadius = 0
        contentView.backgroundColor = .clear
        author.textColor = .secondaryLabel

        if item.superchatData != nil {
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
            case .emote(var u, let id):
                if id != nil {
                    if id!.isSingleEmoji {
                        let am = NSAttributedString(string: id!)
                        fullMessage.append(am)
                    } else {
                        if u.pathExtension == "svg" {
                            u.deletePathExtension()
                            u.appendPathExtension("png")
                        }
                        let html = " <img src=\"\(u.absoluteString)\" width=\"24\" height=\"24\"/> "
                        let data = Data(html.utf8)

                        do {
                            let string = try NSAttributedString(data: data, options: [
                                .documentType: NSAttributedString.DocumentType.html
                            ], documentAttributes: nil)
                            fullMessage.append(string)
                        } catch {
                            // Hmmm... emote NSAttributedString failed. Must be on macOS.
                        }
                    }
                }
            }
        }

        // print("\(item.displayAuthor): \(item.displayMessage)")
        message.attributedText = fullMessage
    }
}

extension Character {
    var isSimpleEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }

    var isCombinedIntoEmoji: Bool { unicodeScalars.count > 1 && unicodeScalars.first?.properties.isEmoji ?? false }

    var isEmoji: Bool { isSimpleEmoji || isCombinedIntoEmoji }
}

extension String {
    var isSingleEmoji: Bool { count == 1 && containsEmoji }

    var containsEmoji: Bool { contains { $0.isEmoji } }

    var containsOnlyEmoji: Bool { !isEmpty && !contains { !$0.isEmoji } }

    var emojiString: String { emojis.map { String($0) }.reduce("", +) }

    var emojis: [Character] { filter { $0.isEmoji } }

    var emojiScalars: [UnicodeScalar] { filter { $0.isEmoji }.flatMap { $0.unicodeScalars } }
}
