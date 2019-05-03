//
//  TagSataSource.swift
//  FinalProject
//
//  Created by Tyler Percy on 5/1/19.
//  Copyright © 2019 Tyler Percy. All rights reserved.
//

import UIKit
import CoreData

class TagDataSource: NSObject, UITableViewDataSource {
    
    var tags = [Tag]()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 1      //The favorite tag
        }
        return tags.count
    }
    
    //Function that creates a section for favoriting a photo that is separate from the rest of the tags
    //PART OF FAVORITES CHALLENGE - A LEVEL
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        
        if indexPath.section == 1 {
            cell.textLabel?.text = "Favorite"
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
            return cell
        }
        
        let tag = tags[indexPath.row]
        cell.textLabel?.text = tag.name
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 1 ? " " : nil
    }
}

