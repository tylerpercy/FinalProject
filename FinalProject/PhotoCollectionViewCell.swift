//
//  PhotoCollectionViewCell.swift
//  FinalProject
//
//  Created by Logan Mayo on 4/30/19.
//  Copyright © 2019 Tyler Percy. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var spinner: UIActivityIndicatorView!
    
    //Precondition:
    //Postcondition: Spinner will spin and stop spinning. Will also display images
    //This function will control the spinner and displaying images
    func update(with image: UIImage?) {
        if let imageToDisplay = image {
            spinner.stopAnimating()
            imageView.image = imageToDisplay
        } else {
            spinner.startAnimating()
            imageView.image = nil
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        update(with: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        update(with: nil)
    }
}
