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
  var tileTapped: IndexPath?
  
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
    
    if (!isSolvable(emptyRow: Int(missingTile / Configs.numberOfTilesOnEdge) + 1)) {
      initPuzzle()
    }
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
    let emptyColumn = missingTile % Configs.numberOfTilesOnEdge
    
    if (!isSolvable(emptyRow: emptyRow + 1)) {
      if (emptyRow == 0 && emptyColumn <= 1) {
        swapTiles(i: tileCount - 2, j: tileCount - 1, k: tileCount - 1, l: tileCount - 1)
      } else {
        swapTiles(i: 0, j: 0, k: 1, l: 0)
      }
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
  
  // MARK: Gesture Recognizers
  
  func prepareGestureRecognizers() {
    let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
    collectionView?.addGestureRecognizer(tapRecognizer)
  }
  
  func handleTapGesture(gesture: UITapGestureRecognizer) {
    
    guard let collectionView = collectionView else {
      return
    }
    
    switch(gesture.state) {
    case UIGestureRecognizerState.ended:
      guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
        break
      }
      tileTapped = selectedIndexPath
      collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
      
      collectionView.endInteractiveMovement()
      print("Tap")
      if let neighbourMissingTileIndex = neighbourMissingTile() {
        guard let tileTapped = tileTapped else {
          return
        }
        self.missingTile = tileTapped.row
        collectionView.performBatchUpdates({
          collectionView.moveItem(at: tileTapped, to: neighbourMissingTileIndex)
          collectionView.moveItem(at: neighbourMissingTileIndex, to: tileTapped)
        }, completion: {(finished) in
          collectionView.dataSource?.collectionView!(collectionView, moveItemAt: tileTapped, to: neighbourMissingTileIndex)
          self.checkIfWon()
        })
      } else {
      }
    default:
      collectionView.cancelInteractiveMovement()
    }
  }
  
  func handleLongPressGesture(gesture: UILongPressGestureRecognizer) {
    guard let collectionView = collectionView else {
      return
    }
    
    switch(gesture.state) {
    case UIGestureRecognizerState.began:
      guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
        break
      }
      tileTapped = selectedIndexPath
      collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
    case UIGestureRecognizerState.changed: break
    //      collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
    case UIGestureRecognizerState.ended:
      collectionView.endInteractiveMovement()
      if let neighbourMissingTileIndex = neighbourMissingTile() {
        guard let tileTapped = tileTapped else {
          return
        }
        self.missingTile = tileTapped.row
        collectionView.performBatchUpdates({
          collectionView.moveItem(at: tileTapped, to: neighbourMissingTileIndex)
          collectionView.moveItem(at: neighbourMissingTileIndex, to: tileTapped)
        }, completion: {(finished) in
          collectionView.dataSource?.collectionView!(collectionView, moveItemAt: tileTapped, to: neighbourMissingTileIndex)
          self.checkIfWon()
        })
      } else {
        print("I don't see missing tile!")
      }
    default:
      collectionView.cancelInteractiveMovement()
    }
  }
}

// MARK: Game Logic

extension PuzzleViewController {
  
  func checkIfWon() {
    if self.sumInversions() == 0 {
      let alert: UIAlertController = UIAlertController(title: NSLocalizedString("Completed", comment: "") , message:NSLocalizedString("You WON!", comment: "") , preferredStyle: .alert)
      let actionButton: UIAlertAction = UIAlertAction(title: NSLocalizedString("Play Again", comment: ""), style: .default) { action -> Void in
      self.initPuzzle()
      }
      alert.addAction(actionButton)
      self.present(alert, animated: true, completion: nil)
    } else {
      print("There are \(self.sumInversions()) inversions")
    }
  }
  
  func neighbourMissingTile() -> IndexPath? {
    guard let tileTapped = tileTapped else {
      return nil
    }
    
    var neighbours: [CGPoint] = []
    let n = tileTapped.row
    let x = n % Configs.numberOfTilesOnEdge
    let y = n / Configs.numberOfTilesOnEdge
    
    let missingTileX = missingTile % Configs.numberOfTilesOnEdge
    let missingTileY = missingTile / Configs.numberOfTilesOnEdge
    
    // Top
    let topY = y - 1
    if topY >= 0 && topY < Configs.numberOfTilesOnEdge {
      let topNeighbour = CGPoint(x: x, y: topY)
      neighbours.append(topNeighbour)
    }
    
    // Bottom
    let bottomY = y + 1
    if bottomY >= 0 && bottomY < Configs.numberOfTilesOnEdge {
      let bottomNeighbour = CGPoint(x: x, y: bottomY)
      neighbours.append(bottomNeighbour)
    }
    
    // Left
    let leftX = x - 1
    if leftX >= 0 && leftX < Configs.numberOfTilesOnEdge {
      let leftNeighbour = CGPoint(x: leftX, y: y)
      neighbours.append(leftNeighbour)
    }
    
    // Right
    let rightX = x + 1
    if rightX >= 0 && rightX < Configs.numberOfTilesOnEdge {
      let rightNeighbour = CGPoint(x: rightX, y: y)
      neighbours.append(rightNeighbour)
    }
    
    for neighbour in neighbours {
      if Int(neighbour.x) == missingTileX && Int(neighbour.y) == missingTileY {
        // We are using a flat array to represent the grid represented by the puzzle, so we use n = y * w + x to translate a grid item position to an array item position
        return IndexPath(row: Int(neighbour.y) * Configs.numberOfTilesOnEdge + Int(neighbour.x), section: 0)
      }
    }
    
    return nil
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
