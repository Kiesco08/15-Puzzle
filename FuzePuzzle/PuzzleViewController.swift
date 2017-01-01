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
  var missingTile = Configs.numberOfTiles - 1
  var missingCell : TileCollectionViewCell? {
    guard let cells = collectionView?.visibleCells as? [TileCollectionViewCell] else {
      return nil
    }
    for cell in cells {
      if cell.tileImageView.image == nil {
        return cell
      }
    }
    return nil
  }
  
  // MARK: Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    initPuzzle()
    prepareGestureRecognizers()
  }
  
  func initPuzzle() {
    guard let image = UIImage(named: "image") else {
      return
    }
    
    missingTile = Int(arc4random_uniform(UInt32(Configs.numberOfTiles) - 1))
    splitImages = image.splitImages
    
    shuffleTiles()
    collectionView?.reloadData()
    
    makeSurePuzzleIsSolvable()
  }
  
  // MARK: Gesture Recognizers
  
  func prepareGestureRecognizers() {
//    let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
//    collectionView?.addGestureRecognizer(gesture)
  }
  
  // TODO: Implement
  func handlePanGesture(gesture: UIPanGestureRecognizer) {
    guard let collectionView = collectionView else {
      return
    }
    
    switch(gesture.state) {
    case UIGestureRecognizerState.began: break
//      collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
    case UIGestureRecognizerState.changed: break
//      collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
    case UIGestureRecognizerState.ended: break
//      collectionView.endInteractiveMovement()
    default: break
//      collectionView.cancelInteractiveMovement()
    }
  }
}

// MARK: Game Logic

extension PuzzleViewController {
  
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
    let arrayPositionToSwap1 = j * tileCount + i
    let arrayPositionToSwap2 = l * tileCount + k
    
    let temp = splitImages[arrayPositionToSwap1]
    splitImages[arrayPositionToSwap1] = splitImages[arrayPositionToSwap2]
    splitImages[arrayPositionToSwap2] = temp
  }
  
  func makeSurePuzzleIsSolvable() {
    let emptyY = Int(missingTile / tileCount)
    
    if (!isSolvable(emptyY: emptyY + 1)) {
      initPuzzle()
    }
  }
  
  func isSolvable(emptyY: Int) -> Bool {
    if (tileCount % 2 == 1) {
      return (sumInversions() % 2 == 0)
    } else {
      return ((sumInversions() + tileCount - emptyY) % 2 == 0)
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
  
  func slideTile(_ collectionView: UICollectionView, tileTapped: IndexPath, missingTile: IndexPath, completion: (()->())? = nil) {
    self.missingTile = tileTapped.row
    
    collectionView.performBatchUpdates({
      collectionView.moveItem(at: tileTapped, to: missingTile)
      collectionView.moveItem(at: missingTile, to: tileTapped)
    }, completion: {(finished) in
      self.swapTiles(i: tileTapped.row % tileCount, j: tileTapped.row / tileCount, k: missingTile.row % tileCount, l: missingTile.row / tileCount)
      self.checkIfWon()
      completion?()
    })
  }
  
  func slideListOfTiles(_ collectionView: UICollectionView, tilesToPush: ([IndexPath], Bool), offset: Int, completion: (()->())? = nil) {
    
    for (index, indexPath) in tilesToPush.0.reversed().enumerated() {
      self.missingTile = indexPath.row
      var destinationIndexPath: IndexPath?
      
      if tilesToPush.1 {
        destinationIndexPath = IndexPath(row: indexPath.row - offset, section: 0)
      } else {
        destinationIndexPath = IndexPath(row: indexPath.row + offset, section: 0)
      }
      
      guard let destinationTile = destinationIndexPath else {
        return
      }
      
      collectionView.performBatchUpdates({
        collectionView.moveItem(at: indexPath, to: destinationTile)
        collectionView.moveItem(at: destinationTile, to: indexPath)
      }, completion: {(finished) in
        if index == tilesToPush.0.count - 1 {
          self.swapListOfTiles(tilesToPush, offset: offset)
          completion?()
        }
      })
    }
  }
  
  func swapListOfTiles(_ tilesToSwap: ([IndexPath], Bool), offset: Int) {
    
    for tileToSwap in tilesToSwap.0.reversed() {
      let tileToSwapArrayIndex = tileToSwap.row
      let tileToSwapX = Int(tileToSwapArrayIndex % tileCount)
      let tileToSwapY = Int(tileToSwapArrayIndex / tileCount)
      
      var destinationIndexPath: IndexPath?
      
      if tilesToSwap.1 {
        destinationIndexPath = IndexPath(row: tileToSwap.row - offset, section: 0)
      } else {
        destinationIndexPath = IndexPath(row: tileToSwap.row + offset, section: 0)
      }
      
      guard let destinationArrayIndex = destinationIndexPath?.row else {
        return
      }
      
      let destinationX = Int(destinationArrayIndex % tileCount)
      let destinationY = Int(destinationArrayIndex / tileCount)
      
      swapTiles(i: tileToSwapX, j: tileToSwapY, k: destinationX, l: destinationY)
    }
  }
  
  func checkIfWon() {
    var solved = true
    for i in 0 ..< tileCount {
      for j in 0 ..< tileCount {
        let n = j * tileCount + i
        if splitImages[n].originalX != i || splitImages[n].originalY != j {
          solved = false
          break
        }
      }
    }
    
    if solved {
      let alert: UIAlertController = UIAlertController(title: NSLocalizedString("Completed", comment: "") , message:NSLocalizedString("You WON!", comment: "") , preferredStyle: .alert)
      let actionButton: UIAlertAction = UIAlertAction(title: NSLocalizedString("Play Again", comment: ""), style: .default) { action -> Void in
      self.initPuzzle()
      }
      alert.addAction(actionButton)
      self.present(alert, animated: true, completion: nil)
    }
  }
  
  func neighbourMissingTile(tileTapped: IndexPath) -> IndexPath? {
    var neighbours: [CGPoint] = []
    let n = tileTapped.row
    let x = n % tileCount
    let y = n / tileCount
    
    let missingTileX = missingTile % tileCount
    let missingTileY = missingTile / tileCount
    
    // Top
    let topY = y - 1
    if topY >= 0 && topY < tileCount {
      let topNeighbour = CGPoint(x: x, y: topY)
      neighbours.append(topNeighbour)
    }
    
    // Bottom
    let bottomY = y + 1
    if bottomY >= 0 && bottomY < tileCount {
      let bottomNeighbour = CGPoint(x: x, y: bottomY)
      neighbours.append(bottomNeighbour)
    }
    
    // Left
    let leftX = x - 1
    if leftX >= 0 && leftX < tileCount {
      let leftNeighbour = CGPoint(x: leftX, y: y)
      neighbours.append(leftNeighbour)
    }
    
    // Right
    let rightX = x + 1
    if rightX >= 0 && rightX < tileCount {
      let rightNeighbour = CGPoint(x: rightX, y: y)
      neighbours.append(rightNeighbour)
    }
    
    for neighbour in neighbours {
      if Int(neighbour.x) == missingTileX && Int(neighbour.y) == missingTileY {
        // We are using a flat array to represent the grid represented by the puzzle, so we use n = y * w + x to translate a grid item position to an array item position
        return IndexPath(row: Int(neighbour.y) * tileCount + Int(neighbour.x), section: 0)
      }
    }
    
    return nil
  }
  
  func isInMissingCellRow(_ targetIndexPath: IndexPath) -> ([IndexPath], Bool)? {
    
    var indexPathsToPush: [IndexPath] = []
    var left = false
    
    guard let missingCell = missingCell,
      let emptySlotIndexPath = collectionView?.indexPath(for: missingCell) else {
        return nil
    }
    
    if (emptySlotIndexPath.row / tileCount == targetIndexPath.row / tileCount) && targetIndexPath.row != emptySlotIndexPath.row {
      var index = targetIndexPath.row
      if index < emptySlotIndexPath.row {
        while index < emptySlotIndexPath.row {
          indexPathsToPush.append(IndexPath(row: index, section: 0))
          index += 1
        }
      } else if index > emptySlotIndexPath.row {
        while index > emptySlotIndexPath.row {
          indexPathsToPush.append(IndexPath(row: index, section: 0))
          index -= 1
        }
        left = true
      }
    }
    return indexPathsToPush.count == 0 ? nil : (indexPathsToPush, left)
  }
  
  func isInMissingCellColumn(_ targetIndexPath: IndexPath) -> ([IndexPath], Bool)? {

    var indexPathsToPush: [IndexPath] = []
    var top = false

    guard let missingCell = missingCell,
      let emptySlotIndexPath = collectionView?.indexPath(for: missingCell) else {
        return nil
    }
    
    if (emptySlotIndexPath.row % tileCount == targetIndexPath.row % tileCount) && targetIndexPath.row != emptySlotIndexPath.row {
      var index = targetIndexPath.row
      if index < emptySlotIndexPath.row {
        while index < emptySlotIndexPath.row {
          indexPathsToPush.append(IndexPath(row: index, section: 0))
          index += tileCount
        }
      } else if index > emptySlotIndexPath.row {
        while index > emptySlotIndexPath.row {
          indexPathsToPush.append(IndexPath(row: index, section: 0))
          index -= tileCount
        }
        top = true
      }
    }
    
    return indexPathsToPush.count == 0 ? nil : (indexPathsToPush, top)
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
      } else {
        cell.tileImageView.image = splitImages[indexPath.row].image
      }
    }
    
    return cell
  }
}

// MARK: UICollectionViewDelegate

extension PuzzleViewController {
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
    if let neighbourMissingTileIndex = neighbourMissingTile(tileTapped: indexPath) {
      
      slideTile(collectionView, tileTapped: indexPath, missingTile: neighbourMissingTileIndex)
      
    } else if let tilesToPush = isInMissingCellRow(indexPath) {
      
      slideListOfTiles(collectionView, tilesToPush: tilesToPush, offset: 1, completion: {
        print(self.splitImages)
        self.checkIfWon()
      })
      
    } else if let tilesToPush = isInMissingCellColumn(indexPath) {
      
      slideListOfTiles(collectionView, tilesToPush: tilesToPush, offset: tileCount, completion: {
        print(self.splitImages)
        self.checkIfWon()
      })
      
    }
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
