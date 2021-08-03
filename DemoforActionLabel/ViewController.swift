//
//  ViewController.swift
//  DemoforActionLabel
//
//  Created by Nilesh Phadtare on 18/05/17.
//  Copyright © 2017 Nilesh Phadtare. All rights reserved.
//

import UIKit

class ViewController: UIViewController, ActionLabelTextOptionViewDelegate {
   
    @IBOutlet weak var actionLabel: ActionLabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let string = NSMutableAttributedString(string: "I was lose")
        string.append(NSMutableAttributedString(string: " 10", attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        string.append(NSMutableAttributedString(string: " kg"))
        string.append(NSMutableAttributedString(string: " on May 21, 2017"))
        actionLabel.labelText = string
        actionLabel.actionWords =  [[ALActionWordName : "10", ALActionWordType : ActionType.EditText, ALActionOrder : 0, ALActionWordIndex : 0],[ALActionWordName : "kg", ALActionWordType : ActionType.DropDown, ALActionWordOptions: ["kg", "lbs"], ALActionOrder : 1, ALActionWordIndex : 1],[ALActionWordName : "May 21, 2017", ALActionWordType : ActionType.DateDropDown, ALActionWordDateType: UIDatePicker.Mode.date, ALActionWordDateFormat: "MMM dd, yyyy", ALActionOrder : 2, ALActionWordIndex : 2]]
        actionLabel.delegate = self
        actionLabel.textAlignment = .left
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func actionLabelDidSelect(_ actionLabelTextField: ActionLabel, selectedWord: String, range: NSRange, actionType: ActionType) -> Bool {
        return true
    }
}

