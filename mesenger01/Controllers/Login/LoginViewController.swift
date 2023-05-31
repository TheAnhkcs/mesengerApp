//
//  LoginViewController.swift
//  Messager
//
//  Created by hoang the anh on 27/05/2023.
//

import UIKit
import Firebase
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD


class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)

    private let scrollView:UIScrollView = {
       let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()

    private let imageView:UIImageView = {
       let imageView = UIImageView()
        imageView.image = UIImage(named: "messenger")
        imageView.contentMode = .scaleAspectFit
        return imageView
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
    
    private let loginButton:UIButton = {
       let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let fbLoginButton : FBLoginButton = {
        let fbButton = FBLoginButton()
        fbButton.permissions = ["public_profile"]  //scope email đã ko còn được hỗ trợ cho developers
        return fbButton
    }()
    
    private let ggLoginButtun: GIDSignInButton = {
        let ggButton = GIDSignInButton()
        ggButton.addTarget(self, action: #selector(ggButtonDidTap), for: .touchUpInside)
        return ggButton
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "LOG IN"
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTabRegister))
        
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailTextField)
        scrollView.addSubview(passwordTextField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(fbLoginButton)
        scrollView.addSubview(ggLoginButtun)
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
        let size = scrollView.width/5
        imageView.frame = CGRect(x: (scrollView.width - size)/2, y: 100, width: size, height: size)
        emailTextField.frame = CGRect(x: 30, y: imageView.bottom + 100, width: scrollView.width - 60, height: 52)
        passwordTextField.frame = CGRect(x: 30, y: emailTextField.bottom + 10, width: scrollView.width - 60, height: 52)
        loginButton.frame = CGRect(x: 150, y: passwordTextField.bottom + 30, width: scrollView.width - 300, height: 52)
        
        fbLoginButton.frame.size.width = passwordTextField.width
        fbLoginButton.frame.size.height = 44
        fbLoginButton.frame.origin.x = passwordTextField.frame.minX
        fbLoginButton.frame.origin.y = loginButton.bottom + 20
        fbLoginButton.delegate = self
        
        ggLoginButtun.frame.size.width = fbLoginButton.frame.width + 6
        ggLoginButtun.frame.size.height = fbLoginButton.frame.height
        ggLoginButtun.frame.origin.x = fbLoginButton.frame.minX - 3
        ggLoginButtun.frame.origin.y = fbLoginButton.bottom + 5
        
        
        
        
        
    }
    
    @objc private func loginButtonTapped() {
        
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        guard let email = emailTextField.text, let password = passwordTextField.text, !email.isEmpty, !password.isEmpty, email.contains("@gmail.com"), password.count >= 6 else {
            alertUserLoginError()
            return
        }
        spinner.show(in: view)
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            guard let strongSelf = self else {return}
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            

            guard let result = authResult, error == nil else {
                print("Failed to log in user with email: \(email)")
                return
            }
            let user = result.user
            
            UserDefaults.standard.set(email, forKey: "email")
            
            print("Loggeg In User: \(user)")
            strongSelf.navigationController?.dismiss(animated: true)
        }
    }
    
    @objc private func ggButtonDidTap() {
        if GIDSignIn.sharedInstance.currentUser  == nil {
            GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] (result, error) in
                guard let strongSelf = self else {return}
                guard error == nil else {
                    if let error = error {
                        print("Failed to sign in google server ")
                    }
                    return
                }
                
                guard let user = result?.user,
                    let idToken = user.idToken?.tokenString
                  else {
                    print("User information authentication failed")
                    return
                  }
                
                if let email = user.profile?.email, let firstName = user.profile?.givenName, let lastName = user.profile?.familyName {
                    
                    UserDefaults.standard.set(email, forKey: "email")
                    DatabaseManager.shared.userExists(with: email) { exists in
                    if !exists {
                        
                        let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                        DatabaseManager.shared.insertUser(with: chatUser) { success in
                            if success {
                                if user.profile?.hasImage != nil {
                                    guard let url = user.profile?.imageURL(withDimension: 200) else {
                                        return
                                    }
                                    URLSession.shared.dataTask(with: url) { data, _, _ in
                                        guard let data = data else {
                                            return
                                        }
                                    let fileName = chatUser.profilePictureFileName
                                    StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { (result: Result<String, Error>) in
                                        switch result {
                                        case .success(let downloadUrl):
                                            UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                            print(downloadUrl)
                                        case .failure(let error):
                                            print("Storagemânger error: \(error)")
                                        }
                                    }
                                    }.resume()
                                }
                            }
                        }
                    }
                }
            }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                                 accessToken: user.accessToken.tokenString)
                
                FirebaseAuth.Auth.auth().signIn(with: credential) {(authResult, error) in
                    guard let result = authResult, error == nil else {
                        print("Failed to log in user with credential :\(credential)")
                        return
                    }
                    let user = result.user
                    print("Loggeg In User: \(user)")
                    strongSelf.navigationController?.dismiss(animated: true)
                }
               
                
        }
    }
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Woop", message: "Please enter all infomation to log in", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dissmiss", style: .cancel))
        alert.addAction(UIAlertAction(title: "Register", style: .default, handler: { _ in
            self.didTabRegister()
        }))
        present(alert, animated: true)
    }
    
    @objc private func didTabRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
 

}


extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        }else if textField == passwordTextField {
            loginButtonTapped()
        }
        return true
    }
}

extension LoginViewController: LoginButtonDelegate {
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with Facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields" : "email, first_name, last_name, picture.type(large)"], tokenString: token, version: nil, httpMethod: .get)
        
        
        facebookRequest.start { _, result, error in
            guard let result = result as? [String:Any], error == nil else {
                print("Failed to make facebook graph request")
                return
            }
            
            guard let firstName = result["first_name"] as? String, let lastName = result["last_name"] as? String, let picture = result["picture"] as? [String:Any], let data = picture["data"] as? [String:Any], let pictureUrl = data["url"] as? String else {
                print("Failed to get email end name from facebook result")
                return
            }
            
            let userInfor = firstName + lastName
            
            UserDefaults.standard.set(userInfor, forKey: "email")
            
            DatabaseManager.shared.userExists(with: userInfor) { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: userInfor)
                    DatabaseManager.shared.insertUser(with: chatUser) { succsess in
                        if succsess {
                            
                            guard let url = URL(string: pictureUrl) else {return}
                            URLSession.shared.dataTask(with: url) { data, response, error in
                                guard let data = data else {
                                    print("Failed get data from facebook")
                                    return
                                }
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { (result: Result<String, Error>) in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storagemânger error: \(error)")
                                    }
                                }
                            }.resume()
                        }
                    }
                }
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                guard let strongSelf = self else {return}
                guard authResult != nil, error == nil else {
                    if let error = error {
                    print("Facebook credential login failed, MFA may be need - \(error)")
                    }
                    return
                }
                
                print("Successfully logged user in ")
                strongSelf.navigationController?.dismiss(animated: true)
            }
        }
        
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //
    }
}
