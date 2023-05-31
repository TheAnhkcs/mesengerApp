//
//  ChatsViewController.swift
//  mesenger01
//
//  Created by hoang the anh on 30/05/2023.
//

import UIKit
import MessageKit
import InputBarAccessoryView

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
private var messages = [Message]()
    private var selfSender: Sender? = {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {return nil}
        let sender = Sender(photoUrl: "", senderId: email, displayName: "Joe Smith")
        return sender
    }()
    init(with email:String) {
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
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
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }

  

}

extension ChatsViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let selfSender = selfSender else {
            return
        }
        print("sending \(text)")
        //Send message
        if isNewConversation {
            //creat convo in database
            let message = Message(sender: selfSender, messageId: createMessageId() ?? "", sentDate: Date(), kind: .text(text))
            DatabaseManager.shared.createNewConvesation(with: otherUserEmail, firstMessage: message) { success in
                if success {
                    print("success sent")
                }else {
                    print("failed to sent")
                }
            }
        }else {
            //append to existing conversation data
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

extension ChatsViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self sender is nil, email should be cached")
        return Sender(photoUrl: "", senderId: "12", displayName: "")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
