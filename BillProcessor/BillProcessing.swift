//
//  BillProcessing.swift
//  BillProcessor
//
//  Created by Michael Chung on 7/9/19.
//  Copyright © 2019 Michael Chung. All rights reserved.
//

import Foundation

public protocol Billable: Hashable {
    var hashValue:Int { get }
    var id: String { get }
    var amount: NSDecimalNumber { get }
    var category: String { get }
    var isTaxExempt: Bool { get }
}

public enum DiscountType {
    case Percent
    case DollarAmount
}

public enum TaxType {
    case Standard
    case Category
}

public protocol Discountable {
    var id: String { get }
    var amount: NSDecimalNumber { get }
    var name: String { get }
    var type: DiscountType { get }
    var isEnabled: Bool { get }
}

public protocol Taxable {
    var id: String { get }
    var amount: NSDecimalNumber { get }
    var category: String { get }
    var isEnabled: Bool { get }
    var type: TaxType { get }
}

public protocol BillProcessorDelegate {
    func update(preTaxPreDiscount:NSDecimalNumber,totalTaxesApplied:NSDecimalNumber,totalDiscountApplied:NSDecimalNumber,postTaxPostDiscount:NSDecimalNumber)
}

final public class BillProcessor<B:Billable, T:Taxable , D:Discountable> {
    
    private var bill:[B] = []
    private var appliedTaxableCategories:[T] = []
    private var appliedDiscounts:[D] = []
    
    private var registeredDiscounts:[D] = [] // then enable the ones that are enabled and send them to applied discounts
    
    private var decimalHandler:NSDecimalNumberHandler = NSDecimalNumberHandler(roundingMode: .plain,
                                                                               scale: 2,
                                                                               raiseOnExactness: false,
                                                                               raiseOnOverflow: false,
                                                                               raiseOnUnderflow: false,
                                                                               raiseOnDivideByZero: false)
    
    public var delegate:BillProcessorDelegate?
    
    public var totalPreTaxPreDiscounts:NSDecimalNumber {
        get {
            return self.subtotal(bill: self.bill)
        }
    }
    
    public var totalAllDiscountsApplied:NSDecimalNumber {
        get {
            let subtotal = self.subtotal(bill: self.bill)
            let totalAllDiscountApplied = self.totalDiscountsAppliedCalc(subtotal: subtotal)
            return totalAllDiscountApplied
        }
    }
    
    public var totalAllTaxesApplied:NSDecimalNumber {
        get {
            let subtotalWithDiscountApplied = self.totalPreTaxPreDiscounts.subtracting(totalAllDiscountsApplied, withBehavior: self.decimalHandler)
            let totalTaxesApplied = totalTaxesAppliedCalculation(subtotalWithDiscountApplied: subtotalWithDiscountApplied)
            return totalTaxesApplied
        }
    }
    
    public var totalPostTaxPostDiscounts:NSDecimalNumber {
        get {
            let totalWithDiscounts = totalPreTaxPreDiscounts.subtracting(totalAllDiscountsApplied,withBehavior: self.decimalHandler)
            let totalTaxesApplied = totalAllTaxesApplied
            let postPostTaxPostDiscounts = totalWithDiscounts.adding(totalTaxesApplied)
            return postPostTaxPostDiscounts
        }
    }
    
    public init() {
        
    }
    
    private func update() {
        delegate?.update(preTaxPreDiscount: totalPreTaxPreDiscounts, totalTaxesApplied: totalAllTaxesApplied,totalDiscountApplied: totalAllDiscountsApplied, postTaxPostDiscount: totalPostTaxPostDiscounts)
        
    }
    
    public func setDiscounts(discounts:[D]) {
        
        self.registeredDiscounts.append(contentsOf: discounts)
        
        for discount in discounts {
            if discount.isEnabled == true {
                self.addDiscount(discount: discount)
            }
        }
        self.update()
    }
    
    public func clearAppliedDiscounts() {
        self.appliedDiscounts.removeAll()
        self.update()
    }
    
    public func setTaxes(taxes:[T]) {
        for tax in taxes {
            self.addTaxable(taxable: tax)
        }
        self.update()
    }
    
    public func clearAppliedTaxes() {
        self.appliedTaxableCategories.removeAll()
        self.update()
    }
    
    public func updateBillable(billable:B) {
        let index = self.bill.firstIndex { (bill) -> Bool in
            return billable.id == bill.id
        }
        if let idx = index {
            self.bill[idx] = billable
            self.update()
            return
        }
        fatalError("Couldn't Update Billable Doesn't Exist")
    }
    
    public func addBillableItem(billable:B) {
        // developer assert billable amount must be greater than 0.00
        assert(billable.amount.compare(NSDecimalNumber(value: 0.00)) == .orderedDescending, "Billable Item must be greater than 0.0")
        self.bill.append(billable)
        self.update()
    }
    
    public func removeBillableItem(billable:B) {
        self.bill.removeAll { (billableItem) -> Bool in
            return billable == billableItem
        }
        self.update()
    }
    
    internal func addDiscount(discount:D) {
        self.appliedDiscounts.append(discount)
        self.update()
    }
    
    public func findRegisteredDiscountFor(id:String) -> D {
        let index = self.registeredDiscounts.firstIndex { (discountItem) -> Bool in
            return id == discountItem.id
        }
        
        if let idx = index {
            let item = self.registeredDiscounts[idx]
            return item
        }
        
        fatalError("Couldn't Update Discount Doesn't Exist")
    }
    
    public func updateDiscount(discount:D) {
        
        if discount.isEnabled == false {
            
            let removedIndex = self.appliedDiscounts.firstIndex { (discountItem) -> Bool in
                return discount.id == discountItem.id
            }
            
            if let idx = removedIndex {
                self.appliedDiscounts.remove(at: idx)
                self.update()
                return
            }
           
        } else { // discount.isEnabled == true {
            
            self.addDiscount(discount: discount)
            return
        }
        
         fatalError("Couldn't Update Discount Doesn't Exist")
    }
    
    internal func removeDiscount(discount: D) {
        self.appliedDiscounts.removeAll { (current_discount) -> Bool in
            return current_discount.id == current_discount.id
        }
    }
    
    internal func addTaxable(taxable: T) {
        self.appliedTaxableCategories.append(taxable)
    }
    
    public func updateTaxable(taxable:T) {
        let index = self.appliedTaxableCategories.firstIndex { (taxItem) -> Bool in
            return taxable.id == taxItem.id
        }
        if let idx = index {
            self.appliedTaxableCategories[idx] = taxable
            self.update()
            return
        }
        fatalError("Couldn't Update Taxable Doesn't Exist")
    }
    
    public func findTaxFor(id:String) -> T {
        let index = self.appliedTaxableCategories.firstIndex { (discountItem) -> Bool in
            return id == discountItem.id
        }
        
        if let idx = index {
            let item = self.appliedTaxableCategories[idx]
            return item
        }
        
        fatalError("Couldn't Find Taxeable Doesn't Exist")
    }
    
    // test only
    internal func removeTaxable(taxable: T) {
        self.appliedTaxableCategories.removeAll { (currentTaxable) -> Bool in
            return currentTaxable.id == taxable.id
        }
    }
    
    private func subtotal(bill:[B]) -> NSDecimalNumber {
        let subtotal = bill.reduce(NSDecimalNumber(value: 0.00))
        { (result, bill) -> NSDecimalNumber in
            return result.adding(bill.amount,withBehavior: self.decimalHandler)
        }
        
        return subtotal
    }
    
    private func totalDiscountsAppliedCalc(subtotal:NSDecimalNumber) -> NSDecimalNumber {
        
        var discountedSubtotal = subtotal
        let originalSubtotal = subtotal
        
        for discount in self.appliedDiscounts {
            // If subtotal is less than 0
            if discount.type == .DollarAmount {
                if discount.isEnabled == true {
                    discountedSubtotal = discountedSubtotal.subtracting(discount.amount,
                                                                    withBehavior: self.decimalHandler)
                }
            } else if discount.type == .Percent {
                if discount.isEnabled == true {
                    discountedSubtotal = discountedSubtotal.subtracting(discountedSubtotal.multiplying(by: discount.amount,
                                                                                                   withBehavior: self.decimalHandler),
                                                                    withBehavior: self.decimalHandler)
                }
            }
            
            if discountedSubtotal.compare(NSDecimalNumber(value: 0.00)) == .orderedAscending {
                break
            }
        }
        
        if discountedSubtotal.compare(NSDecimalNumber(value: 0.00)) == .orderedAscending {
            return originalSubtotal
        } else {
            let totalDiscountApplied = originalSubtotal.subtracting(discountedSubtotal, withBehavior: self.decimalHandler)
            return totalDiscountApplied
        }
    }
    
    private func totalTaxesAppliedCalculation(subtotalWithDiscountApplied: NSDecimalNumber) -> NSDecimalNumber {
        
        if subtotalWithDiscountApplied.compare(NSDecimalNumber(0.00)) == .orderedSame {
            return NSDecimalNumber(0.00)
        } else if subtotalWithDiscountApplied.compare(NSDecimalNumber(0.00)) == .orderedAscending  {
            return NSDecimalNumber(0.00)
        }
        
        // Do taxes
        let governmentTaxes = self.appliedTaxableCategories.filter { (taxable) -> Bool in
            return taxable.category == ""
        }
        
        var totalTaxesApplied = NSDecimalNumber(0.00)
        
        // tax the subtotal
        for governmentTax in governmentTaxes {
            if governmentTax.isEnabled == true {
                totalTaxesApplied = totalTaxesApplied.adding(governmentTax.amount.multiplying(by: subtotalWithDiscountApplied, withBehavior: self.decimalHandler), withBehavior: self.decimalHandler)
            }
        }
        
        var exemptTaxesTotal = NSDecimalNumber(0.00)
        
        for billable in self.bill {
            if billable.isTaxExempt {
                for taxable in governmentTaxes {
                    if taxable.isEnabled == true {
                        exemptTaxesTotal = exemptTaxesTotal.adding(taxable.amount.multiplying(by: billable.amount, withBehavior: self.decimalHandler), withBehavior: self.decimalHandler)
                    }
                }
            }
        }
        
        // remove the exceptions from that subtotal tax and that becomes the new tax
        let taxableCategories = self.appliedTaxableCategories.filter { (taxable) -> Bool in
            return taxable.category != ""
        }
        
        // Do category taxes
        var taxReference:[String: Taxable] = [String: Taxable]()
        
        // Build lookup dictionary
        for taxable in taxableCategories {
            if taxable.isEnabled == true {
                taxReference[taxable.category] = taxable
            }
        }
        
        var categoryTax = NSDecimalNumber(value: 0.00)
        
        // Look through the bill for the specific category, then subtract it out and have another tax applied to it
        for billable in self.bill {
            
            // check if it's in there first
            if let taxable = taxReference[billable.category] {
                if billable.isTaxExempt == false {
                    categoryTax = categoryTax.adding(taxable.amount.multiplying(by: billable.amount,
                                                                                withBehavior: self.decimalHandler),
                                                     withBehavior: self.decimalHandler)
                }
            }
        }
        
        var appliedTaxesExemptTaxAdjustment:NSDecimalNumber
        
        // remove taxes from the subtotal if they are tax exempt
        if exemptTaxesTotal.compare(totalTaxesApplied) == .orderedDescending  {
            appliedTaxesExemptTaxAdjustment = NSDecimalNumber(value: 0.00)
            let finalTotalTaxes = totalTaxesApplied.adding(categoryTax,withBehavior: self.decimalHandler)
            return finalTotalTaxes
            
        } else {
            appliedTaxesExemptTaxAdjustment = totalTaxesApplied.subtracting(exemptTaxesTotal, withBehavior: self.decimalHandler)
            let finalTotalTaxes = categoryTax.adding(appliedTaxesExemptTaxAdjustment,withBehavior: self.decimalHandler)
            return finalTotalTaxes
        }
    }
    
    
}



