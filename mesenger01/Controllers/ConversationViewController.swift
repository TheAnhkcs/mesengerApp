//
//  ViewController.swift
//  Messager
//
//  Created by hoang the anh on 27/05/2023.
//

import UIKit
import FirebaseAuth
import JGProgressHUD


struct Conversation {
    let id:String
    let name:String
    let otherUserEmail:String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date:String
    let text: String
    let isRead: Bool
}

class ConversationViewController: UIViewController {

    
    private let spinner = JGProgressHUD(style: .dark)
    private var conversations = [Conversation]()
    
    private let tableView : UITableView = {
    let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return tableView
    }()
    
    private let noConversationLable : UILabel = {
        let lable = UILabel()
        lable.text = "No Conversation!"
        lable.textAlignment = .center
        lable.textColor = .gray
        lable.font = .systemFont(ofSize: 21, weight: .medium)
        lable.isHidden = true
        return lable
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        
        view.backgroundColor = .cyan
        view.addSubview(tableView)
        view.addSubview(noConversationLable)
        
        setUpTableView()
        
//        startListeningForConversation()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
        startListeningForConversation()
    }
    	
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noConversationLable.frame = CGRect(x: 0, y: view.height/2, width: view.width, height: 50)
    }
    
   
    
    private func startListeningForConversation() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        print("22222222222222222222222222222222")
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConvesations(for: safeEmail) {[weak self] result in
            
           
            guard let self = self else {return}
            switch result {
                
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    self.tableView.isHidden = true
                    self.noConversationLable.isOpaque = false
                    return
                }
                tableView.isHidden = false
                self.conversations = conversations
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                self.tableView.isHidden = true
                self.noConversationLable.isOpaque = false
                print("Failed to get conversation \(error)")
            }
        }
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func fetchConversations() {
        tableView.isHidden = false
        
    }
    
    @objc private func didTapComposeButton() {
        let vc = NewConversationViewController()
        vc.completion = {[weak self] result in
            guard let self = self else {return}
            if let index = self.conversations.firstIndex(where: {$0.otherUserEmail == result.email}) {
                self.openExistConversation(with: index)
            }else {
            self.createdNewConversation(result: result)
            }
        }
        
                let naVC = UINavigationController(rootViewController: vc)
                naVC.modalPresentationStyle = .fullScreen
        present(naVC, animated: true)
        
    }
    
    private func openExistConversation(with index:Int) {
        let model = conversations[index]
        let vc = ChatsViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.isNewConversation = false
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    private func createdNewConversation(result:SearchResult) {
        let name = result.name
        let email = result.email
        let vc1 = ChatsViewController(with: email, id: nil )
        vc1.isNewConversation = true
        vc1.title = name
        vc1.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc1, animated: true)

        
    }

}

extension ConversationViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as? ConversationTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        let vc = ChatsViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        let conversationId = self.conversations[indexPath.row].id
        if editingStyle == .delete {
            tableView.beginUpdates()
            
            DatabaseManager.shared.deleteConversation(with: conversationId) { [weak self] success in
                guard let self = self else {return}
                if success {
                self.conversations.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
           
            
            tableView.endUpdates()
        }
    }
}
}

