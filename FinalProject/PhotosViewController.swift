//
//  PhotosViewController.swift
//  FinalProject
//
//  Created by Logan Mayo on 4/29/19.
//  Copyright © 2019 Tyler Percy. All rights reserved.
//

import UIKit

class PhotosViewController: UIViewController, UICollectionViewDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    
    var store: PhotoStore!
    let photoDataSource = PhotoDataSource()
    
    //Precondition: have pulled photos already
    //Postcondition: gets hotos from wherever user asks
    // This function pulls photos from where the user asks (ex: favorites)
    //PART OF FAVORITES CHALLENGE - A LEVEL
    private func updateDataSource(getFavorite: Bool) {
        //if method is favorite go here
        if getFavorite {
            store.fetchFavoritePhotos { (photosResult) in
                switch photosResult {
                case let .success(photos):
                    self.photoDataSource.photos = photos
                    print("Successfully found \(photos.count) photos.")
                case .failure:
                    self.photoDataSource.photos.removeAll()
                    print("Error fetching photos.")
                }
                self.collectionView.reloadSections(IndexSet(integer: 0))
            }
            //if method is interesting or recent go here
        } else {
            store.fetchAllPhotos { (photosResult) in
                switch photosResult {
                case let .success(photos):
                    self.photoDataSource.photos = photos
                case .failure:
                    self.photoDataSource.photos.removeAll()
                }
                
                self.collectionView.reloadSections(IndexSet(integer: 0))
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = photoDataSource
        collectionView.delegate = self
        
        //programmatically create segmented control to swap between photo arrays
        let segmentedControl = UISegmentedControl(items: ["Interesting", "Recent", "Favorite"])
        segmentedControl.addTarget(self, action: #selector(selectMethod(_:)), for: .valueChanged)
        navigationItem.titleView = segmentedControl
        self.updateDataSource(getFavorite: false)
    }
    
    //Bulk of Chapter 20 Silver
    //Postcondition: buttons must be present on storyboard
    //Precondition: method is selected based on user input
    //This function chooses what method to pull photos
    @objc func selectMethod(_ sender: UISegmentedControl) {
        sender.isEnabled = false
        var method: Method
        switch sender.selectedSegmentIndex {
        case 0:
            method = .interestingPhotos
        case 1:
            method = .recentPhotos
        default:
            //favorites technically isn't a method so it's called through updateDataSource
            updateDataSource(getFavorite: true)
            sender.isEnabled = true
            return
        }
        
        //go here if method is not favorites
        store.fetchSelectedPhotos(for: method) { (photosResult) -> Void in
            self.updateDataSource(getFavorite: false)
            switch photosResult {
            case let .success(photos):
                print("Successfully found \(photos.count) photos.")
                self.updateDataSource(getFavorite: false)
            case let .failure(error):
                print("Error fetching photos: \(error)")
            }
        }
        sender.isEnabled = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showPhoto"?:
            if let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first {
                let photo = photoDataSource.photos[selectedIndexPath.row]
                let destinationVC = segue.destination as! PhotoInfoViewController
                destinationVC.photo = photo
                destinationVC.store = store
                photo.views += 1
            }
        default:
            preconditionFailure("Unexpected segue identifier.")
        }
    }
}

//CollectionView
extension PhotosViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numItemsPerRow = CGFloat(4)
        var spaceBetweenItems = CGFloat(0)
        
        if let collectionViewFlowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            spaceBetweenItems += collectionViewFlowLayout.minimumInteritemSpacing * (numItemsPerRow - 1)
            spaceBetweenItems += collectionViewFlowLayout.sectionInset.left + collectionViewFlowLayout.sectionInset.right
        }
        
        let itemWidth = ((collectionView.bounds.width - spaceBetweenItems) / numItemsPerRow)
        
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        // Download the image data, which could take some time
        let photo = photoDataSource.photos[indexPath.row]
        // The index path for the photo might have changed between the
        // time the request started and finished, so find the most
        // recent index path
        store.fetchImage(for: photo) { (result) in
            guard let photoIndex = self.photoDataSource.photos.index(of: photo),
                case let .success(image) = result else {
                    return
            }
            
            let photoIndexPath = IndexPath(item: photoIndex, section: 0)
            // When the request finishes, only update the cell if it's still visible
            if let cell = self.collectionView.cellForItem(at: photoIndexPath) as? PhotoCollectionViewCell {
                cell.update(with: image)
            }
        }
    }
}

