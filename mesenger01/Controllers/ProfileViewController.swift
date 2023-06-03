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

class ProfileViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    let data = ["Log Out"]
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
                self.downLoadImage(imageView: imageView, url: url)
            case .failure(let error):
                print("Failed to get downlaod url : \(error)")
            }
        }
        return headerView
    }
    func downLoadImage(imageView: UIImageView, url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                return
            }
            
            
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
                self.tableView.reloadData()
            }
           

        }.resume()
    }

}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
            guard let strongSelf = self else {return}
            
            FBSDKLoginKit.LoginManager().logOut()
            GIDSignIn.sharedInstance.signOut()
            
            do{
                try FirebaseAuth.Auth.auth().signOut()
                let vc = LoginViewController()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                nav.navigationBar.backgroundColor = .lightGray
               
                strongSelf.present(nav, animated: false)
            }catch {
                print("Failed to log out")
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
        
    }
}
