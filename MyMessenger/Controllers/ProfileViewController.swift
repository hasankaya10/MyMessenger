//
//  ProfileViewController.swift
//  MyMessenger
//
//  Created by Hasan Kaya on 19.08.2022.
//

import UIKit
import FirebaseAuth
import SDWebImage
/// controller that show user infos and allow to log out



class ProfileViewController: UIViewController {
    public var data = [profileViewModel]()
    @IBOutlet var tableView: UITableView!
    override func viewDidLoad() {
        
        super.viewDidLoad()
        tableView.register(profileTableViewCell.self, forCellReuseIdentifier: profileTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
        data.append(profileViewModel(viewModelType: .info,
                                     title: "\(UserDefaults.standard.object(forKey: "name") as? String ?? "No Name")",
                                     handler: nil))
        if let currentUserEmail = Auth.auth().currentUser?.email as? String {
            data.append(profileViewModel(viewModelType: .info,
                                         title: currentUserEmail,
                                         handler: nil))
        }
       
        data.append(profileViewModel(viewModelType: .logOut,title: "Log Out",handler: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            let actionSheet = UIAlertController(title: "Are you sure to log out?", message: "", preferredStyle: .actionSheet)
            let logOutAction = UIAlertAction(title: "Log Out", style: .destructive) {[weak self] _ in
                guard let strongSelf = self else {
                    return
                }
                UserDefaults.standard.setValue(nil, forKey: "email")
                UserDefaults.standard.setValue(nil, forKey: "name")
                
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    
                    let vc = LoginViewController()
                    let nav = UINavigationController(rootViewController: vc)
                     nav.modalPresentationStyle = .fullScreen
                    strongSelf.present(nav, animated: false)
                } catch  {
                    // error Message
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            actionSheet.addAction(logOutAction)
            actionSheet.addAction(cancelAction)
            strongSelf.present(actionSheet, animated: true)
            
        }))
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.tableHeaderView = createTableHeader()
    }
     
    func createTableHeader() -> UIView? {
        guard let email = Auth.auth().currentUser?.email as? String else {
                return nil
            }

            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            let filename = safeEmail + "_profile_picture.png"
            let path = "images/"+filename

            let headerView = UIView(frame: CGRect(x: 0,
                                            y: 0,
                                            width: self.view.width,
                                            height: 300))

            headerView.backgroundColor = .systemBackground

            let imageView = UIImageView(frame: CGRect(x: (headerView.width-150) / 2,
                                                      y: 75,
                                                      width: 150,
                                                      height: 150))
            imageView.contentMode = .scaleAspectFill
            imageView.backgroundColor = .white
            imageView.layer.borderColor = UIColor.systemBackground.cgColor
            imageView.layer.borderWidth = 3
            imageView.layer.masksToBounds = true
            imageView.layer.cornerRadius = imageView.width/2
            headerView.addSubview(imageView)

        StorageManager.shared.downloadURL(fileName: filename) { result in
            switch result {
            case .success(let string):
                imageView.sd_setImage(with: URL(string: string))
            case .failure(let error):
                print(error)
            }
        }

            return headerView
        }

    }
extension ProfileViewController: UITableViewDelegate , UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: profileTableViewCell.identifier, for: indexPath) as! profileTableViewCell
        cell.setUp(with: viewModel)
       
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        data[indexPath.row].handler?()
        
    }
    
}
class profileTableViewCell: UITableViewCell {
    
    static let identifier = "profileTableViewCell"
    
    func setUp(with model : profileViewModel) {
        self.textLabel?.text = model.title
        switch model.viewModelType {
        case .info:
            textLabel?.textAlignment = .center
            textLabel?.font = UIFont.systemFont(ofSize: 21,weight: .semibold)
            selectionStyle = .none
        case .logOut:
            textLabel?.textColor = .systemRed
            textLabel?.textAlignment = .center
            
        }
    }
}
