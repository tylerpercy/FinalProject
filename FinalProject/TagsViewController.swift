//
//  TagsViewController.swift
//  FinalProject
//
//  Created by Tyler Percy on 5/1/19.
//  Copyright © 2019 Tyler Percy. All rights reserved.
//

import UIKit
import CoreData

class TagsViewController: UITableViewController {
    
    var store: PhotoStore!
    var photo: Photo!
    
    var selectedIndexPaths = [IndexPath]()
    
    let tagDataSource = TagDataSource()
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    //Precondition: The button is tapped to add a new tag
    //Postcondition: A new tag will be added based on what the user inputs
    //This function creates a tag for a photo
    @IBAction func addNewTag(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Add Tag", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "tag name"
            textField.autocapitalizationType = .words
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            if let tagName = alertController.textFields?.first?.text {
                let context = self.store.persistentContainer.viewContext
                let newTag = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: context)
                newTag.setValue(tagName, forKey: "name")
                
                do {
                    try self.store.persistentContainer.viewContext.save()
                } catch let error {
                    print("CoreData save failed: \(error)")
                }
                
                self.updateTags()
            }
        }
        
        alertController.addAction(okAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    //Precondition: make or assign a new tag
    //Postcondition: The tag list will be updated
    //This function refreshes the tags if they have been changed in some way.
    func updateTags() {
        store.fetchAllTags { (tagsResult) in
            switch tagsResult {
            case let .success(tags):
                self.tagDataSource.tags = tags
                
                guard let photoTags = self.photo.tags as? Set<Tag> else { return }
                
                for tag in photoTags {
                    if let index = self.tagDataSource.tags.index(of: tag) {
                        let indexPath = IndexPath(row: index, section: 0)
                        self.selectedIndexPaths.append(indexPath)
                    }
                }
            case let .failure(error):
                print("Error fetching tags: \(error)")
            }
            
            self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = tagDataSource
        
        updateTags()
    }
    
}

extension TagsViewController {
    
    //Precondition: The tag button must be clicked and the view must be photoInfoViewController
    //Postcondition: The table will be created, displaying tags and a favorite tag
    //This function creates the table that the tags will be listed in.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            photo.isFavorite = !photo.isFavorite
            try? store.persistentContainer.viewContext.save()
            tableView.reloadRows(at: [indexPath], with: .automatic)
            return
        }
        
        let tag = tagDataSource.tags[indexPath.row]
        
        if let index = selectedIndexPaths.index(of: indexPath) {
            selectedIndexPaths.remove(at: index)
            photo.removeFromTags(tag)
        } else {
            selectedIndexPaths.append(indexPath)
            photo.addToTags(tag)
        }
        
        do {
            try store.persistentContainer.viewContext.save()
        } catch {
            print("CoreData save failed: \(error)")
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    //Precondition: The tag button must be clicked and the view must be photoInfoViewController
    //Postcondition: The checkmarks will be toggable
    //This function makes a checkmark box that can be checked or unchecked
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            cell.accessoryType = photo.isFavorite ? .checkmark : .none
            return
        }
        if selectedIndexPaths.index(of: indexPath) != nil {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }
}
