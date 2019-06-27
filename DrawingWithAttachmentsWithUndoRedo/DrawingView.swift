//
//  DrawingView.swift
//  MobilePhIS
//
//  Created by Rahul Dange on 6/7/19.
//

import Foundation

public protocol DrawingViewDelegate
{
    func drawingViewUpdated()
    func placeAttachment(touch: UITouch)
}

public class DrawingView: UIView {
    var delegate: DrawingViewDelegate?
    
    public var lines: [Line] = []
    public var pen: Pen?
    fileprivate var drawingHeight: CGFloat = 0.0
    fileprivate var currentPoint: CGPoint = .zero
    fileprivate var previousPoint: CGPoint = .zero
    fileprivate var previousPreviousPoint: CGPoint = .zero
    fileprivate var isEditing: Bool = true
    fileprivate var brushColor: UIColor = UIColor.black
    fileprivate var areAttachmentPlaceTouches: Bool = false
    fileprivate var isCameraImagePlacementGoingOn: Bool = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Overriding draw(rect:) to stroke paths
    override open func draw(_ rect: CGRect) {
        if isEditing || isCameraImagePlacementGoingOn {
            guard let context: CGContext = UIGraphicsGetCurrentContext() else { return }
            
            for line in lines {
                context.setLineCap(.round)
                context.setLineJoin(.round)
                context.setLineWidth((pen?.width)!)
                // set blend mode so an eraser actually erases stuff
                context.setBlendMode(.normal)
                context.setAlpha((pen?.alpha)!)
                context.setStrokeColor((pen?.color.cgColor)!)
                context.addPath(line.path)
                context.strokePath()
            }
        }
    }
    
    open func getBrushColor() -> UIColor {
        return self.brushColor
    }
    
    open func setBrushColor(color: UIColor) {
        self.brushColor = color
    }
    
    open func getDrawingHeight() -> CGFloat {
        return self.drawingHeight
    }
    
    open func setDrawingHeight(height: CGFloat) {
        self.drawingHeight = height
    }
    
    open func setIsEditing(status: Bool) {
        self.isEditing = status
    }
    
    open func getIsEditing() -> Bool {
        return self.isEditing
    }
    
    open func setIsCameraPlacementGoingOn(status: Bool) {
        self.isCameraImagePlacementGoingOn = status
    }
    
    open func getIsCameraPlacementGoingOn() -> Bool {
        return self.isCameraImagePlacementGoingOn
    }
    
    fileprivate func setTouchPoints(_ touch: UITouch,view: UIView) {
        previousPoint = touch.previousLocation(in: view)
        previousPreviousPoint = touch.previousLocation(in: view)
        currentPoint = touch.location(in: view)
    }
    
    fileprivate func updateTouchPoints(for touch: UITouch,in view: UIView) {
        previousPreviousPoint = previousPoint
        previousPoint = touch.previousLocation(in: view)
        currentPoint = touch.location(in: view)
    }
    
    fileprivate func createNewPath() -> CGMutablePath {
        let midPoints = getMidPoints()
        let subPath = createSubPath(midPoints.0, mid2: midPoints.1)
        let newPath = addSubPathToPath(subPath)
        return newPath
    }
    
    fileprivate func calculateMidPoint(_ p1 : CGPoint, p2 : CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) * 0.5, y: (p1.y + p2.y) * 0.5);
    }
    
    fileprivate func getMidPoints() -> (CGPoint,  CGPoint) {
        let mid1 : CGPoint = calculateMidPoint(previousPoint, p2: previousPreviousPoint)
        let mid2 : CGPoint = calculateMidPoint(currentPoint, p2: previousPoint)
        return (mid1, mid2)
    }
    
    fileprivate func createSubPath(_ mid1: CGPoint, mid2: CGPoint) -> CGMutablePath {
        let subpath : CGMutablePath = CGMutablePath()
        subpath.move(to: CGPoint(x: mid1.x, y: mid1.y))
        subpath.addQuadCurve(to: CGPoint(x: mid2.x, y: mid2.y), control: CGPoint(x: previousPoint.x, y: previousPoint.y))
        return subpath
    }
    
    fileprivate func addSubPathToPath(_ subpath: CGMutablePath) -> CGMutablePath {
        let bounds : CGRect = subpath.boundingBox
        let drawBox : CGRect = bounds.insetBy(dx: -2.0 * (self.pen?.width)!, dy: -2.0 * (self.pen?.width)!)
        self.setNeedsDisplay(drawBox)
        return subpath
    }
}

// MARK: - Override Touch Methods implementation-
extension DrawingView {
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        if #available(iOS 9.1, *) {
            if isEditing {
                if touch.type == .stylus {
                    setTouchPoints(touch, view: self)
                    let newLine = Line(path: CGMutablePath(), colorTag: self.brushColor == UIColor.black ? 0 : 1)
                    newLine.path.addPath(createNewPath())
                    lines.append(newLine)
                }
            } else if touch.type == .stylus {
                self.delegate?.placeAttachment(touch: touch)
                self.areAttachmentPlaceTouches = true
            }
        }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isEditing {
            guard let touch = touches.first else { return }
            if #available(iOS 9.1, *) {
                if touch.type == .stylus && !self.areAttachmentPlaceTouches {
                    updateTouchPoints(for: touch, in: self)
                    let newPath = createNewPath()
                    if let currentPath = lines.last {
                        currentPath.path.addPath(newPath)
                    }
                    
                    // -- update drawing Height :- Canvas edited height
                    let location = touch.location(in: self)
                    if self.drawingHeight < location.y {
                        self.drawingHeight = location.y
                    }
                }
            }
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isEditing {
            guard let touch = touches.first else { return }
            if #available(iOS 9.1, *) {
                if touch.type == .stylus {
                    if self.areAttachmentPlaceTouches {
                        self.areAttachmentPlaceTouches = false
                    } else {
                        delegate?.drawingViewUpdated()
                    }
                }
            }
        }
    }
}
