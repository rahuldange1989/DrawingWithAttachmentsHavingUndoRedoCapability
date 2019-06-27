//
//  AttachmentModel.swift
//  DrawingWithAttachmentsWithUndoRedo
//
//  Created by Rahul Dange on 6/27/19.
//  Copyright © 2019 Rahul Dange. All rights reserved.
//

import UIKit

public class AttachmentModel: NSObject {
    var attachView: UIView?
    var attachFrame: CGRect?
    var isHidden: Bool?
    var fontSize: Float?
    var text: String?
    var isDeleted: Bool?
    
    init(attachView: UIView, attachFrame: CGRect, isHidden: Bool, fontSize: Float = 0.0, withText: String = "", isDeleted: Bool = false) {
        self.attachView = attachView
        self.attachFrame = attachFrame
        self.isHidden = isHidden
        self.fontSize = fontSize
        self.text = withText
        self.isDeleted = isDeleted
    }
}
