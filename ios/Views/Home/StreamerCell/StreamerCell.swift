//
//  StreamerCell.swift
//  ios
//
//  Created by Mason Phillips on 3/25/21.
//

import UIKit
import Neon
import Kingfisher
import SwiftDate



class StreamerCell: UITableViewCell {
    static let identifier: String = "streamerCell"
    
    let icon: UIImageView = UIImageView()
    
    let thumbnail: UIImageView = UIImageView()
    
    let title  : UILabel = UILabel()
    let channel: UILabel = UILabel()
    let start  : UILabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.clipsToBounds = true

        contentView.addSubview(thumbnail)
        
        contentView.addSubview(icon)
        
        title.font = .systemFont(ofSize: 18)
        title.textColor = .label
        contentView.addSubview(title)
        
        channel.font = .systemFont(ofSize: 15)
        channel.textColor = .secondaryLabel.withAlphaComponent(1.0)
        contentView.addSubview(channel)
        
        start.font = .systemFont(ofSize: 15)
        start.textColor = .secondaryLabel.withAlphaComponent(1.0)
        start.textAlignment = .right
        contentView.addSubview(start)
    }
    
    func configure(with item: HTResponse.Streamer, services: AppServices) {
        
        title.text = item.title
        channel.text = item.channel.name
        start.text = item.start_scheduled.toRelative(style: RelativeFormatter.defaultStyle())
        
        icon.kf.indicatorType = .activity
        icon.kf.setImage(with: item.channel.photo)
        
        var processor: ImageProcessor
        
        if services.settings.thumbnailDarken {
            processor = OverlayImageProcessor(overlay: .systemBackground, fraction: 0.4)
        } else {
            processor = OverlayImageProcessor(overlay: .systemBackground, fraction: 1)
        }
        
        if services.settings.thumbnailBlur{
            processor = processor |> BlurImageProcessor(blurRadius: 10.0)
        }
        
        if services.settings.thumbnails == false {
            thumbnail.isHidden = true
        } else {
            thumbnail.kf.setImage(with: item.thumbnail!, options: [.processor(processor)])
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        icon.anchorToEdge(.left, padding: 15, width: 50, height: 50)
        icon.layer.cornerRadius = 25
        icon.clipsToBounds = true
        
        title.alignAndFillWidth(align: .toTheRightMatchingTop, relativeTo: icon, padding: 10, height: 20)
        
        channel.align(.toTheRightMatchingBottom, relativeTo: icon, padding: 10, width: width - 180, height: 18)
        start.alignAndFillWidth(align: .toTheRightCentered, relativeTo: channel, padding: 10, height: 18)
        
        thumbnail.anchorToEdge(.left, padding: 0, width: contentView.width, height: (contentView.width * (16/9)))
        thumbnail.clipsToBounds = true
        
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}
