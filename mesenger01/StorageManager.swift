//
//  StorageManager.swift
//  mesenger01
//
//  Created by hoang the anh on 30/05/2023.
//

import Foundation
import FirebaseStorage

typealias UploadPictureCompletion = (Result<String, Error>) -> Void

final class StorageManager {
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    
    /*
     images/anh@gmail-com_profile_picture.png
     */
    
    //upload picture to firebase storage and returns completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName:String, completion: @escaping UploadPictureCompletion) {
        storage.child("image/\(fileName)").putData(data, metadata: nil) { metadata, error in
            guard error == nil else {
                completion(.failure(StorgeError.failedToUpload))
                return
            }
            
            self.storage.child("image/\(fileName)").downloadURL { url, error in
                
                print("url downloadPicture is \(url)")
                
                guard let url = url else {
                    completion(.failure(StorgeError.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            }
            
            
            
        }
    }
    
    //upload image that will be sent in a conversation message
    public func uploadMessagePhoto(with data: Data, fileName:String, completion: @escaping UploadPictureCompletion) {
       
        
        storage.child("message_images/\(fileName)").putData(data, metadata: nil) { [weak self] metadata, error in
            guard let self = self else {return}
            guard error == nil else {
                completion(.failure(StorgeError.failedToUpload))
                return
            }
            
            self.storage.child("message_images/\(fileName)").downloadURL { url, error in
                
                guard let url = url else {
                    completion(.failure(StorgeError.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            }
            
            
            
        }
    }
    
    public func uploadMessageVideo(with fileURL: URL, fileName:String, completion: @escaping UploadPictureCompletion) {
       
        
       
        
        storage.child("message_videos/\(fileName)").putFile(from: fileURL) {[weak self] metadata, error in
            guard let self = self else {return}
            guard error == nil else {
                if let error = error {
                    print("error issssssssssss \(error)")
                }
                completion(.failure(StorgeError.failedToUpload))
                return
            }
            self.storage.child("message_videos/\(fileName)").downloadURL { url, error in
            
                            guard let url = url else {
                                completion(.failure(StorgeError.failedToGetDownloadUrl))
                                return
                            }
            
                            let urlString = url.absoluteString
                            print("download url returned: \(urlString)")
                            completion(.success(urlString))
                        }
                    }
    }
    
    public func downloadUrl(for path:String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
       
        reference.downloadURL { result in
            switch result {
                
            case .success(let url):
                print(url)
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
    }
}

enum StorgeError: Error {
    case failedToUpload
    case failedToGetDownloadUrl
}
