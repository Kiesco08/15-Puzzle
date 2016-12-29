//
//  PuzzleViewController.swift
//  FuzePuzzle
//
//  Created by Zoumite Franck Armel Mamboue on 12/27/16.
//  Copyright © 2016 Zoumite Franck Armel Mamboue. All rights reserved.
//
//  This view controller contains the logic of the puzzle.

import UIKit

private let reuseIdentifier = "TileCollectionViewCell"
private let itemsPerRow:CGFloat = sqrt(CGFloat(Double(Configs.numberOfTiles)))
private let sectionInsets = UIEdgeInsets(top: 25.0, left: 10.0, bottom: 25.0, right: 10.0)
private let tileCount = Configs.numberOfTilesOnEdge

class PuzzleViewController: UICollectionViewController {

  // MARK: Instance Variables
  var splitImages: [Tile] = []
  var missingTile = 0
  
  // MARK: Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    guard let image = UIImage(named: "image") else {
      return
    }
    
    missingTile = Int(arc4random_uniform(UInt32(Configs.numberOfTiles) - 1))
    splitImages = image.splitImages
    
    shuffleTiles()
    makeSurePuzzleIsSolvable()
    prepareGestureRecognizers()
  }
  
  // MARK: Tile Suffling
  
  // Fisher-Yates algorithm: https://en.wikipedia.org/wiki/Fisher–Yates_shuffle
  func shuffleTiles() {
    var i = Configs.numberOfTiles - 1
    while (i > 0) {
      let j = Int(floor(Double(arc4random_uniform(UInt32(i)))))
      let xi = i % tileCount
      let yi = Int(floor(Double(i / tileCount)))
      let xj = j % tileCount
      let yj = Int(floor(Double(j / tileCount)))
      swapTiles(i: xi, j: yi, k: xj, l: yj)
      i -= 1
    }
  }
  
  func swapTiles(i: Int, j: Int, k: Int, l: Int) {
    // We are using a flat array to represent the grid represented by the puzzle, so we use n = y * w + x to translate a grid item position to an array item position
    let arrayPositionToSwap1 = j * Configs.numberOfTilesOnEdge + i
    let arrayPositionToSwap2 = l * Configs.numberOfTilesOnEdge + k
    
    let temp = splitImages[arrayPositionToSwap1]
    splitImages[arrayPositionToSwap1] = splitImages[arrayPositionToSwap2]
    splitImages[arrayPositionToSwap2] = temp
  }
  
  func makeSurePuzzleIsSolvable() {
    let emptyRow = Int(missingTile / Configs.numberOfTilesOnEdge)
    let emptyColum = missingTile % Configs.numberOfTilesOnEdge
    
    if (!isSolvable(emptyRow: emptyRow + 1)) {
      if (emptyColum == 0 && emptyRow <= 1) {
        swapTiles(i: tileCount - 2, j: tileCount - 1, k: tileCount - 1, l: tileCount - 1)
      } else {
        swapTiles(i: 0, j: 0, k: 1, l: 0)
      }
      initEmpty()
    }
  }
  
  func isSolvable(emptyRow: Int) -> Bool {
    if (Configs.numberOfTilesOnEdge % 2 == 1) {
      return (sumInversions() % 2 == 0)
    } else {
      return ((sumInversions() + Configs.numberOfTilesOnEdge - emptyRow) % 2 == 0)
    }
  }
  
  func sumInversions() -> Int {
    var inversions = 0
    for j in 0 ..< tileCount {
      for i in 0 ..< tileCount {
      inversions += countInversions(i: i, j: j)
      }
    }
    return inversions
  }
  
  func countInversions(i: Int, j: Int) -> Int {
    var inversions = 0
    // We are using a flat array to represent the grid represented by the puzzle, so we use n = y * w + x to translate a grid item position to an array item position
    let tileNum = j * tileCount + i
    let lastTile = tileCount * tileCount
    let tileValue = splitImages[tileNum].originalY * tileCount + splitImages[tileNum].originalX
    for q in tileNum + 1 ..< lastTile {
      let k = Int(q % tileCount)
      let l = Int(floor(Double(q / tileCount)))
      
      let tileToCompareNum = l * tileCount + k
      let compValue = splitImages[tileToCompareNum].originalY * tileCount + splitImages[tileToCompareNum].originalX
      if (tileValue > compValue && tileValue != (lastTile - 1)) {
        inversions += 1
      }
    }
    return inversions
  }
  
  func initEmpty() {
    missingTile = Configs.numberOfTiles - 1
    collectionView?.reloadData()
  }
  
  // MARK: Gesture Recognizers
  
  func prepareGestureRecognizers() {
    let tapRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleGesture))
    tapRecognizer.minimumPressDuration = 0.1
    collectionView?.addGestureRecognizer(tapRecognizer)
  }
  
  func handleGesture(gesture: UILongPressGestureRecognizer) {
    guard let collectionView = collectionView else {
      return
    }
    
    switch(gesture.state) {
    case UIGestureRecognizerState.began:
      guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
        break
      }
      collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
    case UIGestureRecognizerState.changed:
      collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
    case UIGestureRecognizerState.ended:
      collectionView.endInteractiveMovement()
    default:
      collectionView.cancelInteractiveMovement()
    }
  }
}

// MARK: UICollectionViewDataSource

extension PuzzleViewController {
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return splitImages.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
    if let cell = cell as? TileCollectionViewCell {
      if indexPath.row == missingTile {
        cell.tileImageView.image = nil
        cell.tileImageView.backgroundColor = UIColor.white
      } else {
        cell.tileImageView.image = splitImages[indexPath.row].image
      }
    }
    
    cell.backgroundColor = UIColor.black
    
    return cell
  }
}

// MARK: UICollectionViewDelegate

extension PuzzleViewController {
  
  override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    let temp = splitImages[sourceIndexPath.row]
    splitImages[sourceIndexPath.row] = splitImages[destinationIndexPath.row]
    splitImages[destinationIndexPath.row] = temp
  }

}

// MARK: Configure spacing between tiles

extension PuzzleViewController : UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = availableWidth / itemsPerRow
    
    return CGSize(width: widthPerItem, height: widthPerItem)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return sectionInsets
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.left
  }
}
