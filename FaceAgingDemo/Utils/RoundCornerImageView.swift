//
//  RoundCornerImageView.swift
//  FaceAgingDemo
//
//  Created by Jason Wu on 2019/6/8.
//  Copyright © 2019 Jason Wu. All rights reserved.
//

import UIKit

@IBDesignable
class RoundCornerImageView: UIImageView {
    
    @IBInspectable var cornerRadius: Int = 2
    
    override func layoutSubviews() {
        layer.cornerRadius = CGFloat(cornerRadius)
    }
}
