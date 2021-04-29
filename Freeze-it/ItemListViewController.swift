//
//  ItemListTableView.swift
//  Freezeit
//
//  Created by Peter Rasmussen on 1/28/21.
//  Copyright © 2021 Peter Rasmussen. All rights reserved.
//

import UIKit

class itemTableViewCell: UITableViewCell {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var brand: UILabel!
    @IBOutlet weak var quantity: UILabel!
    @IBOutlet weak var date: UILabel!
    
}

class ItemListViewController: UITableViewController {
    
    var freezerId: Int32!
    var items: [Item] = []
    var units: [Unit] = []
    var brands: [Brand] = []
    
    
    @IBAction func addItem() {
        self.performSegue(withIdentifier: "ItemNewSegue", sender: nil)
    }
    
    func reload() {
        items = FreezeitManager.shared.getItems(id: freezerId)
        units = FreezeitManager.shared.getUnits()
        brands = FreezeitManager.shared.getBrands()
        //print(items)
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(animated)
        //print("XXX Freezer: ", freezerId ?? 0)
        reload()
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    // Lesson learned: On storyboard, constrain UILabels to cell border with distance 0
    // on the vertical boundaries for the cell to autosize
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = (tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) ) as? itemTableViewCell
        //cell.textLabel?.text = items[indexPath.row].name + "  " + String(items[indexPath.row].quantity)
        
        let item = items[indexPath.row]
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = Locale.current
        
        let brandIndex = brands.firstIndex(where: {$0.id == item.brandId }) ?? nil
        let unitIndex = units.firstIndex(where: {$0.id == item.unitId }) ?? nil
        let unitName = (unitIndex == nil ? "No unit" : units[unitIndex!].name)

        cell?.name.text = item.name
        cell?.brand.text = (brandIndex == nil ? "No brand" : brands[brandIndex!].name)
        cell?.quantity.text = "   " + String(item.quantity) + " " + unitName
        cell?.date.text = "Expires: " + ItemViewController().date2string(date: item.dateDue)
        
        if indexPath.row % 2 == 1 {
            cell?.backgroundColor = UIColor(white: 0.0, alpha: 0.05)
        }
        else {
            cell?.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        }
        
        return cell!
    }
    
    
    // Swipe functionality re-used from my delete functionality in pset for Notes (CS50)
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // pdr: editingStyle == .delete is true with "big" swipe or swipe + click "Delete"
        
        if editingStyle == .delete {
            // print("deleting ...")
            // pdr: 1. delete row in database
            
            FreezeitManager.shared.deleteItem(id: items[indexPath.row].id)
            
            // pdr: 2. delete row in tableView
            items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            //print("XXX rows: ", tableView.numberOfRows(inSection: 0))
            
            // In order to "paint" grey tone alternating background after a delete
            if tableView.numberOfRows(inSection: 0) > 0 {
                var indexPathList: [IndexPath] = []
                
                for cell in tableView.visibleCells {
                    let indexPath = tableView.indexPath(for: cell)!
                    indexPathList.append(indexPath)
                }
                tableView.reloadRows(at: indexPathList, with: .fade)
            }
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //selectedCell = indexPath.item
        //print("XXX selected cell: ", selectedCell, items[selectedCell].id, items[selectedCell].name)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as? ItemViewController
        
        destination?.units = units
        destination?.brands = brands
        
        if segue.identifier == "ItemDetailSegue" {
            destination?.navigationItem.title = "Item details"
            let indexPath = tableView.indexPathForSelectedRow
            //print("XXX segue: ", indexPath!.item, indexPath!.row)
            //print("XXX segue: ", selectedCell, items[selectedCell].id, items[selectedCell].name)
            destination?.item = items[indexPath!.row]
        }
        else if segue.identifier == "ItemNewSegue" {
            destination?.navigationItem.title = "New item"
            destination?.isNew = true
            destination?.item.freezerId = freezerId
            //destination?.item.id = (items.map{$0.id}.max() ?? 0) + 1
        }
    }
    
}
