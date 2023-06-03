//
//  ProfileViewController.swift
//  Messager
//
//  Created by hoang the anh on 27/05/2023.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import SDWebImage

enum ProfileViewModelType {
    case info, logout
}
struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title:String
    let handler:(()->Void)?
}

class ProfileViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var data = [ProfileViewModel]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        data.append(ProfileViewModel(viewModelType: .info, title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No name")", handler:nil))
        data.append(ProfileViewModel(viewModelType: .info, title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No eamil")", handler:nil))
        data.append(ProfileViewModel(viewModelType: .logout, title: "Log Out", handler: { [weak self] in
            guard let self = self else {return}
            let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
               
                
                FBSDKLoginKit.LoginManager().logOut()
                GIDSignIn.sharedInstance.signOut()
                
                do{
                    try FirebaseAuth.Auth.auth().signOut()
                    let vc = LoginViewController()
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    nav.navigationBar.backgroundColor = .lightGray
                   
                    self.present(nav, animated: false)
                }catch {
                    print("Failed to log out")
                }
            }))
            
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(actionSheet, animated: true)
        }))
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
//        tableView.tableHeaderView = createTableViewHeader()
        
        
      
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.tableHeaderView = createTableViewHeader()
       
    }
    
    func createTableViewHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            print("Failed to get email info")
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        
        let path = "image/" + fileName
        print(path)
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        headerView.backgroundColor = .link
        
        let imageView = UIImageView(frame: CGRect(x: (view.width - 150)/2, y: 75, width: 150, height: 150))
        
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = imageView.width/2
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadUrl(for: path) { result in
            switch result {
                
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)
                
            case .failure(let error):
                print("Failed to get downlaod url : \(error)")
            }
        }
        return headerView
    }
    func downLoadImage(imageView: UIImageView, url: URL) {
        
        imageView.sd_setImage(with: url, completed: nil)
        
    }

}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as? ProfileTableViewCell else {
            return UITableViewCell()
        }
        cell.setup(with: viewModel)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let viewMode = data[indexPath.row].handler?()
        
        
        
    }
}

class ProfileTableViewCell :UITableViewCell {
    
    static let identifier = "ProfileTableViewCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setup(with viewModel:ProfileViewModel) {
        self.textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
            
        case .info:
            self.textLabel?.textAlignment = .left
            self.selectionStyle = .none
        case .logout:
            
            self.textLabel?.textColor = .red
            self.textLabel?.textAlignment = .center
        }
    }
}
