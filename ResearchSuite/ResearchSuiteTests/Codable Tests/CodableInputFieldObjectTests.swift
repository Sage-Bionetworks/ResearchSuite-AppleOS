//
//  CodableInputFieldObjectTests.swift
//  ResearchSuiteTests
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import XCTest
import ResearchSuite

class CodableInputFieldObjectTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // setup to have an image wrapper delegate set so the image wrapper won't crash
        RSDImageWrapper.sharedDelegate = TestImageWrapperDelegate()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRSDChoiceObject_Codable_Dictionary_StringValue() {
        
        let json = """
        {
            "value": "foo",
            "text": "Some text.",
            "detail": "A detail about the object",
            "icon": "fooImage",
            "isExclusive": true
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let object = try decoder.decode(RSDChoiceObject<String>.self, from: json)
            
            XCTAssertEqual(object.value as? String, "foo")
            XCTAssertEqual(object.text, "Some text.")
            XCTAssertEqual(object.detail, "A detail about the object")
            XCTAssertEqual(object.icon?.imageName, "fooImage")
            XCTAssertTrue(object.isExclusive)
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["value"] as? String, "foo")
            XCTAssertEqual(dictionary["text"] as? String, "Some text.")
            XCTAssertEqual(dictionary["detail"] as? String, "A detail about the object")
            XCTAssertEqual(dictionary["icon"] as? String, "fooImage")
            XCTAssertEqual(dictionary["isExclusive"] as? Bool, true)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testRSDChoiceObject_Codable_Dictionary_IntValue() {
        
        let json = """
        {
            "value": 3,
            "text": "Some text.",
            "detail": "A detail about the object",
            "icon": "fooImage",
            "isExclusive": true
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(RSDChoiceObject<Int>.self, from: json)
            
            XCTAssertEqual(object.value as? Int, 3)
            XCTAssertEqual(object.text, "Some text.")
            XCTAssertEqual(object.detail, "A detail about the object")
            XCTAssertEqual(object.icon?.imageName, "fooImage")
            XCTAssertTrue(object.isExclusive)
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["value"] as? Int, 3)
            XCTAssertEqual(dictionary["text"] as? String, "Some text.")
            XCTAssertEqual(dictionary["detail"] as? String, "A detail about the object")
            XCTAssertEqual(dictionary["icon"] as? String, "fooImage")
            XCTAssertEqual(dictionary["isExclusive"] as? Bool, true)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testRSDChoiceObject_Codable_Dictionary_TextValue() {
        
        let json = """
        ["alpha", "beta"]
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let objects = try decoder.decode([RSDChoiceObject<String>].self, from: json)
            
            XCTAssertEqual(objects.count, 2)
            XCTAssertEqual(objects.first?.value as? String, "alpha")
            XCTAssertEqual(objects.last?.value as? String, "beta")
            
            guard let object = objects.first else {
                return
            }
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["value"] as? String, "alpha")
            XCTAssertEqual(dictionary["text"] as? String, "alpha")
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testChoiceInputFieldObject_Codable_String() {
        
        let json = """
        {
            "identifier": "foo",
            "dataType": "multipleChoice",
            "choices" : ["never", "sometimes", "often", "always"]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let object = try decoder.decode(RSDChoiceInputFieldObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.dataType, .collection(.multipleChoice, .string))
            XCTAssertFalse(object.isOptional)
            XCTAssertFalse(object.allowOther)
            XCTAssertEqual(object.choices.count, 4)
            XCTAssertEqual(object.choices.last?.text, "always")
            XCTAssertEqual(object.choices.last?.value as? String, "always")
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testChoiceInputFieldObject_Codable_Int() {
        
        let json = """
        {
            "identifier": "foo",
            "prompt": "Text",
            "placeholderText": "enter text",
            "dataType": "singleChoice.integer",
            "uiHint": "picker",
            "optional": true,
            "allowOther": true,
            "choices" : [{  "value" : 0,
                            "text" : "never"},
                         {  "value" : 1,
                            "text" : "sometimes"},
                         {  "value" : 2,
                            "text" : "often"},
                         {  "value" : 3,
                            "text" : "always"}],
            "expectedAnswer": 0
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let object = try decoder.decode(RSDChoiceInputFieldObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.prompt, "Text")
            XCTAssertEqual(object.placeholderText, "enter text")
            XCTAssertEqual(object.dataType, .collection(.singleChoice, .integer))
            XCTAssertEqual(object.uiHint, .standard(.picker))
            XCTAssertTrue(object.isOptional)
            XCTAssertTrue(object.allowOther)
            XCTAssertEqual(object.choices.count, 4)
            XCTAssertEqual(object.choices.last?.text, "always")
            XCTAssertEqual(object.choices.last?.value as? Int, 3)
            
            if let surveyRules = object.surveyRules, let rule = surveyRules.first as? RSDComparableSurveyRule {
                XCTAssertNil(rule.skipIdentifier)
                XCTAssertNil(rule.ruleOperator)
                XCTAssertEqual(rule.matchingAnswer as? Int, 0)
            } else {
                XCTFail("Failed to decode inline survey rule.")
            }
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testMultipleComponentInputFieldObject_Codable_String() {
        
        let json = """
        {
            "identifier": "foo",
            "dataType": "multipleComponent",
            "choices" : [["blue", "red", "green", "yellow"], ["dog", "cat", "rat"]]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let object = try decoder.decode(RSDMultipleComponentInputFieldObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.dataType, .collection(.multipleComponent, .string))
            XCTAssertFalse(object.isOptional)
            XCTAssertEqual(object.choices.count, 2)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testInputFieldObject_Codable_Integer() {
        
        let json = """
        {
            "identifier": "foo",
            "dataType": "integer",
            "uiHint": "slider",
            "range" : { "minimumValue" : -2,
                        "maximumValue" : 3,
                        "stepInterval" : 1,
                        "unit" : "feet" },
            "surveyRules" : [
                            {
                            "skipIdentifier": "lessThan",
                            "ruleOperator": "lt",
                            "expectedAnswer": 0
                            },
                            {
                            "skipIdentifier": "greaterThan",
                            "ruleOperator": "gt",
                            "expectedAnswer": 1
                            }
                            ]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let object = try decoder.decode(RSDInputFieldObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.dataType, .base(.integer))
            XCTAssertEqual(object.uiHint, .standard(.slider))
            if let range = object.range as? RSDDecimalRange {
                XCTAssertEqual(range.minimumValue, -2)
                XCTAssertEqual(range.maximumValue, 3)
                XCTAssertEqual(range.stepInterval, 1)
                XCTAssertEqual(range.unit, "feet")
            }
            else{
                XCTFail("Failed to decode range")
            }
            
            if let surveyRules = object.surveyRules,
                let firstRule = surveyRules.first as? RSDComparableSurveyRule,
                let lastRule = surveyRules.last as? RSDComparableSurveyRule {
                
                XCTAssertEqual(firstRule.skipIdentifier, "lessThan")
                XCTAssertEqual(firstRule.ruleOperator, .lessThan)
                XCTAssertEqual(firstRule.matchingAnswer as? Int, 0)
                
                XCTAssertEqual(lastRule.skipIdentifier, "greaterThan")
                XCTAssertEqual(lastRule.ruleOperator, .greaterThan)
                XCTAssertEqual(lastRule.matchingAnswer as? Int, 1)
                
            } else {
                XCTFail("Failed to decode inline survey rule.")
            }
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testInputFieldObject_Codable_Decimal() {
        
        let json = """
        {
            "identifier": "foo",
            "dataType": "decimal",
            "uiHint": "slider",
            "range" : { "minimumValue" : -2.5,
                        "maximumValue" : 3,
                        "stepInterval" : 0.1,
                        "unit" : "feet",
                        "maximumDigits" : 3 }
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let object = try decoder.decode(RSDInputFieldObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.dataType, .base(.decimal))
            XCTAssertEqual(object.uiHint, .standard(.slider))
            if let range = object.range as? RSDDecimalRangeObject {
                XCTAssertEqual(range.minimumValue, -2.5)
                XCTAssertEqual(range.maximumValue, 3)
                XCTAssertEqual(range.stepInterval, 0.1)
                XCTAssertEqual(range.unit, "feet")
                XCTAssertEqual((range.formatter as? NumberFormatter)?.maximumFractionDigits ?? 0, 3)
            }
            else{
                XCTFail("Failed to decode range")
            }
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testInputFieldObject_Codable_Date() {
        
        let json = """
        {
            "identifier": "foo",
            "dataType": "date",
            "uiHint": "picker",
            "range" : { "minimumDate" : "2017-02-20",
                        "maximumDate" : "2017-03-20",
                        "codingFormat" : "yyyy-MM-dd" }
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let object = try decoder.decode(RSDInputFieldObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.dataType, .base(.date))
            XCTAssertEqual(object.uiHint, .standard(.picker))
            if let range = object.range as? RSDDateRange {
                
                let calendar = Calendar(identifier: .gregorian)
                let calendarComponents = range.calendarComponents
                XCTAssertEqual(calendarComponents, [.year, .month, .day])
                
                XCTAssertNotNil(range.minimumDate)
                if let date = range.minimumDate {
                    let min = calendar.dateComponents(calendarComponents, from: date)
                    XCTAssertEqual(min.year, 2017)
                    XCTAssertEqual(min.month, 2)
                    XCTAssertEqual(min.day, 20)
                }
                
                XCTAssertNotNil(range.maximumDate)
                if let date = range.maximumDate {
                    let max = calendar.dateComponents(calendarComponents, from: date)
                    XCTAssertEqual(max.year, 2017)
                    XCTAssertEqual(max.month, 3)
                    XCTAssertEqual(max.day, 20)
                }
            }
            else{
                XCTFail("Failed to decode range")
            }
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testInputFieldObject_Codable_String() {
        
        let json = """
        {
            "identifier": "foo",
            "dataType": "string",
            "uiHint": "textfield",
            "textFieldOptions" : {
                        "validationRegex" : "[A:C]",
                        "invalidMessage" : "You know me",
                        "maximumLength" : 10,
                        "autocapitalizationType" : "words",
                        "keyboardType" : "asciiCapable",
                        "isSecureTextEntry" : true }
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let object = try decoder.decode(RSDInputFieldObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.dataType, .base(.string))
            XCTAssertEqual(object.uiHint, .standard(.textfield))
            if let textFieldOptions = object.textFieldOptions  {
                XCTAssertEqual(textFieldOptions.validationRegex, "[A:C]")
                XCTAssertEqual(textFieldOptions.invalidMessage, "You know me")
                XCTAssertEqual(textFieldOptions.maximumLength, 10)
                XCTAssertEqual(textFieldOptions.autocapitalizationType, .words)
                XCTAssertEqual(textFieldOptions.keyboardType, .asciiCapable)
                XCTAssertTrue(textFieldOptions.isSecureTextEntry)
            }
            else{
                XCTFail("Failed to decode textFieldOptions")
            }
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testInputFieldObject_Codable_String_DefaultOptions() {
        
        let json = """
        {
            "identifier": "foo",
            "dataType": "string",
            "uiHint": "textfield",
            "textFieldOptions" : {}
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let object = try decoder.decode(RSDInputFieldObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.dataType, .base(.string))
            XCTAssertEqual(object.uiHint, .standard(.textfield))
            if let textFieldOptions = object.textFieldOptions  {
                XCTAssertNil(textFieldOptions.validationRegex)
                XCTAssertNil(textFieldOptions.invalidMessage)
                XCTAssertEqual(textFieldOptions.maximumLength, 0)
                XCTAssertEqual(textFieldOptions.autocapitalizationType, .none)
                XCTAssertEqual(textFieldOptions.keyboardType, .default)
                XCTAssertFalse(textFieldOptions.isSecureTextEntry)
            }
            else{
                XCTFail("Failed to decode textFieldOptions")
            }
            
        } catch let err {
            XCTFail("Failed to decode object: \(err)")
            return
        }
    }
    
}
