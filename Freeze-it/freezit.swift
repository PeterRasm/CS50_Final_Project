//
//  freezer.swift
//  Freezeit
//
//  Created by Peter Rasmussen on 1/20/21.
//  Copyright © 2021 Peter Rasmussen. All rights reserved.
//

import Foundation
import SQLite3


struct Freezer {
    var id: Int32
    var key: String
    var name: String
    var colorCode: Int32
}

struct Item {
    var id: Int32
    var name: String
    var brandId: Int32
    var quantity: Float
    var unitId: Int32
    var freezerId: Int32
    var dateIn: Date
    var dateDue: Date
}

struct Brand {
    var id: Int32
    var name: String
}

struct Unit {
    var id: Int32
    var name: String
    var sortKey: String
}

class FreezeitManager {
    
    func stringToDate(string: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return dateFormatter.date(from: string)!
    }
    
    func dateToString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    var database: OpaquePointer?
    
    static let shared = FreezeitManager()
    
    private init() {
    }
    
    func connect() {
        if database != nil {
            //print("XXX database is_not nil")
            return
        }
        else {
            //print("XXX creating new database")
        }
        
        let databaseURL = try! FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ).appendingPathComponent("freezeit.sqlite")
        
        if sqlite3_open(databaseURL.path, &database) != SQLITE_OK {
            print("Error opening database")
            return
        }
        
        if sqlite3_exec(
            database,
            """
            CREATE TABLE IF NOT EXISTS freezer (
                id NUMBER,
                key TEXT,
                name TEXT,
                color NUMBER
            )
            """,
            nil,
            nil,
            nil
        ) != SQLITE_OK {
            print("Error creating table: \(String(cString: sqlite3_errmsg(database)!))")
        }
        
        if sqlite3_exec(
            database,
            """
            CREATE TABLE IF NOT EXISTS brand (
                id NUMBER,
                name TEXT
            )
            """,
            nil,
            nil,
            nil
        ) != SQLITE_OK {
            print("Error creating table: \(String(cString: sqlite3_errmsg(database)!))")
        }
        
        if sqlite3_exec(
            database,
            """
            CREATE TABLE IF NOT EXISTS unit (
                id NUMBER,
                name TEXT,
                sortkey TEXT
            )
            """,
            nil,
            nil,
            nil
        ) != SQLITE_OK {
            print("Error creating table: \(String(cString: sqlite3_errmsg(database)!))")
        }
        
        if sqlite3_exec(
            database,
            """
            CREATE TABLE IF NOT EXISTS item (
                id NUMBER,
                name TEXT,
                brandid NUMBER,
                quantity NUMBER,
                unitid NUMBER,
                freezerid NUMBER,
                datein TEXT,
                datedue TEXT
            )
            """,
            nil,
            nil,
            nil
        ) != SQLITE_OK {
            print("Error creating table: \(String(cString: sqlite3_errmsg(database)!))")
        }
        
    }
}

// XYZ_Freezer
extension FreezeitManager {
    
    func createFreezer(freezer: Freezer) {
        connect()
        
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "INSERT INTO freezer  VALUES (?, ?, ?, ?)",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, freezer.id)
            sqlite3_bind_text(statement, 2, NSString(string: freezer.key).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, NSString(string: freezer.name).utf8String, -1, nil)
            sqlite3_bind_int(statement, 4, freezer.colorCode)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error adding freezer")
            }
            //print("XXX Added: ", freezer)
        }
        else {
            print("Error creating freezer insert statement")
        }
        
        sqlite3_finalize(statement)
        return //Int(sqlite3_last_insert_rowid(database))
    }
    
    func getFreezers() -> [Freezer] {
        connect()
        
        var result: [Freezer] = []
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(database, "SELECT id, key, name, color FROM freezer ORDER BY key", -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                result.append(Freezer(
                    id: sqlite3_column_int(statement, 0),
                    key: String(cString: sqlite3_column_text(statement, 1)),
                    name: String(cString: sqlite3_column_text(statement, 2)),
                    colorCode: sqlite3_column_int(statement, 3)
                ))
            }
        }
        
        sqlite3_finalize(statement)
        return result
    }
    
    func updateFreezer(freezer: Freezer) {
        connect()
        
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "UPDATE freezer SET key = ?, name = ?, color = ? WHERE id = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, NSString(string: freezer.key).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, NSString(string: freezer.name).utf8String, -1, nil)
            sqlite3_bind_int(statement, 3, freezer.colorCode)
            sqlite3_bind_int(statement, 4, freezer.id)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error updating freezer")
            }
        }
        else {
            print("Error creating freezer update statement")
        }
        
        sqlite3_finalize(statement)
    }
    
    func countFreezerItems(id: Int32) -> Int {
        var statement: OpaquePointer? = nil
        var numberOfItems: Int32 = 0
        
        // Get number of items with this freezer id
        if sqlite3_prepare_v2(
            database,
            "SELECT COUNT(*) FROM item WHERE freezerid = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, id)
            while sqlite3_step(statement) == SQLITE_ROW {
                numberOfItems = sqlite3_column_int(statement, 0)
            }
        }
        else {
            print("Error creating count statement")
        }
        
        sqlite3_finalize(statement)
        
        return Int(numberOfItems)
    }
    
    func deleteFreezer(id: Int32, deleteAll: Bool) -> Bool {
        connect()
        
        // If deleteAll then delete items with freezer id and freezer
        // if not deleteAll, check if items exist with this freezer id
        // If items exist return false to tricker warning to user
        
        if !deleteAll && countFreezerItems(id: id) > 0 {
            return false
        }
        
        var statement: OpaquePointer? = nil
        
        if deleteAll && countFreezerItems(id: id) > 0 {
            deleteFreezerItems(id: id)
        }
        
        if sqlite3_prepare_v2(
            database,
            "DELETE FROM freezer WHERE id = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, id)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error deleting freezer")
            }
        }
        else {
            print("Error creating freezer delete statement")
        }
        
        sqlite3_finalize(statement)
        
        return true
    }
}
    
// XYZ_Brand
extension FreezeitManager {
    func createBrand(brand: Brand) {
        connect()
        
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "INSERT INTO brand  VALUES (?, ?)",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, brand.id)
            sqlite3_bind_text(statement, 2, NSString(string: brand.name).utf8String, -1, nil)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error adding brand")
            }
            //print("XXX Added: ", brand)
        }
        else {
            print("Error creating brand insert statement")
        }
        
        sqlite3_finalize(statement)
        return
    }
    
    func getBrands() -> [Brand] {
        connect()
        
        var result: [Brand] = []
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(database, "SELECT id, name FROM brand ORDER BY name", -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                result.append(Brand(
                    id: sqlite3_column_int(statement, 0),
                    name: String(cString: sqlite3_column_text(statement, 1))
                ))
            }
        }
        
        sqlite3_finalize(statement)
        return result
    }
    
    func updateBrand(brand: Brand) {
        connect()
        
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "UPDATE brand SET name = ? WHERE id = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, NSString(string: brand.name).utf8String, -1, nil)
            sqlite3_bind_int(statement, 2, brand.id)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error updating brand")
            }
        }
        else {
            print("Error creating brand update statement")
        }
        
        sqlite3_finalize(statement)
    }
    
    func countBrandItems(id: Int32) -> Int {
        var statement: OpaquePointer? = nil
        var numberOfItems: Int32 = 0
        
        // Get number of items with this freezer id
        if sqlite3_prepare_v2(
            database,
            "SELECT COUNT(*) FROM item WHERE brandid = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, id)
            while sqlite3_step(statement) == SQLITE_ROW {
                numberOfItems = sqlite3_column_int(statement, 0)
            }
        }
        else {
            print("Error creating count statement")
        }
        
        sqlite3_finalize(statement)
        
        return Int(numberOfItems)
    }
    
    func deleteBrand(id: Int32) -> Bool {
        connect()
        
        if countBrandItems(id: id) > 0 {
            return false
        }
        
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "DELETE FROM brand WHERE id = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, id)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error deleting brand")
            }
        }
        else {
            print("Error creating brand delete statement")
        }
        
        sqlite3_finalize(statement)
        
        return true
    }
}

// XYZ_Unit
// Unit
extension FreezeitManager {
    func createUnit(unit: Unit) {
        connect()
        
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "INSERT INTO unit  VALUES (?, ?, ?)",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, unit.id)
            sqlite3_bind_text(statement, 2, NSString(string: unit.name).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, NSString(string: unit.sortKey).utf8String, -1, nil)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error adding unit")
            }
        }
        else {
            print("Error creating unit insert statement")
        }
        
        sqlite3_finalize(statement)
        return
    }
    
    func getUnits() -> [Unit] {
        connect()
        
        var result: [Unit] = []
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(database, "SELECT id, name, sortkey FROM unit ORDER BY sortkey", -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                result.append(Unit(
                    id: sqlite3_column_int(statement, 0),
                    name: String(cString: sqlite3_column_text(statement, 1)),
                    sortKey: String(cString: sqlite3_column_text(statement, 2))
                ))
            }
        }
        
        sqlite3_finalize(statement)
        return result
    }
    
    func updateUnit(unit: Unit) {
        connect()
        
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "UPDATE unit SET name = ?, sortkey = ? WHERE id = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, NSString(string: unit.name).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, NSString(string: unit.sortKey).utf8String, -1, nil)
            sqlite3_bind_int(statement, 3, unit.id)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error updating unit")
            }
        }
        else {
            print("Error creating unit update statement")
        }
        
        sqlite3_finalize(statement)
    }
    
    func countUnitItems(id: Int32) -> Int {
        var statement: OpaquePointer? = nil
        var numberOfItems: Int32 = 0
        
        // Get number of items with this freezer id
        if sqlite3_prepare_v2(
            database,
            "SELECT COUNT(*) FROM item WHERE unitid = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, id)
            while sqlite3_step(statement) == SQLITE_ROW {
                numberOfItems = sqlite3_column_int(statement, 0)
            }
        }
        else {
            print("Error creating count statement")
        }
        
        sqlite3_finalize(statement)
        
        return Int(numberOfItems)
    }
    
    func deleteUnit(id: Int32) -> Bool {
        connect()
        
        if countUnitItems(id: id) > 0 {
            return false
        }
        
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "DELETE FROM unit WHERE id = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, id)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error deleting unit")
            }
        }
        else {
            print("Error creating unit delete statement")
        }
        
        sqlite3_finalize(statement)
        
        return true
    }
}

// XYZ_Items
extension FreezeitManager {
    
    func createItem(item: Item) {
        connect()
        //print("XXX create item: ", item)
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            // Using IFNULL to check if SELECT MAX() returns no value
            "INSERT INTO item  VALUES (IFNULL((SELECT MAX(id) + 1 FROM item), 0), ?, ?, ?, ?, ?, ?, ?)",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            //sqlite3_bind_int(statement, 1, itemId)
            sqlite3_bind_text(statement, 1, NSString(string: item.name).utf8String, -1, nil)
            sqlite3_bind_int(statement, 2, item.brandId)
            sqlite3_bind_double(statement, 3, Double(item.quantity))
            sqlite3_bind_int(statement, 4, item.unitId)
            sqlite3_bind_int(statement, 5, item.freezerId)
            sqlite3_bind_text(statement, 6, NSString(string: dateToString(date: item.dateIn)).utf8String, -1, nil)
            sqlite3_bind_text(statement, 7, NSString(string: dateToString(date: item.dateDue)).utf8String, -1, nil)
            //print("XXX dateIn: ", item.dateIn)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error adding item")
            }
        }
        else {
            print("Error creating item insert statement")
        }
        
        sqlite3_finalize(statement)
        return
    }
    
    
    func getItems(id: Int32) -> [Item] {
        connect()
        var result: [Item] = []
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(database, "SELECT id, name, brandid, quantity, unitid, freezerid, datein, datedue FROM item WHERE freezerid = ? ORDER BY name", -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, id)
            while sqlite3_step(statement) == SQLITE_ROW {
                result.append(Item(
                    id: sqlite3_column_int(statement, 0),
                    name: String(cString: sqlite3_column_text(statement, 1)),
                    brandId: sqlite3_column_int(statement, 2),
                    quantity: Float(sqlite3_column_double(statement, 3)),
                    unitId: sqlite3_column_int(statement, 4),
                    freezerId: sqlite3_column_int(statement, 5),
                    dateIn: stringToDate(string: String(cString: sqlite3_column_text(statement, 6))),
                    dateDue: stringToDate(string: String(cString: sqlite3_column_text(statement, 7)))
                ))
            }
        }
        
        sqlite3_finalize(statement)
        return result
    }
    
    
    func updateItem(item: Item) {
        connect()
        //print("XXX update item: ", item)
        
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "UPDATE item SET name = ?, brandid = ?, quantity = ?, unitid = ?, freezerid = ?, datein = ?, datedue = ? WHERE id = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, NSString(string: item.name).utf8String, -1, nil)
            sqlite3_bind_int(statement, 2, item.brandId)
            sqlite3_bind_double(statement, 3, Double(item.quantity))
            sqlite3_bind_int(statement, 4, item.unitId)
            sqlite3_bind_int(statement, 5, item.freezerId)
            sqlite3_bind_text(statement, 6, NSString (string: dateToString(date: item.dateIn)).utf8String, -1, nil)
            sqlite3_bind_text(statement, 7, NSString (string: dateToString(date: item.dateDue)).utf8String, -1, nil)
            sqlite3_bind_int(statement, 8, item.id)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error updating item")
            }
        }
        else {
            print("Error creating item update statement")
        }
        sqlite3_finalize(statement)
    }
    
    
    func deleteItem(id: Int32) {
        connect()
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "DELETE FROM item WHERE id = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, id)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error deleting item")
            }
        }
        else {
            print("Error creating item delete statement")
        }
        sqlite3_finalize(statement)
    }
    
    func deleteFreezerItems(id: Int32) {
        connect()
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "DELETE FROM item WHERE freezerid = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, id)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error deleting item")
            }
        }
        else {
            print("Error creating item delete statement")
        }
        sqlite3_finalize(statement)
    }
}


