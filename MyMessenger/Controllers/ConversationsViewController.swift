//
//  ViewController.swift
//  MyMessenger
//
//  Created by Hasan Kaya on 19.08.2022.
//

import UIKit
import FirebaseAuth
import JGProgressHUD




/// controller that shows conversations

final class ConversationsViewController: UIViewController {
    private var conversations = [Conversation]()
    private let tableView : UITableView = {
        let table = UITableView()
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        table.isHidden = false
        return table
    }()
    private let noConversationsLabel : UILabel = {
        let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.textColor = .lightGray
        label.isHidden = true
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        
        startListeningForConversations()
        view.addSubview(tableView)
        view.addSubview(noConversationsLabel)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(composeButtonTapped))
    }
    override func viewWillAppear(_ animated: Bool) {
        startListeningForConversations()
        super.viewWillAppear(animated)
    }
    private func startListeningForConversations(){
        
        guard let email = Auth.auth().currentUser?.email as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConversations(for: safeEmail) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    strongSelf.tableView.isHidden = true
                    strongSelf.noConversationsLabel.isHidden = false
                    return
                }
                strongSelf.noConversationsLabel.isHidden = true
                strongSelf.tableView.isHidden = false
                strongSelf.conversations = conversations
                DispatchQueue.main.async {
                    strongSelf.tableView.reloadData()
                }
            case .failure(let error):
                strongSelf.noConversationsLabel.isHidden = false
                strongSelf.tableView.isHidden = true
                if self?.noConversationsLabel.isHidden == true {
                    let presentableError = ErrorManager.shared.presentError(title: "Error", message: "failed to get conversations, \(error)")
                    strongSelf.present(presentableError, animated: true)
                }
            }
        }
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        noConversationsLabel.frame = CGRect(x: 10,
                                            y: (view.height - 100 ) / 2,
                                            width: view.width - 20,
                                        height: 100)
        tableView.frame = view.bounds
    }
    @objc func composeButtonTapped(){
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            let currentConversations = strongSelf.conversations
            if let targetConversation = currentConversations.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: result.email)
            }) {
                let vc = ChatViewController(with: targetConversation.otherUserEmail, conversationId: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
            else {
                strongSelf.createNewConversation(result: result)
            }
           
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    private func createNewConversation(result : SearchResult){
        let email = DatabaseManager.safeEmail(emailAddress: result.email)
        let name = result.name
        
        // check in database if conversationwith these two users exists
        // if it does , reuse conversation id
        // otherwise use existing code
        DatabaseManager.shared.isConversationExist(with: email) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let conversationId):
                print("Bu yeni bir konuşma değil")
                let vc = ChatViewController(with: email, conversationId: conversationId)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
                
            case .failure(_):
                print("Bu yeni bir konuşma")
                let vc = ChatViewController(with: email, conversationId: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
                
            }
        }
        
    }
    
    private func validateAuth(){
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
             nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    private func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self
    }
}
extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        openConversation(model: conversations[indexPath.row])
    }
    func openConversation(model : Conversation) {
        let vc = ChatViewController(with: model.otherUserEmail,conversationId: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.pushViewController(vc, animated: true)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            let conversationId = conversations[indexPath.row].id
            // begin delete
            tableView.beginUpdates()
            self.conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            DatabaseManager.shared.deleteConversation(conversationId: conversationId) { [weak self] success in
                if !success {
                    let error = ErrorManager.shared.presentError(title: "Oopps" , message: "Failed to delete conversation please")
                    self?.present(error, animated: true)
                }
            }
            tableView.endUpdates()
            
        }
    }
}

