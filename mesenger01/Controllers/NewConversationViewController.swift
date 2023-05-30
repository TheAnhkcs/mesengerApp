//
//  NewConversationViewController.swift
//  Messager
//
//  Created by hoang the anh on 27/05/2023.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    private let spinner = JGProgressHUD()
    private lazy var searchController: UISearchController = {
          let searchController = UISearchController(searchResultsController: nil)
          searchController.obscuresBackgroundDuringPresentation = false // che khuất background
          searchController.hidesNavigationBarDuringPresentation = false
//          searchController.searchBar.showsCancelButton = true
        searchController.automaticallyShowsCancelButton = true
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
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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

    }


}

extension NewConversationViewController : UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismiss(animated: true)
    }
}

extension NewConversationViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        
    }
    
    
}
