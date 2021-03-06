//
//  RSDMultipleComponentInputFieldObject.swift
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

/// `RSDMultipleComponentInputFieldObject` extends the properties of `RSDInputFieldObject` with information
/// required to create a multiple component input field.
open class RSDMultipleComponentInputFieldObject : RSDInputFieldObject, RSDMultipleComponentInputField {
    
    /// A list of choices for input fields that make up the multiple component option set.
    public let choices : [[RSDChoice]]
    
    /// If this is a multiple component input field, the UI can optionally define a separator.
    /// For example, blood pressure would have a separator of "/".
    open private(set) var separator: String?
    
    /// Default initializer.
    ///
    /// - parameters:
    ///     - identifier: A short string that uniquely identifies the input field within the step.
    ///     - choices: A list of choices for input fields that make up the multiple component option set.
    ///     - baseType: The base type for this input field.
    ///     - separator: A separator to display between the components.
    ///     - uiHint: A UI hint for how the study would prefer that the input field is displayed to the user.
    ///     - prompt: A localized string that displays a short text offering a hint to the user of the data to be entered for
    ///               this field.
    public init(identifier: String, choices: [[RSDChoice]], baseType: RSDFormDataType.BaseType, separator: String? = nil, uiHint: RSDFormUIHint? = nil, prompt: String? = nil) {
        self.choices = choices
        self.separator = separator
        let dataType = RSDFormDataType.collection(.multipleComponent, baseType)
        super.init(identifier: identifier, dataType: dataType, uiHint: uiHint, prompt: prompt)
    }
    
    private enum CodingKeys : String, CodingKey {
        case choices, separator
    }
    
    /// Initialize from a `Decoder`. This method uses the `RSDFormDataType.BaseType` associated with this input field to
    /// decode a list of `RSDChoiceObject` objects with the appropriate `Value` type.
    ///
    /// - parameter decoder: The decoder to use to decode this instance.
    /// - throws: `DecodingError` if there is a decoding error.
    public required init(from decoder: Decoder) throws {
        
        // Get the base data type
        let dataType = try type(of: self).dataType(from: decoder)
        
        // decode the choices
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let choices: [[RSDChoice]]
        switch dataType.baseType {
        case .boolean:
            choices = try container.decode([[RSDChoiceObject<Bool>]].self, forKey: .choices)
        case .integer, .year:
            choices = try container.decode([[RSDChoiceObject<Int>]].self, forKey: .choices)
        case .date:
            if let intChoices = try? container.decode([[RSDChoiceObject<Int>]].self, forKey: .choices) {
                choices = intChoices
            } else {
                choices = try container.decode([[RSDChoiceObject<Int>]].self, forKey: .choices)
            }
        case .decimal:
            choices = try container.decode([[RSDChoiceObject<Double>]].self, forKey: .choices)
        case .string:
            choices = try container.decode([[RSDChoiceObject<String>]].self, forKey: .choices)
        }
        self.choices = choices
        
        // decode the separator
        self.separator = try container.decodeIfPresent(String.self, forKey: .separator)
        
        // call super
        try super.init(from: decoder)
    }
    
    /// Encode the result to the given encoder.
    /// - parameter encoder: The encoder to use to encode this instance.
    /// - throws: `EncodingError`
    override open func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let obj = separator {
            try container.encode(obj, forKey: .separator)

        }

        var nestedContainer = container.nestedUnkeyedContainer(forKey: .choices)
        for nestedChoices in choices {
            let nestedEncoder = nestedContainer.superEncoder()
            var innerContainer = nestedEncoder.unkeyedContainer()
            for choice in nestedChoices {
                guard let encodable = choice as? Encodable else {
                    throw EncodingError.invalidValue(choice, EncodingError.Context(codingPath: innerContainer.codingPath, debugDescription: "The choice does not conform to the Encodable protocol"))
                }
                let innerEncoder = innerContainer.superEncoder()
                try encodable.encode(to: innerEncoder)
            }
        }
    }
}

