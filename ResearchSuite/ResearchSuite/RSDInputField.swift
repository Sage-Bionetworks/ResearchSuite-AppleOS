//
//  RSDInputField.swift
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

/// `RSDInputField` is used to describe a form input and includes the data type and a possible hint to how the UI
/// should be displayed. The ResearchSuite framework uses `RSDFormUIStep` to represent questions to ask the user.
/// Each question must have at least one associated input field. An input field is validated when its owning step
/// is validated.
///
/// - seealso: `RSDFormUIStep`
public protocol RSDInputField {
    
    /// A short string that uniquely identifies the input field within the step. The identifier is reproduced in the
    /// results of a step result in the step history of a task result.
    var identifier: String { get }
    
    /// A localized string that displays a short text offering a hint to the user of the data to be entered for
    /// this field.
    var prompt: String? { get }
    
    /// A localized string that displays placeholder information for the input field.
    ///
    /// You can display placeholder text in a text field or text area to help users understand how to answer
    /// the item's question.
    var placeholderText: String? { get }
    
    /// A Boolean value indicating whether the user can skip the input field without providing an answer.
    var isOptional: Bool { get }
    
    /// The data type for this input field. The data type can have an associated ui hint.
    var dataType: RSDFormDataType { get }
    
    /// A UI hint for how the study would prefer that the input field is displayed to the user.
    var uiHint: RSDFormUIHint? { get }
    
    /// Options for displaying a text field. This is only applicable for certain types of UI hints and data types.
    var textFieldOptions: RSDTextFieldOptions? { get }
    
    /// A range used by dates and numbers for setting up a picker wheel, slider, or providing text field
    /// input validation.
    var range: RSDRange? { get }
    
    /// A formatter that is appropriate to the data type. If `nil`, the format will be determined by the UI.
    /// This is the formatter used to display a previously entered answer to the user or to convert an answer
    /// entered in a text field into the appropriate value type.
    ///
    /// - seealso: `RSDAnswerResultType.BaseType` and `RSDFormStepDataSource`
    var formatter: Formatter? { get }
    
    /// Validate the input field to check for any configuration that should throw an error.
    func validate() throws
}

/// `RSDChoice` is used to describe a choice item for use with a multiple choice or multiple component input field.
public protocol RSDChoice {
    
    /// A JSON encodable object to return as the value when this choice is selected. A `nil` value indicates that
    /// the user has selected to skip the question or "prefers not to answer".
    var value: Codable? { get }
    
    /// Localized text string to display for the choice.
    var text: String? { get }
    
    /// Additional detail text.
    var detail: String? { get }
    
    /// For a multiple choice option, is this choice mutually exclusive? For example, "none of the above".
    var isExclusive: Bool { get }
    
    /// Whether or not this choice has an image associated with it that should be returned by the fetch icon method.
    var hasIcon: Bool { get }
    
    /// An icon image that can be used for displaying the choice.
    ///
    /// - parameters:
    ///     - size:        The size of the image to return.
    ///     - callback:    The callback with the image, run on the main thread.
    func fetchIcon(for size: CGSize, callback: @escaping ((UIImage?) -> Void))
    
    /// Is the choice value equal to the given result?
    /// - parameter result: A result to test for equality.
    /// - returns: `true` if the values are equal.
    func isEqualToResult(_ result: RSDResult?) -> Bool
}

/// `RSDChoiceInputField` extends the properties of `RSDInputField` with information required to create a
/// multiple or single choice question.
public protocol RSDChoiceInputField : RSDInputField, RSDChoiceOptions {
}

extension RSDChoiceInputField {
    
    /// Convenience property for whether or not the choice input field has associated images
    public var hasImages: Bool {
        for choice in choices {
            if choice.hasIcon {
                return true
            }
        }
        return false
    }
}

/// `RSDMultipleComponentInputField` extends the properties of `RSDInputField` with information
/// required to create a multiple component input field.
///
/// - seealso: `RSDFormDataType.CollectionType.multipleComponent`
public protocol RSDMultipleComponentInputField : RSDInputField, RSDMultipleComponentOptions {
}
