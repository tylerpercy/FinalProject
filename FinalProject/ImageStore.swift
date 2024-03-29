//
//  ImageStore.swift
//  Homepwner
//
//  Created by Logan Mayo on 4/6/19.
//  Copyright © 2019 Logan Mayo. All rights reserved.
//

import UIKit
class ImageStore {

    let cache = NSCache<NSString, UIImage>()
    
    //Sets image for a specific item
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
        // Create full URL for image
        let url = imageURL(forKey: key)
        //Turn image into JPEG data
        if let data = UIImagePNGRepresentation(image) {
            //write it to full URL
            let _ = try? data.write(to: url, options: [.atomic])
        }
    }
    
    //Chooses an image
    func image(forKey key: String) -> UIImage? {
        if let existingImage = cache.object(forKey: key as NSString) {
            return existingImage
        }
        
        let url = imageURL(forKey: key)
        guard let imageFromDisk = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        
        cache.setObject(imageFromDisk, forKey: key as NSString)
        
        return imageFromDisk
    }
     // Deletes an image from a certain item
    func deleteImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
        
        let url = imageURL(forKey: key)
        do {
            try FileManager.default.removeItem(at: url)
        } catch let deleteError {
            print("Error removing the image from disk: \(deleteError)")
        }
    }
    
    func imageURL(forKey key: String) -> URL {
        let documentsDirectories =
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        return documentDirectory.appendingPathComponent(key)
    }
    
}
