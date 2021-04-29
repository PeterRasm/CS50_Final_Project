//
//  CreateFreezerViewController.swift
//  Freezeit
//
//  Created by Peter Rasmussen on 1/21/21.
//  Copyright © 2021 Peter Rasmussen. All rights reserved.
//
//  Create/Edit Freezer, set name, color etc
//  When action is done, return to previous view

import UIKit

class FreezerDetails: UIViewController {
    
    var freezer: Freezer? = nil
    var stateNewEdit: String = "New"    // Used by segue to direct if this controller
                                        // is used for EDIT or CREATE (New)
    var canSave: Bool = false
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var freezerKey: UITextField!
    @IBOutlet var freezerName: UITextField!
    
    // Used to hide keyboard when 'Return'/'Done'
    @IBAction func textfieldHitReturn(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBOutlet var color1x: UIButton!
    @IBAction func color1() {
        if freezer?.colorCode != 1 {
            setColor(button: color1x, colorCode: 1)
        }
    }
    
    @IBOutlet var color2x: UIButton!
    @IBAction func color2() {
        if freezer?.colorCode != 2 {
            setColor(button: color2x, colorCode: 2)
        }
        
    }
    
    @IBOutlet var color3x: UIButton!
    @IBAction func color3() {
        if freezer?.colorCode != 3 {
            setColor(button: color3x, colorCode: 3)
        }
    }
    
    // Highlight chosen color/button with a frame
    func setColor(button: UIButton, colorCode: Int32) {
        color1x.layer.borderWidth = 0
        color2x.layer.borderWidth = 0
        color3x.layer.borderWidth = 0
        button.layer.borderWidth = 6
        // colorCode 0 is passed if view is entered to create new post
        if colorCode != 0 {
            freezer?.colorCode = colorCode
            saveButton.setTitleColor(UIColor.systemBlue, for: .normal)
            canSave = true
        }
    }
    
    @IBAction func editKeyChanged(_ sender: Any) {
        freezerKey.text = String((freezerKey.text?.prefix(3))!)
        //print("XXX key changed .....: ", canSave)
        if !canSave {
            canSave = true
            //print (canSave)
            saveButton.setTitleColor(UIColor.systemBlue, for: .normal)
        }
    }
    
    @IBAction func editNameChanged(_ sender: Any) {
        freezerName.text = String((freezerName.text?.prefix(25))!)
        //print("XXX name changed ...: ", canSave)
        if !canSave {
            canSave = true
            saveButton.setTitleColor(UIColor.systemBlue, for: .normal)
        }
    }
  
    @IBOutlet var saveButton: UIButton!
    @IBAction func saveFreezer() {
        // write to DB, get ID in return, unlock 'delete freezer'
        // check for new freezer that both key and name have value
        freezer!.key = freezerKey.text!
        freezer!.name = freezerName.text!
        
        if stateNewEdit == "New" && canSave  {
            FreezeitManager.shared.createFreezer(freezer: freezer!)
            //print("XXX saved # ", freezer!.id)
            exitView()
        }
        else if canSave {
            FreezeitManager.shared.updateFreezer(freezer: freezer!)
            //saveButton.setTitleColor(UIColor.lightGray, for: .normal)
            //print("XXX saved: ", freezer!.id)
            exitView()
        }
    }
    
    @IBOutlet var deleteButton: UIButton!
    @IBAction func deleteFreezer() {
        if stateNewEdit != "Edit" {
            return
        }
        
        // First attempt to delete freezer returns false if items exzist with freezer id
        let canDelete = FreezeitManager.shared.deleteFreezer(id: freezer!.id, deleteAll: false)
        if !canDelete {
            // Learning how to use 'alert' msg:
            // https://learnappmaking.com/uialertcontroller-alerts-swift-how-to/
            
            let alert = UIAlertController(title: "Delete this freezer?", message: "The freezer you are attempting to delete already contains items, deleting this freezer will also delete these items!", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { action in
                _ = FreezeitManager.shared.deleteFreezer(id: self.freezer!.id, deleteAll: true)
                self.exitView()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            self.present(alert, animated: true)
            
        }
        // This exitView is otherwise handled by the alert action above
        if canDelete {
            exitView()
        }
    }
    
    // Hide keyboard when user taps outside textfield
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        color1x.backgroundColor = UIColor.systemTeal
        color2x.backgroundColor = UIColor.systemGreen
        color3x.backgroundColor = UIColor.systemYellow
        color1x.layer.borderColor = UIColor.black.cgColor
        color2x.layer.borderColor = UIColor.black.cgColor
        color3x.layer.borderColor = UIColor.black.cgColor
        
        if stateNewEdit == "New" {
            titleLabel.text = "Setup New Freezer"
            //freezerKey.textColor = UIColor.lightGray
            //freezerName.textColor = UIColor.lightGray
            deleteButton.setTitleColor(UIColor.lightGray, for: .normal)
            setColor(button: color1x, colorCode: 0)
            freezer?.colorCode = 1
        }
        else {
            titleLabel.text = "Edit Freezer Details"
            deleteButton.setTitleColor(UIColor.systemBlue, for: .normal)
            freezerKey.text = freezer?.key
            freezerName.text = freezer?.name
            if freezer?.colorCode == 1 {
                color1x.layer.borderWidth = 6
            }
            else if freezer?.colorCode == 2 {
                color2x.layer.borderWidth = 6
            }
            else if freezer?.colorCode == 3 {
                color3x.layer.borderWidth = 6
            }
        }
        saveButton.setTitleColor(UIColor.lightGray, for: .normal)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Place code here that should execute when exits this view
    }
    
    // Programatically exit this view
    func exitView() {
        navigationController?.popViewController(animated: true)
    }
}
