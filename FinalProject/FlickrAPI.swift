//
//  FlickrAPI.swift
//  FinalProject
//
//  Created by Logan Mayo on 4/29/19.
//  Copyright © 2019 Tyler Percy. All rights reserved.
//

import Foundation
import CoreData

enum FlickrError: Error {
    case invalidJSONData
}

enum Method: String {
    case interestingPhotos = "flickr.interestingness.getList"
    case recentPhotos = "flickr.photos.getRecent"
}

struct FlickrAPI {
    
    private static let baseURLString = "https://api.flickr.com/services/rest"
    private static let apiKey = "a6d819499131071f158fd740860a5a88"
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    static func flickrURL(method: Method, parameters: [String: String]?) -> URL {
        var components = URLComponents(string: baseURLString)!
        
        let baseParams = [
            "method": method.rawValue,
            "format": "json",
            "nojsoncallback": "1",
            "api_key": apiKey
        ]
        
        var queryItems: [URLQueryItem] = baseParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        if let additionalParams = parameters {
            let additionalQueryItems: [URLQueryItem] = additionalParams.map { URLQueryItem(name: $0.key, value: $0.value) }
            queryItems.append(contentsOf: additionalQueryItems)
        }
        
        components.queryItems = queryItems
        
        return components.url!
    }
    
    static func photosURL(for method: Method) -> URL {
        return FlickrAPI.flickrURL(method: method, parameters: ["extras": "url_h,date_taken"])
    }
    
    static func photos(fromJSON data: Data, into context: NSManagedObjectContext) -> PhotosResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDictionary = jsonObject as? [AnyHashable: Any],
                let photos = jsonDictionary["photos"] as? [String: Any],
                let photosArray = photos["photo"] as? [[String: Any]] else {
                    return .failure(FlickrError.invalidJSONData)
            }
            
            var finalPhotos = [Photo]()
            
            for photoJSON in photosArray {
                if let photo = photo(fromJSON: photoJSON, into: context) {
                    finalPhotos.append(photo)
                }
            }
            
            if finalPhotos.isEmpty && !photosArray.isEmpty {
                return .failure(FlickrError.invalidJSONData)
            }
            
            return .success(finalPhotos)
            
        } catch let error {
            return .failure(error)
        }
    }
    
    private static func photo(fromJSON json: [String: Any], into context: NSManagedObjectContext) -> Photo? {
        guard let photoID = json["id"] as? String,
            let title = json["title"] as? String,
            let dateString = json["datetaken"] as? String,
            let photoURLString = json["url_h"] as? String,
            let url = URL(string: photoURLString),
            let dateTaken = dateFormatter.date(from: dateString) else {
                return nil
        }
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "\(#keyPath(Photo.photoID)) == \(photoID)")
        fetchRequest.predicate = predicate
        
        var fetchedPhotos: [Photo]?
        context.performAndWait {
            fetchedPhotos = try? fetchRequest.execute()
        }
        
        if let existingPhoto = fetchedPhotos?.first {
            return existingPhoto
        }
        
        var photo: Photo!
        context.performAndWait {
            photo = Photo(context: context)
            photo.title = title
            photo.photoID = photoID
            photo.remoteURL = url as NSURL
            photo.dateTaken = dateTaken as NSDate
        }
        
        return photo
    }
    
}
