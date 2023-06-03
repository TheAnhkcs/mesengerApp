//
//  ChatsViewController.swift
//  mesenger01
//
//  Created by hoang the anh on 30/05/2023.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation

struct Message: MessageType {
    public  var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

extension MessageKind {
    var messageKindString:String {
        switch self {
            
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_Text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}

struct Location: LocationItem {
    var location: CLLocation
    
    var size: CGSize
    
    
}

struct Sender: SenderType {
    public var photoUrl:String
    public var senderId: String
    public var displayName: String
}

struct Media: MediaItem {
    var url: URL?
    
    var image: UIImage?
    
    var placeholderImage: UIImage
    
    var size: CGSize
    
    
}

class ChatsViewController: MessagesViewController {
    
    private var senderPhotoUrl:URL?
    private var otherUserPhotoUrl:URL?
    public static let dateFormatter: DateFormatter = {
       let fmDate = DateFormatter()
        fmDate.dateStyle = .medium
        fmDate.timeStyle = .long
        fmDate.locale = .current
        return fmDate
    }()
    public var isNewConversation = false
    public let otherUserEmail:String
    private var conversationID:String?
private var messages = [Message]()
    private var selfSender: Sender? = {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {return nil}
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let sender = Sender(photoUrl: "", senderId: safeEmail, displayName: "Me")
        return sender
    }()
    init(with email:String, id: String?) {
        self.conversationID = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
        
        if let conversationID = conversationID {
            listenForMesssage(id: conversationID)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .red
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.becomeFirstResponder()
        setupInputButton()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }

    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 30, height: 30), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { _ in
            self.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media", message: "What would you like to attach", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            guard let self = self else {return}
            self.presentPhotoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            guard let self = self else {return}
            self.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { [weak self] _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] _ in
            guard let self = self else {return}
            self.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinate: nil)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode  = .never
        vc.completion = { [weak self] selectedCoordinate in
            guard let self = self else {return}
            guard let messageId = self.createMessageId(), let conversationId = self.conversationID, let name = self.title, let selfSender = self.selfSender else {
                return
            }
            
            
            
            let longitude: Double = selectedCoordinate.longitude
            let latitude:Double = selectedCoordinate.latitude
            
            print("long = \(longitude) / lat = \(latitude)")
           
            let media = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: .zero)
            let message = Message(sender: selfSender, messageId: self.createMessageId() ?? "", sentDate: Date(), kind: .location(media))
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { success in
                if success {
                    print("sent location message")
                }else {
                    print("Failed sent location message")
                }
            }
        }
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where would you like to attach a photo from?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
      
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where would you like to attach a photo from?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
      
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    
    private func listenForMesssage(id:String) {
        
       
        DatabaseManager.shared.getAllMessageForConvesation(with: id) { [weak self] result in
            guard let self = self else {return}
            switch result {
                
            case .success(let message):
                guard !message.isEmpty else {
                    return
                }
                self.messages = message
//                print("messagec is \(message)")
                DispatchQueue.main.async {
               
                self.messagesCollectionView.reloadDataAndKeepOffset()
                    
                }
            case .failure(let error):
                print("Failed to get message \(error)")
            }
        }
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == self.selfSender?.senderId {
            return .link
        }
        return .lightGray
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        
        if sender.senderId == selfSender?.senderId {
            if let currentUserImageURL = self.senderPhotoUrl {
                avatarView.sd_setImage(with: currentUserImageURL)
            }else{
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "image/\(safeEmail)_profile_picture.png"
                
                StorageManager.shared.downloadUrl(for: path) {[weak self] result in
                    guard let self = self else {return}
                    switch result {
                    case .success(let url):
                        self.senderPhotoUrl = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url)
                        }
                        
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }else {
            if let otherUserImageURL = self.otherUserPhotoUrl {
                avatarView.sd_setImage(with: otherUserImageURL)
            }else{
                 let email = self.otherUserEmail
                
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "image/\(safeEmail)_profile_picture.png"
                
                StorageManager.shared.downloadUrl(for: path) {[weak self] result in
                    guard let self = self else {return}
                    switch result {
                    case .success(let url):
                        self.otherUserPhotoUrl = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url)
                        }
                        
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
    }

}

extension ChatsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let messageId = createMessageId(),
        let conversationId = conversationID,
        let name = self.title,
        let selfSender = self.selfSender else {
            return
        }
        
        
        if let image = info[.editedImage] as? UIImage,
           let imageData = image.pngData() {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            //Upload image
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName) { [weak self] result in
                guard let self = self else {return}
                
                switch result {
                    
                case .success(let urlSt):
                    print("Upload message photo \(urlSt)")
                    
                    guard let url = URL(string: urlSt),
                    let palceholder = UIImage(systemName: "plus") else {return}
                    let media = Media(url: url, image: nil, placeholderImage: palceholder, size: .zero)
                    let message = Message(sender: selfSender, messageId: self.createMessageId() ?? "", sentDate: Date(), kind: .photo(media))
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("sent photo message")
                        }else {
                            print("Failed sent photo message")
                        }
                    }
                case .failure(let error):
                    print("message photo upload error \(error)")
                }
            }
        }
        else if let videoUrl = info[.mediaURL] as? URL {
        
            let fileName = "video_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            StorageManager.shared.uploadMessageVideo(with: videoUrl.absoluteURL, fileName: fileName) { [weak self] result in
                guard let self = self else {return}
                print("77777777777777777777777777777777 \(result)")
                switch result {
                    
                case .success(let urlSt):
                    print("Upload message video \(urlSt)")
                    
                    guard let url = URL(string: urlSt),
                    let palceholder = UIImage(named: "film-roll") else {return}
                    let media = Media(url: url, image: nil, placeholderImage: palceholder, size: .zero)
                    let message = Message(sender: selfSender, messageId: self.createMessageId() ?? "", sentDate: Date(), kind: .video(media))
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("sent photo message")
                        }else {
                            print("Failed sent photo message")
                        }
                    }
                case .failure(let error):
                    print("message photo upload error \(error)")
                }
            }
        }
        
    }

}

extension ChatsViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let selfSender = selfSender else {
            return
        }
        
        //Send message
        
        let message = Message(sender: selfSender, messageId: createMessageId() ?? "", sentDate: Date(), kind: .text(text))
        if isNewConversation {
            //creat convo in database
            
            DatabaseManager.shared.createNewConvesation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message) { [weak self] success in
                guard let self = self else {return}
                if success {
                    print("success sent")
                    self.isNewConversation = false
                     let newConversationId = "conversation_\(message.messageId)"
                    self.conversationID = newConversationId
                    self.listenForMesssage(id: self.conversationID!)
                    
                }else {
                    print("failed to sent")
                }
            }
        }else {
            //append to existing conversation data
            
            guard let conversationId = conversationID, let name = self.title else {
                return
            }
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: message) { success in
                if success {
                    print("message sent")
                }else {
                    print("failed to sent")
                }
            }
        }
        inputBar.inputTextView.text = ""
        
        
    }
    private func createMessageId() -> String? {
        //data, otherEmail, senderEmail , randomInt
        
        guard let curentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: curentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeEmail)_\(dateString)"
        print("created message id: \(newIdentifier)")
        return newIdentifier
    }
    
}

extension ChatsViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, MessageCellDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self sender is nil, email should be cached")
        
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        
    default:
        break
    }
    }
    
    
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = self.messages[indexPath.section]
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            
            let vc = PhotoViewerViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
            
          let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true)
        default:
            break
        }
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = self.messages[indexPath.section]
        switch message.kind {
        case .location(let locationData):
            let coordinate = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinate: coordinate)
            vc.title = "Location"
            self.navigationController?.pushViewController(vc, animated: true)
       
        default:
            break
        }
    }
    
    
}
