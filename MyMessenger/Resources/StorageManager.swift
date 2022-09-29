//
//  StorageManager.swift
//  MyMessenger
//
//  Created by Hasan Kaya on 22.08.2022.
//

import Foundation
import FirebaseStorage

/// allows you to get fetch, and upload files to firebase storage
final class StorageManager {
    static let shared = StorageManager()
    private init () {}
    private let storage = Storage.storage().reference()

    public typealias UploadPictureCompletion = (Result<String,Error>) -> Void
    /// Upload Profile Picture
    public func UploadProfilePicture(with data : Data , fileName : String, completion : @escaping UploadPictureCompletion){
    
        storage.child("Images/\(fileName)").putData(data) { [weak self] metaData, error in
            guard error == nil ,let strongSelf = self else {
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            strongSelf.storage.child("Images/\(fileName)").downloadURL { url, error in
               
                guard let url = url else {
                    print("failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                completion(.success(urlString))

            }
            
        }
        
    }
    /// Upload Photo to send in Conversation
    public func uploadPhotoMessage(with data : Data , fileName : String, completion : @escaping UploadPictureCompletion){
    
        storage.child("message_images/\(fileName)").putData(data) { [weak self] metaData, error in
            guard error == nil else {
                completion(.failure(StorageErrors.failedToUpload))
                print("error to upload firebase to profile picture")
                return
            }
            self?.storage.child("message_images/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    print("failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                completion(.success(urlString))

            }
            
        }
        
    }
    // uplaod Video Message
    public func uploadVideoMessage(with fileUrl : URL , fileName : String, completion : @escaping UploadPictureCompletion){
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl) { [weak self] metaData, error in
            guard error == nil else {
                completion(.failure(StorageErrors.failedToUpload))
                print("error to upload firebase to video file")
                return
            }
            self?.storage.child("message_videos/\(fileName)").downloadURL { url, error in
                print(url)
                guard let url = url else {
                    print("failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("Download Url returned : \(urlString)")
                completion(.success(urlString))

            }
            
        }
        
    }
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }

    public func downloadURL(fileName: String, completion: @escaping (Result<String,Error>) -> Void) {
        self.storage.child("Images/\(fileName)").downloadURL { url, error in
            guard let url = url else {
                print("failed to get download url")
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            let urlString = url.absoluteString
            completion(.success(urlString))

        }
        }
    
}
