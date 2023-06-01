//
//  PhotoViewerViewController.swift
//  Messager
//
//  Created by hoang the anh on 27/05/2023.
//

import UIKit
import SDWebImage
import AVFoundation


class PhotoViewerViewController: UIViewController {
    private var url:URL
  
    

    init(with url:URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var imageView:UIImageView = {
      let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(imageView)
        imageView.sd_setImage(with: url)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = view.bounds
    }
}
