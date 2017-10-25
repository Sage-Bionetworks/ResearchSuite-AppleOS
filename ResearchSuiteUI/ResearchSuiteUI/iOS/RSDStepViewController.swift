//
//  RSDStepViewController.swift
//  ResearchSuiteUI
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

public protocol RSDStepViewControllerDelegate : class, RSDUIActionHandler {
    
    func stepViewController(_ stepViewController: (UIViewController & RSDStepController), willAppear animated: Bool)
    func stepViewController(_ stepViewController: (UIViewController & RSDStepController), didAppear animated: Bool)
    func stepViewController(_ stepViewController: (UIViewController & RSDStepController), willDisappear animated: Bool)
    func stepViewController(_ stepViewController: (UIViewController & RSDStepController), didDisappear animated: Bool)
}

/**
 Protocol to allow setting the step view controller delegate on a view controller that may not inherit directly from
 UIViewController.
 
 Note: Any implementation should call the delegate methods during view appearance transitions.
 */
public protocol RSDStepViewControllerProtocol : class {
    weak var delegate: RSDStepViewControllerDelegate? { get set }
}

open class RSDStepViewController : UIViewController, RSDStepController, RSDUIActionHandler, RSDStepViewControllerProtocol {

    open weak var taskController: RSDTaskController!
    
    open weak var delegate: RSDStepViewControllerDelegate?
    
    open var step: RSDStep!
    
    public var uiStep: RSDUIStep? {
        return step as? RSDUIStep
    }
    
    public var activeStep: RSDActiveUIStep? {
        return step as? RSDActiveUIStep
    }
    
    public var formStep: RSDFormUIStep? {
        return step as? RSDFormUIStep
    }
    
    open var originalResult: RSDResult? {
        return taskController.taskPath.previousResults?.last(where: { $0.identifier == self.step.identifier })
    }
    
    lazy open var currentResult: RSDResult = {
        if let lastResult = taskController.taskPath.result.stepHistory.last, lastResult.identifier == self.step.identifier {
            return lastResult
        } else {
            let result = self.step.instantiateStepResult()
            taskController.taskPath.appendStepHistory(with: result)
            return result
        }
    }()
    
    public init(step: RSDStep) {
        super.init(nibName: nil, bundle: nil)
        self.step = step
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    // MARK: View appearance handling
    
    // We use a flag to track whether viewWillDisappear has been called because we run a check on
    // viewDidAppear to see if we have any textFields in the tableView. This check is done after a delay,
    // so we need to track if viewWillDisappear was called during the delay
    public private(set) var isVisible = false
    public private(set) var isFirstAppearance: Bool = true
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.stepViewController(self, willAppear: animated)
        if isFirstAppearance {
            setupNavigation()
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        isVisible = true
        super.viewDidAppear(animated)
        delegate?.stepViewController(self, didAppear: animated)
        
        // setup the result (lazy load) to mark the startDate
        let _ = currentResult
        
        // If this is the first appearance then perform the start commands
        if isFirstAppearance {
            performStartCommands()
        }
        isFirstAppearance = false
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        isVisible = false
        super.viewWillDisappear(animated)
        delegate?.stepViewController(self, willDisappear: animated)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.stepViewController(self, didDisappear: animated)
    }
    
    
    // MARK: Navigation
    
    @IBOutlet open weak var cancelButton: UIButton?
    @IBOutlet open weak var continueButton: UIButton?
    @IBOutlet open weak var backButton: UIButton?
    @IBOutlet open weak var skipButton: UIButton?
    @IBOutlet open weak var learnMoreButton: UIButton?
    
    open var isForwardEnabled: Bool {
        return taskController.isForwardEnabled
    }
    
    open func didFinishLoading() {
        // Enable the continue button
        continueButton?.isEnabled = true
    }

    open func setupNavigation() {
        setupButton(cancelButton, for: .navigation(.cancel))
        setupButton(continueButton, for: .navigation(.goForward))
        setupButton(backButton, for: .navigation(.goBackward))
        setupButton(skipButton, for: .navigation(.skip))
        setupButton(learnMoreButton, for: .navigation(.learnMore))
    }
    
    open func setupButton(_ button: UIButton?, for actionType: RSDUIActionType) {
        guard let btn = button else { return }
        
        // Set up whether or not the button is visible and it's text/image
        btn.isHidden = self.shouldHideAction(for: actionType) ?? true
        if let action = self.action(for: actionType) {
            btn.setTitle(action.buttonTitle, for: .normal)
            btn.setImage(action.buttonIcon, for: .normal)
        }
        
        // If this is a goForward button, then there is some additional logic around
        // loading state and whether or not any input fields are optional
        if actionType == .navigation(.goForward) {
            btn.isEnabled = isForwardEnabled
        }
    }
    
    @IBAction open func goForward() {
        performStopCommands()
        self.taskController.goForward()
    }
    
    @IBAction open func goBack() {
        stop()
        self.taskController.goBack()
    }
    
    @IBAction open func skipForward() {
        stop()
        self.taskController.goForward()
    }
    
    @IBAction open func cancel() {
        stop()
        self.taskController.handleTaskCancelled()
    }
    
    
    // MARK: RSDUIActionHandler
    
    open func action(for actionType: RSDUIActionType) -> RSDUIAction? {
        if let action = (self.step as? RSDUIActionHandler)?.action(for: actionType) {
            // Allow the step to override the default from the delegate
            return action
        }
        else if let action = self.delegate?.action(for: actionType){
            // If no override by the step then return the action from the delegate
           return action
        }
        else {
            // Otherwise, look at the action and show the default based on the type
            switch actionType {
            case .navigation(.cancel):
                return RSDUIActionObject(buttonTitle: Localization.buttonCancel())
            case .navigation(.goForward):
                return self.taskController.hasStepAfter ? RSDUIActionObject(buttonTitle: Localization.buttonNext()) : RSDUIActionObject(buttonTitle: Localization.buttonDone())
            case .navigation(.goBackward):
                return self.taskController.hasStepBefore ? RSDUIActionObject(buttonTitle: Localization.buttonBack()) : nil
            default:
                return nil
            }
        }
    }
    
    open func shouldHideAction(for actionType: RSDUIActionType) -> Bool? {
        if let shouldHide = (self.step as? RSDUIActionHandler)?.shouldHideAction(for: actionType) {
            // Allow the step to override the default from the delegate
            return shouldHide
        }
        else if let shouldHide = self.delegate?.shouldHideAction(for: actionType) {
            // If no override by the step then return the action from the delegate if there is one
            return shouldHide
        }
        else {
            // Otherwise, look at the action and show the button based on the type
            switch actionType {
            case .navigation(.cancel), .navigation(.goForward):
                return false
            case .navigation(.goBackward):
                return !self.taskController.hasStepBefore
            default:
                return self.action(for: actionType) != nil
            }
        }
    }
    
    
    // MARK: Active step handling
    
    public private(set) var startUptime: TimeInterval?
    private var timer: Timer?
    private var lastInstruction: Int = 0
    
    open func performStartCommands() {
        if let commands = self.activeStep?.commands {
            if commands.contains(.playSoundOnStart) {
                playSound()
            }
            if commands.contains(.vibrateOnStart) {
                vibrateDevice()
            }
            if commands.contains(.startTimerAutomatically) {
                start()
            }
        }
        
        if let instruction = self.activeStep?.spokenInstruction(at: 0) {
            speak(instruction: instruction, timeInterval: 0)
        }
    }
    
    open func performStopCommands() {
        if let commands = self.activeStep?.commands {
            if commands.contains(.playSoundOnFinish) {
                playSound()
            }
            if commands.contains(.vibrateOnFinish) {
                vibrateDevice()
            }
        }
        
        if let instruction = self.activeStep?.spokenInstruction(at: Double.infinity) {
            speak(instruction: instruction, timeInterval: Double.infinity)
        }
        
        // Always run the stop command
        stop()
    }
    
    open func playSound() {
        // TODO: Implement syoung 10/17/2017
    }
    
    open func vibrateDevice() {
        // TODO: Implement syoung 10/17/2017
    }
    
    open func speak(instruction: String, timeInterval: TimeInterval) {
        // TODO: Implement syoung 10/17/2017
    }
    
    open func start() {
        if startUptime == nil {
            startUptime = ProcessInfo.processInfo.systemUptime
        }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (_) in
            self?.timerFired()
        })
    }
    
    open func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    open func timerFired() {
        guard let uptime = startUptime else { return }
        let duration = ProcessInfo.processInfo.systemUptime - uptime
        
        if let stepDuration = self.activeStep?.duration, stepDuration > 0,
            let commands = self.activeStep?.commands, commands.contains(.continueOnFinish),
            duration > stepDuration {
            // Look to see if this step should end and if so, go forward
            goForward()
        }
        else {
            // Otherwise, look for any spoekn instructions since last fire
            let nextInstruction = Int(duration)
            if nextInstruction > lastInstruction {
                for ii in (lastInstruction + 1)...nextInstruction {
                    let timeInterval = TimeInterval(ii)
                    if let instruction = self.activeStep?.spokenInstruction(at: timeInterval) {
                        speak(instruction: instruction, timeInterval: timeInterval)
                    }
                }
                lastInstruction = nextInstruction
            }
        }
    }
}