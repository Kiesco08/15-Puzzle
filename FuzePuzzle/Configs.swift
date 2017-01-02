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
  // Number of tiles per row. Update this value for different difficulty levels
  static let tilesPerRow = 4
  
  // Total tiles in the grid
  static let totalTiles = tilesPerRow * tilesPerRow
}
