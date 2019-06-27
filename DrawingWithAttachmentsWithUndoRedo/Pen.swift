//
//  Pen.swift
//  DrawingWithAttachmentsWithUndoRedo
//
//  Created by Rahul Dange on 6/27/19.
//  Copyright © 2019 Rahul Dange. All rights reserved.
//

import Foundation

public struct Pen {
    public var color: UIColor
    public var width: CGFloat
    public var alpha: CGFloat
    
    init(color: UIColor, width: CGFloat, alpha: CGFloat) {
        self.color = color
        self.width = width
        self.alpha = alpha
    }
}
