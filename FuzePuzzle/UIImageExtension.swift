//
//  UIImageExtension.swift
//  FuzePuzzle
//
//  Created by Zoumite Franck Armel Mamboue on 12/27/16.
//  Copyright © 2016 Zoumite Franck Armel Mamboue. All rights reserved.
//
//  This UIImage extension allows to turn any UIImage into an array of Tiles.

import UIKit

// This extension was written with the assumption that the image is SQUARE (i.e.: Aspect ration 1:1)
extension UIImage {
  
  var splitImages: [Tile] {
    var images: [Tile] = []
    
    var y: Double = 0
    var j: Int = 0
    let edgeLength: Double = Double(size.width) // Equals size.height according to our assumption
    let edgeUnitLength = Double(size.width) / Double(Configs.numberOfTilesOnEdge) // Edge length of one tile
    
    while y < edgeLength {
      var x: Double = 0
      var i: Int = 0
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
        images.append(Tile(originalX: i, originalY: j, image: UIImage(cgImage: image, scale: 1, orientation: imageOrientation)))
        
        x += edgeUnitLength
        i += 1
      }
      y += edgeUnitLength
      j += 1
    }
    
    return images
  }
}
