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
        string.append(NSMutableAttributedString(string: " 10", attributes: [NSForegroundColorAttributeName : UIColor.lightGray, NSFontAttributeName : UIFont.systemFont(ofSize: 16)]))
        string.append(NSMutableAttributedString(string: " kg"))
        string.append(NSMutableAttributedString(string: " on May 21, 2017"))
        actionLabel.labelText = string
        actionLabel.actionWords =  [[ALActionWordName : "10", ALActionWordType : ActionType.EditText],[ALActionWordName : "kg", ALActionWordType : ActionType.DropDown, ALActionWordOptions: ["kg", "lbs"]],[ALActionWordName : "May 21, 2017", ALActionWordType : ActionType.DateDropDown, ALActionWordDateType: UIDatePickerMode.date, ALActionWordDateFormat: "MMM dd, yyyy"]]
        actionLabel.delegate = self
        actionLabel.textAlignment = .left
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

