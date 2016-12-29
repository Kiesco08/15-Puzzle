//
//  Tile.swift
//  FuzePuzzle
//
//  Created by Zoumite Franck Armel Mamboue on 12/29/16.
//  Copyright © 2016 Zoumite Franck Armel Mamboue. All rights reserved.
//

import UIKit

struct Tile {
  var originalX: Int
  var originalY: Int
  var image: UIImage?
  
  init(originalX: Int, originalY: Int, image: UIImage?) {
    self.originalX = originalX
    self.originalY = originalY
    self.image = image
  }
}
