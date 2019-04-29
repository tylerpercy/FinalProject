//
//  Photo.swift
//  FinalProject
//
//  Created by Logan Mayo on 4/29/19.
//  Copyright © 2019 Tyler Percy. All rights reserved.
//

import Foundation

class Photo {
    let title: String
    let remoteURL: URL
    let photoID: String
    let dateTaken: Date
    init(title: String, photoID: String, remoteURL: URL, dateTaken: Date) {
        self.title = title
        self.photoID = photoID
        self.remoteURL = remoteURL
        self.dateTaken = dateTaken
    }
}
