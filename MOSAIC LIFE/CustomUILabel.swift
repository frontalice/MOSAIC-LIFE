//
//  CustomUILabel.swift
//  MOSAIC LIFE
//
//  Created by Toshiki Hanakawa on 2021/05/05.
//

import UIKit

@IBDesignable class CustomUILabel: UILabel {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    @IBInspectable var borderColor : UIColor = UIColor.black
    @IBInspectable var borderWidth : CGFloat = 1.0
//    @IBInspectable var horizontalPadding: CGFloat = 0
    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        invalidateIntrinsicContentSize()
//    }
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        invalidateIntrinsicContentSize()
//    }
//
//    override var intrinsicContentSize: CGSize {
//        var contentSize = super.intrinsicContentSize
//        contentSize.width += horizontalPadding * 2
//        return contentSize
//    }
    
    override func draw(_ rect: CGRect) {
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = borderWidth
        
        super.draw(rect)
    }

}
