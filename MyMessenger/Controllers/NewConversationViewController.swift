//
//  NewConversationViewController.swift
//  MyMessenger
//
//  Created by Hasan Kaya on 19.08.2022.
//

import UIKit
import JGProgressHUD
import FirebaseAuth
/// controller that shows list of users for new conversation
class NewConversationViewController: UIViewController {
    
    public var completion : ((SearchResult) -> (Void))?
    
    private var users = [[String : String]]()
    private var results = [SearchResult]()
    private var hasFetched = false
    
    private let spinner = JGProgressHUD(style: .dark)
    
    
    private let searchBar : UISearchBar = {
       let searchBar = UISearchBar()
        searchBar.placeholder = "Search User.."
        return searchBar
    }()
    private let tableView : UITableView = {
        let table = UITableView()
        table.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
        table.isHidden = true
        return table
    }()
    private let noResultsLabel : UILabel = {
       let label = UILabel()
        label.text = "No Results..."
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 21, weight: .bold)
        label.isHidden = true
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        view.addSubview(noResultsLabel)
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(selfDismiss))
        navigationController?.navigationBar.topItem?.rightBarButtonItem?.tintColor = .systemGray
        
        searchBar.becomeFirstResponder()
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultsLabel.frame = CGRect(x: view.width / 4, y: (view.height - 200) / 2, width: view.width / 2, height: 200)
    }
    @objc func selfDismiss(){
        dismiss(animated: true)
    }
}
extension NewConversationViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier,
                                                 for: indexPath) as! NewConversationCell
        cell.configure(with: model)
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targetUserData = results[indexPath.row]
        
        dismiss(animated: true) { [weak self] in
            self?.completion?(targetUserData)
            
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}
extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text , !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            print("hata")
            return
        }
        searchBar.resignFirstResponder()
        results.removeAll()
        spinner.show(in: view)
        searchUsers(query: text)
    }
    func searchUsers(query: String){
        // check if array has firebase results
        if hasFetched {
            // if it does , filter
            filterUsers(with: query)
        }
        else {
            // if not , fetch than filter
            DatabaseManager.shared.getAllUsers { [weak self] result in
                switch result {
                case .success(let usersCollection): 
                    self?.users = usersCollection
                    self?.hasFetched = true
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("can not fetch \(error)")
                }
            }

        }
       
        
        // Update the UI : show tableView or Label
    }
    private func filterUsers(with term : String){
        guard let currentUserEmail = Auth.auth().currentUser?.email as? String, hasFetched else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        self.spinner.dismiss(animated: true)
        
        let results : [SearchResult] = users.filter({
            guard let email = $0["email"] ,email != safeEmail else {
                return false
            }
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        }).compactMap({
            guard let email = $0["email"] , let name = $0["name"]?.lowercased() else {
                return nil
            }
            return SearchResult(name: name, email: email)
           
        })
        self.results = results
        updateUI()
        
    }
    func updateUI(){
        if results.isEmpty {
           noResultsLabel.isHidden = false
            tableView.isHidden = true
            
        } else {
            noResultsLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
            
        }
    }
}
