//
//  RSDInputFieldObject.swift
//  ResearchSuite
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

import Foundation

open class RSDInputFieldObject : RSDSurveyInputField, Decodable {
    
    public private(set) var identifier: String
    
    open private(set) var dataType: RSDFormDataType
    open private(set) var uiHint: RSDFormUIHint?
    
    open var prompt: String?
    open var placeholderText: String?
    open var textFieldOptions: RSDTextFieldOptions?
    open var range: RSDRange?
    open var isOptional: Bool = false
    
    open var surveyRules: [RSDSurveyRule]?
    
    private var _formatter: Formatter?
    open var formatter: Formatter? {
        get {
            return _formatter ?? (self.range as? RSDRangeWithFormatter)?.formatter
        }
        set {
            _formatter = newValue
        }
    }
    
    public init(identifier: String, dataType: RSDFormDataType, uiHint: RSDFormUIHint? = nil, prompt: String? = nil) {
        self.identifier = identifier
        self.dataType = dataType
        self.uiHint = uiHint
        self.prompt = prompt
    }
    
    open func validate() throws {
        // TODO: syoung 10/04/2017 Implement
    }
    
    private enum CodingKeys : String, CodingKey {
        case identifier, prompt, placeholderText, dataType, uiHint, isOptional = "optional", textFieldOptions, range, surveyRules
    }
    
    open class func dataType(from decoder: Decoder) throws -> RSDFormDataType {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        return try container.decode(RSDFormDataType.self, forKey: .dataType)
    }
    
    open class func uiHint(from decoder: Decoder, for dataType: RSDFormDataType) throws -> RSDFormUIHint? {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let uiHint = try container.decodeIfPresent(RSDFormUIHint.self, forKey: .uiHint) else {
            return nil
        }
        guard let standardType = uiHint.standardType else {
            return uiHint
        }
        guard dataType.validStandardUIHints.contains(standardType) else {
            throw RSDValidationError.invalidType("\(uiHint) is not a valid uiHint for \(dataType)")
        }
        return uiHint
    }
    
    open class func range(from decoder: Decoder, dataType: RSDFormDataType) throws -> RSDRange? {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch dataType.baseType {
        case .integer, .decimal:
            return try container.decodeIfPresent(RSDDecimalRangeObject.self, forKey: .range)
        case .date:
            return try container.decodeIfPresent(RSDDateRangeObject.self, forKey: .range)
        case .year:
            // For a year data type, we first need to check if there is a min/max range set using the date
            // and if so, return that. The decoder could fail to find any property keys and not fail to
            // decode because everything in the range is optional.
            if let dateRange = try container.decodeIfPresent(RSDDateRangeObject.self, forKey: .range),
                (dateRange.minimumDate != nil || dateRange.maximumDate != nil) {
                return dateRange
            } else {
                return try container.decodeIfPresent(RSDDecimalRangeObject.self, forKey: .range)
            }
        default:
            return nil
        }
    }
    
    open class func textFieldOptions(from decoder: Decoder, dataType: RSDFormDataType) throws -> RSDTextFieldOptionsObject? {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let textFieldOptions = try container.decodeIfPresent(RSDTextFieldOptionsObject.self, forKey: .textFieldOptions) {
            return textFieldOptions
        }
        // If there isn't a text field returned, then set the default for certain types
        switch dataType.baseType {
        case .integer:
            return RSDTextFieldOptionsObject(keyboardType: .numberPad)
        case .decimal:
            return RSDTextFieldOptionsObject(keyboardType: .decimalPad)
        default:
            return nil
        }
    }
    
    public required init(from decoder: Decoder) throws {
        
        let dataType = try type(of: self).dataType(from: decoder)
        let uiHint = try type(of: self).uiHint(from: decoder, for: dataType)
        let range = try type(of: self).range(from: decoder, dataType: dataType)
        let textFieldOptions = try type(of: self).textFieldOptions(from: decoder, dataType: dataType)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.dataType = dataType
        self.uiHint = uiHint
        self.range = range
        self.textFieldOptions = textFieldOptions
        self.identifier = try container.decode(String.self, forKey: .identifier)
        self.prompt = try container.decodeIfPresent(String.self, forKey: .prompt)
        self.placeholderText = try container.decodeIfPresent(String.self, forKey: .placeholderText)
        self.isOptional = try container.decodeIfPresent(Bool.self, forKey: .isOptional) ?? false
        
        if container.contains(.surveyRules) {
            switch dataType.baseType {
            case .boolean:
                self.surveyRules = try container.decode([RSDComparableSurveyRuleObject<Bool>].self, forKey: .surveyRules)
            case .string:
                self.surveyRules = try container.decode([RSDComparableSurveyRuleObject<String>].self, forKey: .surveyRules)
            case .date:
                self.surveyRules = try container.decode([RSDComparableSurveyRuleObject<Date>].self, forKey: .surveyRules)
            case .decimal:
                self.surveyRules = try container.decode([RSDComparableSurveyRuleObject<Double>].self, forKey: .surveyRules)
            case .integer, .year:
                self.surveyRules = try container.decode([RSDComparableSurveyRuleObject<Int>].self, forKey: .surveyRules)
            }
        } else {
            let rule: RSDSurveyRule?
            switch dataType.baseType {
            case .boolean:
                rule = try? RSDComparableSurveyRuleObject<Bool>(from: decoder)
            case .string:
                rule = try? RSDComparableSurveyRuleObject<String>(from: decoder)
            case .date:
                rule = try? RSDComparableSurveyRuleObject<Date>(from: decoder)
            case .decimal:
                rule = try? RSDComparableSurveyRuleObject<Double>(from: decoder)
            case .integer, .year:
                rule = try? RSDComparableSurveyRuleObject<Int>(from: decoder)
            }
            if rule != nil {
                self.surveyRules = [rule!]
            }
        }
    }
    
// TODO: syoung 11/14/2017 Implement Encodable protocol for the survey rules if there is a need to make this encodable.
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(self.identifier, forKey: .identifier)
//        try container.encode(self.dataType, forKey: .dataType)
//        try container.encodeIfPresent(prompt, forKey: .prompt)
//        try container.encodeIfPresent(placeholderText, forKey: .placeholderText)
//        try container.encodeIfPresent(uiHint, forKey: .uiHint)
//        if let obj = self.range {
//            let nestedEncoder = container.superEncoder(forKey: .range)
//            guard let encodable = obj as? Encodable else {
//                throw EncodingError.invalidValue(obj, EncodingError.Context(codingPath: nestedEncoder.codingPath, debugDescription: "The range does not conform to the Encodable protocol"))
//            }
//            try encodable.encode(to: nestedEncoder)
//        }
//        if let obj = self.textFieldOptions {
//            let nestedEncoder = container.superEncoder(forKey: .textFieldOptions)
//            guard let encodable = obj as? Encodable else {
//                throw EncodingError.invalidValue(obj, EncodingError.Context(codingPath: nestedEncoder.codingPath, debugDescription: "The textFieldOptions does not conform to the Encodable protocol"))
//            }
//            try encodable.encode(to: nestedEncoder)
//        }
//        try container.encode(isOptional, forKey: .isOptional)
//    }
}
