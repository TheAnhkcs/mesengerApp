//
//  RegisterViewController.swift
//  Messager
//
//  Created by hoang the anh on 27/05/2023.
//

import UIKit
import FirebaseAuth
import JGProgressHUD


class RegisterViewController: UIViewController {

    private let spinner = JGProgressHUD(style: .dark)
    private let scrollView:UIScrollView = {
       let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()

    private let imageView:UIImageView = {
       let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person")
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 0.3
        imageView.layer.backgroundColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    private let firstNametField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
//        field.placeholder = "Email Address..."
        field.attributedPlaceholder = NSAttributedString(string: "First Name...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.textColor = .black
        return field
    }()
    
    private let lastNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
//        field.placeholder = "Email Address..."
        field.attributedPlaceholder = NSAttributedString(string: "Last Name...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.textColor = .black
        return field
    }()
    
    private let emailTextField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
//        field.placeholder = "Email Address..."
        field.attributedPlaceholder = NSAttributedString(string: "Email Address...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.textColor = .black
        return field
    }()
    
    private let passwordTextField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
//        field.placeholder = "Password..."
        field.attributedPlaceholder = NSAttributedString(string: "Password...", attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.textColor = .black
        field.isSecureTextEntry = true
        return field
    }()
    
    private let reEnterPasswordTextField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
//        field.placeholder = "Password..."
        field.attributedPlaceholder = NSAttributedString(string: "Re-Enter Password...", attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.textColor = .black
        field.isSecureTextEntry = true
        return field
    }()
    
    private let registerButton:UIButton = {
       let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .green
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "REGISTER"
        view.backgroundColor = .white
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(firstNametField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(emailTextField)
        scrollView.addSubview(passwordTextField)
        scrollView.addSubview(registerButton)
        scrollView.addSubview(reEnterPasswordTextField)
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        imageView.isUserInteractionEnabled = true
        let guesture = UITapGestureRecognizer(target: self, action: #selector(didTapProfilePic))
        imageView.addGestureRecognizer(guesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
        let size = scrollView.width/1.5
        imageView.layer.cornerRadius = size/2
        imageView.frame = CGRect(x: (scrollView.width - size)/2, y: 50, width: size, height: size)
        firstNametField.frame = CGRect(x: 30, y: imageView.bottom + 50, width: scrollView.width - 60, height: 52)
        lastNameField.frame = CGRect(x: 30, y: firstNametField.bottom + 10, width: scrollView.width - 60, height: 52)
        emailTextField.frame = CGRect(x: 30, y: lastNameField.bottom + 10, width: scrollView.width - 60, height: 52)
        passwordTextField.frame = CGRect(x: 30, y: emailTextField.bottom + 10, width: scrollView.width - 60, height: 52)
        reEnterPasswordTextField.frame = CGRect(x: 30, y: passwordTextField.bottom + 10, width: scrollView.width - 60, height: 52)
        registerButton.frame = CGRect(x: 150, y: reEnterPasswordTextField.bottom + 30, width: scrollView.width - 300, height: 52)
    }
    
    @objc private func didTapProfilePic() {
        presentPhotoActionSheet()
    }
    
    @objc private func registerButtonTapped() {
        firstNametField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        reEnterPasswordTextField.resignFirstResponder()
        
        guard let firstName = firstNametField.text, let lastName = lastNameField.text, let email = emailTextField.text, let password = passwordTextField.text, let reEnterPass = reEnterPasswordTextField.text, !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !password.isEmpty, email.contains("@gmail.com"), password.count >= 6, reEnterPass == password else {
            alertUserRegisterError()
            return
        }
        
        spinner.show(in: view)
        
        let safeEmail = email.replacingOccurrences(of: ".", with: "-")
        DatabaseManager.shared.userExists(with: safeEmail) { [weak self] exists in
            guard let strongSelf = self else {return}
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss(animated: true)
            }
            
            guard !exists else {
                strongSelf.alertUserRegisterError(message: "There are an user account for that email address already exists")
                return
            }
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
                
                guard authResult != nil, error == nil else {
                    print("Error create user")
                    return
                }
                
                DatabaseManager.shared.insertUser(with: ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: safeEmail))
                strongSelf.navigationController?.popViewController(animated: true)
            }
        }
        
       
        
    }
    
    func alertUserRegisterError(message:String = "Please enter all infomation to create new account") {
        let alert = UIAlertController(title: "Woop", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dissmiss", style: .cancel))
        present(alert, animated: true)
    }
    
    func alertUserRegisterSuccess() {
        let alert = UIAlertController(title: "Congratulations", message: "You have successfully registered", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Come back to login", style: .cancel, handler: { _ in
            self.didTabConfirm()
        }))
        present(alert, animated: true)
    }
    
    @objc private func didTabConfirm() {
        navigationController?.popViewController(animated: true)
    }
 

}


extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == firstNametField {
            lastNameField.becomeFirstResponder()
        }else if textField == lastNameField {
            emailTextField.becomeFirstResponder()
        }else if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            reEnterPasswordTextField.becomeFirstResponder()
        }else if textField == reEnterPasswordTextField {
            registerButtonTapped()
        }
        return true
    }
}


extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture", message: "How would you like to select a picture", preferredStyle: .actionSheet)
        actionSheet.overrideUserInterfaceStyle = .light
        
        actionSheet.setBackgroundColor(color: .clear)
        actionSheet.setTitlet(font: .systemFont(ofSize: 25, weight: .bold), color: .link)
        actionSheet.setMessage(font: .systemFont(ofSize: 12, weight: .bold), color: .link)
        
        
        actionSheet.addAction(UIAlertAction(title: "Cancle", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { [weak self] _ in
            guard let self = self else {return}
            self.presentCamera()
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Chose Photo", style: .default, handler: { [weak self] _ in
            guard let self = self else {return}
            self.presentPhoto()
        }))
        present(actionSheet, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhoto() {
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
