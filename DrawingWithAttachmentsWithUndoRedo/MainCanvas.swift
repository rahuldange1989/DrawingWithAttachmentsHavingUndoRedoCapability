//
//  MainCanvas.swift
//  MobilePhIS
//
//  Created by Rahul Dange on 5/28/19.
//

import Foundation

protocol MainCanvasDelegate
{
    func canvas(_ canvas: MainCanvas, didUpdateDrawing drawing: Drawing?, mergedImage image: UIImage?)
    func canvas(_ canvas: MainCanvas, didSaveDrawing drawing: Drawing, mergedImage image: UIImage?)
    func canvas(_ canvas: MainCanvas, didDraftDrawing drawing: Drawing, mergedImage image: UIImage?)
    func canvas(_ canvas: MainCanvas, enableEditing: Bool)
}

public class MainCanvas: UIView {
    var delegate: MainCanvasDelegate?
    fileprivate var backgroundImageView: UIImageView?
    fileprivate var session: DrawingSession = DrawingSession.init(maxSessionSize: 100)
    fileprivate var drawing = Drawing()
    fileprivate var attachModels:[AttachmentModel] = []
    
    var penColor: UIColor = UIColor.black
    var penWidth: CGFloat = 1.8
    var penAlpha: CGFloat = 1.0
    var undoRedoCapacity: Int = 100
    var saved = false
    var isSelectionOn: Bool = false
    private var pen: Pen?
    fileprivate var canvasId: String?
    fileprivate var drawingView: DrawingView?
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.white
        self.createBackgroundImageView()
        self.createDrawingView()
        self.createPenForDrawing()
        self.session = DrawingSession.init(maxSessionSize: self.undoRedoCapacity)
    }
    
    func createPenForDrawing() {
        self.pen = Pen.init(color: self.penColor, width: self.penWidth, alpha: self.penAlpha)
    }
    
    func createDrawingView() {
        self.drawingView = DrawingView.init(frame: CGRect.init(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        // -- to identify if it is Drawing View
        drawingView?.tag = -600
        drawingView?.backgroundColor = UIColor.clear
        drawingView?.pen = self.pen
        self.drawingView?.delegate = self
        self.addSubview(drawingView!)
        drawingView?.autoresizingMask = [.flexibleHeight ,.flexibleWidth]
        self.bringSubviewToFront(self.drawingView!)
    }
    
    func createBackgroundImageView() {
        let imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        // -- to identify if it is background imageview
        imageView.tag = -500
        self.addSubview(imageView)
        imageView.autoresizingMask = [.flexibleHeight ,.flexibleWidth]
        self.backgroundImageView = imageView
        self.backgroundImageView?.contentMode = .scaleAspectFill
    }
    
    fileprivate func compare(_ lines1: [Line], isEqualTo lines2: [Line]) -> Bool {
        if (lines1.isEmpty && lines2.isEmpty) {
            return true
        } else if (lines1.isEmpty || lines2.isEmpty) {
            return false
        }
        
        return (lines1.count == lines2.count)
    }
    
    fileprivate func currentDrawing() -> Drawing {
        // -- attach model array to insert in undo list
        var attachArray : [AttachmentModel] = []
        for model in self.attachModels {
            let attchModel = AttachmentModel.init(attachView: model.attachView!, attachFrame: model.attachFrame!, isHidden: model.isHidden!, fontSize: model.fontSize!, withText: model.text!, isDeleted: model.isDeleted!)
            attachArray.append(attchModel)
        }
        return Drawing.init(_attachList: attachArray, _lines: self.drawingView?.lines ?? [])
    }

    fileprivate func updateByLastSession() {
        let lastSession = self.session.lastDrawingSession()
        self.drawingView?.lines = lastSession?.lines ?? []

        var index = 0
        for currentModel in self.attachModels {
            if index < lastSession?.attachModels.count ?? 0 {
                let lastSessionModel = lastSession?.attachModels[index]
                currentModel.attachView?.frame = (lastSessionModel?.attachFrame)!
                currentModel.attachView?.isHidden = (lastSessionModel?.isHidden)!
                currentModel.isHidden = lastSessionModel?.isHidden

                if (lastSessionModel?.isDeleted)! {
                    currentModel.attachView?.isHidden = (lastSessionModel?.isDeleted)!
                    currentModel.isHidden = lastSessionModel?.isDeleted
                }

                if currentModel.attachView is UITextView && currentModel.attachView?.tag != 200 {
                    if Float(lastSessionModel?.fontSize ?? 0.0) > Float(0.0) {
                        (currentModel.attachView as! UITextView).font = UIFont.init(name: ((currentModel.attachView as! UITextView).font?.fontName)!, size: CGFloat((lastSessionModel?.fontSize)!))
                        (currentModel.attachView as! UITextView).text = lastSessionModel?.text
                    }
                }

            } else {
                currentModel.attachView?.isHidden = true
                currentModel.isHidden = true
            }

            index = index + 1
        }
        
        // -- update drawing view
        self.drawingView?.setNeedsDisplay()
    }
    
    fileprivate func didUpdateCanvas() {
        self.delegate?.canvas(self, didUpdateDrawing: nil, mergedImage: nil)
    }
    
    fileprivate func isStrokeEqual() -> Bool {
        return self.compare(self.drawing.lines, isEqualTo: self.drawingView?.lines ?? [])
    }
    
    fileprivate func saveFinalImage() {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        var image = UIGraphicsGetImageFromCurrentImageContext()?.trim()
        UIGraphicsEndImageContext()
        
        // -- 0.512 :- Original scroll view size ratio
        let newSize = CGSize.init(width: (image?.size.width)! * 0.512, height: (image?.size.height)! * 0.512)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image?.draw(in: CGRect.init(x: 0, y: 0, width: newSize.width, height: newSize.height))
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.delegate?.canvas(self, didSaveDrawing: self.drawing, mergedImage: image)
    }
    
    fileprivate func saveDraftImage() {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.delegate?.canvas(self, didDraftDrawing: self.drawing, mergedImage: image)
    }
}

// MARK: - Public Methods -
extension MainCanvas {
    open func addViewToUndo(view: UIView, frame: CGRect, isFirstTime: Bool, fontSize: Float = 0.0, text: String = "", isFromDelete: Bool = false) {
        
        if isFirstTime {
            let index = self.attachModels.count
            view.tag = index
            self.attachModels.append(.init(attachView: view, attachFrame: view.frame, isHidden: false, fontSize: fontSize, withText: text, isDeleted: isFromDelete))
        } else {
            let currentModel = AttachmentModel.init(attachView: view, attachFrame: view.frame, isHidden: view.isHidden, fontSize: fontSize, withText: text, isDeleted: isFromDelete)
            let models = self.attachModels.filter({ $0.attachView == view })
            if models.count > 0 {
                if let index = self.attachModels.index(of: models[0]) {
                    self.attachModels[index] = currentModel
                }
            }
        }
        
        // -- attach model array to insert in undo list
        var attachArray : [AttachmentModel] = []
        for model in self.attachModels {
            let attchModel = AttachmentModel.init(attachView: model.attachView!, attachFrame: model.attachFrame!, isHidden: model.isHidden!, fontSize: model.fontSize!, withText: model.text!, isDeleted: model.isDeleted!)
            attachArray.append(attchModel)
        }
        
        let drawingToAppend = Drawing.init(_attachList: attachArray, _lines: self.drawingView?.lines ?? [])
        self.session.append(session: drawingToAppend)
        self.didUpdateCanvas()
        self.saved = self.canSave()
    }
    
    open func updateBackgroundImage(_ image: UIImage?) {
        self.backgroundImageView?.image = image
    }
    
    open func update(_ backgroundImage: UIImage?) {
        self.backgroundImageView?.image = backgroundImage
        self.session.append(session: self.currentDrawing())
        self.didUpdateCanvas()
        self.saved = self.canSave()
    }
    
    open func undo() {
        self.session.undo()
        self.updateByLastSession()
        self.saved = self.canSave()
        self.didUpdateCanvas()
    }
    
    open func redo() {
        self.session.redo()
        self.updateByLastSession()
        self.saved = self.canSave()
        self.didUpdateCanvas()
    }
    
    open func clearUndoRedoQueues() {
        self.session.clearDrawingSession()
        self.updateByLastSession()
        self.didUpdateCanvas()
        self.attachModels = []
        self.saved = true
    }
    
    open func clear() {
        self.session.clearDrawingSession()
        self.updateByLastSession()
        self.saved = true
        self.didUpdateCanvas()
        self.drawingView?.setDrawingHeight(height: 0.0)
        self.attachModels.removeAll()
    
        for currentView in self.subviews {
            if currentView == backgroundImageView {
                (currentView as! UIImageView).image = nil
                continue
            } else if currentView == drawingView {
                self.drawingView?.lines.removeAll()
                self.setNeedsDisplay()
                continue
            }
            
            currentView.removeFromSuperview()
        }
    }
    
    open func save() {
        self.drawing.lines = self.drawingView?.lines ?? []
        self.saved = true
        self.saveFinalImage()
    }
    
    open func draft() {
        self.drawing.lines = self.drawingView?.lines ?? []
        self.saved = true
        self.saveDraftImage()
    }
    
    open func canUndo() -> Bool {
        return self.session.canUndo()
    }
    
    open func canRedo() -> Bool {
        return self.session.canRedo()
    }
    
    open func canSave() -> Bool {
        return !(self.isStrokeEqual())
    }
    
    open func getDrawingView() -> DrawingView {
        return self.drawingView!
    }
    
    open func getBackgroundImageView() -> UIImageView {
        return self.backgroundImageView!
    }
}

// MARK: - Drawing view delegate methods -
extension MainCanvas : DrawingViewDelegate {
    public func drawingViewUpdated() {
        self.session.append(session: self.currentDrawing())
        self.didUpdateCanvas()
    }
    
    public func placeAttachment(touch: UITouch) {
        let currentView = self.subviews.last
        let locationPoint = touch.location(in: self)
        
        if !(currentView?.frame.contains(locationPoint))! {
            // -- Place the object in the view and disable its movement
            if !isSelectionOn && (currentView?.layer.borderWidth)! > CGFloat(0.0) {
                if currentView?.layer.borderWidth != 2.0 {
                    currentView?.layer.borderWidth = 0.0
                }
                currentView?.isUserInteractionEnabled = false
                self.bringSubviewToFront(self.drawingView!)
                self.delegate?.canvas(self, enableEditing: true)
            }
        }
    }
}
