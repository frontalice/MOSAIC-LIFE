//
//  UIBarLabel.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/05/08.
//

import UIKit

class UIBarLabel: UIBarButtonItem {
    
    override init() {
        super.init()
        self.title = "0 pts"
        isEnabled = false
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.black], for: .normal)
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.black], for: .highlighted)
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.black], for: .disabled)
    }
    
    required init?(coder: NSCoder){
        super.init(coder: coder)
        self.title = "0 pts"
        isEnabled = false
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.black], for: .normal)
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.black], for: .highlighted)
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.black], for: .disabled)
    }
}
