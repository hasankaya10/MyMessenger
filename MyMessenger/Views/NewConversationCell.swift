//
//  NewConversationTableViewCell.swift
//  MyMessenger
//
//  Created by Hasan Kaya on 13.09.2022.
//

import Foundation
import SDWebImage

class NewConversationCell: UITableViewCell {
    static let identifier = "NewConversationCell"
    private var userImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 35
        return imageView
    }()
    private var userNameLabel : UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
        
    }()

    
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(   x: 10,
                                        y: (contentView.top + contentView.bottom - 60) / 2,
                                     width: 70,
                                     height: 70)
        userNameLabel.frame = CGRect(x: userImageView.right + 10,
                                     y: 20,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: 50)
       
        
    }
    public func configure(with model : SearchResult) {
        userNameLabel.text = model.name
        let path = "\(model.email)_profile_picture.png"
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
