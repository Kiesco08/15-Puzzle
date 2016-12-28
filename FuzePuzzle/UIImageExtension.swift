//
//  UIImageExtension.swift
//  FuzePuzzle
//
//  Created by Zoumite Franck Armel Mamboue on 12/27/16.
//  Copyright © 2016 Zoumite Franck Armel Mamboue. All rights reserved.
//

import UIKit

let numberOfTiles = 16

// This extension was written with the assumption that the image is SQUARE (i.e.: Aspect ration 1:1)
extension UIImage {
  
  var splitImages: [UIImage?] {
    var images: [UIImage] = []
    
    var y: Double = 0
    let edgeLength: Double = Double(size.width) // Equals size.height according to our assumption
    let edgeUnitLength = Double(size.width) / sqrt(Double(numberOfTiles)) // Edge length of one tile
    
    while y < edgeLength {
      var x: Double = 0
      while x < edgeLength {
        // Define rect of current tile
        let rectX = x
        let rectY = y
        let rectWidth = edgeUnitLength
        let rectHeight = edgeUnitLength
        
        // Create image from rect
        guard let image = cgImage?.cropping(to: CGRect(origin: CGPoint(x: rectX, y: rectY), size: CGSize(width: rectWidth, height: rectHeight))) else {
          return images
        }
        
        // Add image to array
        images.append(UIImage(cgImage: image, scale: 1, orientation: imageOrientation))
        
        x += edgeUnitLength
      }
      y += edgeUnitLength
    }
    
    return images
  }
  
  var topHalf: UIImage? {
    guard let cgImage = cgImage,
          let image = cgImage.cropping(to: CGRect(origin: CGPoint(x: 0, y: 0),
                                                          size: CGSize(width: size.width, height: size.height/2)))
      else { return nil }
    return UIImage(cgImage: image, scale: 1, orientation: imageOrientation)
  }
  
  var bottomHalf: UIImage? {
    guard let cgImage = cgImage,
          let image = cgImage.cropping(to: CGRect(origin: CGPoint(x: 0,  y: CGFloat(Int(size.height)-Int(size.height/2))), size: CGSize(width: size.width, height: CGFloat(Int(size.height) - Int(size.height/2))))) else { return nil }
    return UIImage(cgImage: image, scale: 1, orientation: imageOrientation)
  }
  
  var leftHalf: UIImage? {
    guard let cgImage = cgImage,
          let image = cgImage.cropping(to: CGRect(origin: CGPoint(x: 0, y: 0),
                                                          size: CGSize(width: size.width/2, height: size.height)))
      else { return nil }
    return UIImage(cgImage: image, scale: 1, orientation: imageOrientation)
  }
  
  var rightHalf: UIImage? {
    guard let cgImage = cgImage,
          let image = cgImage.cropping(to: CGRect(origin: CGPoint(x: CGFloat(Int(size.width)-Int((size.width/2))), y: 0),
                                                          size: CGSize(width: CGFloat(Int(size.width)-Int((size.width/2))), height: size.height)))
      else { return nil }
    return UIImage(cgImage: image, scale: 1, orientation: imageOrientation)
  }
}
