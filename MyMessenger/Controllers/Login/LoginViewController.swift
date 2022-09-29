//
//  LoginViewController.swift
//  MyMessenger
//
//  Created by Hasan Kaya on 19.08.2022.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import JGProgressHUD
/// controller that shows login screen 
final class LoginViewController: UIViewController {
    private let spinner = JGProgressHUD(style: .dark)
    private let scrollView : UIScrollView = {
      let view = UIScrollView()
        view.clipsToBounds = true
        return view
    }()
    private let imageView : UIImageView = {
        let imageview = UIImageView()
        imageview.image = UIImage(named: "messenger")
        imageview.backgroundColor = .systemBackground
        imageview.contentMode = .scaleAspectFit
        return imageview
    }()
    private let emailField : UITextField = {
       let field = UITextField()
        field.placeholder = "Email address..."
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    private let passwordField : UITextField = {
       let field = UITextField()
        field.placeholder = "Password..."
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.isSecureTextEntry = true
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    private let logInbutton : UIButton = {
       let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        return button
    }()
    private let facebookLoginButton : FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email"] 
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Log In"

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didRegisterTapped))
   
        
        logInbutton.addTarget(self, action: #selector(LogInButtonTapped), for: .touchUpInside)
        emailField.delegate = self
        passwordField.delegate = self
        
        facebookLoginButton.delegate = self
      
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(logInbutton)
        scrollView.addSubview(facebookLoginButton)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width - size) / 2, y: scrollView.top + 50, width: size, height: size)
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom + 50, width: scrollView.width - 60, height: 52)
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 50,
                                     width: scrollView.width - 60,
                                     height: 52)
        logInbutton.frame = CGRect(x: 30,
                                   y: passwordField.bottom + 50,
                                   width: scrollView.width - 60,
                                   height: 52)
        facebookLoginButton.frame = CGRect(x: 30,
                                   y: logInbutton.bottom + 50,
                                   width: scrollView.width - 60,
                                   height: 52)
        facebookLoginButton.layer.cornerRadius = 12
        facebookLoginButton.layer.masksToBounds = true
        facebookLoginButton.backgroundColor = .link
    }
    @objc private func didRegisterTapped(){
        
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc func LogInButtonTapped(){
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text , let password = passwordField.text, password.count >= 6 else {
            let error = ErrorManager.shared.presentError(title: "Ooops", message: "please fill of oll the informations to log in")
            present(error, animated: true)
            return
        }
        spinner.show(in: view)
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] authDataResult, error in
            
            guard let strongSelf = self else {
                return
            }
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss(animated: true)
            }
            
            guard let result = authDataResult, error == nil else {
                let errorMessage = ErrorManager.shared.presentError(title: "Ooops", message: "Not log in")
                return
            }
            let user = result.user
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail) { result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String : Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String else {
                        return
                    }
                    UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                  
                    print(UserDefaults.standard.object(forKey: "name"))
                case .failure(let error):
                    print("an error occured while trying to get name \(error)")
                }
            }
            UserDefaults.standard.setValue(email, forKey: "email")
             
            print("Log in user : \(user.email)")
            strongSelf.navigationController?.dismiss(animated: true)
        }
        
        
    }
    
    
}
extension LoginViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            LogInButtonTapped()
        }
        return true
    }
}
extension LoginViewController : LoginButtonDelegate {
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("Token error")
            return
        }
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields":"email,name"], tokenString: token, version: nil, httpMethod: .get)
        facebookRequest.start { _, result, error in
            guard let result = result as? [String:Any], error == nil else {
                print("error in facebook request")
                return
            }
            print(result)
            guard let name = result["name"] as? String,let email = result["email"] as? String else {
                return
            }
            let nameComponents = name.components(separatedBy: " ")
            let firstName = nameComponents[0]
            let lastName = nameComponents[0]
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self]authDataResult, error in
                guard let strongSelf = self else {
                    return
                }
                guard let authResult = authDataResult, error == nil else {
                    print("error to sign in with facebook")
                    return
                }
                let user = authResult.user
                DispatchQueue.main.async {
                    UserDefaults.standard.set(email, forKey: "email")
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                }
                print("Succesfully logged in")
                strongSelf.navigationController?.dismiss(animated: true)
            }
        }
            
        }
       
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        
    }
    
    
}
