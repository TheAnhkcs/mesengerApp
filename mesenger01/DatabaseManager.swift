//
//  DatabaseManager.swift
//  Messager
//
//  Created by hoang the anh on 28/05/2023.
//

import Foundation
import FirebaseDatabase


final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
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
            completion(true)
        }
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
