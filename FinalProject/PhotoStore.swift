//
//  PhotoStore.swift
//  FinalProject
//
//  Created by Logan Mayo on 4/29/19.
//  Copyright © 2019 Tyler Percy. All rights reserved.
//

import UIKit
import CoreData

enum ImageResult {
    case success(UIImage)
    case failure(Error)
}

enum PhotoError: Error {
    case imageCreationError
}

enum PhotosResult {
    case success([Photo])
    case failure(Error)
}

enum TagResult {
    case success([Tag])
    case failure(Error)
}

class PhotoStore {
    
    let imageStore = ImageStore()
    var showInterestingPhotos = true //recent = false
    
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Photorama")
        container.loadPersistentStores(completionHandler: { (description, error) in
            if let error = error {
                print("Error setting up CoreData \(error).")
            }
        })
        return container
    }()
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    //Precondition: The photo must have a photoID and URL
    //Postconditon: The photo will be fetched and ready to be displayed
    //This function fetches the image, but if there are errors it will print to the console.
    func fetchImage(for photo: Photo, completion: @escaping (ImageResult) -> Void) {
        guard let photoKey = photo.photoID else {
            preconditionFailure("Photo expected to have a photoID")
        }
        
        if let image = imageStore.image(forKey: photoKey) {
            OperationQueue.main.addOperation {
                completion(.success(image))
            }
            
            return
        }
        
        guard let photoURL = photo.remoteURL else {
            preconditionFailure("Photo expected to have a remote URL.")
        }
        
        let request = URLRequest(url: photoURL as URL)
        
        let task = session.dataTask(with: request) {
            (data, response, error) in
           
            let result = self.processImageRequest(data: data, error: error)
            if case let .success(image) = result {
                self.imageStore.setImage(image, forKey: photoKey)
            }
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
    
    //Precondition: app is populated with photos that may or may not be tagged
    //Postcondition: the tags will be fetched and ready to be displayed
    //This function fetches all the tags on photos and displays them
    func fetchAllTags(completion: @escaping (TagResult) -> Void) {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        let sortByName = NSSortDescriptor(key: "\(#keyPath(Tag.name))", ascending: true)
        fetchRequest.sortDescriptors = [sortByName]
        
        let viewContext = persistentContainer.viewContext
        
        viewContext.perform {
            do {
                let allTags = try fetchRequest.execute()
                completion(.success(allTags))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    //Precondition: User clicks on the image
    //Postcondition: The photo will either be able to open or not be able to be opened
    //This function checks that the photo can be opened and displayed
    private func processImageRequest(data: Data?, error: Error?) -> ImageResult {
        guard let imageData = data,
            let image = UIImage(data: imageData) else {
                if data == nil {
                    return .failure(error!)
                } else {
                    return .failure(PhotoError.imageCreationError)
                }
        }
        
        return .success(image)
    }
    
    //Precondition: The user selects photos
    //Postcondition: Gets the photos that the users selected based on method
    //This function will get the photos based on the method that the user has selected
    func fetchSelectedPhotos(for method: Method, completion: @escaping (PhotosResult) -> Void) {
        let url = FlickrAPI.photosURL(for: method)
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            //Chapter 20 Bronze
            if let response = response as? HTTPURLResponse {
                print("Status Code: \(response.statusCode)")
                
                for field in response.allHeaderFields {
                    print("Header Fields:\(field.key): \(field.value)")
                }
            }
            
            self.processPhotoRequest(data: data, error: error, completion: { (result) in
                OperationQueue.main.addOperation {
                    completion(result)
                }
            })
        }
        
        task.resume()
    }
    
    //Precondition: Have favorite photos, it will work without them, but the field will be blank
    //Postcondition: The favorite photos will be fetched and displayed
    // This function moves to the favorites tab and displays the photos that are favorited
    func fetchFavoritePhotos(completion: @escaping (PhotosResult) -> Void) {
        let fetchRequest: NSFetchRequest = Photo.fetchRequest()
        let sortByDateTaken = NSSortDescriptor(key: #keyPath(Photo.photoID), ascending: true)
        fetchRequest.sortDescriptors = [sortByDateTaken]
        
        let predicate = NSPredicate(format: "(%K == TRUE)", #keyPath(Photo.isFavorite))
        fetchRequest.predicate = predicate
        
        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            do {
                let favoritePhotos = try viewContext.fetch(fetchRequest)
                completion(.success(favoritePhotos))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func fetchAllPhotos(completion: @escaping (PhotosResult) -> Void) {
        let fetchRequest: NSFetchRequest = Photo.fetchRequest()
        let sortByDateTaken = NSSortDescriptor(key: "\(#keyPath(Photo.photoID))", ascending: true)
        fetchRequest.sortDescriptors = [sortByDateTaken]
        
        let viewContext = persistentContainer.viewContext
        
        viewContext.perform {
            do {
                let allPhotos = try viewContext.fetch(fetchRequest)
                completion(.success(allPhotos))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
    
    
    //Precondition: The data for a photo has been requested
    //Postcondition: The data will be sent or it will fail and print to the console
    //This function returns the data of the photo
    private func processPhotoRequest(data: Data?, error: Error?, completion: @escaping (PhotosResult) -> Void) {
        guard let jsonData = data else {
            completion(.failure(error!))
            return
        }
        
        persistentContainer.performBackgroundTask { (context) in
            let result = FlickrAPI.photos(fromJSON: jsonData, into: context)
            
            do {
                try context.save()
            } catch {
                print("Error saving to CoreData: \(error)")
                completion(.failure(error))
                return
            }
            
            switch result {
            case let .success(photos):
                let photoIDs = photos.map { $0.objectID }
                let viewContext = self.persistentContainer.viewContext
                let viewContextPhotos = photoIDs.map { viewContext.object(with: $0) } as! [Photo]
                completion(.success(viewContextPhotos))
            case .failure:
                completion(result)
            }
        }
    }
    
    func saveIfNeeded() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            try? context.save()
        }
    }
}
