//
//  ViewController.swift
//  Freezeit
//
//  Created by Peter Rasmussen on 1/20/21.
//  Copyright © 2021 Peter Rasmussen. All rights reserved.
//
//  Credits to Axel Kee, https://fluffy.es/move-view-when-keyboard-is-shown/
//  for showing how to move the view when keyboard would
//  otherwise cover the textfield.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var freezers: [Freezer] = []
    //var brands: [Brand] = []
    var selectedCell: Int = 0
    
    @IBOutlet weak var freezerCollectionView: UICollectionView!
    // Functions related to freezerCollectionView are placed in extension to this ViewController
    
    @IBAction func longPressCell(_ sender: UILongPressGestureRecognizer) {
        
        if sender.state == .began {
            //print("XXX Cell long press", sender.location(in: freezerCollectionView))
            let cellLocation = sender.location(in: freezerCollectionView)
            
            // Guarding against 'long press' outside cell
            guard let tempCell = UICollectionView.indexPathForItem(freezerCollectionView)(at: cellLocation)?.item else {
                return
            }
            selectedCell = tempCell
            
            self.performSegue(withIdentifier: "Freezer2EditSegue", sender: nil)
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        freezerCollectionView.delegate = self
        freezerCollectionView.dataSource = self
        reload()
        
        // XXX testing
        //print("XXX screen size: ", UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        
        if freezers.count == 0 {
            let alert = UIAlertController(title: nil, message: "To start your first freezer, press the + icon in upper right corner.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Got it!", style: .cancel, handler: nil))

            self.present(alert, animated: true)
        }
                
    }
    
    
    override func prepare (for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "Freezer2EditSegue",
          let destination = segue.destination as? FreezerDetails {
            destination.stateNewEdit = "Edit"
            destination.freezer = freezers[selectedCell]
        }
        else if segue.identifier == "FreezerNewSegue",
            let destination = segue.destination as? FreezerDetails {
            let maxID = freezers.map{$0.id}.max()
            destination.stateNewEdit = "New"
            destination.freezer = Freezer(id: Int32(maxID ?? 0) + 1, key: "", name: "", colorCode: 0)
        }
        else if segue.identifier == "UnitsSegue",
                let destination = segue.destination as? UnitsBrandsList {
            destination.navigationItem.title = "Units"
            destination.unitsOrBrands = "units"
            
        }
        else if segue.identifier == "BrandsSegue",
                let destination = segue.destination as? UnitsBrandsList {
            destination.navigationItem.title = "Brands"
            destination.unitsOrBrands = "brands"
            
        }
        else if segue.identifier == "Freezer2ListSegue",
                let destination = segue.destination as? ItemListViewController {
            destination.navigationItem.title = freezers[selectedCell].name
            destination.freezerId = freezers[selectedCell].id
            //print("XXX freezerID: ", freezers[selectedCell].id)
        }
    }
    
}  // End class


// Functions related to the freezerCollectionView
extension ViewController {
        
    func reload() {
        freezers = FreezeitManager.shared.getFreezers()
        freezerCollectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Set the number of items in your collection view.
        return freezers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Access
        let cell = freezerCollectionView.dequeueReusableCell(withReuseIdentifier: "FreezerCell", for: indexPath) as! FreezerCell
        
        // Do any custom modifications you your cell, referencing the outlets you defined in the Custom cell file.
        if freezers[indexPath.item].colorCode == 1 {
            cell.backgroundColor = UIColor.systemTeal
        }
        else if freezers[indexPath.item].colorCode == 2 {
            cell.backgroundColor = UIColor.systemGreen
        }
        else {
            cell.backgroundColor = UIColor.systemYellow
        }
        
        cell.cellLabel.text = freezers[indexPath.item].key     //"item \(indexPath.item)"
        cell.cellName.text = String(freezers[indexPath.item].name.prefix(8))
        cell.freezer = freezers[indexPath.item]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCell = indexPath.item
        //print ("XXX touched cell: ", selectedCell)
        self.performSegue(withIdentifier: "Freezer2ListSegue", sender: nil)
    }
   
}
