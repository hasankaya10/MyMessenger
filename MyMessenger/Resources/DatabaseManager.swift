//
//  DatabaseManager.swift
//  MyMessenger
//
//  Created by Hasan Kaya on 20.08.2022.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth
import MessageKit
import CoreLocation

/// Manager object to read and write data to realtime database
final class DatabaseManager{
    /// shared instance of class
    static let shared = DatabaseManager()
    private init(){}
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
            var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
            safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
            return safeEmail
        }
}
// get name datas for user
extension DatabaseManager {
    /// returns dictionary node at child path
    public func getDataFor(path : String , completion : @escaping (Result<Any,Error>) -> Void) {
        database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}
// MARK: - Account Management
extension DatabaseManager {
    /// check if user exists for given email
    public func isUserExists(with  email: String, completion : @escaping ((Bool)->(Void))){
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? [String : Any] != nil else {
                completion(false)
                return 
            }
            completion(true)
        }
    }
    
    
    /// inserts new user to database
    public func insertNewUser(with user: MyMessengerUser, completion : @escaping ((Bool)->(Void))){
        database.child(DatabaseManager.safeEmail(emailAddress: user.emailAdress)).setValue([
            "first_name" : user.firstName,
            "last_name" : user.lastName
        ]) { [weak self] error, _ in
            guard error == nil else {
                completion(false)
                print("failed to write firebase")
                return
            }
            guard let strongSelf = self else {
                return
            }
            strongSelf.database.child("users").observeSingleEvent(of: .value) { snapshot in
                if var usersCollection = snapshot.value as? [[String:String]] {
                    // append to user dictionary
                    let newElement = [
                        "name" : user.firstName + " " + user.lastName,
                        "email" : DatabaseManager.safeEmail(emailAddress: user.emailAdress)
                    ]
                    usersCollection.append(newElement)
                    strongSelf.database.child("users").setValue(usersCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                    
                }
                else {
                    // create the array
                    let newCollection : [[String:String]] = [
                        [
                            "name" : user.firstName + " " + user.lastName,
                            "email" : DatabaseManager.safeEmail(emailAddress: user.emailAdress)
                        
                        
                        ]
                    ]
                    strongSelf.database.child("users").setValue(newCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
            /*
             users ->
             [  [
                "name" : "Hasan Kaya"
                "email": hasan@gmail.com
                ],
             [
               "name" : "Beyza Erol"
               "email": beyza@gmail.com
               ]
             
             ]
             */
        }
    }
    public func getAllUsers(completion: @escaping (Result<[[String:String]],Error>)-> Void){
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    public enum DatabaseErrors : Error{
        case failedToFetch
    }
}
// MARK: - Sending Messages / Conversations
extension DatabaseManager {
    /*
            (conversation example ->) "123456" {
                "messages": [
                    {
                        "id": String,
                        "type": text, photo, video,
                        "content": String,
                        "date": Date(),
                        "sender_email": String,
                        "isRead": true/false,
                    }
                ]
            }
               conversaiton => [
                  [
                      "conversation_id": "123456"
                      "other_user_email":
                      "latest_message": => {
                        "date": Date()
                        "latest_message": "message"
                        "is_read": true/false
                      }
                  ],
                ]
               */
    
    /// Create new conversation with target Email and sending first message
    public func createNewConversation(with otherUserEmail : String, firstMessage : Message,name: String, completion: @escaping (Bool) -> Void){
        guard let currentEmail = Auth.auth().currentUser?.email as? String,
        let currentName = UserDefaults.standard.value(forKey: "name") else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String:Any] else {
                print("user not found")
                return
            }
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch firstMessage.kind {
                
            case .text(let messagesended):
                message = messagesended
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
            let newConversationData : [String : Any] = [
                "id" : conversationId,
                "other_user_email" : otherUserEmail,
                "name": name,
                "latest_message" : [
                    "date" : dateString,
                    "message" : message,
                    "isRead" : false
                ]
            ]
            let recipient_newConversationData : [String : Any] = [
                "id" : conversationId,
                "other_user_email" : safeEmail,
                "name": currentName,
                "latest_message" : [
                    "date" : dateString,
                    "message" : message,
                    "isRead" : false
                ]
            ]
            // Update other user conversation entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String:Any]] {
                    // append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else {
                    
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                    // create a conversation array
                }
            }
            
            // Update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // append message to conversations array that is exist
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        print(error?.localizedDescription)
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversations(name: name,conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                    
                }
                
                
            } else {
                // create a conversation array
                userNode["conversations"] = [
                newConversationData
                ]
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        print(error?.localizedDescription)
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversations(name: name,conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                   
                    
                }
                    
                
            }
        }
    }
    private func finishCreatingConversations(name: String, conversationID : String , firstMessage : Message, completion : @escaping (Bool) -> Void) {
        var message = ""
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        switch firstMessage.kind {
            
        case .text(let messagesended):
            message = messagesended
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
        guard let currentUserEmail = Auth.auth().currentUser?.email as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let collectionMessage : [String : Any] = [
            "id" : firstMessage.messageId,
            "name" : name,
            "type": firstMessage.kind.messageKindString,
            "content" : message,
            "date" : dateString,
            "sender_email" : safeEmail,
            "is_read" : false
        ]
        let value : [String : Any] = [
            "messages": [
            collectionMessage
            ]
        ]
        
        database.child("\(conversationID)").setValue(value) { error, _ in
            guard error == nil else {
                print(error?.localizedDescription)
                completion(false)
                return
            }
            completion(true)

        }
    }
    /// fetch all conversations for  auth email
    public func getAllConversations(for Email : String, completion : @escaping (Result<[Conversation],Error>) -> Void){
        database.child("\(Email)/conversations").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            let conversations: [Conversation] = value.compactMap { dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String ,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String:Any],
                      let date = latestMessage["date"] as? String,
                      let is_read = latestMessage["isRead"] as? Bool,
                      let message = latestMessage["message"] as? String else {
                    return nil
                }
                let latestMessageObject = LatestMessage(date: date, Message: message, isRead: is_read)
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
             }
            completion(.success(conversations))
            
            
        }
    
    }
    
    /// fetch all messages for given conversation
    public func getAllMessagesForConversation(with id : String, completion: @escaping (Result<[Message],Error>) -> Void){
        database.child("\(id)/messages").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            let messages: [Message] = value.compactMap { dictionary in
                guard let content = dictionary["content"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let id = dictionary["id"] as? String,
                      let is_read = dictionary["is_read"] as? Bool,
                      let name = dictionary["name"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                        return nil
                }
                let kind : MessageKind?
                
                if type == "photo" {
                    guard let imageUrl = URL(string: content) ,
                    let placeholder = UIImage(systemName: "photo") else {
                        return nil
                    }
                    let media = Media(url: imageUrl, image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                } else if type == "video" {
                    guard let videoUrl = URL(string: content) ,
                    let placeholder = UIImage(systemName: "photo") else {
                        return nil
                    }
                    let media = Media(url: videoUrl, image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                } else if type == "location" {
                    let locationComponents = content.components(separatedBy: ",")
                    guard  let longitude = Double(locationComponents[0]),
                           let latitude = Double(locationComponents[1]) else {
                        return nil
                    }
                    
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: CGSize(width: 300, height: 300))
                    kind = .location(location)
                } else {
                    kind = .text(content)
                }
                guard let finalKind = kind else {
                    return nil
                }
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                return Message(sender: sender, messageId: id, sentDate: date, kind: finalKind)
            }
            completion(.success(messages))
            
            
        }
    }
    /// send messages with target conversation and message
    public func sendMessages(to conversation : String,otherUserEmail : String, name : String,  newMessage : Message, completion: @escaping (Bool) -> Void){
        guard let myEmail = Auth.auth().currentUser?.email else {
            completion(false)
            return
        }
        let mySafeEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        database.child("\(conversation)/messages").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let strongSelf = self else {
                return
            }
            guard var currentMessages = snapshot.value as? [[String:Any]] else {
                completion(false)
                return
            }
            var message = ""
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            switch newMessage.kind {
                
            case .text(let messagesended):
                message = messagesended
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
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
            guard let currentUserEmail = Auth.auth().currentUser?.email as? String else {
                return
            }
            let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
            let collectionMessage : [String : Any] = [
                "id" : newMessage.messageId,
                "name" : name,
                "type": newMessage.kind.messageKindString,
                "content" : message,
                "date" : dateString,
                "sender_email" : safeEmail,
                "is_read" : false
            ]
            currentMessages.append(collectionMessage)
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                strongSelf.database.child("\(safeEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                    var databaseEntryConversations = [[String : Any]]()
                    let updatedValue : [String:Any] = [
                        "date": dateString,
                        "isRead": false ,
                        "message": message,
                    ]
                    if var currentUserConversations = snapshot.value as? [[String:Any]]{
                       
                        var targetConversation : [String: Any]?
                        var position = 0
                        
                        for conversationDictionary in currentUserConversations {
                            if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                targetConversation = conversationDictionary
                                break
                            }
                            position += 1
                        }
                        if var targetConversation = targetConversation {
                            targetConversation["latest_message"] = updatedValue
                            currentUserConversations[position] = targetConversation
                            databaseEntryConversations = currentUserConversations
                        }
                        else {
                            let newConversationData : [String : Any] = [
                                "id" : conversation,
                                "other_user_email" : DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                                "name": name,
                                "latest_message" : updatedValue
                            ]
                            currentUserConversations.append(newConversationData)
                            databaseEntryConversations = currentUserConversations
                        }
                    }
                    else {
                        let newConversationData : [String : Any] = [
                            "id" : conversation,
                            "other_user_email" : DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                            "name": name,
                            "latest_message" : updatedValue
                        ]
                        databaseEntryConversations = [
                        newConversationData
                        ]
                    }
                   
                    strongSelf.database.child("\(safeEmail)/conversations").setValue(databaseEntryConversations) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        // update latest message for recipient user
                        
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                            let updatedValue : [String:Any] = [
                                "date": dateString,
                                "isRead": false ,
                                "message": message,
                            ]
                            var databaseEntryConversations = [[String : Any]]()
                            guard let currentName = UserDefaults.standard.object(forKey: "name") as? String else {
                                return
                            }
                            
                            if var otherUserConversations = snapshot.value as? [[String:Any]] {
                                var targetConversation : [String: Any]?
                                var position = 0
                                
                                for conversationDictionary in otherUserConversations {
                                    if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                        targetConversation = conversationDictionary
                                        break
                                    }
                                    position += 1
                                }
                                if var targetConversation = targetConversation {
                                    targetConversation["latest_message"] = updatedValue
                                    otherUserConversations[position] = targetConversation
                                    databaseEntryConversations = otherUserConversations
                                } else {
                                    // failed to find in current collection
                                    
                                    let newConversationData : [String : Any] = [
                                        "id" : conversation,
                                        "other_user_email" : DatabaseManager.safeEmail(emailAddress: currentUserEmail),
                                        "name": currentName,
                                        "latest_message" : updatedValue
                                    ]
                                    otherUserConversations.append(newConversationData)
                                    databaseEntryConversations = otherUserConversations
                                }
                            }
                            else {
                                // current collection doesnt exist
                                let newConversationData : [String : Any] = [
                                    "id" : conversation,
                                    "other_user_email" : DatabaseManager.safeEmail(emailAddress: currentUserEmail),
                                    "name": currentName,
                                    "latest_message" : updatedValue
                                ]
                                databaseEntryConversations = [
                                    newConversationData
                                ]
                            }
                            
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations) { error, _ in
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
    public func deleteConversation(conversationId : String , completion : @escaping (Bool) -> Void) {
        guard let email = Auth.auth().currentUser?.email as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        print("deleting conversation with id : \(conversationId)")
        // get all conversations for current user
        
        // delete conversations for conversationId
        
        // reset the conversations for the user in database
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value) { snapshot in
            if var conversations = snapshot.value as? [[String : Any]] {
                var positionToRemove = 0
                
                for conversation in conversations {
                    if let id = conversation["id"] as? String , id == conversationId{
                        print("found conversation to delete")
                        break
                    }
                    positionToRemove += 1
                }
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations) { error, _ in
                    guard error == nil else {
                        completion(false)
                        print("something wrong conversation is not deleted")
                        return
                    }
                    print("conversation deleted")
                    completion(true)
                }
            }
        }
    }
    public func isConversationExist(with targetOtherUserEmail : String, completion: @escaping (Result<String,Error>) -> Void) {
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAddress: targetOtherUserEmail)
        guard let senderEmail = Auth.auth().currentUser?.email as? String else {
            return
        }
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
            guard var collection = snapshot.value as? [[String : Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }) {
                // get id
                
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseErrors.failedToFetch))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseErrors.failedToFetch))
            return
        }
        
    }
}


struct MyMessengerUser{
    public let firstName : String
    public let lastName : String
    public let emailAdress : String
    var profilePictureUrl : String {
        let safeEmail = DatabaseManager.safeEmail(emailAddress: emailAdress)
        return "\(safeEmail)_profile_picture.png"
    }
}
