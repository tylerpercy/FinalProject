//
//  PhotosViewController.swift
//  FinalProject
//
//  Created by Logan Mayo on 4/29/19.
//  Copyright © 2019 Tyler Percy. All rights reserved.
//

import UIKit
class PhotosViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    var store: PhotoStore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        store.fetchInterestingPhotos()
    }

}


