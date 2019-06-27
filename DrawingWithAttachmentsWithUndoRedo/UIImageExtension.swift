//
//  UIImageExtension.swift
//  DrawingWithAttachmentsWithUndoRedo
//
//  Created by Rahul Dange on 6/27/19.
//  Copyright © 2019 Rahul Dange. All rights reserved.
//

import Foundation

// MARK: - Trimming Image extension -
extension UIImage {
    
    func trim() -> UIImage {
        let newRect = self.cropRect
        if let imageRef = self.cgImage!.cropping(to: newRect) {
            return UIImage(cgImage: imageRef)
        }
        return self
    }
    
    var cropRect: CGRect {
        let cgImage = self.cgImage
        let context = createARGBBitmapContextFromImage(inImage: cgImage!)
        if context == nil {
            return CGRect.zero
        }
        
        let height = CGFloat(cgImage!.height)
        let width = CGFloat(cgImage!.width)
        
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context?.draw(cgImage!, in: rect)
        
        //let data = UnsafePointer<CUnsignedChar>(CGBitmapContextGetData(context))
        guard let data = context?.data?.assumingMemoryBound(to: UInt8.self) else {
            return CGRect.zero
        }
        
        var lowX = width
        var lowY = height
        var highX: CGFloat = 0
        var highY: CGFloat = 0
        
        let heightInt = Int(height)
        let widthInt = Int(width)
        //Filter through data and look for non-transparent pixels.
        for y in (0 ..< heightInt) {
            let y = CGFloat(y)
            for x in (0 ..< widthInt) {
                let x = CGFloat(x)
                let pixelIndex = (width * y + x) * 4 /* 4 for A, R, G, B */
                
                if data[Int(pixelIndex)] == 0  { continue } // crop transparent
                
                if data[Int(pixelIndex+1)] > 0xE0 && data[Int(pixelIndex+2)] > 0xE0 && data[Int(pixelIndex+3)] > 0xE0 { continue } // crop white
                
                if (x < lowX) {
                    lowX = x
                }
                if (x > highX) {
                    highX = x
                }
                if (y < lowY) {
                    lowY = y
                }
                if (y > highY) {
                    highY = y
                }
                
            }
        }
        
        if lowX > 10.0 {
            lowX = lowX - 10.0
        }
        
        if lowY > 10.0 {
            lowY = lowY - 10.0
        }
        
        var finalWidth = highX - lowX
        if (highX - lowX + 10) <= (UIScreen.main.bounds.width) {
            finalWidth = (highX - lowX + 10)
        }
        
        var finalHeight = highY - lowY
        if (highY - lowY + 10) <= (UIScreen.main.bounds.height) {
            finalHeight = (highY - lowY + 10)
        }
        
        return CGRect(x: lowX, y: lowY, width: finalWidth, height: finalHeight)
    }
    
    func createARGBBitmapContextFromImage(inImage: CGImage) -> CGContext? {
        
        let width = inImage.width
        let height = inImage.height
        
        let bitmapBytesPerRow = width * 4
        let bitmapByteCount = bitmapBytesPerRow * height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bitmapData = malloc(bitmapByteCount)
        if bitmapData == nil {
            return nil
        }
        
        let context = CGContext (data: bitmapData,
                                 width: width,
                                 height: height,
                                 bitsPerComponent: 8,      // bits per component
            bytesPerRow: bitmapBytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        return context
    }
}
