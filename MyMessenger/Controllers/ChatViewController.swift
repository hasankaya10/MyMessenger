//
//  ChatViewController.swift
//  MyMessenger
//
//  Created by Hasan Kaya on 21.08.2022.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import FirebaseAuth
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation
/// controller that you can chat with other users 

class ChatViewController: MessagesViewController {
    private var senderPhotoUrl : URL?
    private var otherUserPhotoUrl : URL?
    public static let dateFormatter : DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    public let otherUserEmail : String
    private var conversationId : String?
    public var isNewConversation = false
    private var messages = [Message]()
    private var sender : Sender = {
        guard let email = Auth.auth().currentUser?.email as? String else {
            return Sender(photoURL: "", senderId: "123", displayName: "qwde2pleö")
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        return Sender(photoURL: "", senderId: safeEmail, displayName: "Me")
    }()
    
    init(with email : String,conversationId : String?) {
        self.otherUserEmail = email
        self.conversationId = conversationId
        super.init(nibName: nil, bundle: nil)
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.backgroundColor = .white
        setupInputButton()
        
    }
    private func setupInputButton(){
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: true)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self]_ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: true)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: true)
    }
    private func presentInputActionSheet(){
        let actionSheet = UIAlertController(title: "Choose Media", message: "What would you like to send?", preferredStyle: .actionSheet)
        let sendPhoto = UIAlertAction(title: "Photo", style: .default) { [weak self]_ in
            self?.presentSendPhotoActionSheet()
        }
        let sendVideo = UIAlertAction(title: "Video", style: .default) { [weak self]_ in
            self?.presentSendVideoActionSheet()
        }
        
        let sendLocation = UIAlertAction(title: "Location", style: .default) { [weak self] _ in
            self?.presentLocationPicker()
        }
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheet.addAction(sendPhoto)
        actionSheet.addAction(sendVideo)
        actionSheet.addAction(sendLocation)
        actionSheet.addAction(cancelButton)
        self.present(actionSheet, animated: true)
        
    }
    private func presentLocationPicker(){
        let vc = LocationPickerViewController(coordinates: nil,isPickable: true)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] selectedCoordinates in
            guard let strongSelf = self else {
                return
            }
            print("\(selectedCoordinates)")
            guard let messageId = strongSelf.createMessageId(),
                  let conversationId = strongSelf.conversationId,
                let name = strongSelf.title else {
                return
            }
            let longitude : Double = selectedCoordinates.longitude
            let latitude : Double = selectedCoordinates.latitude
            
            print("long : \(longitude), lat : \(latitude)")
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: .zero)
            
            let locationMessage = Message(sender: strongSelf.sender, messageId: messageId, sentDate: Date(), kind: .location(location))
            
            DatabaseManager.shared.sendMessages(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: locationMessage) { [weak self] success in
                if success {
                    print("sent video message")
                }
                else {
                    let errorMessage = ErrorManager.shared.presentError(title: "Oopps", message: "Not send to Video Messsage please check your connection")
                    self?.present(errorMessage, animated: true)
                }
            }
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    private func presentSendPhotoActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where would you like to attaach from?", preferredStyle: .actionSheet)
        let openCamera = UIAlertAction(title: "Camera", style: .default) { [weak self]_ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }
        let openLibrary = UIAlertAction(title: "Library", style: .default) { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheet.addAction(openCamera)
        actionSheet.addAction(openLibrary)
        actionSheet.addAction(cancelButton)
        self.present(actionSheet, animated: true)
    }
    private func presentSendVideoActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Video", message: "Where would you like to attaach from?", preferredStyle: .actionSheet)
        let openCamera = UIAlertAction(title: "Camera", style: .default) { [weak self]_ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }
        let openLibrary = UIAlertAction(title: "Library", style: .default) { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheet.addAction(openCamera)
        actionSheet.addAction(openLibrary)
        actionSheet.addAction(cancelButton)
        self.present(actionSheet, animated: true)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let id = conversationId {
            listenForMessages(conversationId: id, shouldScrollToBottom : true)
        }
    }
    private func listenForMessages(conversationId : String, shouldScrollToBottom : Bool){
        DatabaseManager.shared.getAllMessagesForConversation(with: conversationId) { [weak self] result in
            switch result {
            case .success(let messages):
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToBottom()
                    }
                }
            case .failure(let error):
                print("An error occured")
            }
        }
    }
    

}
extension ChatViewController : UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let messageId = createMessageId(),
        let conversationId = conversationId,
        let name = self.title else {
            return
        }
        // Upload Image
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
           let imageData = image.pngData() {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            print(fileName)
            StorageManager.shared.uploadPhotoMessage(with: imageData, fileName: fileName) { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    // ready to send message
                    print("Uploaded Photo Message \(urlString)")
                    guard let url = URL(string: urlString) ,
                    let placeholder = UIImage(systemName: "person") else {
                        return
                    }
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    
                    let message = Message(sender: strongSelf.sender, messageId: messageId, sentDate: Date(), kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessages(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("sent photo message")
                        }
                        else {
                            let errorMessage = ErrorManager.shared.presentError(title: "Oopps", message: "Not send to Photo please check your connection")
                            self?.present(errorMessage, animated: true)
                        }
                    }
                    
                case .failure(let error):
                    let errorMessage = ErrorManager.shared.presentError(title: "Oopps", message: "Not send to Photo Messsage please check your connection")
                    self?.present(errorMessage, animated: true)
                }
            }
        } else if let videoUrl = info[.mediaURL] as? URL {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            
            // Upload Video
            StorageManager.shared.uploadVideoMessage(with: videoUrl, fileName: fileName) { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    // ready to send message
                    print("Uploaded Video Message \(urlString)")
                    guard let url = URL(string: urlString) ,
                    let placeholder = UIImage(systemName: "person") else {
                        return
                    }
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    
                    let message = Message(sender: strongSelf.sender, messageId: messageId, sentDate: Date(), kind: .video(media))
                    
                    DatabaseManager.shared.sendMessages(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("sent video message")
                        }
                        else {
                            let errorMessage = ErrorManager.shared.presentError(title: "Oopps", message: "Not send to Messsage, please check your connection")
                            self?.present(errorMessage, animated: true)
                        }
                    }
                    
                case .failure(let error):
                    let errorMessage = ErrorManager.shared.presentError(title: "Oopps", message: "Not send to Messsage please check your connection")
                    self?.present(errorMessage, animated: true)
                }
            }
            
        }
    }
}
extension ChatViewController : InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty ,
        let messageId = createMessageId() else {
            return
        }
        let sender = self.sender
        print("Sending : \(text)")
        let message = Message(sender: sender , messageId: messageId, sentDate: Date(), kind: .text(text))
        if isNewConversation {
            // create new conversation
            print("Bu yeni bir konuşma")
            DatabaseManager.shared.createNewConversation(with: otherUserEmail,firstMessage: message,name: self.title ?? "User") { [weak self] success in
                if success {
                    print("message sent")
                    self?.isNewConversation = false
                    let newConversationId = "conversation_\(message.messageId)"
                    self?.conversationId = newConversationId
                    self?.listenForMessages(conversationId: newConversationId, shouldScrollToBottom: true)
                    self?.messageInputBar.inputTextView.text = nil
                }
                else {
                    print("error creating new conversation")
                }
            }
        } else {
            guard let conversationId = conversationId ,
            let name = self.title else {
                return
            }
            DatabaseManager.shared.sendMessages(to: conversationId, otherUserEmail : otherUserEmail,name: name,newMessage: message) { [weak self] success in
                if success {
                    print("successfully sent a message")
                    self?.messageInputBar.inputTextView.text = nil
                } else {
                    print("an error occured while sending message")
                }
            }
            // append messages to exist conversation
        }
    }
    private func createMessageId() -> String? {
        let dateString = ChatViewController.dateFormatter.string(from: Date())
        guard let currentUserEmail = Auth.auth().currentUser?.email else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
       
        let newIdentifer = "\(otherUserEmail)_\(safeEmail)_\(dateString)"
        print("created message id : \(newIdentifer)")
        
        return newIdentifer
    }
    
}

extension ChatViewController:MessagesDataSource,MessagesLayoutDelegate,MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        let sender = self.sender
        return sender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
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
            imageView.sd_setImage(with: imageUrl)
        default:
            break
        }
    }
  
    
    
}
extension ChatViewController : MessageCellDelegate {
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates,isPickable: false)
            vc.title = "Location"
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == self.sender.senderId {
            // our message
            return .systemGreen
        }
        // recipient message
        return .secondarySystemBackground
    }
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == self.sender.senderId {
            // our message
            return .white
        }
        // recipient message
        return .black
        
    }
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        if sender.senderId == self.sender.senderId {
            // show our image
            if let currentUserImageURL = self.senderPhotoUrl {
                avatarView.sd_setImage(with: currentUserImageURL)
            }
            else {
                // Images/safeEmail_profile_picture.png
                // fetch the senderPhotoUrl
                guard let currentUserEmail = Auth.auth().currentUser?.email as? String else {
                    return
                }
                let safeCurrentUserEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
                let fileName = "\(safeCurrentUserEmail)_profile_picture.png"
                StorageManager.shared.downloadURL(fileName: fileName) {[weak self] result in
                    guard let strongSelf = self else {
                        return
                    }
                    switch result {
                    case .success(let urlString):
                        strongSelf.senderPhotoUrl = URL(string: urlString)
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: strongSelf.senderPhotoUrl)
                        }
                        
                    case .failure(let error):
                        print("not upload to profile photo for sender: \(error)")
                    }
                }
            }
        } else {
            // other user image
            if let otherUserImageUrl = self.otherUserPhotoUrl {
                avatarView.sd_setImage(with: otherUserImageUrl)
            }
            else {
                // fetch the otherUserPhotoUrl
                // Images/safeEmail_profile_picture.png
                
                let safeOtherUserEmail = DatabaseManager.safeEmail(emailAddress: otherUserEmail)
                let fileName = "\(safeOtherUserEmail)_profile_picture.png"
                StorageManager.shared.downloadURL(fileName: fileName) {[weak self] result in
                    guard let strongSelf = self else {
                        return
                    }
                    switch result {
                    case .success(let urlString):
                        strongSelf.otherUserPhotoUrl = URL(string: urlString)
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: strongSelf.otherUserPhotoUrl)
                        }
                        
                    case .failure(let error):
                        print("not upload to profile photo for otherUser: \(error)")
                    }
                }
            }
        }
    }
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            let vc = PhotoViewerViewController(with: imageUrl)
            navigationController?.pushViewController(vc, animated: true)
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
    
}
