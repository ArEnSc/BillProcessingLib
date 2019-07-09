//
//  BillProcessorTests.swift
//  BillProcessorTests
//
//  Created by Michael Chung on 7/9/19.
//  Copyright © 2019 Michael Chung. All rights reserved.
//

import XCTest
@testable import BillProcessor

class BillProcessorTests: XCTestCase {

    struct Tax: Taxable {
        
        var type: TaxType {
            return self._type
        }
        
        var isEnabled: Bool = true
        
        var category: String {
            return self.value.category
        }
        
        var id: String {
            return self.value.id
        }
        
        var amount: NSDecimalNumber {
            return self.value.amount
        }
        
        var name: String  {
            return self.value.name
        }
        
        let value:TaxItem
        let _type:TaxType
        
        init(value:TaxItem, type:TaxType) {
            self.value = value
            self._type = type
        }
    }
    
    struct Discount:Discountable {
        
        var isEnabled: Bool = true
        
        
        var id: String {
            return self.value.id
        }
        
        var amount: NSDecimalNumber {
            return self.value.amount
        }
        
        var name: String {
            return self.value.name
        }
        
        var type: DiscountType {
            return self._type
        }
        
        var value:DiscountItem
        let _type:DiscountType
        
        init(value:DiscountItem, discountType:DiscountType) {
            self.value = value
            self._type = discountType
        }
        
    }
    
    struct BillableItem:Billable {
        
        static func == (lhs: BillProcessorTests.BillableItem,
                        rhs: BillProcessorTests.BillableItem) -> Bool {
            
            return lhs.amount == rhs.amount &&
                lhs.id == rhs.id  &&
                lhs.category == rhs.category &&
                lhs.isTaxExempt == rhs.isTaxExempt
        }
        
        var hashValue: Int {
            return self.value.amount.hashValue ^
                self.value.id.hashValue ^
                self.value.category.hashValue ^
                self.value.isTaxExempt.hashValue
        }
        
        var id: String {
            return self.value.id
        }
        
        var amount: NSDecimalNumber {
            return self.value.amount
        }
        
        var category: String {
            return self.value.category
        }
        
        var isTaxExempt: Bool {
            return self.value.isTaxExempt
        }
        
        let value:FoodItem
        
        init(value:FoodItem) {
            self.value = value
        }
    }
    
    typealias FoodItem = (id:String, amount:NSDecimalNumber, category:String, isTaxExempt:Bool)
    typealias TaxItem = (id:String,name:String, amount:NSDecimalNumber, category:String)
    typealias DiscountItem = (id:String,name:String, amount:NSDecimalNumber, type:DiscountType)
    typealias CategoryTaxItem = (id:String,name:String,amount:NSDecimalNumber, category:String)
    
    let nestea = (id:UUID().uuidString, amount:NSDecimalNumber(value: 1.50), category:"Tea", isTaxExempt:true)
    let coke = (id:UUID().uuidString, amount:NSDecimalNumber(value: 1.50), category:"Pop", isTaxExempt:false)
    let greyGoose = (id:UUID().uuidString, amount:NSDecimalNumber(value: 50.45), category:"Alcohol", isTaxExempt:false)
    let pizza = (id:UUID().uuidString, amount:NSDecimalNumber(value: 5.00), category:"Pizza", isTaxExempt:false)
    let hst = (id:UUID().uuidString, name: "Harmonized Tax 13%",amount:NSDecimalNumber(value:0.13),category: "")
    let cokeTax = (id:UUID().uuidString, name: "Coke Tax 20%",amount:NSDecimalNumber(value:0.20),category: "Pop")
    
    let cokeLarge = (id:UUID().uuidString, amount:NSDecimalNumber(value: 5.00), category:"Pop", isTaxExempt:false)
    
    let twoDollarDiscount = (id:UUID().uuidString,name:"Two Dollar Discount", amount:NSDecimalNumber(value:2.00),type:DiscountType.DollarAmount)
    let tenPercentDiscount = (id:UUID().uuidString,name:"10 Percent Discount", amount:NSDecimalNumber(value:0.10),type:DiscountType.Percent)
    
    let oneDollarAndFourtyNineCentDiscount =  (id:UUID().uuidString,name:"1.49 Discount", amount:NSDecimalNumber(value:1.49), type:DiscountType.DollarAmount)
    
    let alcoholTax = (id:UUID().uuidString, name:"Alcohol Tax 10%", amount:NSDecimalNumber(value:0.10), category:"Alcohol")
    
    var billProcessor = BillProcessor<BillableItem,Tax,Discount>()
    
    func testAddingBillables() {
        
        billProcessor.addBillableItem(billable: BillableItem(value: nestea))
        billProcessor.addBillableItem(billable: BillableItem(value: coke))
        billProcessor.addBillableItem(billable: BillableItem(value: pizza))
        
        let result = NSDecimalNumber(value: 8.00) == billProcessor.totalPreTaxPreDiscounts
        XCTAssert(result, "Test Adding Billables with TotalPretaxPrePreDiscount")
    }
    
    func testRemovingBillablesNonExsistent() {
        
        let nesteaB = BillableItem(value: nestea)
        let cokeB = BillableItem(value: coke)
        
        billProcessor.addBillableItem(billable: cokeB)
        billProcessor.removeBillableItem(billable: nesteaB)
        
        let result = NSDecimalNumber(value: 1.50) == billProcessor.totalPreTaxPreDiscounts
        XCTAssert(result, "Test Adding Billables TotalPretaxPrePreDiscount")
    }
    
    func testRemovingBillables() {
        
        let nesteaB = BillableItem(value: nestea)
        let cokeB = BillableItem(value: coke)
        let pizzaB =  BillableItem(value: pizza)
        
        billProcessor.addBillableItem(billable: nesteaB)
        billProcessor.addBillableItem(billable: cokeB)
        billProcessor.addBillableItem(billable: pizzaB)
        
        billProcessor.removeBillableItem(billable: nesteaB)
        billProcessor.removeBillableItem(billable: cokeB)
        
        let result = NSDecimalNumber(value: 5.00) == billProcessor.totalPreTaxPreDiscounts
        
        XCTAssert(result, "Test Adding Billables and Removing Them TotalPretaxPrePreDiscount")
    }
    
    func testDiscountCalculationAndRemovals() {
        let nesteaB = BillableItem(value: nestea)
        let cokeB = BillableItem(value: coke)
        let pizzaB =  BillableItem(value: pizza)
        let greyGooseB = BillableItem(value: greyGoose)
        
        billProcessor.addBillableItem(billable: nesteaB)
        billProcessor.addBillableItem(billable: cokeB)
        billProcessor.addBillableItem(billable: pizzaB)
        billProcessor.addBillableItem(billable: greyGooseB)
        
        let discount1 = Discount(value: twoDollarDiscount, discountType: .DollarAmount)
        let discount2 = Discount(value: tenPercentDiscount, discountType: .Percent)
        
        billProcessor.addDiscount(discount: discount1)
        billProcessor.addDiscount(discount: discount2)
        
        let result = billProcessor.totalPreTaxPreDiscounts.subtracting(billProcessor.totalAllDiscountsApplied)
        
        XCTAssert(result == NSDecimalNumber(value:50.80), "Test Two Dollar First Ten Percent Second")
        
        billProcessor.removeDiscount(discount: discount1)
        billProcessor.removeDiscount(discount: discount2)
        
        billProcessor.addDiscount(discount: discount2)
        billProcessor.addDiscount(discount: discount1)
        
        let result2 = billProcessor.totalPreTaxPreDiscounts.subtracting(billProcessor.totalAllDiscountsApplied)
        
        XCTAssert(result2 == NSDecimalNumber(value:50.60), "Test Ten Percent Section and Two Dollar Second")
    }
    
    func testTotalTaxesAppliedCalculation() {
        
        let nesteaB = BillableItem(value: nestea)
        let cokeB = BillableItem(value: coke)
        let pizzaB =  BillableItem(value: pizza)
        let greyGooseB = BillableItem(value: greyGoose)
        
        billProcessor.addBillableItem(billable: cokeB)
        billProcessor.addBillableItem(billable: pizzaB)
        billProcessor.addBillableItem(billable: greyGooseB)
        billProcessor.addBillableItem(billable: nesteaB)
        
        let discount1 = Discount(value: twoDollarDiscount, discountType: .DollarAmount)
        let discount2 = Discount(value: tenPercentDiscount, discountType: .Percent)
        
        let tax1 = Tax(value: hst, type: .Standard)
        let tax2 = Tax(value: alcoholTax, type: .Category)
        
        billProcessor.addDiscount(discount: discount1)
        billProcessor.addDiscount(discount: discount2)
        
        billProcessor.addTaxable(taxable: tax1)
        billProcessor.addTaxable(taxable: tax2)
        
        let subtotalWithDiscounts = billProcessor.totalPreTaxPreDiscounts.subtracting(billProcessor.totalAllDiscountsApplied)
        let totalTaxesApplied = billProcessor.totalAllTaxesApplied
        
        let result = subtotalWithDiscounts.adding(totalTaxesApplied)
        
        XCTAssert(result == NSDecimalNumber(value: 62.25), "Total Taxes Plus Discounts where 2 dollar discount is first")
        
        billProcessor.removeDiscount(discount: discount1)
        billProcessor.removeDiscount(discount: discount2)
        
        billProcessor.addDiscount(discount: discount2)
        billProcessor.addDiscount(discount: discount1)
        
        let subtotalWithDiscounts2 = billProcessor.totalPreTaxPreDiscounts.subtracting(billProcessor.totalAllDiscountsApplied)
        
        let totalTaxesApplied2 = billProcessor.totalAllTaxesApplied
        
        let result2 = subtotalWithDiscounts2.adding(totalTaxesApplied2)
        
        XCTAssert(result2 == NSDecimalNumber(value: 62.03), "Total Taxes Plus Discounts where 10 percent discount is first")
    }
    
    func testTotalPostTaxPostDiscount() {
        let nesteaB = BillableItem(value: nestea)
        let cokeB = BillableItem(value: coke)
        let pizzaB =  BillableItem(value: pizza)
        let greyGooseB = BillableItem(value: greyGoose)
        
        billProcessor.addBillableItem(billable: cokeB)
        billProcessor.addBillableItem(billable: pizzaB)
        billProcessor.addBillableItem(billable: greyGooseB)
        billProcessor.addBillableItem(billable: nesteaB)
        
        let discount1 = Discount(value: twoDollarDiscount, discountType: .DollarAmount)
        let discount2 = Discount(value: tenPercentDiscount, discountType: .Percent)
        
        let tax1 = Tax(value: hst,type:.Standard)
        let tax2 = Tax(value: alcoholTax,type:.Category)
        
        billProcessor.addDiscount(discount: discount1)
        billProcessor.addDiscount(discount: discount2)
        
        billProcessor.addTaxable(taxable: tax1)
        billProcessor.addTaxable(taxable: tax2)
        
        let result = billProcessor.totalPostTaxPostDiscounts
        
        XCTAssert(result == NSDecimalNumber(value: 62.25), "Total Taxes Plus Discounts where 2 dollar discount is first")
        
        
        billProcessor.removeDiscount(discount: discount1)
        billProcessor.removeDiscount(discount: discount2)
        
        billProcessor.addDiscount(discount: discount2)
        billProcessor.addDiscount(discount: discount1)
        
        
        let result2 = billProcessor.totalPostTaxPostDiscounts
        
        XCTAssert(result2 == NSDecimalNumber(value: 62.03), "Total Taxes Plus Discounts where 10 percent discount is first")
    }
    
    func testDiscountsAppliedValueAndSwap() {
        let nesteaB = BillableItem(value: nestea)
        let cokeB = BillableItem(value: coke)
        let pizzaB =  BillableItem(value: pizza)
        let greyGooseB = BillableItem(value: greyGoose)
        
        billProcessor.addBillableItem(billable: cokeB)
        billProcessor.addBillableItem(billable: pizzaB)
        billProcessor.addBillableItem(billable: greyGooseB)
        billProcessor.addBillableItem(billable: nesteaB)
        
        let discount1 = Discount(value: twoDollarDiscount, discountType: .DollarAmount)
        let discount2 = Discount(value: tenPercentDiscount, discountType: .Percent)
        
        billProcessor.addDiscount(discount: discount1)
        billProcessor.addDiscount(discount: discount2)
        
        let totalDiscount = billProcessor.totalAllDiscountsApplied
        
        XCTAssertTrue(totalDiscount == NSDecimalNumber(value: 7.65), "Test Regular Order")
        
        billProcessor.removeDiscount(discount: discount1)
        billProcessor.removeDiscount(discount: discount2)
        
        billProcessor.addDiscount(discount: discount2)
        billProcessor.addDiscount(discount: discount1)
        
        let totalDiscount2 = billProcessor.totalAllDiscountsApplied
        
        XCTAssertTrue(totalDiscount2 == NSDecimalNumber(value: 7.85), "Test Swapped Order")
        
    }
    
    func testGivenDiscount() {
        
        let cokeB = BillableItem(value: coke)
        
        billProcessor.addBillableItem(billable: cokeB)
        
        
        let discount1 = Discount(value: twoDollarDiscount, discountType: .DollarAmount)
        let discount2 = Discount(value: tenPercentDiscount, discountType: .Percent)
        
        billProcessor.addDiscount(discount: discount1)
        billProcessor.addDiscount(discount: discount2)
        
        let totalDiscount = billProcessor.totalAllDiscountsApplied
        
        XCTAssertTrue(totalDiscount == NSDecimalNumber(value: 1.50), "If a discount is given and brings you into the negative")
        
        billProcessor.removeDiscount(discount: discount1)
        billProcessor.removeDiscount(discount: discount2)
        
        
        billProcessor.addDiscount(discount: discount2)
        billProcessor.addDiscount(discount: discount1)
        
        let totalDiscount2 = billProcessor.totalAllDiscountsApplied
        XCTAssertTrue(totalDiscount2 == NSDecimalNumber(value: 1.50), "If a discount is given and brings you into the negative")
    }
    
    
    func testCategoryTaxWithFreeDiscount() {
        
        let cokeB = BillableItem(value: coke)
        
        billProcessor.addBillableItem(billable: cokeB)
        
        let discount1 = Discount(value: twoDollarDiscount, discountType: .DollarAmount)
        let discount2 = Discount(value: tenPercentDiscount, discountType: .Percent)
        
        billProcessor.addDiscount(discount: discount1)
        billProcessor.addDiscount(discount: discount2)
        
        let subtotal = billProcessor.totalPreTaxPreDiscounts
        let discount = billProcessor.totalAllDiscountsApplied
        let total = billProcessor.totalPostTaxPostDiscounts
        let result = billProcessor.totalAllTaxesApplied
        
        print(result)
        XCTAssert(discount == NSDecimalNumber(value: 1.50),"Discount should remove the subtotal ")
        XCTAssert(result == NSDecimalNumber(value: 0.00), "Should not be taxed at all")
        XCTAssert(total == NSDecimalNumber(value: 0.00), "Should be zero")
        XCTAssert(subtotal == NSDecimalNumber(value: 1.50),"Subtotal should be 1.50 Coke")
        
        
        billProcessor.removeDiscount(discount: discount1)
        billProcessor.removeDiscount(discount: discount2)
        
        billProcessor.addDiscount(discount: discount2)
        billProcessor.addDiscount(discount: discount1)
        
        
        let subtotal2 = billProcessor.totalPreTaxPreDiscounts
        let discountX2 = billProcessor.totalAllDiscountsApplied
        let total2 = billProcessor.totalPostTaxPostDiscounts
        let result2 = billProcessor.totalAllTaxesApplied
        
        print(result2)
        XCTAssert(discountX2 == NSDecimalNumber(value: 1.50),"Discount should remove the subtotal swapping discounts ")
        XCTAssert(result2 == NSDecimalNumber(value: 0.00), "Should not be taxed at all swapping discounts")
        XCTAssert(total2 == NSDecimalNumber(value: 0.00), "Should be zero swapping discounts")
        XCTAssert(subtotal2 == NSDecimalNumber(value: 1.50),"Subtotal should be 1.50 Coke swapping discounts")
        
    }
    
    func testCloseToEdgeDiscount() {
        
        let cokeB = BillableItem(value: coke)
        billProcessor.addBillableItem(billable: cokeB)
        
        let discount1 = Discount(value: oneDollarAndFourtyNineCentDiscount,discountType: .DollarAmount)
        
        billProcessor.addDiscount(discount: discount1)
        let tax1 = Tax(value: hst, type: .Standard)
        let tax2 = Tax(value: cokeTax, type: .Category)
        
        billProcessor.addTaxable(taxable: tax1)
        billProcessor.addTaxable(taxable: tax2)
        
        let subtotal = billProcessor.totalPreTaxPreDiscounts
        let discount = billProcessor.totalAllDiscountsApplied
        let taxes = billProcessor.totalAllTaxesApplied
        let total = billProcessor.totalPostTaxPostDiscounts
        
        XCTAssert(subtotal == NSDecimalNumber(value: 1.50))
        XCTAssert(discount == NSDecimalNumber(value: 1.49))
        XCTAssert(taxes == NSDecimalNumber(value: 0.30))
        XCTAssert(total == NSDecimalNumber(value: 0.31))
    }
    
    func testDiscount() {
        
    }
    
    func testTaxExempt() {
        let nesteaB = BillableItem(value: nestea)
        billProcessor.addBillableItem(billable: nesteaB)
        billProcessor.addTaxable(taxable: Tax(value:hst,type: .Standard))
        
        XCTAssert(billProcessor.totalAllDiscountsApplied == NSDecimalNumber(value: 0.00), "")
        XCTAssert(billProcessor.totalAllTaxesApplied == NSDecimalNumber(value: 0.00), "")
        XCTAssert(billProcessor.totalPreTaxPreDiscounts == NSDecimalNumber(value: 1.50), "")
        XCTAssert(billProcessor.totalPostTaxPostDiscounts == NSDecimalNumber(value: 1.50) , "")
    }
    
    func testTaxExemptWithDiscount() {
        let nesteaB = BillableItem(value: nestea)
        billProcessor.addBillableItem(billable: nesteaB)
        billProcessor.addTaxable(taxable: Tax(value:hst, type: .Standard))
        
        let discount = Discount(value: oneDollarAndFourtyNineCentDiscount, discountType: .DollarAmount)
        
        billProcessor.addDiscount(discount: discount)
        
        XCTAssert(billProcessor.totalAllDiscountsApplied == NSDecimalNumber(value: 1.49), "")
        XCTAssert(billProcessor.totalAllTaxesApplied == NSDecimalNumber(value: 0.00), "")
        XCTAssert(billProcessor.totalPreTaxPreDiscounts == NSDecimalNumber(value: 1.50), "")
        XCTAssert(billProcessor.totalPostTaxPostDiscounts == NSDecimalNumber(value: 0.01) , "")
    }
    
    func testTaxExemptWithDiscountAndOneItemWithAddedTax() {
        let nesteaB = BillableItem(value: nestea)
        let cokeB = BillableItem(value:coke)
        
        billProcessor.addBillableItem(billable: nesteaB)
        billProcessor.addBillableItem(billable: cokeB)
        
        billProcessor.addTaxable(taxable: Tax(value:cokeTax,type:.Category))
        billProcessor.addTaxable(taxable: Tax(value:hst, type: .Standard))
        
        let discount1 = Discount(value: oneDollarAndFourtyNineCentDiscount, discountType: .DollarAmount)
        let discount2 = Discount(value: oneDollarAndFourtyNineCentDiscount, discountType: .DollarAmount)
        
        billProcessor.addDiscount(discount: discount1)
        billProcessor.addDiscount(discount: discount2)
        
        XCTAssert(billProcessor.totalAllDiscountsApplied == NSDecimalNumber(value: 2.98), "")
        XCTAssert(billProcessor.totalAllTaxesApplied == NSDecimalNumber(value: 0.30), "")
        XCTAssert(billProcessor.totalPreTaxPreDiscounts == NSDecimalNumber(value: 3.00), "")
        XCTAssert(billProcessor.totalPostTaxPostDiscounts == NSDecimalNumber(value: 0.32) , "")
    }
    
    
    func debugPrintCurrentState() {
        var subtotal = billProcessor.totalPreTaxPreDiscounts
        var discount = billProcessor.totalAllDiscountsApplied
        
        var finalTotal = billProcessor.totalPostTaxPostDiscounts
        var totalTaxes = billProcessor.totalAllTaxesApplied
        
        print("subtotal: \(subtotal)")
        print("discount: \(discount)")
        print("totalTaxes: \(totalTaxes)")
        print("finalTotal: \(finalTotal)")
    }
    
    
    func testRegistrationOfDiscounts() {
        let cokeB = BillableItem(value: cokeLarge)
        
        billProcessor.addBillableItem(billable: cokeB)
        
        billProcessor.addTaxable(taxable: Tax(value:hst, type: .Standard))
        
        var discount1 = Discount(value: twoDollarDiscount, discountType: .DollarAmount)
        discount1.isEnabled = false
        
        var discount2 = Discount(value: tenPercentDiscount, discountType: .Percent)
        discount2.isEnabled = false
        
        billProcessor.setDiscounts(discounts: [discount1,discount2])

        print("Adding Discounts")
        
        var discountRef1 = billProcessor.findRegisteredDiscountFor(id: discount1.id)
        discountRef1.isEnabled = true
        billProcessor.updateDiscount(discount: discountRef1)
    
        var discountRef2 = billProcessor.findRegisteredDiscountFor(id: discount2.id)
        discountRef2.isEnabled = true
        billProcessor.updateDiscount(discount: discountRef2)
    
        XCTAssert(billProcessor.totalPostTaxPostDiscounts == NSDecimalNumber(value: 3.05) , "Sanity Check")
        XCTAssert(billProcessor.totalAllDiscountsApplied == NSDecimalNumber(value: 2.30) , "Sanity Check")
        
   
        
        // remove discounts
        discountRef1 = billProcessor.findRegisteredDiscountFor(id: discount1.id)
        discountRef1.isEnabled = false
        billProcessor.updateDiscount(discount: discountRef1)
        

        print("Removing Discounts")
        
        XCTAssert(billProcessor.totalPostTaxPostDiscounts == NSDecimalNumber(value: 5.09) , "Test Removing 1 Discount")
        XCTAssert(billProcessor.totalAllDiscountsApplied == NSDecimalNumber(value: 0.5) , "Test Removing 1 Discount")
        
   
        
        // reenable should apply this discount last 10% then -2.00
        discountRef1 = billProcessor.findRegisteredDiscountFor(id: discount1.id)
        discountRef1.isEnabled = true
        billProcessor.updateDiscount(discount: discountRef1)
      
        
        XCTAssert(billProcessor.totalPostTaxPostDiscounts == NSDecimalNumber(value:  2.83) , "Test Readding Discount 1")
        XCTAssert(billProcessor.totalAllDiscountsApplied == NSDecimalNumber(value:   2.5) , "Test Readding Discount 1")
      
        
    }
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.billProcessor = BillProcessor<BillableItem,Tax,Discount>()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
