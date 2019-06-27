//
//  DrawingSession.swift
//  DrawingWithAttachmentsWithUndoRedo
//
//  Created by Rahul Dange on 6/27/19.
//  Copyright © 2019 Rahul Dange. All rights reserved.
//

import Foundation

class DrawingSession {
    private var maxDrawingSessionSize = 100
    var undoDrawingSessionList:[Drawing] = []
    var redoDrawingSessionList:[Drawing] = []
    
    init(maxSessionSize: Int) {
        self.maxDrawingSessionSize = maxSessionSize
    }
    
    // MARK: - Internal Methods -
    private func appendUndo(session: Drawing?) {
        if session != nil {
            if self.undoDrawingSessionList.count >= self.maxDrawingSessionSize {
                self.undoDrawingSessionList.removeFirst()
            }
            
            self.undoDrawingSessionList.append(session!)
        }
    }
    
    private func appendRedo(session: Drawing?) {
        if session != nil {
            if self.redoDrawingSessionList.count >= self.maxDrawingSessionSize {
                self.redoDrawingSessionList.removeFirst()
            }
            
            self.redoDrawingSessionList.append(session!)
        }
    }
    
    private func clearUndoList() {
        self.undoDrawingSessionList.removeAll()
    }
    
    private func clearRedoList() {
        self.redoDrawingSessionList.removeAll()
    }
    
    // MARK: - Public Methods -
    func lastDrawingSession() -> Drawing? {
        if self.undoDrawingSessionList.last != nil {
            return self.undoDrawingSessionList.last
        }
        
        return nil
    }
    
    func append(session: Drawing?) {
        self.appendUndo(session: session)
        self.clearRedoList()
    }
    
    func undo() {
        let lastDrawingSession = self.undoDrawingSessionList.last
        if lastDrawingSession != nil {
            self.appendRedo(session: lastDrawingSession)
            self.undoDrawingSessionList.removeLast()
        }
    }
    
    func redo() {
        let lastDrawingSession = self.redoDrawingSessionList.last
        if lastDrawingSession != nil {
            self.appendUndo(session: lastDrawingSession)
            self.redoDrawingSessionList.removeLast()
        }
    }
    
    func clearDrawingSession() {
        self.clearRedoList()
        self.clearUndoList()
    }
    
    func canUndo() -> Bool {
        return self.undoDrawingSessionList.count > 0
    }
    
    func canRedo() -> Bool {
        return self.redoDrawingSessionList.count > 0
    }
}
