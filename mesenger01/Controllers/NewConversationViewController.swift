//
//  NewConversationViewController.swift
//  Messager
//
//  Created by hoang the anh on 27/05/2023.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    public var completion: ((SearchResult) -> Void)?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String:String]]()
    private var results = [SearchResult]()
    private var hasFetched = false
    
    private lazy var searchController: UISearchController = {
          let searchController = UISearchController(searchResultsController: nil)
          searchController.obscuresBackgroundDuringPresentation = false // che khuất background
          searchController.hidesNavigationBarDuringPresentation = false
          searchController.searchBar.showsCancelButton = true
//        searchController.automaticallyShowsCancelButton = true
          searchController.searchBar.returnKeyType = .done
        searchController.searchBar.becomeFirstResponder()
          searchController.searchBar.placeholder = "Search for User..."
          searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
          return searchController
      }()

    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
        
        return table
    }()
    
    private let noResultsLAble :UILabel = {
        let lable = UILabel()
        lable.isHidden = true
        lable.text = "No Results"
        lable.textAlignment = .center
        lable.textColor = .green
        lable.font = .systemFont(ofSize: 21, weight: .medium)
        return lable
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        navigationItem.searchController = searchController
        view.addSubview(noResultsLAble)
        view.addSubview(tableView)
       
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultsLAble.frame = CGRect(x: view.width/4, y: (view.height - 200)/2, width: view.width/2, height: 200)
    }


}

extension NewConversationViewController : UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismiss(animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {return}
        
        results.removeAll()
        self.spinner.show(in: view)
        self.searchUser(query: text)
    }
    
    func searchUser(query:String) {
        if hasFetched {
            self.filterUser(with: query)
        }else {
            DatabaseManager.shared.getAllUsers { [weak self] result in
                switch result {
                    
                case .success(let userColletion):
                    self?.hasFetched = true
                    self?.users = userColletion
                    self?.filterUser(with: query)
                case .failure(let error):
                    print("Failed to get users :\(error)")
                }
            }
        }
    }
    
    func filterUser(with term:String) {
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetched else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        self.spinner.dismiss()
        let results:[SearchResult] = self.users.filter({
            guard let email = $0["email"] as? String, email != safeEmail else {
                return false
            }
            
            guard let  name = $0["name"]?.lowercased() as? String else {return false}
            return name.hasPrefix(term.lowercased())
        }).compactMap({
            guard let email = $0["email"] as? String, let  name = $0["name"] as? String else {return nil}
            return SearchResult(name: name, email: email)})
        self.results = results
        self.updateUI()
    }
    
   private func updateUI() {
       if results.isEmpty {
           self.noResultsLAble.isHidden = false
           self.tableView.isHidden = true
       }else {
           self.noResultsLAble.isHidden = true
           self.tableView.isHidden = false
           self.tableView.reloadData()
       }
    }
    
}

extension NewConversationViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        
    }
    
    
}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as? NewConversationCell else {
            return UITableViewCell()
        }
        cell.configure(with: model)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        searchController.isActive = false
        let targetUserData = results[indexPath.row]
        
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else {return}
            self.completion?(targetUserData)
        }
        
        
      
    }
}


struct SearchResult {
    
    
    var name:String
    var email: String
}
