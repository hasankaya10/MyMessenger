//
//  RegisterViewController.swift
//  MyMessenger
//
//  Created by Hasan Kaya on 19.08.2022.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
/// controller that shows login screen 
final class RegisterViewController: UIViewController, UINavigationControllerDelegate {
    let spinner = JGProgressHUD(style: .dark)
    private let scrollView : UIScrollView = {
      let view = UIScrollView()
        view.clipsToBounds = true
        return view
    }()
    private let firstNameField : UITextField = {
       let field = UITextField()
        field.placeholder = "First Name"
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
    private let lastNameField : UITextField = {
       let field = UITextField()
        field.placeholder = "Last Name"
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
    private let imageView : UIImageView = {
        let imageview = UIImageView()
        imageview.image = UIImage(systemName: "person.crop.circle.fill")
        imageview.tintColor = UIColor.tintColor
        imageview.contentMode = .scaleAspectFit
        imageview.layer.masksToBounds = true
        // imageview.layer.borderWidth = 2
        // imageview.layer.borderColor = UIColor.systemGray.cgColor
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
    private let secondPasswordField : UITextField = {
       let field = UITextField()
        field.placeholder = "Password Again"
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
    private let RegisterButton : UIButton = {
       let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .tintColor
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Register"
        RegisterButton.addTarget(self, action: #selector(RegisterButtonTapped), for: .touchUpInside)
        firstNameField.delegate = self
        lastNameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        imageView.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        imageView.addGestureRecognizer(gesture)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        view.addSubview(scrollView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(secondPasswordField)
        scrollView.addSubview(RegisterButton)
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width - size) / 2, y: scrollView.top + 50, width: size, height: size)
        imageView.layer.cornerRadius = imageView.width / 2
        firstNameField.frame = CGRect(x: 30,
                                  y: imageView.bottom + 40, width: scrollView.width - 60, height: 52)
        lastNameField.frame = CGRect(x: 30,
                                  y: firstNameField.bottom + 40, width: scrollView.width - 60, height: 52)
        emailField.frame = CGRect(x: 30,
                                  y: lastNameField.bottom + 40, width: scrollView.width - 60, height: 52)
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 40,
                                     width: scrollView.width - 60,
                                     height: 52)
        secondPasswordField.frame = CGRect(x: 30,
                                     y: passwordField.bottom + 40,
                                     width: scrollView.width - 60,
                                     height: 52)
        RegisterButton.frame = CGRect(x: 30,
                                   y: secondPasswordField.bottom + 40,
                                   width: scrollView.width - 60,
                                   height: 52)
    }
    @objc func RegisterButtonTapped(){
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        
        guard let firstName = firstNameField.text,
              let lastName = lastNameField.text,
              let email = emailField.text,
              let password = passwordField.text,
              let secondPassword = secondPasswordField.text,
              secondPassword == password,
              !firstName.isEmpty,
              !lastName.isEmpty,
              !email.isEmpty,
              !password.isEmpty,
              !secondPassword.isEmpty,
              password.count >= 6 else {
            let errorMessage = ErrorManager.shared.presentError(title: "Error", message: "Please Write all of the informations correctly, check passwords")
            present(errorMessage, animated: true)
            return
        }
        spinner.show(in: view)
        
        DatabaseManager.shared.isUserExists(with: email) { [weak self]isExist in
            guard let strongSelf = self else {
                return
            }
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss(animated: true)
            }
            guard !isExist else {
                strongSelf.logInErrorMessage(with: "Looks like this Email adress is already exist")
                return
            }
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { [weak self]authdataResult, error in
                guard let strongSelf = self else {
                    return
                }
        
                guard authdataResult != nil , error == nil else {
                    strongSelf.logInErrorMessage(with: error?.localizedDescription ?? "Error while creating user")
                    return
                }
                UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                UserDefaults.standard.setValue(email, forKey: "email ")
                let user = MyMessengerUser(firstName: firstName, lastName: lastName, emailAdress: email)
                DatabaseManager.shared.insertNewUser(with: user) { success in
                    if success {
                        // upload photo
                        guard let image = strongSelf.imageView.image , let data = image.pngData() else {
                            print("İmage error")
                            return
                        }
                        let fileName = user.profilePictureUrl
                        StorageManager.shared.UploadProfilePicture(with: data, fileName: fileName) { result in
                            switch result {
                            case .success(let downloadUrl):
                                print(downloadUrl)
                                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                            case .failure(let error):
                                print("Storage Manager Error \(error)")
                            }
                        }
                    }
                }
                
                strongSelf.navigationController?.dismiss(animated: true)
            }
            
            
            
        }
        
        
        
        
    }
    func logInErrorMessage(with message :String = "Please enter all information to create a new account."){
        let alert = UIAlertController(title: "Woopps!", message: message, preferredStyle: .alert)
        let dismissButton = UIAlertAction(title: "Dismiss", style: .cancel)
        alert.addAction(dismissButton)
        self.present(alert, animated: true)
    }
    @objc func imageTapped() {
        presentActionSheet()
    }
    

}
extension RegisterViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            RegisterButtonTapped()
        }
        return true
    }
}
extension RegisterViewController : UIImagePickerControllerDelegate {
    
    func presentActionSheet(){
        let actionSheet = UIAlertController(title: "Profile Picture", message: "How would you like to select a picture", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let takePictureAction = UIAlertAction(title: "Take a picture", style: .default) { [weak self] _ in
            self?.presentTakePhoto()
        }
        let choosePictureAction = UIAlertAction(title: "Choose a photo", style: .default) { [weak self ] _ in
            self?.PresentChoosePhoto()
        }
        actionSheet.addAction(cancelAction)
        actionSheet.addAction(takePictureAction)
        actionSheet.addAction(choosePictureAction)
        present(actionSheet, animated: true)
    }
    func presentTakePhoto(){
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
        
    }
    func PresentChoosePhoto(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        self.imageView.image = selectedImage
        
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
