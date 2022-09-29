//
//  ConversationTableViewCell.swift
//  MyMessenger
//
//  Created by Hasan Kaya on 31.08.2022.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
    static let identifier = "ConversationTableViewCell"
    private var userImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 30
        return imageView
    }()
    private var userNameLabel : UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
        
    }()
    private var userMessageLabel : UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.numberOfLines = 0
        return label
        
    }()
    
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(   x: 10,
                                        y: (contentView.top + contentView.bottom - 60) / 2,
                                     width: 60,
                                     height: 60)
        userNameLabel.frame = CGRect(x: userImageView.right + 10,
                                     y: 10,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: (contentView.height - 20)/2)
        userMessageLabel.frame = CGRect(    x: userImageView.right + 10,
                                        y: userNameLabel.bottom ,
                                        width: contentView.width - 20 - userImageView.width,
                                        height: (contentView.height - 40)/2)
        
        
    }
    public func configure(with model : Conversation) {
        userNameLabel.text = model.name
        let message = model.latestMessage.Message
        
        
        if model.latestMessage.Message.contains("https://firebasestorage") {
            userMessageLabel.text = "Photo Message"
        } else if message.contains("0") && message.contains(",") && message.contains(".") {
            userMessageLabel.text = "Location Message"
        } else {
            userMessageLabel.text = message
        }
        
        let path = "\(model.otherUserEmail)_profile_picture.png"
        StorageManager.shared.downloadURL(fileName: path) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    strongSelf.userImageView.sd_setImage(with: URL(string: url))
                }
            case .failure(let error):
                print(error)
            }
        }
        
    }
    
}
