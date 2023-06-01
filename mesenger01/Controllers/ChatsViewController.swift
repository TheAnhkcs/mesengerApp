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
    public static let dateFormatter: DateFormatter = {
       let fmDate = DateFormatter()
        fmDate.dateStyle = .medium
        fmDate.timeStyle = .long
        fmDate.locale = .current
        return fmDate
    }()
    public var isNewConversation = false
    public let otherUserEmail:String
    private let conversationID:String?
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
            self?.presentPhotoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { [weak self] _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
        
        present(actionSheet, animated: true)
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

}

extension ChatsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
        let imageData = image.pngData(),
        let messageId = createMessageId(),
        let conversationId = conversationID,
        let name = self.title,
        let selfSender = self.selfSender else {
            return
        }
        
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
}

extension ChatsViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let selfSender = selfSender else {
            return
        }
        print("sending \(text)")
        //Send message
        
        let message = Message(sender: selfSender, messageId: createMessageId() ?? "", sentDate: Date(), kind: .text(text))
        if isNewConversation {
            //creat convo in database
            
            DatabaseManager.shared.createNewConvesation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message) { [weak self] success in
                guard let self = self else {return}
                if success {
                    print("success sent")
                    self.isNewConversation = false
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
        default:
            break
        }
    }
    
    
}
