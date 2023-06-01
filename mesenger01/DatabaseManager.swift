//
//  DatabaseManager.swift
//  Messager
//
//  Created by hoang the anh on 28/05/2023.
//

import Foundation
import FirebaseDatabase
import MessageKit


final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress:String) -> String {
        return emailAddress.replacingOccurrences(of: ".", with: "-")
    }
}

//MARK: - Account Management
extension DatabaseManager {
    
    
    
    public func userExists(with email:String, completion: @escaping (Bool) -> Void) {
        let safeEmail = email.replacingOccurrences(of: ".", with: "-")
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            guard ((snapshot.value as? String) != nil) else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    ///Inserts new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool)->Void) {
        database.child(user.safeEmail).setValue(["first_name": user.firstName, "last_name": user.lastName]) { error, _ in
            guard error == nil else {
                print("failed to write to database")
                completion(false)
                return
            }
            
            self.database.child("usersxx").observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let self = self else {return}
                if var usersCollection = snapshot.value as? [[String:String]] {
                    
                    let newElement = ["name":user.firstName + " " + user.lastName, "email": user.safeEmail]
                    usersCollection.append(newElement)
                    self.database.child("usersxx").setValue(usersCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }else {
                    let newCollection: [[String:String]] = [["name": user.firstName + " " + user.lastName,
                                                             "email": user.safeEmail]]
                    self.database.child("usersxx").setValue(newCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
        }
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String:String]], Error>) -> Void) {
        database.child("usersxx").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
}

struct ChatAppUser {
    let firstName:String
    let lastName:String
    let emailAddress:String
   
    
    var safeEmail:String {
        let email = emailAddress.replacingOccurrences(of: ".", with: "-")
        return email
    }
    var profilePictureFileName:String {
        return "\(safeEmail)_profile_picture.png"
    }
}

//MARK: Sending message / convesation
extension DatabaseManager {
    /*
     
     "jsadkfjksdf" {
     "messages": [
      {
     "id" : String,
     "type" : text, photo, video,
     "content" : String,
     "date" : Date,
     "sender_email" : String,
     "isRead" : true/false,
     }
     ]
     }
     
     
     
     conversation => [[
     "convesation_id": "jsadkfjksdf"
     "other_user_email":
     "lastest_message" => {
     "date": Date()
     "lasted+message": "message"
     "is_read": true/fase
     }
     ],[]]
     
     
     
     
     */
    //create a new convesation with target user email and first mesage sent
    public func createNewConvesation(with otherUserEmail:String, name:String, firstMessage:Message, completion: @escaping (Bool)-> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String, let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value) { snapshot in
            guard var userNode = snapshot.value as? [String:Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatsViewController.dateFormatter.string(from: messageDate)
            
            
            var message = ""
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            let newConversationData : [String:Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipient_newConversationData : [String:Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            //Update recipient conversation entry
            self.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let self = self else {return}
                if var conversations = snapshot.value as? [[String:Any]] {
                    conversations.append(recipient_newConversationData)
                    self.database.child("\(otherUserEmail)/conversations").setValue([conversations])
                }else {
                    self.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            }
            
            //Update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String:Any]] {
                // conversation array exists for current user
                //you should to append
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                
                ref.setValue(userNode) { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self.finishCreatingConvesation(name: name, conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                }
            }else {
              // convesation array does not exist
                //create it
                
                userNode["conversations"] = [
                newConversationData
                ]
                
                ref.setValue(userNode) { [weak self] error, _ in
                    guard let self = self else {return}
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self.finishCreatingConvesation(name: name, conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                   
                }
            }
        }
    }
    private func finishCreatingConvesation(name: String, conversationID: String, firstMessage:Message, completion: @escaping (Bool)->Void) {
//        {
//            "id":String,
//            "type": "",
//            "content":String,
//            "date": Date(),
//            "sender_email":String,
//            "isRead": true/false,
//
//        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatsViewController.dateFormatter.string(from: messageDate)
        
        
        var message = ""
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        let collectionMessage:[String:Any] = [
            "id":firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name": name
        ]
        
        let value: [String:Any] = [
            "messages": [
            collectionMessage
            ]
        ]
        print("adding convo \(conversationID)")
        database.child("\(conversationID)").setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    //fetches and returns al convesation for the user with passed email
    public func getAllConvesations(for email:String, completion: @escaping (Result<[Conversation], Error>)-> Void) {
        
        
        database.child("\(email)/conversations").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
           
            let conversations :[Conversation] = value.compactMap { dictionary in
                guard let converastionID = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMesssage = dictionary["latest_message"] as? [String:Any],
                      let date = latestMesssage["date"] as? String,
                      let message = latestMesssage["message"] as? String,
                      let isRead = latestMesssage["is_read"] as? Bool else {
                    return nil
                }
                
                let lastedMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                return Conversation(id: converastionID, name: name, otherUserEmail: otherUserEmail, latestMessage: lastedMessageObject)
            }
            
            completion(.success(conversations))
        }
    }
    //get all convesation for a given convesation
    public func getAllMessageForConvesation(with id:String, completion: @escaping (Result<[Message], Error>)->Void) {
        database.child("\(id)/messages").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages :[Message] = value.compactMap { dictionary in
                
                
               guard let content = dictionary["content"] as? String,
                     let date = dictionary["date"] as? String,
                     let id = dictionary["id"] as? String,
                     let isRead = dictionary["is_read"] as? Bool,
                     let name = dictionary["name"] as? String,
                     let senderMail = dictionary["sender_email"] as? String,
                     let type = dictionary["type"] as? String,
                let dataF = ChatsViewController.dateFormatter.date(from: date) else {
                   return nil
               }
                print("type is \(type)")
                var kind: MessageKind?
                if type == "photo" {
                    guard let imageUrl = URL(string: content),
                          let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    
                   
                    let meia = Media(url: imageUrl, image: nil, placeholderImage: placeholder, size: CGSize(width: 200, height: 200))
                    kind = .photo(meia)
                }
                else {
                    kind = .text(content)
                }
                guard let finalKind = kind else {
                    return nil
                }
                let sender = Sender(photoUrl: "", senderId: senderMail, displayName: name)
                return Message(sender: sender, messageId: content, sentDate: dataF, kind: finalKind)
            }
            print("allMessage is \(messages)")
            completion(.success(messages))
        }
    }
    //Send a mesgae with target convesastion and message
    public func sendMessage(to conversation:String, otherUserEmail:String, name:String, newMessage:Message, completion: @escaping (Bool)->Void) {
        //add new message to messages
        
        //update sender latest message
        
        //update recipient latest messafe
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else {return}
            guard var currentMessage = snapshot.value as? [[String:Any]] else {
                completion(false)
                return
            }
            let messageDate = newMessage.sentDate
            let dateString = ChatsViewController.dateFormatter.string(from: messageDate)
            
            
            var message = ""
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let itemStr = mediaItem.url?.absoluteString {
                message = itemStr
                }
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
            let newMessageEntry:[String:Any] = [
                "id":newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]
            
            currentMessage.append(newMessageEntry)
            self.database.child("\(conversation)/messages").setValue(currentMessage) { error, _ in
                guard error == nil else {
                    if let error = error {
                        print("Failed to set currentMessage \(error)")
                    }
                    completion(false)
                    return
                }
                
                self.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    let updatedValue :[String:Any] = [
                        "date": dateString,
                        "message": message,
                        "is_read": false
                    ]
                    
                    var targetConvesation :[String:Any]?
                    var position = 0
                    for conversationDic in currentUserConversations {
                        if let currentId = conversationDic["id"] as? String, currentId == conversation {
                            targetConvesation = conversationDic
                            break
                            
                        }
                        position += 1
                    }
                    
                    targetConvesation?["latest_message"] = updatedValue
                    guard let finalConvesation = targetConvesation else {
                        completion(false)
                        return
                    }
                    currentUserConversations[position] = finalConvesation
                    self.database.child("\(currentEmail)/conversations").setValue(currentUserConversations) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        self.database.child("\(otherUserEmail	)/conversations").observeSingleEvent(of: .value) { snapshot in
                            guard var otherUserConversations = snapshot.value as? [[String: Any]] else {
                                completion(false)
                                return
                            }
                            let updatedValue :[String:Any] = [
                                "date": dateString,
                                "message": message,
                                "is_read": false
                            ]
                            
                            var targetConvesation :[String:Any]?
                            var position = 0
                            for conversationDic in otherUserConversations {
                                if let currentId = conversationDic["id"] as? String, currentId == conversation {
                                    targetConvesation = conversationDic
                                    break
                                    
                                }
                                position += 1
                            }
                            
                            targetConvesation?["latest_message"] = updatedValue
                            guard let finalConvesation = targetConvesation else {
                                completion(false)
                                return
                            }
                            otherUserConversations[position] = finalConvesation
                            self.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations) { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            }
                }
                
            }
        }
    }
}
    }
}

extension DatabaseManager {
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>)->Void) {
        self.database.child("\(path)").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else {return}
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
}
