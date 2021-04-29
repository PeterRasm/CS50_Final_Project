//
//  UnitsBrandsViewController.swift
//  Freezeit
//
//  Created by Peter Rasmussen on 2/3/21.
//  Copyright © 2021 Peter Rasmussen. All rights reserved.
//

import UIKit

class UnitsBrandsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var group: UILabel!
}

class UnitsBrandsList: UIViewController {
    
    var unitsOrBrands: String!
    var isNew: Bool = false
    var canSave: Bool = false
    
    var units: [Unit] = []
    var brands: [Brand] = []
    
    @IBOutlet var editCreate: UILabel!
    var unitOrBrandId: Int32!
    @IBOutlet var unitOrBrand: UILabel!
    @IBOutlet var unitOrBrandText: UITextField!
    @IBOutlet var sortKey: UILabel!
    @IBOutlet var sortKeyText: UITextField!
    
    
    @IBOutlet weak var unitsBrandsTableView: UITableView!
    
    @IBOutlet weak var name: UILabel!
    
    @IBAction func addUnitBrand() {
        editCreate.text = "Create New"
        deleteButton.setTitleColor(UIColor.lightGray, for: .normal)
        if unitsOrBrands == "units" {
            // ?? asks if nil, then defaults to 0
            // New id is max-old-id + 1
            unitOrBrandId = (units.map{$0.id}.max() ?? 0) + 1
        }
        else if unitsOrBrands == "brands" {
            unitOrBrandId = (brands.map{$0.id}.max() ?? 0) + 1
        }
        else {
            return
        }
        isNew = true
        unitOrBrandText.text = ""
        unitOrBrandText.placeholder = "New"
        sortKeyText.text = ""
        sortKeyText.placeholder = "New"
    }
    
    
    @IBAction func nameChanged() {
        canSave = true
    }
    
    @IBAction func keyChanged() {
        canSave = true 
    }
    
    @IBAction func save(_ sender: Any) {
        if !canSave {
            return
        }
        if isNew {
            if unitsOrBrands == "units" {
                FreezeitManager.shared.createUnit(unit: Unit(id: unitOrBrandId, name: unitOrBrandText.text!, sortKey: sortKeyText.text!))
            }
            else if unitsOrBrands == "brands" {
                FreezeitManager.shared.createBrand(brand: Brand(id: unitOrBrandId, name: unitOrBrandText.text!))
            }
            isNew = false
        }
        else {
            if unitsOrBrands == "units" {
                FreezeitManager.shared.updateUnit(unit: Unit(id: unitOrBrandId, name: unitOrBrandText.text!, sortKey: sortKeyText.text!))
            }
            else if unitsOrBrands == "brands" {
                FreezeitManager.shared.updateBrand(brand: Brand(id: unitOrBrandId, name: unitOrBrandText.text!))
            }
        }
        deleteButton.setTitleColor(UIColor.systemBlue, for: .normal)
        editCreate.text = "Edit"
        view.endEditing(true)
        reload()
        
        setSelectedRow(row: getRow())
    }
    
    @IBOutlet var deleteButton: UIButton!
    @IBAction func deleteCell(_ sender: Any) {
        // delete in DB and reload
        // XYZ: update to NULL if exists in item records
        let row = getRow()
        var didDelete: Bool = false
        if unitsOrBrands == "brands" {
            didDelete = FreezeitManager.shared.deleteBrand(id: unitOrBrandId)
        }
        else {
            didDelete = FreezeitManager.shared.deleteUnit(id: unitOrBrandId)
        }
        
        if !didDelete {
            let alert = UIAlertController(title: nil, message: "The brand or unit you attempted to delete is already in use and cannot be deleted!", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))

            self.present(alert, animated: true)
        }
        
        if didDelete {
            reload()
            // Highlight/select row - 1 after delete
            setSelectedRow(row: (row - 1 < 0 ? 0 : row - 1))
        }
    }
    
    func getRow() -> Int32 {
        // Find row location based on id
        // XYZ: Try to find better way to locate row that is NOT selected by user
        var row: Int32 = -1
        if unitsOrBrands == "brands" {
            for brand in brands {
                row += 1
                if brand.id == unitOrBrandId {
                    break
                }
            }
        }
        else {
            for unit in units {
                row += 1
                if unit.id == unitOrBrandId {
                    break
                }
            }
        }
        return row
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super .viewWillDisappear(animated)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(animated)
        //print("XXX will appear ...")
        if unitsOrBrands == "units" {
            unitOrBrand.text = "Unit name"
        }
        else if unitsOrBrands == "brands" {
            unitOrBrand.text = "Brand name"
            sortKey.text = ""
            sortKeyText.placeholder = ""
            sortKeyText.isHidden = true
        }
    }
    
    override func viewDidLoad() {
        super .viewDidLoad()
        
        reload()
        
        // Call the 'keyboardWillShow' function when the view controller receive the
        // notification that a keyboard is going to be shown
        NotificationCenter.default.addObserver(self, selector: #selector(UnitsBrandsList.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        // Call the 'keyboardWillHide' function when the view controlelr receive notification
        // that keyboard is going to be hidden
        NotificationCenter.default.addObserver(self, selector: #selector(UnitsBrandsList.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // If no existing element start in create mode
        if (unitsOrBrands == "brands" && brands.count == 0) || (unitsOrBrands == "units" && units.count == 0) {
            addUnitBrand()
        }
        else {
            editCreate.text = "Edit"
            setSelectedRow(row: 0)
            if unitsOrBrands == "units" {
                unitOrBrandId = units[0].id
                unitOrBrandText.text = units[0].name
                sortKeyText.text = units[0].sortKey
            }
            else if unitsOrBrands == "brands" {
                unitOrBrandId = brands[0].id
                unitOrBrandText.text = brands[0].name
            }
        }
    }
    
    // Credit: Axel Kee, https://fluffy.es/move-view-when-keyboard-is-shown/
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
           // if keyboard size is not available for some reason, dont do anything
           return
        }
      
      // move the root view up by the distance of keyboard height
      self.view.frame.origin.y = 0 - keyboardSize.height
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
      // move back the root view origin to zero
      self.view.frame.origin.y = 0
    }
    
    // Hide keyboard when user taps outside textfield
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
}

// XYZ_tableView
extension UnitsBrandsList: UITableViewDelegate, UITableViewDataSource {
    
    func reload() {
        if unitsOrBrands == "units" {
            units = FreezeitManager.shared.getUnits()
        }
        else if unitsOrBrands == "brands" {
            brands = FreezeitManager.shared.getBrands()
        }
        unitsBrandsTableView.reloadData()
    }
    
    func setSelectedRow(row: Int32) {
        // If last row was just deleted, re-start in "create" mode
        if (unitsOrBrands == "brands" && brands.count == 0) || (unitsOrBrands == "units" && units.count == 0) {
            addUnitBrand()
            return
        }
        // Find indexPath of passed argument ('row' = 'id')
        let indexPath = IndexPath(row: Int(row), section: 0)
        unitsBrandsTableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableView.ScrollPosition.none)
        unitsBrandsTableView.scrollToRow(at: indexPath, at: .middle, animated: false)
        
        setSelectedValues(indexPath: indexPath)
    }
    
    func setSelectedValues(indexPath: IndexPath) {
        if unitsOrBrands == "units" {
            unitOrBrandId = units[indexPath.row].id
            unitOrBrandText.text = units[indexPath.row].name
            sortKeyText.text = units[indexPath.row].sortKey
        }
        else if unitsOrBrands == "brands" {
            unitOrBrandId = brands[indexPath.row].id
            unitOrBrandText.text = brands[indexPath.row].name
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if unitsOrBrands == "units" {
            return units.count
        }
        else  {
            return brands.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UnitBrandCell", for: indexPath) as! UnitsBrandsTableViewCell
        if unitsOrBrands == "units" {
            cell.name.text = units[indexPath.row].name
            cell.group.text = units[indexPath.row].sortKey
            
        }
        else if unitsOrBrands == "brands" {
            cell.name.text = brands[indexPath.row].name
            cell.group.text = " "
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        setSelectedValues(indexPath: indexPath)
    }
    
}
