//
//  Line.swift
//  DrawingWithAttachmentsWithUndoRedo
//
//  Created by Rahul Dange on 6/27/19.
//  Copyright © 2019 Rahul Dange. All rights reserved.
//

import Foundation

public struct Line {
    public var path: CGMutablePath
    public var colorTag: Int
    
    init(path: CGMutablePath, colorTag: Int) {
        self.path = path
        self.colorTag = colorTag
    }
}
