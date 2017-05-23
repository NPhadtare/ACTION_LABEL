//
//  ActionLabel.swift
//  DemoforActionLabel
//
//  Created by Nilesh Phadtare on 18/05/17.
//  Copyright © 2017 Nilesh Phadtare. All rights reserved.
//

import UIKit
@objc protocol ActionLabelTextOptionViewDelegate: class {
    
    @objc optional func actionLabellTextOptionShouldBeginEditing(_ actionLabelTextField: ActionLabel) -> Bool
    @objc optional func actionLabelTextOptionDidBeginEditing(_ actionLabelTextField: ActionLabel)
    @objc optional func actionLabelTextOptionShouldEndEditing(_ actionLabelTextField: ActionLabel) -> Bool
    @objc optional func actionLabelTextOptionDidEndEditing(_ actionLabelTextField: ActionLabel)
    @objc optional func actionLabelTextOption(_ actionLabelTextField: ActionLabel, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    @objc optional func actionLabelTextOptionDidChangeText(_ actionLabelTextField: ActionLabel)
    @objc optional func actionLabelTextOptionShouldClear(_ actionLabelTextField: ActionLabel) -> Bool
    @objc optional func actionLabelTextOptionShouldReturn(_ actionLabelTextField: ActionLabel) -> Bool
    @objc optional func actionLabelDidSelect(_ actionLabelTextField: ActionLabel, selectedWord: String, range: NSRange)
  
    @objc optional func actionLabelDidChangeTextValue(_ actionLabelTextField: ActionLabel, selectedWord: String, index: Int, range: NSRange)
    @objc optional func actionLabelDidChangeOptionValue(_ actionLabelTextField: ActionLabel, selectedWord: String, index: Int, range: NSRange)
    @objc optional func actionLabelDidChangeDateValue(_ actionLabelTextField: ActionLabel, selectedWord: String, index: Int, range: NSRange)
    
    @objc optional func actionLabelDidCancelOptionSelect(_ actionLabelTextField: ActionLabel)
    @objc optional func actionLabelDidCancelDateSelect(_ actionLabelTextField: ActionLabel)
    
}

@objc enum ActionType : Int {
    case Action
    case EditText
    case DropDown
    case DateDropDown

}

let ALActionWordName = "string"
let ALActionWordType = "type"
let ALActionWordOptions = "Options"
let ALActionWordDateType = "dateType"
let ALActionWordDateFormat = "dateFormat"

class ActionLabel: UIView {
    
    fileprivate var txtField: UITextField!
    private var fieldTitleLeftPaddingConstraint: NSLayoutConstraint!
    private var fieldTitleRightPaddingConstraint: NSLayoutConstraint!
    private var fieldTitleBottomSpacingConstraint: NSLayoutConstraint!
    private var textFieldBottomSpacingConstraint: NSLayoutConstraint!
    private var pickerBottomSpacingConstraint: NSLayoutConstraint!
    private var datePickerBottomSpacingConstraint: NSLayoutConstraint!

    fileprivate var heightCorrection: CGFloat = 0
    internal lazy var textStorage = NSTextStorage()
    fileprivate lazy var layoutManager = NSLayoutManager()
    fileprivate lazy var textContainer = NSTextContainer()
    
    var selectedIndex = 0
    
    fileprivate var accesoryView: UIView! {
        didSet {
            accesoryView.layer.borderColor = UIColor.lightGray.cgColor
            accesoryView.layer.borderWidth = 2
        }
    }
    fileprivate var pickerContainerView: UIView!
    fileprivate var pickerView: UIPickerView!
    fileprivate var toolBarView: UIToolbar!

    fileprivate var datePickerContainerView: UIView!
    fileprivate var datePickerView: UIDatePicker!
    fileprivate var dateToolBarView: UIToolbar!
    
    fileprivate var btnDone: UIButton! {
        didSet {
            btnDone.setTitle("Done", for: .normal)
            btnDone.setTitleColor(UIColor.blue, for: .normal)
            btnDone.addTarget(self, action: #selector(ActionLabel.btnDoneAction(_:)), for: .touchUpInside)
        }
    }

    fileprivate var selectedStringDict = [String : Any]()
    fileprivate var _customizing: Bool = true

    var labelTitleColor = UIColor.black
    var labelTitleFont = UIFont.systemFont(ofSize: 20)
    var actionWordColor = UIColor.blue
    var actionWordRange = [[String: Any]]()

    var font = UIFont.systemFont(ofSize: 20) {
        didSet {
            if txtField != nil { txtField.font = font }
            updateTextStorage(parseText: false)
        }
    }
    
    var textAlignment = NSTextAlignment.center {
        didSet {
            updateTextStorage(parseText: false)
        }
    }
    
    var numberOfLines = 1 {
        didSet { textContainer.maximumNumberOfLines = numberOfLines; updateTextStorage(parseText: false) }
    }
    
    var lineBreakMode =  NSLineBreakMode.byTruncatingTail {
        didSet { textContainer.lineBreakMode = lineBreakMode; updateTextStorage(parseText: false) }
    }
    
    var invalidContent = false { didSet { setNeedsDisplay() } }
    var invalidContentColor = UIColor.red { didSet { setNeedsDisplay() } }
    var fieldTitlePadding: CGFloat = 0 { didSet { fieldTitleRightPaddingConstraint.constant = fieldTitlePadding; fieldTitleLeftPaddingConstraint.constant = fieldTitlePadding } }
    
    var labelText: NSMutableAttributedString?
    
    var actionWords = [[String: Any]]() {
        didSet {
            fetchrangeOfActionWords()
            updateTextStorage(parseText: false)
        }
    }
    var text: String? {
        get { return txtField.text }
        set { txtField.text = text }
    }
    var placeholder: String? {
        get { return txtField.placeholder }
        set { txtField.placeholder = placeholder }
    }
    
    var keyboardType = UIKeyboardType.default { didSet { txtField.keyboardType = keyboardType } }
    var isEditable = true {
        didSet {
            txtField.isEnabled = isEditable
            txtField.textColor = isEditable ? UIColor.black : UIColor.darkGray
            updateTextStorage(parseText: false)
        }
    }
    
    weak var delegate: ActionLabelTextOptionViewDelegate? {
        didSet {
            txtField.delegate = self
            updateTextStorage(parseText: false)
        }
    }
    
    var hideTextField = false {
        didSet {
            txtField.isHidden = hideTextField
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _customizing = false
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _customizing = false
        setup()
    }
    
    // MARK: - customzation
    @discardableResult
    open func customize(_ block: (_ label: ActionLabel) -> ()) -> ActionLabel {
        _customizing = true
        block(self)
        _customizing = false
        updateTextStorage()
        return self
    }
    
    private func setup() {
        backgroundColor = UIColor.clear
        contentMode = .redraw

        if (txtField == nil) {
            txtField = UITextField(frame: CGRect.zero)
            txtField.translatesAutoresizingMaskIntoConstraints = false
            txtField.borderStyle = .none
            txtField.textAlignment = .left
            txtField.font = font
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ActionLabel.keyboardStateChanged(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ActionLabel.keyboardStateChanged(notification:)), name: .UIKeyboardWillHide, object: nil)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = lineBreakMode
        textContainer.maximumNumberOfLines = numberOfLines
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(ActionLabel.tap(_ :)))
        gesture.cancelsTouchesInView = false
        self.addGestureRecognizer(gesture)

        // add observer
        NotificationCenter.default.addObserver(self, selector: #selector(ActionLabel.textDidChange(notification:)), name: .UITextFieldTextDidChange, object: txtField)

    }
    
    fileprivate func updateTextStorage(parseText: Bool = true) {
        if _customizing { return }
        // clean up previous active elements
        guard let attributedText = labelText, attributedText.length > 0 else {
            //clearActiveElements()
            textStorage.setAttributedString(NSAttributedString())
            setNeedsDisplay()
            return
        }
        
        let mutAttrString = addLineBreak(attributedText)
        
        addLinkAttribute(mutAttrString)
        textStorage.setAttributedString(mutAttrString)
        _customizing = true
        text = mutAttrString.string
        _customizing = false
        setNeedsDisplay()
    }
    
    /// add link attribute
    fileprivate func addLinkAttribute(_ mutAttrString: NSMutableAttributedString) {
        var range = NSRange(location: 0, length: 0)
        var attributes = mutAttrString.attributes(at: 0, effectiveRange: &range)
        
        attributes[NSFontAttributeName] = labelTitleFont
        attributes[NSForegroundColorAttributeName] = labelTitleColor
        mutAttrString.addAttributes(attributes, range: range)
        
        attributes[NSForegroundColorAttributeName] = labelTitleColor
        mutAttrString.setAttributes(attributes, range: range)
    }

    
    @IBInspectable public var lineSpacing: CGFloat = 0 {
        didSet { updateTextStorage(parseText: false) }
    }
    
    @IBInspectable public var minimumLineHeight: CGFloat = 0 {
        didSet { updateTextStorage(parseText: false) }
    }
    /// add line break mode
    fileprivate func addLineBreak(_ attrString: NSAttributedString) -> NSMutableAttributedString {
        let mutAttrString = NSMutableAttributedString(attributedString: attrString)
        
        var range = NSRange(location: 0, length: 0)
        var attributes = mutAttrString.attributes(at: 0, effectiveRange: &range)
        
        let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.alignment = textAlignment
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.minimumLineHeight = minimumLineHeight > 0 ? minimumLineHeight: self.font.pointSize * 1.14
        attributes[NSParagraphStyleAttributeName] = paragraphStyle
        mutAttrString.setAttributes(attributes, range: range)
        return mutAttrString
    }
    
    func setupDropDownView() {
        if (pickerContainerView == nil) {
            pickerContainerView = UIView(frame: CGRect.zero)
            pickerContainerView.isHidden = true
            pickerContainerView.translatesAutoresizingMaskIntoConstraints = false
            let viewController = self.delegate as? UIViewController
            viewController?.view.addSubview(pickerContainerView)
            
            if (toolBarView == nil) {
                toolBarView = UIToolbar(frame: CGRect.zero)
                toolBarView.translatesAutoresizingMaskIntoConstraints = false
                let btnDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(btnAddAction(_:)))
                let flexiableSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
                let btnCancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(btnCancelAction(_:)))
                toolBarView.items = [btnCancel,flexiableSpace,btnDone]
                pickerContainerView.addSubview(toolBarView)
            }
            
            if (pickerView == nil) {
                pickerView = UIPickerView(frame: CGRect(x: 0, y: toolBarView.frame.size.width, width: self.frame.size.width, height: 216))
                pickerView.translatesAutoresizingMaskIntoConstraints = false
                pickerView.delegate = self
                pickerContainerView.addSubview(pickerView)
            }
            
            pickerBottomSpacingConstraint = NSLayoutConstraint(item: viewController?.view ?? UIView(), attribute: .bottom, relatedBy: .equal, toItem: pickerContainerView , attribute: .bottom, multiplier: 1.0, constant: -216)
            viewController?.view.addConstraint(pickerBottomSpacingConstraint)
            
            viewController?.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[pickerContainerView]|", options: .directionLeftToRight, metrics: nil, views: ["pickerContainerView": pickerContainerView]))
            
            pickerContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: String(format: "H:|[toolBarView]|"), options: .directionLeftToRight, metrics: nil, views: ["toolBarView": toolBarView]))
            pickerContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: String(format: "V:|[toolBarView][pickerView]|"), options: .directionLeftToRight, metrics: nil, views: ["toolBarView": toolBarView, "pickerView": pickerView]))
            pickerContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[pickerView]|", options: .directionLeftToRight, metrics: nil, views: ["pickerView": pickerView]))
        }
    }
    
    func setupDateDropDownView() {
        if (datePickerContainerView == nil) {
            datePickerContainerView = UIView(frame: CGRect.zero)
            datePickerContainerView.isHidden = true
            datePickerContainerView.translatesAutoresizingMaskIntoConstraints = false
            let viewController = self.delegate as? UIViewController
            viewController?.view.addSubview(datePickerContainerView)
            
            if (dateToolBarView == nil) {
                dateToolBarView = UIToolbar(frame: CGRect.zero)
                dateToolBarView.translatesAutoresizingMaskIntoConstraints = false
                let btnDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(btnDateAddAction(_:)))
                let flexiableSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action:nil)
                let btnCancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(btnDateCancelAction(_:)))
                dateToolBarView.items = [btnCancel,flexiableSpace,btnDone]
                datePickerContainerView.addSubview(dateToolBarView)
            }
            
            if (datePickerView == nil) {
                datePickerView = UIDatePicker(frame: CGRect(x: 0, y: dateToolBarView.frame.size.width, width: self.frame.size.width, height: 216))
                datePickerView.translatesAutoresizingMaskIntoConstraints = false
                datePickerContainerView.addSubview(datePickerView)
            }
            
            datePickerBottomSpacingConstraint = NSLayoutConstraint(item: viewController?.view ?? UIView(), attribute: .bottom, relatedBy: .equal, toItem: datePickerContainerView , attribute: .bottom, multiplier: 1.0, constant: -216)
            viewController?.view.addConstraint(datePickerBottomSpacingConstraint)
            
            viewController?.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[datePickerContainerView]|", options: .directionLeftToRight, metrics: nil, views: ["datePickerContainerView": datePickerContainerView]))
            
            datePickerContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: String(format: "H:|[dateToolBarView]|"), options: .directionLeftToRight, metrics: nil, views: ["dateToolBarView": dateToolBarView]))
            datePickerContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: String(format: "V:|[dateToolBarView][datePickerView]|"), options: .directionLeftToRight, metrics: nil, views: ["dateToolBarView": dateToolBarView, "datePickerView": datePickerView]))
            datePickerContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[datePickerView]|", options: .directionLeftToRight, metrics: nil, views: ["datePickerView": datePickerView]))
        }
    }
    
    func setupAccesorView() {
        if (accesoryView == nil) {
            accesoryView = UIView(frame: CGRect.zero)
            accesoryView.isHidden = true
            accesoryView.translatesAutoresizingMaskIntoConstraints = false
            let viewController = self.delegate as? UIViewController
            viewController?.view.addSubview(accesoryView)
            
            if (txtField != nil) {
                accesoryView.addSubview(txtField)
            }
            if (btnDone == nil) {
                btnDone = UIButton(frame: CGRect.zero)
                btnDone.translatesAutoresizingMaskIntoConstraints = false
                btnDone.titleLabel?.font = font
                accesoryView.addSubview(btnDone)
            }
            
            textFieldBottomSpacingConstraint = NSLayoutConstraint(item: accesoryView, attribute: .bottom, relatedBy: .equal, toItem: viewController?.view ?? UIView(), attribute: .bottom, multiplier: 1.0, constant: 0)
            viewController?.view.addConstraint(textFieldBottomSpacingConstraint)
            
            viewController?.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[accesoryView]|", options: .directionLeftToRight, metrics: nil, views: ["accesoryView": accesoryView]))
            
            let width = (self.frame.size.width - 105)
            accesoryView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: String(format: "H:|-20-[txtField(%f)]-5-[btnDone(%d)]|",width,80), options: .directionLeftToRight, metrics: nil, views: ["txtField": txtField, "btnDone": btnDone]))
            accesoryView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[txtField]|", options: .directionLeftToRight, metrics: nil, views: ["txtField": txtField]))
            accesoryView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[btnDone]|", options: .directionLeftToRight, metrics: nil, views: ["btnDone": btnDone]))
        }
    }
    
    func keyboardStateChanged(notification: NSNotification) {
        if notification.name == .UIKeyboardWillHide {
            accesoryView.isHidden = true
            textFieldBottomSpacingConstraint.constant = 0
        }else if notification.name == .UIKeyboardWillShow {
            accesoryView.isHidden = false
            if let userInfo = notification.userInfo as? [String: AnyObject] {
                if let keyboardRect = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue {
                    let viewController = self.delegate as? UIViewController
                    let keyboardFrame = viewController?.view.convert(keyboardRect.cgRectValue, from: nil) //this is it!
                    textFieldBottomSpacingConstraint.constant = -(keyboardFrame?.size.height)!
                }
            }
        }
    }
    
    fileprivate func fetchrangeOfActionWords() {
        for dictionary in actionWords {
                let lblString = labelText?.string
                let string = dictionary[ALActionWordName] as? String
                let range = lblString?.range(of: string!)
                let from = range?.lowerBound.samePosition(in: (lblString?.utf16)!)
                let to = range?.upperBound.samePosition(in: (lblString?.utf16)!)
                var dict = [String:Any]()
                dict[ALActionWordName] = string
                let stringrange = NSRange(location: (lblString?.utf16.distance(from: (lblString?.utf16.startIndex)!, to: from!))!,
                                    length: (lblString?.utf16.distance(from: from!, to: to!))!)
                dict["range"] = stringrange
                var effectiveRange = NSRange()

                let atrributes = labelText?.attributes(at: (lblString?.utf16.distance(from: (lblString?.utf16.startIndex)!, to: from!))!, longestEffectiveRange: &effectiveRange, in: stringrange)
                dict["effectiveRange"] = effectiveRange
                dict["attributes"] = atrributes
                dict[ALActionWordType] = dictionary[ALActionWordType] as? ActionType
                dict[ALActionWordOptions] = dictionary[ALActionWordOptions] as? [String]
                dict[ALActionWordDateType] = dictionary[ALActionWordDateType] as? UIDatePickerMode
                dict[ALActionWordDateFormat] = dictionary[ALActionWordDateFormat] as? String
                actionWordRange.append(dict)
        }
    }
    
    fileprivate func showGeneralPicker(_ show: Bool) {
        pickerView.reloadAllComponents()
        self.txtField.resignFirstResponder()
        UIView.animate(withDuration: 0.3) {
            if show && self.pickerBottomSpacingConstraint.constant != 0  {
                self.pickerBottomSpacingConstraint.constant = 0
                self.pickerContainerView.isHidden = false
            }else if !show && self.pickerBottomSpacingConstraint.constant == 0 {
                self.pickerBottomSpacingConstraint.constant -= self.pickerContainerView.frame.size.height
                self.pickerContainerView.isHidden = true
            }
            let viewController = self.delegate as? UIViewController
            viewController?.view.layoutIfNeeded()
        }
    }

    fileprivate func showDatePicker(_ show: Bool) {
        self.txtField.resignFirstResponder()
        UIView.animate(withDuration: 0.3) {
            if show && self.datePickerBottomSpacingConstraint.constant != 0  {
                self.datePickerBottomSpacingConstraint.constant = 0
                self.datePickerContainerView.isHidden = false
            }else if !show && self.datePickerBottomSpacingConstraint.constant == 0 {
                self.datePickerBottomSpacingConstraint.constant -= self.datePickerContainerView.frame.size.height
                self.datePickerContainerView.isHidden = true
            }
            let viewController = self.delegate as? UIViewController
            viewController?.view.layoutIfNeeded()
        }
    }
    
    private func actionForSelectedText(type : ActionType) {
        
        switch type {
        case .DropDown:
            setupDropDownView()
            showGeneralPicker(true)
            delegate?.actionLabelDidSelect?(self, selectedWord: (selectedStringDict[ALActionWordName] as? String)!, range: (selectedStringDict["range"] as? NSRange)!)
            
        case .DateDropDown:
            setupDateDropDownView()
            datePickerView.datePickerMode = selectedStringDict[ALActionWordDateType] as! UIDatePickerMode
            showDatePicker(true)
            delegate?.actionLabelDidSelect?(self, selectedWord: (selectedStringDict[ALActionWordName] as? String)!, range: (selectedStringDict["range"] as? NSRange)!)
            
        case .EditText:
            setupAccesorView()
            accesoryView.isHidden = false
            txtField.text = selectedStringDict[ALActionWordName] as? String
            txtField.becomeFirstResponder()
            //selectedIndex += (selectedIndex < actionWords.count) ? 1 : 0
            delegate?.actionLabelDidSelect?(self, selectedWord: (selectedStringDict[ALActionWordName] as? String)!, range: (selectedStringDict["range"] as? NSRange)!)
            
        default:
            delegate?.actionLabelDidSelect?(self, selectedWord: (selectedStringDict[ALActionWordName] as? String)!, range: (selectedStringDict["range"] as? NSRange)!)


        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let range = NSRange(location: 0, length: textStorage.length)
        let newOrigin = textOrigin(inRect: rect)
        layoutManager.drawBackground(forGlyphRange: range, at: newOrigin)
        layoutManager.drawGlyphs(forGlyphRange: range, at: newOrigin)
    }
    
    override var canBecomeFirstResponder: Bool {
        return txtField.canBecomeFirstResponder
    }
    
    override func resignFirstResponder() -> Bool {
        return txtField.resignFirstResponder()
    }
    
    override func becomeFirstResponder() -> Bool {
        return txtField.resignFirstResponder()
    }
    
    @objc private func textDidChange(notification: Notification) {
        if let field = notification.object as? UITextField, field == txtField {
            delegate?.actionLabelTextOptionDidChangeText?(self)
        }
    }
    
    //MARK: IBActions
    @objc fileprivate func btnDateAddAction(_ sender: UIButton) {
        var range = selectedStringDict["range"] as! NSRange
        if range.length <= (labelText?.length)!{
            var string = labelText?.string
            let word = selectedStringDict[ALActionWordName] as! String
            let dateFormatter = DateFormatter()
            dateFormatter.amSymbol = "am"
            dateFormatter.pmSymbol = "pm"
            dateFormatter.dateFormat = selectedStringDict[ALActionWordDateFormat] as! String
            let text = dateFormatter.string(from: datePickerView.date)
            string = string?.replacingOccurrences(of: word, with: text, options: String.CompareOptions.literal, range: nil)
            //agar var effectiveRange = NSRange()
            if let value = labelText, let length = (labelText?.length) {
                labelText = NSMutableAttributedString(string: string!)
                value.beginEditing()
                value.enumerateAttributes(in: NSRange(0..<length), options: NSAttributedString.EnumerationOptions.reverse, using: { (attr : [String : Any], range : NSRange, _) in
                    var newRange = range
                    if range.length + range.location > (labelText?.length)! {
                        if let newLength = (labelText?.length) {
                            let length1 = (newLength - range.location)
                            newRange = NSMakeRange(range.location,length1)
                        }
                    }
                    labelText?.addAttributes(attr, range: newRange)
                })
                value.endEditing()
            }
            
            range.length = text.characters.count
            labelText?.addAttributes(selectedStringDict["attributes"] as! [String : Any], range: range)
            actionWords = actionWords.filter(){$0[ALActionWordName] as? String != word}
            actionWords.append([ALActionWordName:text, ALActionWordType: selectedStringDict[ALActionWordType] ?? ActionType.Action, ALActionWordDateFormat:selectedStringDict[ALActionWordDateFormat] ?? "MMM dd, yyyy" , ALActionWordDateType: selectedStringDict[ALActionWordDateType] ?? UIDatePickerMode.date])
            actionWordRange.removeAll()
            fetchrangeOfActionWords()
            delegate?.actionLabelDidChangeDateValue?(self, selectedWord: text, index: 0, range: range)
        }
        showDatePicker(false)
    }
    
    @objc fileprivate func btnDateCancelAction(_ sender: UIButton) {
        showDatePicker(false)
        delegate?.actionLabelDidCancelDateSelect?(self)
    }
    
    @objc fileprivate func btnAddAction(_ sender: UIButton) {
        let index = pickerView.selectedRow(inComponent: 0)
        var range = selectedStringDict["range"] as! NSRange
        if range.length <= (labelText?.length)!{
            var string = labelText?.string
            let word = selectedStringDict[ALActionWordName] as! String
            let array = selectedStringDict[ALActionWordOptions] as? [String]
            let text = array?[index] ?? ""
            string = string?.replacingOccurrences(of: word, with: text, options: String.CompareOptions.literal, range: nil)
            //agar var effectiveRange = NSRange()
            if let value = labelText, let length = (labelText?.length) {
                labelText = NSMutableAttributedString(string: string!)
                value.beginEditing()
                value.enumerateAttributes(in: NSRange(0..<length), options: NSAttributedString.EnumerationOptions.reverse, using: { (attr : [String : Any], range : NSRange, _) in
                    var newRange = range
                    if range.length + range.location > (labelText?.length)! {
                        if let newLength = (labelText?.length) {
                            let length1 = (newLength - range.location)
                            newRange = NSMakeRange(range.location,length1)
                        }
                    }
                    labelText?.addAttributes(attr, range: newRange)
                })
                value.endEditing()
                
            }
            
            range.length = text.characters.count
            labelText?.addAttributes(selectedStringDict["attributes"] as! [String : Any], range: range)
            actionWords = actionWords.filter(){$0[ALActionWordName] as! String != word}
            actionWords.append([ALActionWordName:text, ALActionWordType: selectedStringDict[ALActionWordType] ?? ActionType.Action, ALActionWordOptions:  selectedStringDict[ALActionWordOptions] ?? [String]()])
            actionWordRange.removeAll()
            fetchrangeOfActionWords()
            delegate?.actionLabelDidChangeTextValue?(self, selectedWord: text, index: index, range: range)
        }
        showGeneralPicker(false)
    }
    
    @objc fileprivate func btnCancelAction(_ sender: UIButton) {
        showGeneralPicker(false)
        delegate?.actionLabelDidCancelOptionSelect?(self)
    }
    
    @objc fileprivate func btnDoneAction(_ sender: UIButton) {
        var range = selectedStringDict["range"] as! NSRange
        if range.length <= (labelText?.length)!{
            var string = labelText?.string
            let word = selectedStringDict[ALActionWordName] as! String
            let text = txtField.text ?? ""
            string = string?.replacingOccurrences(of: word, with: text, options: String.CompareOptions.literal, range: nil)
            //agar var effectiveRange = NSRange()
            if let value = labelText, let length = (labelText?.length) {
                labelText = NSMutableAttributedString(string: string!)
                value.beginEditing()
                value.enumerateAttributes(in: NSRange(0..<length), options: NSAttributedString.EnumerationOptions.reverse, using: { (attr : [String : Any], range : NSRange, _) in
                    var newRange = range
                    if range.length + range.location > (labelText?.length)! {
                        if let newLength = (labelText?.length) {
                            let length1 = (newLength - range.location)
                            newRange = NSMakeRange(range.location,length1)
                        }
                    }
                    labelText?.addAttributes(attr, range: newRange)
                })
                value.endEditing()
                
            }
            range.length = text.characters.count
            labelText?.addAttributes(selectedStringDict["attributes"] as! [String : Any], range: range)
            actionWords = actionWords.filter(){$0[ALActionWordName] as! String != word}
            actionWords.append([ALActionWordName:text, ALActionWordType: selectedStringDict[ALActionWordType] ?? ActionType.Action, ALActionWordOptions:  selectedStringDict[ALActionWordOptions] ?? [String]()])
            actionWordRange.removeAll()
            fetchrangeOfActionWords()
            delegate?.actionLabelDidChangeOptionValue?(self, selectedWord: text, index: 0, range: range)
        }
        _ = self.resignFirstResponder()
    }

    
    
    //MARK: Auto Layout
    open override var intrinsicContentSize: CGSize {
        _ = super.intrinsicContentSize
        textContainer.size = CGSize(width: self.frame.size.width, height: CGFloat.greatestFiniteMagnitude)
        let size = layoutManager.usedRect(for: textContainer)
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
    
    fileprivate func textOrigin(inRect rect: CGRect) -> CGPoint {
        let usedRect = layoutManager.usedRect(for: textContainer)
        heightCorrection = (rect.height - usedRect.height)/2
        let glyphOriginY = heightCorrection > 0 ? rect.origin.y + heightCorrection : rect.origin.y
        return CGPoint(x: rect.origin.x, y: glyphOriginY)
    }

    
    
    //MARK: Touch Event
    @objc private func tap(_ gestureRecognizer: UITapGestureRecognizer) {
        
        for dict in actionWordRange {
            let linkRange = dict["range"] as! NSRange
            guard textStorage.length > 0 else {
                return
            }
            let location = gestureRecognizer.location(in: self)
            var correctLocation = location
            correctLocation.y -= heightCorrection
            let boundingRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: 0, length: textStorage.length), in: textContainer)
            guard boundingRect.contains(correctLocation) else {
                return
            }
            
            let index = layoutManager.glyphIndex(for: correctLocation, in: textContainer)
            
            if index >= linkRange.location && index <= linkRange.location + linkRange.length {
                selectedStringDict = dict
                actionForSelectedText(type: dict[ALActionWordType] as! ActionType)
                break
            }
            selectedIndex += (selectedIndex < actionWords.count) ? 1 : 0
        }
    }

}

//MARK: Picker Data Source
extension ActionLabel : UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let array = selectedStringDict[ALActionWordOptions] as? [String]
        return array?.count ?? 0
    }
}

//MARK: Picker Delegate
extension ActionLabel : UIPickerViewDelegate {
    // these methods return either a plain NSString, a NSAttributedString, or a view (e.g UILabel) to display the row for the component.
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let array = selectedStringDict[ALActionWordOptions] as? [String]
        return array?[row] ?? ""
    }
}

//MARK: Text Field Delegates
extension ActionLabel: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return delegate?.actionLabellTextOptionShouldBeginEditing?(self) ?? true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.actionLabelTextOptionDidBeginEditing?(self)
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return delegate?.actionLabelTextOptionShouldEndEditing?(self) ?? true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField){
        delegate?.actionLabelTextOptionDidEndEditing?(self)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool  {
        return delegate?.actionLabelTextOption?(self, shouldChangeCharactersIn: range, replacementString: string) ?? true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return delegate?.actionLabelTextOptionShouldClear?(self) ?? true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //selectedIndex += (selectedIndex < actionWords.count) ? 1 : 0
        //self.btnDoneAction(UIButton())
        
        return delegate?.actionLabelTextOptionShouldReturn?(self) ?? true
    }
}

