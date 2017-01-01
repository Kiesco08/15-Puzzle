//
//  CGPointExtension.swift
//  FuzePuzzle
//
//  Created by Zoumite Franck Armel Mamboue on 1/1/17.
//  Copyright © 2017 Zoumite Franck Armel Mamboue. All rights reserved.
//
//  This CGPoint extension allows to calculate the distance between two points.

import UIKit

extension CGPoint {
  func distanceToPoint(p:CGPoint) -> CGFloat {
    return sqrt(pow((p.x - x), 2) + pow((p.y - y), 2))
  }
}
