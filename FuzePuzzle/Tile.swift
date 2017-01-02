//
//  Tile.swift
//  FuzePuzzle
//
//  Created by Zoumite Franck Armel Mamboue on 12/29/16.
//  Copyright © 2016 Zoumite Franck Armel Mamboue. All rights reserved.
//
//  This model object holds Tile information

import UIKit

struct Tile {
  // The original X coordinate of the tile
  var originalX: Int
  
  // The original Y coordinate of the tile
  var originalY: Int
  
  //  - The tile image (optional because it might be an empty tile)
  var image: UIImage?
  
  init(originalX: Int, originalY: Int, image: UIImage?) {
    self.originalX = originalX
    self.originalY = originalY
    self.image = image
  }
}
