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
private let tilesPerRow = Configs.tilesPerRow
private let totalTiles = Configs.totalTiles
private let sectionInsets = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)

class PuzzleViewController: UICollectionViewController {

  // MARK: Instance Variables
  
  // Holds Tile data.
  var tileData: [Tile] = []
  
  // Keeps track of the missing tile's position.
  var missingTilePosition = totalTiles - 1
  
  // Returns the missing tile's cell.
  var missingTileCell : TileCollectionViewCell? {
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
  
  // The cell the user first touches when starting to drag.
  var cellTouchedToDrag: TileCollectionViewCell?
  
  // Keeps track of the indexes of the group of cells being dragged. The boolean value tracks the direction in which they are being dragged.
  var indexesOfCellsToDrag: ([IndexPath], Bool)?
  
  // Keeps track of whether or not cells are being dragged horizontally
  var draggingHorizontally = true
  
  // Keeps track of the difference between the centers of the group of cells being dragged and the position of the user's finger.
  var dragFingerPositionsRelativeToCellsToDragCenters : [CGPoint]?
  
  // Keeps track of the initial positions of the centers of the group of cells being dragged.
  var initialPositionsOfCellsToDragCenters : [CGPoint]?
  
  // MARK: Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    initPuzzle()
    prepareGestureRecognizers()
  }
  
  // MARK: User Actions
  
  @IBAction func refreshPressed(_ sender: Any) {
    initPuzzle()
  }
  
  // MARK: Gesture Recognizers
  
  func prepareGestureRecognizers() {
    let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
    collectionView?.addGestureRecognizer(gesture)
  }
}

// MARK: Puzzle Logic

extension PuzzleViewController {
  
  // Initializes the puzzle.
  func initPuzzle() {
    guard let image = UIImage(named: "image") else {
      return
    }
    
    missingTilePosition = Int(arc4random_uniform(UInt32(totalTiles) - 1))
    tileData = image.splittedImage
    
    shuffleTiles()
    collectionView?.reloadData()
    
    makeSurePuzzleIsSolvable()
  }
  
  // Using Fisher-Yates algorithm to shuffle: https://en.wikipedia.org/wiki/Fisher–Yates_shuffle.
  func shuffleTiles() {
    var i = totalTiles - 1
    while i > 0 {
      let j = Int(floor(Double(arc4random_uniform(UInt32(i)))))
      let xi = i % tilesPerRow
      let yi = Int(floor(Double(i / tilesPerRow)))
      let xj = j % tilesPerRow
      let yj = Int(floor(Double(j / tilesPerRow)))
      swapTiles(x1: xi, y1: yi, x2: xj, y2: yj)
      i -= 1
    }
  }
  
  // This function allows to swap two tiles considering we are on a 2D space (i.e.: swap tileA (x1, x2) with tileB (y1, y2)).
  func swapTiles(x1: Int, y1: Int, x2: Int, y2: Int) {
    // We are using a flat array to represent the grid represented by the puzzle, so we use n = y * w + x to translate a grid item position to an array item position.
    let tileA = y1 * tilesPerRow + x1
    let tileB = y2 * tilesPerRow + x2
    
    let temp = tileData[tileA]
    tileData[tileA] = tileData[tileB]
    tileData[tileB] = temp
  }
  
  // This function checks whether or not the puzzle is solvable: https://www.cs.bham.ac.uk/~mdr/teaching/modules04/java2/TilesSolvability.html.
  func isSolvable(emptyY: Int) -> Bool {
    if (tilesPerRow % 2 == 1) {
      return (sumInversions() % 2 == 0)
    } else {
      return ((sumInversions() + tilesPerRow - emptyY) % 2 == 0)
    }
  }
  
  // This function re-initializes the puzzle if it's not solvable.
  func makeSurePuzzleIsSolvable() {
    let emptyY = Int(missingTilePosition / tilesPerRow)
    
    if (!isSolvable(emptyY: emptyY + 1)) {
      initPuzzle()
    }
  }
  
  // This function sums the of inversions of each array position in the tile data array.
  func sumInversions() -> Int {
    var inversions = 0
    for y in 0 ..< tilesPerRow {
      for x in 0 ..< tilesPerRow {
        inversions += countInversions(x: x, y: y)
      }
    }
    return inversions
  }
  
  // This function counts the inversions of an array position in the tile data array.
  func countInversions(x: Int, y: Int) -> Int {
    var inversions = 0
    // We are using a flat array to represent the grid represented by the puzzle, so we use n = y * w + x to translate a grid item position to an array item position.
    let tileNum = y * tilesPerRow + x
    let lastTile = tilesPerRow * tilesPerRow
    let tileValue = tileData[tileNum].originalY * tilesPerRow + tileData[tileNum].originalX
    for q in tileNum + 1 ..< lastTile {
      let k = Int(q % tilesPerRow)
      let l = Int(floor(Double(q / tilesPerRow)))
      
      let tileToCompareNum = l * tilesPerRow + k
      let compValue = tileData[tileToCompareNum].originalY * tilesPerRow + tileData[tileToCompareNum].originalX
      if (tileValue > compValue && tileValue != (lastTile - 1)) {
        inversions += 1
      }
    }
    return inversions
  }
  
  // This function swaps a tile with the missing one. A sliding animation is resulted from it.
  func slideTile(_ collectionView: UICollectionView, tileTapped: IndexPath, missingTile: IndexPath, completion: (()->())? = nil) {
    self.missingTilePosition = tileTapped.row
    
    collectionView.performBatchUpdates({
      collectionView.moveItem(at: tileTapped, to: missingTile)
      collectionView.moveItem(at: missingTile, to: tileTapped)
    }, completion: {(finished) in
      self.swapTiles(x1: tileTapped.row % tilesPerRow, y1: tileTapped.row / tilesPerRow, x2: missingTile.row % tilesPerRow, y2: missingTile.row / tilesPerRow)
      self.checkIfPuzzleIsSolved()
      completion?()
    })
  }
  
  // This function swaps a group of tiles with the missing one. A sliding animation is resulted from it.
  func slideGroupOfTiles(_ collectionView: UICollectionView, tilesToDrag: ([IndexPath], Bool), offset: Int, completion: (()->())? = nil) {
    
    for (index, indexPath) in tilesToDrag.0.reversed().enumerated() {
      self.missingTilePosition = indexPath.row
      var destinationIndexPath: IndexPath?
      
      if tilesToDrag.1 {
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
        if index == tilesToDrag.0.count - 1 {
          self.swapGroupOfTilesData(tilesToDrag, offset: offset)
          completion?()
        }
      })
    }
  }
  
  // This function swaps a group of tiles data with the missing one.
  func swapGroupOfTilesData(_ tilesToSwap: ([IndexPath], Bool), offset: Int) {
    
    for tileToSwap in tilesToSwap.0.reversed() {
      let tileToSwapArrayIndex = tileToSwap.row
      let tileToSwapX = Int(tileToSwapArrayIndex % tilesPerRow)
      let tileToSwapY = Int(tileToSwapArrayIndex / tilesPerRow)
      
      var destinationIndexPath: IndexPath?
      
      if tilesToSwap.1 {
        destinationIndexPath = IndexPath(row: tileToSwap.row - offset, section: 0)
      } else {
        destinationIndexPath = IndexPath(row: tileToSwap.row + offset, section: 0)
      }
      
      guard let destinationArrayIndex = destinationIndexPath?.row else {
        return
      }
      
      let destinationX = Int(destinationArrayIndex % tilesPerRow)
      let destinationY = Int(destinationArrayIndex / tilesPerRow)
      
      swapTiles(x1: tileToSwapX, y1: tileToSwapY, x2: destinationX, y2: destinationY)
    }
  }
  
  // This function determines whether or not the puzzle is solved.
  func checkIfPuzzleIsSolved() {
    var solved = true
    for i in 0 ..< tilesPerRow {
      for j in 0 ..< tilesPerRow {
        let n = j * tilesPerRow + i
        if tileData[n].originalX != i || tileData[n].originalY != j {
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
  
  // This function determines whether the passed index is located in the missing tile's row.
  func isInMissingTileRow(_ targetIndexPath: IndexPath) -> ([IndexPath], Bool)? {
    
    var indexPathsToDrag: [IndexPath] = []
    var left = false
    
    guard let missingCell = missingTileCell,
      let emptySlotIndexPath = collectionView?.indexPath(for: missingCell) else {
        return nil
    }
    
    if (emptySlotIndexPath.row / tilesPerRow == targetIndexPath.row / tilesPerRow) && targetIndexPath.row != emptySlotIndexPath.row {
      var index = targetIndexPath.row
      if index < emptySlotIndexPath.row {
        while index < emptySlotIndexPath.row {
          indexPathsToDrag.append(IndexPath(row: index, section: 0))
          index += 1
        }
      } else if index > emptySlotIndexPath.row {
        while index > emptySlotIndexPath.row {
          indexPathsToDrag.append(IndexPath(row: index, section: 0))
          index -= 1
        }
        left = true
      }
    }
    return indexPathsToDrag.count == 0 ? nil : (indexPathsToDrag, left)
  }
  
  // This function determines whether the passed index is located in the missing tile's column.
  func isInMissingTileColumn(_ targetIndexPath: IndexPath) -> ([IndexPath], Bool)? {

    var indexPathsToDrag: [IndexPath] = []
    var top = false

    guard let missingCell = missingTileCell,
      let emptySlotIndexPath = collectionView?.indexPath(for: missingCell) else {
        return nil
    }
    
    if (emptySlotIndexPath.row % tilesPerRow == targetIndexPath.row % tilesPerRow) && targetIndexPath.row != emptySlotIndexPath.row {
      var index = targetIndexPath.row
      if index < emptySlotIndexPath.row {
        while index < emptySlotIndexPath.row {
          indexPathsToDrag.append(IndexPath(row: index, section: 0))
          index += tilesPerRow
        }
      } else if index > emptySlotIndexPath.row {
        while index > emptySlotIndexPath.row {
          indexPathsToDrag.append(IndexPath(row: index, section: 0))
          index -= tilesPerRow
        }
        top = true
      }
    }
    
    return indexPathsToDrag.count == 0 ? nil : (indexPathsToDrag, top)
  }
  
  // This function handles the dragging of a tile.
  func handlePanGesture(gesture: UIPanGestureRecognizer) {
    
    guard let collectionView = collectionView else {
      return
    }
    
    switch(gesture.state) {
      
    // When a user starts dragging on the grid:
    case .began:
      
      // Detect the location at which the grid was touched.
      let locationInView = gesture.location(in: collectionView)

      // Detect the cell that was touched.
      guard let touchedIndexPath = collectionView.indexPathForItem(at: locationInView),
        let cellTouched = collectionView.cellForItem(at: touchedIndexPath) as? TileCollectionViewCell
        else {
          break
      }
      cellTouchedToDrag = cellTouched
      
      // Detect whether the user is dragging a group of tiles in the row or column of the missing tile.
      if let toDrag = isInMissingTileRow(touchedIndexPath) {
        indexesOfCellsToDrag = toDrag
        draggingHorizontally = true
      } else if let toDrag = isInMissingTileColumn(touchedIndexPath) {
        indexesOfCellsToDrag = toDrag
        draggingHorizontally = false
      }
      
      // Otherwise return.
      guard let indexPathsToDrag = indexesOfCellsToDrag else {
        return
      }
      
      // Track:
      // 1. The distances between the center of the tiles and the location being touched.
      // 2. The initial position of the tiles.
      dragFingerPositionsRelativeToCellsToDragCenters = []
      initialPositionsOfCellsToDragCenters = []
      
      for indexPathToDrag in indexPathsToDrag.0.reversed() {
        guard let cell = collectionView.cellForItem(at: indexPathToDrag) else {
          break
        }
        dragFingerPositionsRelativeToCellsToDragCenters!.append(CGPoint(x: locationInView.x - cell.center.x, y: locationInView.y - cell.center.y))
        initialPositionsOfCellsToDragCenters!.append(cell.center)
      }
      
    // While a user is dragging on the grid:
    case .changed:
      
      // Detect the new location at which the grid is being touched.
      let locationInView = gesture.location(in: collectionView)

      // Make sure all variables needed are set.
      guard let cellTouchedToDrag = cellTouchedToDrag,
        let dragFingerPositionsRelativeToCellsToDragCenters = dragFingerPositionsRelativeToCellsToDragCenters,
        let initialPositionsOfCellsToDragCenters = initialPositionsOfCellsToDragCenters,
        let indexPathOfCellTouchedToDrag = collectionView.indexPath(for: cellTouchedToDrag),
        let missingTileCell = missingTileCell else {
          break
      }
      
      var isBreakingUpperBoundRule = false
      var isBreakingLowerBoundRule = false
      
      // If dragging horizontally:
      if let tilesToDrag = indexesOfCellsToDrag, draggingHorizontally {
        
        // Make sure the group of tiles cannot be dragged backwards.
        if tilesToDrag.0[0] == indexPathOfCellTouchedToDrag {
          
          // Detect the location at which the user is trying to drag the tiles. The y coordinate is maintained static to keep the dragging completely horizontal.
          let potentialCenterOfLastTileToBeDragged = CGPoint(x: locationInView.x - dragFingerPositionsRelativeToCellsToDragCenters[dragFingerPositionsRelativeToCellsToDragCenters.count - 1].x,
                                                    y: cellTouchedToDrag.center.y)
          
          // Check if user is trying to drag the tile behind the initial position of the tile touched to drag.
          let isGoingLeft = tilesToDrag.1
          let initialPositionOfLastCellCenterToDrag = initialPositionsOfCellsToDragCenters[initialPositionsOfCellsToDragCenters.count - 1]
          
          if isGoingLeft && potentialCenterOfLastTileToBeDragged.x - initialPositionOfLastCellCenterToDrag.x > 0 {
            isBreakingLowerBoundRule = true
          } else if !isGoingLeft && initialPositionOfLastCellCenterToDrag.x - potentialCenterOfLastTileToBeDragged.x > 0 {
            isBreakingLowerBoundRule = true
          }
        }
        
        // Make sure the group of tiles do not go beyond the missing tile.
        if tilesToDrag.0[0] == indexPathOfCellTouchedToDrag {
          
          // Detect the location at which the user is trying to drag the tiles.
          let potentialCenterOfFirstTileToBeDragged = CGPoint(x: locationInView.x - dragFingerPositionsRelativeToCellsToDragCenters[0].x,
                                                    y: cellTouchedToDrag.center.y)
          
          // Check if user is trying to drag the tile beyond the missing tile cell.
          let isGoingLeft = tilesToDrag.1
          
          if isGoingLeft && missingTileCell.center.x - potentialCenterOfFirstTileToBeDragged.x > 0 {
            isBreakingUpperBoundRule = true
          } else if !isGoingLeft && potentialCenterOfFirstTileToBeDragged.x - missingTileCell.center.x > 0 {
            isBreakingUpperBoundRule = true
          }
        }
        
        // Drag each tile in the group of tiles.
        for (index, indexPath) in tilesToDrag.0.reversed().enumerated() {
          
          guard let cellToDrag = collectionView.cellForItem(at: indexPath) else {
            return
          }
          
          var newCellCenter = CGPoint(x: locationInView.x - dragFingerPositionsRelativeToCellsToDragCenters[index].x,
                                      y: cellToDrag.center.y)
          
          // Update the position at which to drag depending on whether or not a bounds rule was broken.
          if isBreakingLowerBoundRule {
            newCellCenter = initialPositionsOfCellsToDragCenters[index]
          }
          if isBreakingUpperBoundRule {
            switch index {
            case 0:
              newCellCenter = missingTileCell.center
            default:
              newCellCenter = initialPositionsOfCellsToDragCenters[index - 1]
            }
          }
          UIView.animate(withDuration: 0.1) {
            cellToDrag.center = newCellCenter
          }
        }
        
      // If dragging vertically:
      } else if let tilesToDrag = indexesOfCellsToDrag, !draggingHorizontally {
        
        // Make sure the group of tiles cannot be dragged backwards.
        if tilesToDrag.0[0] == indexPathOfCellTouchedToDrag {
          
          // Detect the location at which the user is trying to drag the tiles. The x coordinate is maintained static to keep the dragging completely vertical.
          let potentialCenterOfLastTileToBeDragged = CGPoint(x: cellTouchedToDrag.center.x,
                                                    y: locationInView.y - dragFingerPositionsRelativeToCellsToDragCenters[dragFingerPositionsRelativeToCellsToDragCenters.count - 1].y)
          
          // Check if user is trying to drag the tile behind the initial position of the tile touched to drag.
          let isGoingUp = tilesToDrag.1
          let initialPositionOfLastCellCenterToDrag = initialPositionsOfCellsToDragCenters[initialPositionsOfCellsToDragCenters.count - 1]
          
          if (isGoingUp && potentialCenterOfLastTileToBeDragged.y - initialPositionOfLastCellCenterToDrag.y > 0) ||
            (!isGoingUp && initialPositionOfLastCellCenterToDrag.y - potentialCenterOfLastTileToBeDragged.y > 0) {
            isBreakingLowerBoundRule = true
          }
        }
        
        // Make sure the group of tiles do not go beyond the missing tile.
        if tilesToDrag.0[0] == indexPathOfCellTouchedToDrag {
          
          // Detect the location at which the user is trying to drag the tiles.
          let potentialCenterOfFirstTileToBeDragged = CGPoint(x: cellTouchedToDrag.center.x,
                                                    y: locationInView.y - dragFingerPositionsRelativeToCellsToDragCenters[0].y)
          
          // Check if user is trying to drag the tile beyond the missing tile cell.
          let isGoingUp = tilesToDrag.1
          
          if (isGoingUp && missingTileCell.center.y - potentialCenterOfFirstTileToBeDragged.y > 0) ||
            (!isGoingUp && potentialCenterOfFirstTileToBeDragged.y - missingTileCell.center.y > 0) {
            isBreakingUpperBoundRule = true
          }
        }
        
        // Drag each tile in the group of tiles.
        for (index, indexPath) in tilesToDrag.0.reversed().enumerated() {
          
          guard let cellToDrag = collectionView.cellForItem(at: indexPath) else {
            return
          }
          
          var newCellCenter = CGPoint(x: cellToDrag.center.x,
                                      y: locationInView.y - dragFingerPositionsRelativeToCellsToDragCenters[index].y)
          
          // Update the position at which to drag depending on whether or not a bounds rule was broken.
          if isBreakingLowerBoundRule {
            newCellCenter = initialPositionsOfCellsToDragCenters[index]
          }
          if isBreakingUpperBoundRule {
            switch index {
            case 0:
              newCellCenter = missingTileCell.center
            default:
              newCellCenter = initialPositionsOfCellsToDragCenters[index - 1]
            }
          }
          UIView.animate(withDuration: 0.1) {
            cellToDrag.center = newCellCenter
          }
        }
        
      }
      
    // When a user stops dragging on the grid:
    case .ended:
      
      // Make sure all variables needed are set.
      guard let cellSelectedForPan = cellTouchedToDrag,
        let indexOfcellSelectedForPan = collectionView.indexPath(for: cellSelectedForPan),
        let dragOriginalCenters = initialPositionsOfCellsToDragCenters,
        let tileImageWidth = cellSelectedForPan.tileImageView.image?.size.width else {
          return
      }
      
      // Detect the distance of half a tile.
      let minimumDistance: CGFloat = CGFloat(CGFloat(tileImageWidth) / 2)
      
      // If sliding horizontally:
      if let tilesToDrag = isInMissingTileRow(indexOfcellSelectedForPan) {
        
        // Slide the group of tile if the distance dragged is more than half a tile.
        if let lastTileToDrag = collectionView.cellForItem(at: tilesToDrag.0[tilesToDrag.0.count - 1]),
            lastTileToDrag.center.distanceToPoint(p: dragOriginalCenters[0]) > minimumDistance {
          
          slideGroupOfTiles(collectionView, tilesToDrag: tilesToDrag, offset: 1, completion: {
            self.checkIfPuzzleIsSolved()
          })
          
        // Bring the group of tiles back to their original positions otherwise.
        } else {
          
          for (index, indexPath) in tilesToDrag.0.reversed().enumerated() {
            
            guard let cellToDrag = collectionView.cellForItem(at: indexPath) else {
              return
            }
            
            let newCellCenter = CGPoint(x: dragOriginalCenters[index].x,
                                        y: dragOriginalCenters[index].y)
            
            UIView.animate(withDuration: 0.1) {
              cellToDrag.center = newCellCenter
            }
          }
        }
        
      // If sliding vertically:
      } else if let tilesToDrag = isInMissingTileColumn(indexOfcellSelectedForPan) {
        
        // Slide the group of tile if the distance dragged is more than half a tile.
        if let lastTileToDrag = collectionView.cellForItem(at: tilesToDrag.0[tilesToDrag.0.count - 1]),
            lastTileToDrag.center.distanceToPoint(p: dragOriginalCenters[0]) > minimumDistance {
          
          slideGroupOfTiles(collectionView, tilesToDrag: tilesToDrag, offset: tilesPerRow, completion: {
            self.checkIfPuzzleIsSolved()
          })
          
        // Bring the group of tiles back to their original positions otherwise.
        } else {
          
          for (index, indexPath) in tilesToDrag.0.reversed().enumerated() {
            
            guard let cellToDrag = collectionView.cellForItem(at: indexPath) else {
              return
            }
            
            let newCellCenter = CGPoint(x: dragOriginalCenters[index].x,
                                        y: dragOriginalCenters[index].y)
            
            UIView.animate(withDuration: 0.1) {
              cellToDrag.center = newCellCenter
            }
          }
        }
        
      }
      
      // Reset values needed for next drag
      self.indexesOfCellsToDrag = nil
      self.dragFingerPositionsRelativeToCellsToDragCenters = nil
      self.initialPositionsOfCellsToDragCenters = nil
      self.cellTouchedToDrag = nil
      
    default: break
    }
  }
}

// MARK: UICollectionViewDataSource

extension PuzzleViewController {
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return tileData.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
    if let cell = cell as? TileCollectionViewCell {
      if indexPath.row == missingTilePosition {
        cell.tileImageView.image = nil
      } else {
        cell.tileImageView.image = tileData[indexPath.row].image
      }
    }
    
    return cell
  }
}

// MARK: UICollectionViewDelegate

extension PuzzleViewController {
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

    if let tilesToDrag = isInMissingTileRow(indexPath) {
      
      slideGroupOfTiles(collectionView, tilesToDrag: tilesToDrag, offset: 1, completion: {
        self.checkIfPuzzleIsSolved()
      })
      
    } else if let tilesToDrag = isInMissingTileColumn(indexPath) {
      
      slideGroupOfTiles(collectionView, tilesToDrag: tilesToDrag, offset: tilesPerRow, completion: {
        self.checkIfPuzzleIsSolved()
      })
      
    }
  }
}

// MARK: Configure spacing between tiles

extension PuzzleViewController : UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    let paddingSpace = sectionInsets.left * CGFloat(tilesPerRow + 1)
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = availableWidth / CGFloat(tilesPerRow)
    
    return CGSize(width: widthPerItem, height: widthPerItem)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return sectionInsets
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.left
  }
}
