//
//  ConversationTableViewCell.swift
//  mesenger01
//
//  Created by hoang the anh on 01/06/2023.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
    
    static let identifier = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 35
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userNameLable: UILabel = {
       let lable = UILabel()
        lable.font = .systemFont(ofSize: 25, weight: .semibold)
        lable.numberOfLines = 0
        return lable
    }()
    
    private let userMesageLable: UILabel = {
       let lable = UILabel()
        lable.font = .systemFont(ofSize: 18, weight: .regular)
        return lable
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLable)
        contentView.addSubview(userMesageLable)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: 10, y: 10, width: 70, height: 70)
        userNameLable.frame = CGRect(x: userImageView.right + 10, y: 5, width: contentView.width - 20 - userImageView.width, height: (contentView.height - 20)/2)
        userMesageLable.frame = CGRect(x: userImageView.right + 10, y: userNameLable.bottom + 5, width: contentView.width - 20 - userImageView.width, height: (contentView.height - 20)/2)
    }
    
    public func configure(with model:Conversation) {
        self.userMesageLable.text = model.latestMessage.text
        self.userNameLable.text = model.name
        
        let path = "image/\(model.otherUserEmail)_profile_picture.png"
        StorageManager.shared.downloadUrl(for: path) { [weak self] result in
            guard let self = self else {return}
            switch result {
                
            case .success(let url):
                DispatchQueue.main.async {
                self.userImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("Failed to get image url \(error)")
            }
        }
    }
    
}
