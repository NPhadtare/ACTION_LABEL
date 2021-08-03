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
    
    @objc func actionLabelDidSelect(_ actionLabelTextField: ActionLabel, selectedWord: String, range: NSRange, actionType: ActionType) -> Bool
    
    @objc optional func actionLabelDidChangeTextValue(_ actionLabelTextField: ActionLabel, selectedWord: String, index: Int, range: NSRange, order: Int)
    
    @objc optional func actionLabelDidChangeOptionValue(_ actionLabelTextField: ActionLabel, selectedWord: String, index: Int, range: NSRange, order: Int)
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

let downArrow = " ▾"
let ALActionWordName = "string"
let ALActionWordType = "type"
let ALActionWordOptions = "Options"
let ALActionWordDateType = "dateType"
let ALActionWordDateFormat = "dateFormat"
let ALActionOrder = "order"
let ALActionWordIndex = "index"

class ActionLabel: UIView {
    
    struct Constants {
        static let doneString = "Done"
        static let plsEnterSomeValueString =  "Please enter some value."
        static let valueCannotBeZeroString = "Value can not be zero."
    }
    public var txtField: UITextField! {
        didSet {
            txtField.isHidden = true
        }
    }
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
    
    fileprivate var pickerContainerView: UIView!{
        didSet{
            if #available(iOS 13.0, *) {
                pickerContainerView.backgroundColor = UIColor.systemGray2
            } else {
                // Fallback on earlier versions
            }
        }
    }
    fileprivate var pickerView: UIPickerView!
    fileprivate var toolBarView: UIToolbar!
    
    fileprivate var datePickerContainerView: UIView!{
        didSet{
            if #available(iOS 13.0, *) {
                datePickerContainerView.backgroundColor = UIColor.systemGray2
            } else {
                // Fallback on earlier versions
            }
        }
    }
    fileprivate var datePickerView: UIDatePicker!
    fileprivate var dateToolBarView: UIToolbar!
    
    fileprivate var btnDone: UIButton! {
        didSet {
            btnDone.setTitle(Constants.doneString, for: .normal)
            btnDone.setTitleColor(UIColor.blue, for: .normal)
            btnDone.addTarget(self, action: #selector(ActionLabel.btnDoneAction(_:)), for: .touchUpInside)
        }
    }
    
    fileprivate var selectedStringDict = [String : Any]()
    fileprivate var _customizing: Bool = true
    fileprivate var selectedRange : NSRange?
    fileprivate var selectedLocation : CGPoint?
    var selectedDate : Date? = Date()
    
    //var labelTitleColor = UIColor.black
    //var labelTitleFont = UIFont.systemFont(ofSize: 20)
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
    
    var keypadMode = UIKeyboardType.default {
        didSet {
            txtField.keyboardType = keypadMode
            updateTextStorage(parseText: false)
        }
    }
    
    var numberOfLines = 0 {
        didSet { textContainer.maximumNumberOfLines = numberOfLines; textContainer.heightTracksTextView = true; self.layoutManager.textContainerChangedGeometry(self.textContainer)
            self.setNeedsDisplay(); updateTextStorage(parseText: false) }
    }
    
    var lineBreakMode =  NSLineBreakMode.byWordWrapping {
        didSet { textContainer.lineBreakMode = lineBreakMode; updateTextStorage(parseText: false) }
    }
    
    var invalidContent = false { didSet { setNeedsDisplay() } }
    var invalidContentColor = UIColor.red { didSet { setNeedsDisplay() } }
    var fieldTitlePadding: CGFloat = 0 { didSet { fieldTitleRightPaddingConstraint.constant = fieldTitlePadding; fieldTitleLeftPaddingConstraint.constant = fieldTitlePadding } }
    
    var labelText: NSMutableAttributedString?
    
    var actionWords = [[String: Any]]() {
        didSet {
            makeUserIdentifiebleActionWords()
            fetchrangeOfActionWords()
            updateTextStorage(parseText: false)
        }
    }
    var text: String? {
        get { return txtField.text }
        set { txtField.text = newValue }
    }
    var placeholder: String? {
        get { return txtField.placeholder }
        set { txtField.placeholder = newValue }
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
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(ActionLabel.keyboardStateChanged(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ActionLabel.keyboardStateChanged(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.heightTracksTextView = true
        textContainer.lineBreakMode = lineBreakMode
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(ActionLabel.tap(_ :)))
        gesture.cancelsTouchesInView = false
        self.addGestureRecognizer(gesture)
        
        // add observer
        NotificationCenter.default.addObserver(self, selector: #selector(ActionLabel.textDidChange(notification:)), name: UITextField.textDidChangeNotification, object: txtField)
        
    }
    
    fileprivate func updateTextStorage(parseText: Bool = true) {
        if _customizing { return }
        // clean up previous active elements
        guard let attributedText = labelText, attributedText.length > 0 else {
            //clearActiveElements()
            textStorage.setAttributedString(NSAttributedString())
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
            return
        }
        
        let mutAttrString = addLineBreak(attributedText)
        
        addLinkAttribute(mutAttrString)
        textStorage.setAttributedString(mutAttrString)
        _customizing = true
        //text = mutAttrString.string
        _customizing = false
        invalidateIntrinsicContentSize()
        setNeedsDisplay()
    }
    
    /// add link attribute
    fileprivate func addLinkAttribute(_ mutAttrString: NSMutableAttributedString) {
        var range = NSRange(location: 0, length: 0)
        let attributes = mutAttrString.attributes(at: 0, effectiveRange: &range)
        mutAttrString.addAttributes(attributes, range: range)
        mutAttrString.setAttributes(attributes, range: range)
    }
    
    @IBInspectable public var lineSpacing: CGFloat = 2 {
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
        
        let paragraphStyle = attributes[NSAttributedString.Key.paragraphStyle] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = lineBreakMode
        paragraphStyle.alignment = textAlignment
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.minimumLineHeight = minimumLineHeight > 0 ? minimumLineHeight: self.font.pointSize * 1.14
        attributes[NSAttributedString.Key.paragraphStyle] = paragraphStyle
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
            if #available(iOS 14.0, *) {
                datePickerView.preferredDatePickerStyle = .wheels
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
            accesoryView = UIView(frame: .zero)
            accesoryView.isHidden = true
            accesoryView.translatesAutoresizingMaskIntoConstraints = false
            accesoryView.backgroundColor = UIColor.white
            let viewController = self.delegate as? UIViewController
            viewController?.view.addSubview(accesoryView)
            
            if (txtField != nil) {
                accesoryView.addSubview(txtField)
            }
            if (btnDone == nil) {
                btnDone = UIButton(type: .custom)
                btnDone.translatesAutoresizingMaskIntoConstraints = false
                btnDone.titleLabel?.font = font
                btnDone.setContentHuggingPriority(UILayoutPriority(rawValue: 252), for: .horizontal)
                accesoryView.addSubview(btnDone)
            }
            
            if let accesoryView = accesoryView, let txtField = txtField, let btnDone = btnDone{
                
                textFieldBottomSpacingConstraint = NSLayoutConstraint(item: accesoryView, attribute: .bottom, relatedBy: .equal, toItem: viewController?.view ?? UIView(), attribute: .bottom, multiplier: 1.0, constant: 0)
                viewController?.view.addConstraint(textFieldBottomSpacingConstraint)
                
                viewController?.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[accesoryView]|", options: .directionLeftToRight, metrics: nil, views: ["accesoryView": accesoryView]))
                
                accesoryView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: String(format: "H:|-[txtField]-[btnDone]-|"), options: .directionLeftToRight, metrics: nil, views: ["txtField": txtField, "btnDone": btnDone]))
                accesoryView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[txtField]-|", options: .directionLeftToRight, metrics: nil, views: ["txtField": txtField]))
                NSLayoutConstraint(item: btnDone, attribute: .centerY, relatedBy: .equal, toItem: txtField, attribute: .centerY, multiplier: 1.0, constant: 0.0).isActive = true
            }            
        }
    }
    
    @objc func keyboardStateChanged(notification: NSNotification) {
        if notification.name == UIResponder.keyboardWillHideNotification {
            textFieldBottomSpacingConstraint.constant = 0
            // animate(for: 0.5){ [weak self] (success) in
            self.accesoryView.isHidden = true
            //}
        }else if notification.name == UIResponder.keyboardWillShowNotification {
            accesoryView.isHidden = false
            if let userInfo = notification.userInfo as? [String: AnyObject] {
                if let keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                    let viewController = self.delegate as? UIViewController
                    let keyboardFrame = viewController?.view.convert(keyboardRect.cgRectValue, from: nil) //this is it!
                    textFieldBottomSpacingConstraint.constant = -(keyboardFrame?.size.height)!
                    UIView.animate(withDuration: 0.5, animations: { [weak self] in
                        self?.layoutIfNeeded()
                    }) { (success) in}
                }
            }
        }
    }
    
    func makeUserIdentifiebleActionWords(){
        var index = 0
        var previouseRange: NSRange?
        for dictionary in actionWords {
            let lblString = labelText?.string ?? ""
            let string = dictionary[ALActionWordName] as? String ?? ""
            index = dictionary[ALActionWordIndex] as? Int ?? 0
            var range = lblString.range(of: string)
            if index > 0 {
                if let preR = previouseRange{
                    let newRange = NSRange(location: (preR.location+preR.length+1), length: (lblString.count-(preR.location+preR.length+1)))
                    range = lblString.range(of: string, options: [], range: Range(newRange, in: lblString))
                }
            }
            var stringrange : NSRange
            if range == nil {
                stringrange = selectedStringDict["range"] as? NSRange ?? NSMakeRange(0, 1)
                stringrange.length = 3
            } else {
                let from = range?.lowerBound.samePosition(in: (lblString.utf16))
                let to = range?.upperBound.samePosition(in: (lblString.utf16))
                stringrange = NSRange(location: (lblString.utf16.distance(from: (lblString.utf16.startIndex), to: from!)),
                                      length: (lblString.utf16.distance(from: from!, to: to!)))
            }
            let type = dictionary[ALActionWordType] as? ActionType ?? ActionType.Action
            var attr = labelText?.attributes(at: stringrange.location, effectiveRange: nil)
            attr?[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.single.rawValue
            attr?[NSAttributedString.Key.underlineColor] = UIColor.black
            if string == "---"{
                attr?[NSAttributedString.Key.foregroundColor] = UIColor.darkGray
            } else {
                attr?[NSAttributedString.Key.foregroundColor] = UIColor.black
            }
            previouseRange = stringrange
            labelText?.setAttributes(attr, range: stringrange)
            switch type {
                case .DropDown:
                    
                    labelText?.insert(NSAttributedString(string: downArrow), at: stringrange.location+stringrange.length)
                    labelText?.addAttributes([NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue, NSAttributedString.Key.underlineColor: UIColor.black, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20), NSAttributedString.Key.foregroundColor: UIColor.black], range: NSMakeRange(stringrange.location+stringrange.length, downArrow.count))
                //actionWords.remove(at: index)
                //actionWords.insert(newDictionary, at: index)
                
                case .DateDropDown:
                    labelText?.insert(NSAttributedString(string: downArrow), at: stringrange.location+stringrange.length)
                    labelText?.addAttributes([NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue, NSAttributedString.Key.underlineColor: UIColor.black, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20), NSAttributedString.Key.foregroundColor: UIColor.black], range: NSMakeRange(stringrange.location+stringrange.length, downArrow.count))
                //actionWords.remove(at: index)
                //actionWords.insert(newDictionary, at: index)
                
                default:
                    break
            }
            index += downArrow.count
        }
        updateString()
    }
    fileprivate func updateString() {
        let labelString = labelText?.string ?? ""
        if let range = labelString.range(of:(downArrow + downArrow)), let from = range.lowerBound.samePosition(in: (labelString.utf16)), let to = range.upperBound.samePosition(in: (labelString.utf16)) {
            let stringrange = NSRange(location: (labelString.utf16.distance(from: (labelString.utf16.startIndex), to: from)),
                                      length: (labelString.utf16.distance(from: from, to: to)))
            labelText?.replaceCharacters(in: stringrange, with: downArrow)
            if let value = labelText, let length = (labelText?.length) {
                value.beginEditing()
                value.enumerateAttributes(in: NSRange(0..<length), options: NSAttributedString.EnumerationOptions(rawValue: 0), using: { (attr : [NSAttributedString.Key : Any], attRange : NSRange, _) in
                    let newRange = attRange
                    labelText?.addAttributes(attr, range: newRange)
                    if newRange.location+newRange.length >= length {
                        updateString()
                    }
                })
                value.endEditing()
            }
        }
    }
    
    fileprivate func fetchrangeOfActionWords() {
        actionWordRange.removeAll()
        var indexDuplicate = 0
        var previouseRange: NSRange?
        for dictionary in actionWords {
            let lblString = labelText?.string
            let string = dictionary[ALActionWordName] as? String ?? ""
            indexDuplicate = dictionary[ALActionWordIndex] as? Int ?? 0
            var stringrange = NSRange()
            var result: [String.Index] = []
            if var start = lblString?.startIndex, let endIndex = lblString?.endIndex {
                while let range = lblString?.range(of: lblString ?? "", options: .literal, range: start..<endIndex) {
                    result.append(range.lowerBound)
                    start = range.upperBound
                }
            }
            let indexes = result

            var dict = [String:Any]()
            
            let array = actionWordRange.filter(){$0[ALActionWordName] as? String == string}
            let order = array.count
            
            if array.count > 0, (indexes.count) > 0, (indexes.count)>=order, let str = lblString{
                let location = indexes[order]
                if let toIndex = location.samePosition(in: (str.utf16)) {
                    let fromIndex = str.utf16.startIndex
                    let from = str.utf16.distance(from: fromIndex, to: toIndex)
                    stringrange = NSMakeRange(from, string.count)
                }
            }else {
                var range = (lblString?.range(of: string))
                if indexDuplicate > 0 {
                    if let preR = previouseRange{
                        let newRange = NSRange(location: (preR.location+preR.length+1), length: ((lblString?.count ?? 0)-(preR.location+preR.length+1)))
                        range = lblString?.range(of: string, options: [], range: Range(newRange, in: lblString ?? ""))
                    }
                }
                if range == nil {
                    stringrange = selectedStringDict["range"] as? NSRange ?? NSMakeRange(0, 1)
                    stringrange.length = 3
                } else if let str = lblString, let from = range?.lowerBound.samePosition(in: str.utf16), let to = range?.upperBound.samePosition(in: str.utf16) {
                    dict[ALActionWordName] = string
                    stringrange = NSRange(location: str.utf16.distance(from: str.utf16.startIndex, to: from), length: str.utf16.distance(from: from, to: to))
                }
            }
            dict["range"] = stringrange
            previouseRange = stringrange
            dict[ALActionWordType] = dictionary[ALActionWordType] as? ActionType
            dict[ALActionWordName] = dictionary[ALActionWordName] as? String
            dict[ALActionWordOptions] = dictionary[ALActionWordOptions] as? [String]
            dict[ALActionWordDateType] = dictionary[ALActionWordDateType] as? UIDatePicker.Mode
            dict[ALActionWordDateFormat] = dictionary[ALActionWordDateFormat] as? String
            dict[ALActionOrder] = dictionary[ALActionOrder] as? Int
            dict[ALActionWordIndex] = dictionary[ALActionWordIndex] as? Int
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
                self.setupDropDownView()
                let isAction = delegate?.actionLabelDidSelect(self, selectedWord: (selectedStringDict[ALActionWordName] as? String)!, range: (selectedStringDict["range"] as? NSRange)! , actionType: type)
                if isAction! {
                    self.txtField.resignFirstResponder()
                    showGeneralPicker(true)
                }
            case .DateDropDown:
                self.setupDateDropDownView()
                let isAction = delegate?.actionLabelDidSelect(self, selectedWord: (selectedStringDict[ALActionWordName] as? String)!, range: (selectedStringDict["range"] as? NSRange)!, actionType: type)
                if isAction! {
                    let pickerMode = selectedStringDict[ALActionWordDateType] as! UIDatePicker.Mode
                    self.txtField.resignFirstResponder()
                    datePickerView.datePickerMode = pickerMode
                    showDatePicker(true)
                }
                
            case .EditText:
                let isAction = delegate?.actionLabelDidSelect(self, selectedWord: (selectedStringDict[ALActionWordName] as? String)!, range: (selectedStringDict["range"] as? NSRange)!, actionType: type)
                
                if isAction! {
                    setupAccesorView()
                    accesoryView.isHidden = false
                    if let text = selectedStringDict[ALActionWordName] as? String, text == "---" {
                        txtField.text = ""
                    } else {
                        txtField.text = selectedStringDict[ALActionWordName] as? String
                    }
                    txtField.selectAll(txtField.text)
                    
                    if txtField.isFirstResponder == false{
                        txtField.becomeFirstResponder()
                    }
                    //selectedIndex += (selectedIndex < actionWords.count) ? 1 : 0
                }
            default:
                _ = delegate?.actionLabelDidSelect(self, selectedWord: (selectedStringDict[ALActionWordName] as? String)!, range: (selectedStringDict["range"] as? NSRange)!, actionType: type)
                
                
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
        self.accesoryView.isHidden = true
        return txtField.resignFirstResponder()
    }
    
    override func becomeFirstResponder() -> Bool {
        return txtField.becomeFirstResponder()
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
            dateFormatter.dateFormat = selectedStringDict[ALActionWordDateFormat] as? String
            let text = dateFormatter.string(from: datePickerView.date)
            string = string?.replacingOccurrences(of: word, with: text, options: String.CompareOptions.literal, range: nil)
            //agar var effectiveRange = NSRange()
            if let value = labelText, let length = (labelText?.length) {
                labelText = NSMutableAttributedString(string: string!)
                value.beginEditing()
                
                value.enumerateAttributes(in: NSRange(0..<length), options: NSAttributedString.EnumerationOptions.reverse, using: { (attr, range, _) in
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
            
            range.length = text.count
            //labelText?.addAttributes(selectedStringDict["attributes"] as! [NSAttributedString.Key : Any], range: range)
            actionWords = actionWords.filter(){$0[ALActionWordName] as? String != word}
            actionWords.append([ALActionWordName:text, ALActionWordType: selectedStringDict[ALActionWordType] ?? ActionType.Action, ALActionWordDateFormat:selectedStringDict[ALActionWordDateFormat] ?? "MMM dd, yyyy" , ALActionWordDateType: selectedStringDict[ALActionWordDateType] ?? UIDatePicker.Mode.date])
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
        let order = selectedStringDict[ALActionOrder]
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
                value.enumerateAttributes(in: NSRange(0..<length), options: NSAttributedString.EnumerationOptions.reverse, using: { (attr, range, _) in
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
            
            range.length = text.count
//            labelText?.addAttributes(selectedStringDict["attributes"] as! [NSAttributedString.Key : Any], range: range)
            actionWords = actionWords.filter(){$0[ALActionWordName] as! String != word}
            actionWords.append([ALActionWordName:text, ALActionWordType: selectedStringDict[ALActionWordType] ?? ActionType.Action, ALActionWordOptions:  selectedStringDict[ALActionWordOptions] ?? [String]()])
            actionWordRange.removeAll()
            fetchrangeOfActionWords()
            delegate?.actionLabelDidChangeTextValue?(self, selectedWord: text, index: index, range: range, order: order as? Int ?? 0)
        }
        showGeneralPicker(false)
    }
    
    @objc fileprivate func btnCancelAction(_ sender: UIButton) {
        showGeneralPicker(false)
        delegate?.actionLabelDidCancelOptionSelect?(self)
    }
    @objc fileprivate func btnDoneAction(_ sender: UIButton) {
        let text = (txtField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? "")
        var message = ""
        if text.count == 0 {
            message = Constants.plsEnterSomeValueString
        }
        if Int(text) == 0 {
            message = Constants.valueCannotBeZeroString
        }
        if text == "---" {
            message = Constants.plsEnterSomeValueString
        }
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate{
            appDelegate.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
        self.manageTextFieldDone(text: text, isDone: true)
        let linkSelectedRange = selectedStringDict["range"] as! NSRange
        labelText?.removeAttribute(NSAttributedString.Key.backgroundColor , range:linkSelectedRange)
        _ = self.resignFirstResponder()
    }
    
    func manageTextFieldDone(text: String, isDone: Bool) {
        let range = selectedStringDict["range"] as! NSRange
        if range.length <= (labelText?.length)!{
            var string = labelText?.string
            let word = selectedStringDict[ALActionWordName] as! String
            let order = selectedStringDict[ALActionOrder]
            let index = selectedStringDict[ALActionWordIndex] as! Int
            if isDone == false {
                string = string?.replacingOccurrences(of: word, with: text, options: String.CompareOptions.literal, range: Range(range, in: string!))
                //agar var effectiveRange = NSRange()
                if let value = labelText, let length = (labelText?.length) {
                    labelText = NSMutableAttributedString(string: string!)
                    value.beginEditing()
                    value.enumerateAttributes(in: NSRange(0..<length), options: NSAttributedString.EnumerationOptions(rawValue: 0), using: { (attr : [NSAttributedString.Key : Any], attRange : NSRange, _) in
                        var newRange = attRange
                        //                    if range.length + range.location > (labelText?.length)! {
                        //                        if let newLength = (labelText?.length) {
                        //                            let length1 = (newLength - range.location)
                        //                            newRange = NSMakeRange(range.location,length1)
                        //                        }
                        //                    } else
                        if word.count < text.count, range.location<attRange.location{
                            newRange = NSMakeRange(attRange.location+(text.count - word.count),attRange.length)
                        } else if word.count > text.count, range.location<attRange.location{
                            newRange = NSMakeRange(attRange.location - (word.count - text.count),attRange.length)
                        } else if word.count > text.count, ((range.location==attRange.location+1) || (range.location==attRange.location)){
                            newRange = NSMakeRange(range.location,text.count)
                        } else if word.count < text.count, ((range.location==attRange.location+1) || (range.location==attRange.location)) {
                            newRange = NSMakeRange(range.location,text.count)
                        }
                        labelText?.addAttributes(attr, range: newRange)
                    })
                    value.endEditing()
                }
                
                //range.length = text.count
                //labelText?.addAttributes(selectedStringDict["attributes"] as! [String : Any], range: range)
                
                actionWords = actionWords.filter({ $0[ALActionWordName] as! String != word || $0[ALActionWordIndex] as! Int != index })
                actionWords.append([ALActionWordName:text, ALActionWordType: selectedStringDict[ALActionWordType] ?? ActionType.Action, ALActionWordOptions:  selectedStringDict[ALActionWordOptions] ?? [String](), ALActionOrder: selectedStringDict[ALActionOrder] ?? 0, ALActionWordIndex: selectedStringDict[ALActionWordIndex] ?? 0])
                actionWordRange.removeAll()
                fetchrangeOfActionWords()
            }
            var stringValue = text
            // if isDone == true {
            if stringValue == "---"{
                stringValue = ""
            }
            delegate?.actionLabelDidChangeTextValue?(self, selectedWord: stringValue, index: index , range: range, order: order as? Int ?? 0)
            //}
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        textContainer.size = CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude)
        invalidateIntrinsicContentSize()
    }
    
    //MARK: Auto Layout
    override var intrinsicContentSize: CGSize {
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
        if let linkSelectedRange = selectedStringDict["range"] {
            let range = linkSelectedRange as! NSRange
            labelText?.removeAttribute(NSAttributedString.Key.backgroundColor , range:range)
            setNeedsDisplay()
        }
        let location = gestureRecognizer.location(in: self)
        selectedLocation = location
        self.recogniseRange(location : location)
    }
    fileprivate func recogniseRange(location : CGPoint){
        for dict in actionWordRange {
            let linkRange = dict["range"] as! NSRange
            guard textStorage.length > 0 else {
                return
            }
            var correctLocation = location
            correctLocation.y -= heightCorrection
            let boundingRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: 0, length: textStorage.length), in: textContainer)
            guard boundingRect.contains(correctLocation) else {
                return
            }
            
            let index = layoutManager.glyphIndex(for: correctLocation, in: textContainer)
            let type = dict[ALActionWordType] as? ActionType ?? ActionType.Action
            let value = linkRange.location + linkRange.length+((type == ActionType.DropDown || type == ActionType.DateDropDown) ? 1 : 0)
            if index >= linkRange.location && index <= value {
                selectedStringDict = dict
                selectedRange = linkRange
                labelText?.addAttributes([NSAttributedString.Key.backgroundColor: UIColor.lightGray.withAlphaComponent(0.4)], range: linkRange)
                updateTextStorage()
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
        if let text = txtField.text {
            var input = (text as NSString).replacingCharacters(in: range, with: string)
            input = input.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if input.count > 0 {
                self.manageTextFieldDone(text: input, isDone: false)
                selectedStringDict[ALActionWordName] = input
                let lblString = labelText?.string ?? ""
                //let range = lblString.range(of: input)
                let newRange: Range<String.Index>?
                if let rangeOfSubString = selectedStringDict["range"] as? NSRange {
                    newRange = Range(NSRange(location: rangeOfSubString.location, length: input.count), in: lblString)
                } else {
                    newRange = lblString.range(of: input)
                }
                let range = lblString.range(of: input, options: [], range: newRange)
                var stringrange : NSRange?
                if range == nil {
                    stringrange = selectedRange
                } else {
                    let from = range?.lowerBound.samePosition(in: (lblString.utf16))
                    let to = range?.upperBound.samePosition(in: (lblString.utf16))
                    stringrange = NSRange(location: (lblString.utf16.distance(from: (lblString.utf16.startIndex), to: from!)),
                                          length: (lblString.utf16.distance(from: from!, to: to!)))
                }
                selectedStringDict["range"] = stringrange
                //actionForSelectedText(type: selectedStringDict[ALActionWordType] as! ActionType)
            } else{
                self.manageTextFieldDone(text: "---", isDone: false)
                selectedStringDict[ALActionWordName] = "---"
                selectedRange?.length = 3
                selectedStringDict["range"] = selectedRange
                actionForSelectedText(type: selectedStringDict[ALActionWordType] as! ActionType)
            }
        }
        return delegate?.actionLabelTextOption?(self, shouldChangeCharactersIn: range, replacementString: string) ?? true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return delegate?.actionLabelTextOptionShouldClear?(self) ?? true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        self.txtField.resignFirstResponder()
        return delegate?.actionLabelTextOptionShouldReturn?(self) ?? true
    }
}

