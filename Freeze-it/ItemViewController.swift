//
//  ItemViewController.swift
//  Freezeit
//
//  Created by Peter Rasmussen on 2/16/21.
//  Copyright © 2021 Peter Rasmussen. All rights reserved.
//
//
//
//  ToDo:
//          - connect keyboard to textfields
//          - connect date picker to date fields
//          - select brand/unit from select list with option to add new

import UIKit
import Foundation

class ItemViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // View is used for both viewing existing item and creating a new item
    var isNew: Bool = false
    
    var item: Item = Item(id: 0, name: "", brandId: 0, quantity: 0, unitId: 0, freezerId: 0, dateIn: Date(), dateDue: Date())
    var units: [Unit] = []
    var brands: [Brand] = []
    
    @IBOutlet var itemName: UITextField!
    @IBOutlet var brandName: UITextField!
    @IBOutlet var quantity: UITextField!
    @IBOutlet var unitName: UITextField!
    @IBOutlet var dateIn: UITextField!
    @IBOutlet var dateDue: UITextField!
    
    var selectedPickerRow = 0
    var elementPicker: UIPickerView!
    
    
    // Used to hide keyboard when 'Return'/'Done'
    @IBAction func textfieldHitReturn(_ sender: Any) {
        view.endEditing(true)
    }
    
    
    // pdr: I think I can merge these 2 IBAction and distinguish with isFirstResponder
    @IBAction func brandEditDidBegin(_ sender: Any) {
        createPicker()
        focusPicker(elementType: "brand")
    }
    
    @IBAction func UnitEditDidBegin(_ sender: Any) {
        createPicker()
        focusPicker(elementType: "unit")
    }
    
    @IBAction func DateInEditDidBegin(_ sender: Any) {
        createDatePicker()
    }
    
    @IBAction func dateDueEditDidBegin(_ sender: Any) {
        createDatePicker()
    }
    
    // Locate in picker the item already in text field
    func focusPicker(elementType: String) {
        var index = 0
        if elementType == "brand" {
            index = brands.firstIndex(where: {$0.id == item.brandId }) ?? 0
        }
        else if elementType == "unit" {
            index = units.firstIndex(where: {$0.id == item.unitId }) ?? 0
        }
        elementPicker.selectRow(index, inComponent: 0, animated: true)
    }
    
    @IBAction func saveItem() {
        item.name = itemName.text ?? "no name"
        item.quantity = (Float(quantity.text ?? "0") ?? 0)
        if isNew {
            FreezeitManager.shared.createItem(item: item)
        }
        else {
            
            FreezeitManager.shared.updateItem(item: item)
        }
        // Programatically exit this view
        navigationController?.popViewController(animated: true)
    }
    
    @objc func tapDone() {
        if dateIn.isFirstResponder, let datePicker = dateIn.inputView as? UIDatePicker {
            item.dateIn = datePicker.date
            dateIn.text = date2string(date: datePicker.date)
        }
        else if dateDue.isFirstResponder, let datePicker = dateDue.inputView as? UIDatePicker {
            item.dateDue = datePicker.date
            dateDue.text = date2string(date: datePicker.date)
        }
        else if brandName.isFirstResponder {
            brandName.text = brands[selectedPickerRow].name
            item.brandId = brands[selectedPickerRow].id
        }
        else if unitName.isFirstResponder {
            unitName.text = units[selectedPickerRow].name
            item.unitId = units[selectedPickerRow].id
        }
        view.endEditing(true)
    }
    
    @objc func tapCancel() {
        view.endEditing(true)
    }
    
    @objc func tapNew() {
        
        self.performSegue(withIdentifier: "ItemAddUnitBrand", sender: nil)
        //print("XXX and we are back ...")
    }
    
    // Used to populate units/brands after adding new,
    // when coming back from segue
    override func viewDidAppear(_ animated: Bool) {
        //print("XXX view is locked and loaded ...")
        
        if brandName.isFirstResponder {
            brands = FreezeitManager.shared.getBrands()
        }
        else if unitName.isFirstResponder {
            units = FreezeitManager.shared.getUnits()
        }
    }
    
    // Hide picker/keyboard when user taps outside textfield
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if brandName.isFirstResponder, let destination = segue.destination as? UnitsBrandsList {
            destination.navigationItem.title = "Brands"
            destination.unitsOrBrands = "brands"
        }
        else if unitName.isFirstResponder, let destination = segue.destination as? UnitsBrandsList {
            destination.navigationItem.title = "Units"
            destination.unitsOrBrands = "units"
        }
    }
    
    func date2string(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = Locale.current
        
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    override func viewDidLoad() {
        super .viewDidLoad()
        
        quantity.keyboardType = .numbersAndPunctuation
        itemName.autocorrectionType = .no
        
        
        if !isNew {
            itemName.text = item.name
            brandName.text = findBrandName(id: item.brandId)
            quantity.text = String(item.quantity)
            unitName.text = findUnitName(id: item.unitId)
            dateIn.text = date2string(date: item.dateIn)
            dateDue.text = date2string(date: item.dateDue)
        }
        else {
            // Setting today as default for new items
            dateIn.text = date2string(date: Date())
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(animated)
        
    }
    
    func findBrandName(id: Int32) -> String {
        guard let index = brands.firstIndex(where: {$0.id == id}) else {
            return "No brand "
        }
        return brands[index].name
    }
    
    func findUnitName(id: Int32) -> String {
        guard let index = units.firstIndex(where: {$0.id == id}) else {
            return "No unit"
        }
        return units[index].name
    }
    
}


// Unit-Brand picker extension
extension ItemViewController {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        //print("picker: number of rows")
        if brandName.isFirstResponder {
            return brands.count
        }
        else if unitName.isFirstResponder {
            return units.count
        }
        else {
            return 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        //print("picker: add data to picker")
        if brandName.isFirstResponder {
            return brands[row].name
        }
        else if unitName.isFirstResponder {
            return units[row].name
        }
        else {
            return "Not found"
        }
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //print("picker: selecting row")
        // Save the selected row to use in tapDone
        selectedPickerRow = row
    }
    
    func createPicker() {
        //print("Creating new picker ...")
        let screenWidth = UIScreen.main.bounds.width
        
        elementPicker = UIPickerView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 216))
        elementPicker.sizeToFit()
        elementPicker.delegate = self
        
        if brandName.isFirstResponder {
            brandName.inputView = elementPicker
        }
        else if unitName.isFirstResponder {
            unitName.inputView = elementPicker
        }
        
        let toolBar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: screenWidth, height: 45.0))
        
        
        // "flexible" is used as a filler between tollBar buttons
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        // #selector(..) is used to call the @objc func when that button is tapped
        let cancel = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: #selector(tapCancel))
        let done = UIBarButtonItem(title: "Done", style: .plain, target: target, action: #selector(tapDone))
        let new = UIBarButtonItem(title: "Add New", style: .plain, target: target, action: #selector(tapNew))
        
        toolBar.setItems([cancel, flexible, new, flexible, done], animated: false)
        
        if brandName.isFirstResponder {
            brandName.inputAccessoryView = toolBar
        }
        else if unitName.isFirstResponder {
            unitName.inputAccessoryView = toolBar
        }
    }
    
}

// Date picker extension
extension ItemViewController {
    
    func createDatePicker() {
        let screenWidth = UIScreen.main.bounds.width
        let datePicker = UIDatePicker(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 216))
        datePicker.datePickerMode = .date
        if #available(iOS 14, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.sizeToFit()
        
        let toolBar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: screenWidth, height: 45.0))
        
        // "flexible" is used as a filler between tollBar buttons
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        // #selector(..) is used to call the @objc func when that button is tapped
        let cancel = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: #selector(tapCancel))
        let done = UIBarButtonItem(title: "Done", style: .plain, target: target, action: #selector(tapDone))
        toolBar.setItems([cancel, flexible, done], animated: false)
        
        if dateIn.isFirstResponder {
            dateIn.inputView = datePicker
            dateIn.inputAccessoryView = toolBar
            setDateForDatePicker(datePicker: datePicker, dateString: dateIn.text ?? " ")
        }
        else if dateDue.isFirstResponder {
            dateDue.inputView = datePicker
            dateDue.inputAccessoryView = toolBar
            setDateForDatePicker(datePicker: datePicker, dateString: dateDue.text ?? " ")
        }
    }
    
    // Set default date to show for the date picker
    func setDateForDatePicker(datePicker: UIDatePicker, dateString: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = Locale.current
        
        if let date = dateFormatter.date(from: dateString) {
            datePicker.date = date
        }
    }
    
}
