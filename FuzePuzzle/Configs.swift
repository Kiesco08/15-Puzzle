//
//  Configs.swift
//  FuzePuzzle
//
//  Created by Zoumite Franck Armel Mamboue on 12/29/16.
//  Copyright © 2016 Zoumite Franck Armel Mamboue. All rights reserved.
//
//  This Configs struct holds constants used across the whole application.

import Foundation

struct Configs {
  static let numberOfTiles: Int = 16
  static let numberOfTilesOnEdge: Int = Int(sqrt(Double(Configs.numberOfTiles)))
}
