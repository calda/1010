//
//  Game.swift
//  TenTen
//
//  Created by Cal Stephens on 4/13/25.
//

import GameplayKit
import Observation
import StoreKit
import SwiftUI

// MARK: - Game

@Observable
final class Game: Codable {

  // MARK: Lifecycle

  init(highScore: Int = 0) {
    score = 0
    achievements = []
    startDate = .now
    undoHistory = []
    self.highScore = highScore
    isHighScore = (highScore == 0)

    tiles = Array(
      repeating: Array(repeating: .empty, count: 10),
      count: 10,
    )

    availablePieces = []
    reloadAvailablePiecesIfNeeded()

    // When the game starts, animate out any existing pieces on the board
    animateAllTileUpdates()
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let score = try container.decode(Int.self, forKey: .score)
    let highScore = try container.decode(Int.self, forKey: .highScore)
    self.score = score
    self.highScore = highScore

    tiles = try container.decode([[Tile]].self, forKey: .tiles)
    availablePieces = try container.decode([RandomPiece?].self, forKey: .availablePieces)
    startDate = try container.decode(Date.self, forKey: .startDate)

    achievements = (try? container.decodeIfPresent([Achievement].self, forKey: .achievements)) ?? []
    undoHistory = (try? container.decode([UndoSnapshot].self, forKey: .undoHistory)) ?? []
    isHighScore = (try? container.decode(Bool.self, forKey: .isHighScore)) ?? (highScore <= score)
    powerupPosition = try? container.decodeIfPresent(Point.self, forKey: .powerupPosition)
    powerupTurnsRemaining = (try? container.decode(Int.self, forKey: .powerupTurnsRemaining)) ?? 0
    lastPowerupScore = (try? container.decode(Int.self, forKey: .lastPowerupScore)) ?? 0
    moveCount = (try? container.decode(Int.self, forKey: .moveCount)) ?? 0
    powerups = (try? container.decode([Powerup: Int].self, forKey: .powerups)) ?? [:]
  }

  // MARK: Internal

  /// The date and time that the user started playing the game
  let startDate: Date

  /// The number of points scored so far in this game. You score
  /// one point for every tile placed on the board.
  private(set) var score: Int

  /// The highest score every achieved in any game
  private(set) var highScore: Int

  /// Whether or not the current game is the user's high score
  private(set) var isHighScore: Bool

  /// A 10x10 grid of tiles that start empty and are filled by the randomly generated pieces
  private(set) var tiles: [[Tile]]

  /// Three slots of randomly generated pieces that can be dragged to the board
  private(set) var availablePieces: [RandomPiece?]

  /// Bonus 1x1 piece available from powerup (separate from the 3 main pieces)
  private(set) var bonusPiece = RandomPiece(id: UUID(), piece: .oneByOne)

  /// Achievements scored this game
  private(set) var achievements: [Achievement]

  /// Previous game states that can be restored
  private(set) var undoHistory: [UndoSnapshot]

  /// Active powerup position on the board (nil if no powerup)
  private(set) var powerupPosition: Point?

  /// Number of turns remaining to collect the powerup
  private(set) var powerupTurnsRemaining = 0

  /// Last score when powerup was spawned (used to track 500-point intervals)
  private(set) var lastPowerupScore = 0

  /// Inventory of collected powerups
  private(set) var powerups: [Powerup: Int] = [:]

  /// The piece that has just been selected and placed on the board
  private(set) var placedPiece: (piece: RandomPiece, targetTile: Point, dragDecelerationAnimation: Animation?)?

  /// The piece that has just been unplaced after an undo
  private(set) var unplacedPiece: (piece: RandomPiece, tile: Point, hidden: Bool)?

  /// Animations for when pieces should be removed from the board
  private(set) var tileAnimations = [Point: Animation]()

  /// Number of moves made (pieces placed) - used to track powerup timer
  private(set) var moveCount = 0

  /// Whether the game is in delete piece mode (pieces are jiggling and can be deleted)
  private(set) var isInDeleteMode = false

  /// Current powerup being collected with animation
  private(set) var collectingPowerup: Powerup?

  /// Whether or not there is a playable move based on the available pieces
  var hasPlayableMove: Bool {
    var allPieces = availablePieces
    if (powerups[.bonusPiece] ?? 0) > 0 {
      allPieces.append(bonusPiece)
    }

    for availablePiece in allPieces.compactMap({ $0?.piece }) {
      for tile in tiles.allPoints {
        if canAddPiece(availablePiece, at: tile) {
          return true
        }
      }
    }

    return false
  }

  /// Whether or not the last move can be undone
  var canUndoLastMove: Bool {
    guard !undoHistory.isEmpty else { return false }

    return undoHistory[0].canBeUndoneDuringGameplay
      // Any move can be undone on the game over screen
      || !hasPlayableMove
  }

  /// Whether or not it's possible to add the given piece to the given tile on the board
  func canAddPiece(_ piece: Piece, at point: Point) -> Bool {
    guard
      (point.x + piece.width) <= 10,
      (point.y + piece.height) <= 10
    else { return false }

    for x in 0..<piece.width {
      for y in 0..<piece.height {
        let pieceTile = piece.tiles[Point(x: x, y: y)]
        let gameTile = tiles[Point(x: point.x + x, y: point.y + y)]

        if gameTile.isFilled, pieceTile.isFilled {
          return false
        }
      }
    }

    return true
  }

  /// Adds the piece from the given draggable piece to the board at the given point
  func addPiece(from draggablePiece: DraggablePiece, at point: Point, dragDecelerationAnimation: Animation? = nil) {
    let randomPiece: RandomPiece

    switch draggablePiece {
    case .slot(let slot):
      guard
        let piece = availablePieces[slot],
        canAddPiece(piece.piece, at: point)
      else { return }
      randomPiece = piece

    case .bonusPiece:
      guard
        (powerups[.bonusPiece] ?? 0) > 0,
        canAddPiece(bonusPiece.piece, at: point)
      else { return }
      randomPiece = bonusPiece
    }

    let piece = randomPiece.piece
    recordUndoSnapshot(didPlacePiece: randomPiece, at: point, fromDraggablePiece: draggablePiece)

    increaseScore(by: piece.points)
    moveCount += 1
    placedPiece = (piece: randomPiece, targetTile: point, dragDecelerationAnimation: dragDecelerationAnimation)
    lightImpactGenerator.impactOccurred()

    // Wait for the drag deceleration animation (0.125s) to finish.
    DispatchQueue.main.asyncAfter_syncInUnitTests(deadline: .now() + 0.15) { [self] in
      // Use `withAnimation` to avoid an unexpected animation when
      // clearing the placed piece from its slot.
      withAnimation(nil) {
        removePiece(draggablePiece)
      }

      placedPiece = nil
      addPiece(piece, at: point)
      reloadAvailablePiecesIfNeeded()

      // Ensure the piece has been added to the board before we clear the filled rows.
      // Otherwise SwiftUI may miss the intermediate state where the piece is actually
      // briefly rendered on the board, and we won't get the expected removal animation.
      DispatchQueue.main.asyncAfter_syncInUnitTests(deadline: .now() + 0.025) {
        self.clearFilledRows(placedPiece: piece, placedLocation: point)

        // If an undo action was queued because of this active piece animation, trigger it now.
        self.performPendingUndoIfNecessary()
      }
    }
  }

  /// Increases the score by the given amount and awards any new achievements
  func increaseScore(by points: Int) {
    let previousScore = score
    score += points

    if score > highScore {
      highScore = score
      isHighScore = true
    }

    let scoreAchievements: [Int: Achievement] = [
      1_000: .oneThousandPoints,
      10_000: .tenThousandPoints,
      21_000: .twentyOneThousandPoints,
      100_000: .oneHundredThousandPoints,
      1_000_000: .oneMillionPoints,
    ]

    for (scoreGoal, achievement) in scoreAchievements {
      if score >= scoreGoal, !achievements.contains(achievement) {
        awardAchievement(achievement)
      }
    }

    // When the user passes 500 points for the first time, request an app review
    if score >= 500, previousScore < 500, isHighScore {
      Task { @MainActor in
        if let scene = UIApplication.shared.scene {
          AppStore.requestReview(in: scene)
        }
      }
    }

    // Spawn powerup every 500 points
    spawnPowerupIfNeeded()
  }

  /// Adds the piece to the given tile on the board
  func addPiece(_ piece: Piece, at point: Point) {
    guard canAddPiece(piece, at: point) else { return }

    for x in 0..<piece.width {
      for y in 0..<piece.height {
        let pieceTile = piece.tiles[Point(x: x, y: y)]

        if pieceTile.isFilled {
          tiles[Point(x: point.x + x, y: point.y + y)] = pieceTile
        }
      }
    }
  }

  /// Removes the piece from the given draggable piece after it's been played
  func removePiece(_ draggablePiece: DraggablePiece) {
    switch draggablePiece {
    case .slot(let slot):
      availablePieces[slot] = nil
    case .bonusPiece:
      usePowerup(.bonusPiece)
    }
  }

  /// Reloads the set of available pieces if all slots are empty
  func reloadAvailablePiecesIfNeeded(newPieces: [RandomPiece]? = nil) {
    guard availablePieces.allSatisfy({ $0 == nil }) else { return }

    if let newPieces {
      assert(newPieces.count == 3)
      availablePieces = newPieces
    } else {
      availablePieces = [
        generateRandomPiece(slot: 0),
        generateRandomPiece(slot: 1),
        generateRandomPiece(slot: 2),
      ]
    }

    // Award achievements for randomly getting all 3x3s or 1x1s
    if availablePieces.allSatisfy({ $0?.piece == .threeByThree }) {
      awardAchievement(.allThreeByThrees)
    }

    if availablePieces.allSatisfy({ $0?.piece == .oneByOne }) {
      awardAchievement(.allOneByOnes)
    }
  }

  /// Generates a random piece, seeded by the game start date
  /// This ensures if we undo to before a set of pieces was generated,
  /// then we still get the same set of generated pieces next time.
  func generateRandomPiece(slot: Int) -> RandomPiece {
    let seed = slot + score + startDate.hashValue

    var randomPiece = Piece.spawnTable.randomElement(seed: seed)

    // Rotate the piece 0º, 90º, 180º, or 270º
    randomPiece =
      switch [0, 1, 2, 3].randomElement(seed: seed) {
      case 0:
        randomPiece
      case 1:
        randomPiece.rotated
      case 2:
        randomPiece.rotated.rotated
      case 3:
        randomPiece.rotated.rotated.rotated
      default:
        randomPiece
      }

    return RandomPiece(id: UUID(), piece: randomPiece)
  }

  /// Clears any row or column of the board that is fully filled with pieces
  func clearFilledRows(placedPiece: Piece, placedLocation: Point) {
    // Compute all of the tiles that are eligible to be cleared before we remove any.
    var tilesToClear = [Point: Double]()
    var tilesPerDelay = [Double: Int]()
    var clears = 0

    for x in 0...9 {
      let column = Array(0...9).map { y in Point(x: x, y: y) }
      let shouldClearColumn = column.allSatisfy { tiles[$0].isFilled }

      if shouldClearColumn {
        clears += 1

        for point in column {
          let delay = clearDelay(for: point, placedPiece: placedPiece, placedLocation: placedLocation)
          tilesToClear[point] = delay
          tilesPerDelay[delay, default: 0] += 1
        }
      }
    }

    for y in 0...9 {
      let row = Array(0...9).map { x in Point(x: x, y: y) }
      let shouldClearRow = row.allSatisfy { tiles[$0].isFilled }

      if shouldClearRow {
        clears += 1

        for point in row {
          let delay = clearDelay(for: point, placedPiece: placedPiece, placedLocation: placedLocation)
          tilesToClear[point] = delay
          tilesPerDelay[delay, default: 0] += 1
        }
      }
    }

    // Check if powerup should be collected before clearing tiles
    checkPowerupCollection(clearedTiles: Set(tilesToClear.keys))

    for tileToClear in tilesToClear.keys {
      tiles[tileToClear] = .empty
    }

    // Award an achievement after clearing the entire board
    if clears >= 1, tiles.allPoints.allSatisfy({ tiles[$0].isEmpty }) {
      awardAchievement(.clearEntireBoard)
    }

    // Award an achievement after clearing 6 rows/columns at once with a 3x3 piece
    if clears == 6 {
      awardAchievement(.sixClears)
    }

    // Store the delays for the cascade animation, and then clear them after the animations start.
    // This lets the tiles see the delay when the removal animation is performed, but prevents
    // the animation from still being present if a place is placed there quickly after the clear animation.
    // We don't use `withAnimation(.spring.delay(delay))` because it doesn't work, and we don't use
    // `DispatchQueue.main.asyncAfter(deadline: .now() + delay)` because it has performance issues.
    for (tileToClear, delay) in tilesToClear {
      tileAnimations[tileToClear] = .spring.delay(delay)
    }
    
    lightImpactGenerator.prepare()
    mediumImpactGenerator.prepare()
    heavyImpactGenerator.prepare()
    
    for (delay, count) in tilesPerDelay {
      // Stretch out the haptics a bit longer to more closely match the perceived visuals
      let hapticDelay = delay * 1.25
      
      DispatchQueue.main.asyncAfter(deadline: .now() + hapticDelay) {
        switch count {
        case 1:
          self.lightImpactGenerator.impactOccurred()
        case 2, 3:
          self.mediumImpactGenerator.impactOccurred()
        default: // 4, 5, 6:
          self.heavyImpactGenerator.impactOccurred()
        }
      }
    }

    DispatchQueue.main.asyncAfter_syncInUnitTests(deadline: .now() + 0.05) {
      self.tileAnimations = [:]
    }
  }

  /// The delay for removing a piece from the board after clearing a row.
  /// Radiates outwards from the placed piece.
  func clearDelay(for tile: Point, placedPiece: Piece, placedLocation: Point) -> Double {
    // The tiles on the board that are filled in the placed piece
    let pieceTilesOnBoard = placedPiece.tilesOnBoard(at: placedLocation)
    let distanceToClosestPointInPiece = pieceTilesOnBoard.map { tile.distance(to: $0) }.min()
    return (distanceToClosestPointInPiece ?? 0) * 0.025
  }

  /// Creates a new game, preserving any persistent data, and recording the final score of this game
  func newGame() -> Game {
    GameCenterManager.recordFinalScore(score)
    return Game(highScore: highScore)
  }

  /// Records an entry in the undo stack that can be restored later.
  func recordUndoSnapshot(
    didPlacePiece placedPiece: RandomPiece,
    at point: Point,
    fromDraggablePiece draggablePiece: DraggablePiece,
  ) {
    recordUndoSnapshot(action: .placePiece(piece: placedPiece, point: point, source: draggablePiece))
  }

  /// Records an entry in the undo stack for a delete action.
  func recordUndoSnapshot(didDeletePieceInSlot slot: Int) {
    recordUndoSnapshot(action: .deletePiece(slot: slot))
  }

  /// Restores the most recent undo snapshot and removes it from the undo stack if permitted
  func undoLastMove() {
    // Exit delete mode if active
    exitDeleteMode()

    // If there's already an active piece animation, queue this undo to be handled
    // after that animation ends. This is supported so that tapping the undo button
    // multiple times in quick succession works as expected.
    guard unplacedPiece == nil, placedPiece == nil else {
      pendingUndoCount += 1
      return
    }

    guard canUndoLastMove else {
      pendingUndoCount = 0
      return
    }

    let restoredSnapshot = undoHistory.removeFirst()

    // Handle different types of undo actions
    switch restoredSnapshot.action {
    case .placePiece(let piece, let tile, _):
      undoPlacePieceAction(piece: piece, tile: tile, restoredSnapshot: restoredSnapshot)
    case .deletePiece:
      undoDeletePieceAction(restoredSnapshot: restoredSnapshot)
    }
  }

  /// Performs any pending undo action
  func performPendingUndoIfNecessary() {
    if pendingUndoCount > 1 {
      pendingUndoCount -= 1
      undoLastMove()
    }
  }

  /// Animates any updates to tiles (removals or insertions) by temporarily
  /// providing a `tileAnimation` for all points on the board.
  func animateAllTileUpdates() {
    for point in tiles.allPoints {
      tileAnimations[point] = .spring
    }

    DispatchQueue.main.asyncAfter_syncInUnitTests(deadline: .now() + 0.1) {
      self.tileAnimations = [:]
    }
  }

  /// Spawns a powerup at a random empty tile if score has increased by 500 points
  func spawnPowerupIfNeeded(newPowerupPosition: Point? = nil) {
    guard powerupPosition == nil else { return }

    #if targetEnvironment(simulator)
    let lowerScoreThreshold = NSClassFromString("XCTest") == nil
    #else
    let lowerScoreThreshold = false
    #endif

    let pointsBetweenPowerups = lowerScoreThreshold ? 10 : 500
    let turnsForPowerup = lowerScoreThreshold ? 20 : 5

    guard ((score - lastPowerupScore) >= pointsBetweenPowerups) || newPowerupPosition != nil else { return }

    let emptyTiles = tiles.allPoints.filter { tiles[$0].isEmpty }
    let randomTile = newPowerupPosition ?? emptyTiles.randomElement(seed: score + startDate.hashValue)

    powerupPosition = randomTile
    powerupTurnsRemaining = turnsForPowerup
    lastPowerupScore = score
  }

  /// Decrements the powerup timer and removes powerup if time expires
  func decrementPowerupTimer() {
    guard powerupPosition != nil else { return }

    powerupTurnsRemaining -= 1
    if powerupTurnsRemaining <= 0 {
      powerupPosition = nil
    }
  }

  /// Checks if powerup should be collected when clearing rows/columns
  func checkPowerupCollection(clearedTiles: Set<Point>) {
    guard let powerupPos = powerupPosition else { return }
    successGenerator.prepare()

    if clearedTiles.contains(powerupPos) {
      // Start powerup collection animation
      let randomPowerup = Powerup.allCases.randomElement(seed: score + startDate.hashValue)
      collectingPowerup = randomPowerup

      // Award powerup after animation reaches the button (0.9 seconds)
      DispatchQueue.main.asyncAfter_syncInUnitTests(deadline: .now() + 0.9) { [self] in
        awardPowerup(randomPowerup)
      }

      // Clean up after full animation (1 second)
      DispatchQueue.main.asyncAfter_syncInUnitTests(deadline: .now() + 1.0) { [self] in
        powerupPosition = nil
        powerupTurnsRemaining = 0
        collectingPowerup = nil
      }
    } else {
      decrementPowerupTimer()
    }
  }

  /// Awards a powerup to the player's inventory
  func awardPowerup(_ powerupType: Powerup) {
    powerups[powerupType, default: 0] += 1
    successGenerator.notificationOccurred(.success)

    // Generate a new bonus piece with unique ID when awarding bonus piece powerup
    if powerupType == .bonusPiece {
      generateNewBonusPiece()
    }
  }

  /// Uses a powerup from the player's inventory
  @discardableResult
  func usePowerup(_ powerupType: Powerup) -> Bool {
    guard let count = powerups[powerupType], count > 0 else { return false }
    powerups[powerupType] = count - 1

    // Generate a new bonus piece with unique ID when using bonus piece powerup
    if powerupType == .bonusPiece {
      generateNewBonusPiece()
    }

    return true
  }

  /// Uses the delete piece powerup to remove a piece from the available pieces
  func useDeletePiecePowerup(slot: Int) -> Bool {
    guard usePowerup(.deletePiece) else { return false }
    guard slot >= 0, slot < availablePieces.count else { return false }

    removePiece(.slot(slot))
    reloadAvailablePiecesIfNeeded()
    return true
  }

  /// Enters delete piece mode - pieces will jiggle and be selectable for deletion
  @discardableResult
  func enterDeleteMode() -> Bool {
    guard (powerups[.deletePiece] ?? 0) > 0 else { return false }
    isInDeleteMode = true
    return true
  }

  /// Exits delete piece mode
  func exitDeleteMode() {
    isInDeleteMode = false
  }

  /// Deletes a piece from the available pieces (used when in delete mode)
  func deletePieceInSlot(_ slot: Int) {
    guard isInDeleteMode else { return }
    guard slot >= 0, slot < availablePieces.count else { return }
    guard availablePieces[slot] != nil else { return }

    // Check if we have the powerup before proceeding
    guard (powerups[.deletePiece] ?? 0) > 0 else { return }

    // Record undo snapshot BEFORE consuming the powerup
    recordUndoSnapshot(didDeletePieceInSlot: slot)

    // Now consume the powerup
    usePowerup(.deletePiece)

    removePiece(.slot(slot))
    exitDeleteMode()

    // Wait a moment before regenerating new pieces if needed
    // to prevent them from visually overlapping
    DispatchQueue.main.asyncAfter_syncInUnitTests(deadline: .now() + 0.2) {
      self.reloadAvailablePiecesIfNeeded()
    }
  }

  // MARK: Private

  let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
  let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
  let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
  let successGenerator = UINotificationFeedbackGenerator()
  
  /// The number of undo actions that are pending because another undo is already animating
  private var pendingUndoCount = 0

  /// Records an entry in the undo stack with the specified action.
  private func recordUndoSnapshot(action: UndoAction) {
    // You can't undo after receiving new random pieces (except on the game over screen)
    // so you can never undo more than three times in a row.
    let undoStackLimit = 3

    let snapshot = UndoSnapshot(
      score: score,
      tiles: tiles,
      availablePieces: availablePieces,
      bonusPiece: bonusPiece,
      action: action,
      powerupPosition: powerupPosition,
      powerupTurnsRemaining: powerupTurnsRemaining,
      lastPowerupScore: lastPowerupScore,
      moveCount: moveCount,
      powerups: powerups,
    )

    undoHistory.insert(snapshot, at: 0)

    while undoHistory.count > undoStackLimit {
      undoHistory.removeLast()
    }
  }

  /// Undoes a piece placement action
  private func undoPlacePieceAction(piece: RandomPiece, tile: Point, restoredSnapshot: UndoSnapshot) {
    unplacedPiece = (piece: piece, tile: tile, hidden: false)

    // Check if placing the tile triggered a clear
    let pieceTilesInBoard = piece.piece.tilesOnBoard(at: tile)
    let clearedTilesFromPiece = pieceTilesInBoard.filter { !tiles[$0].isFilled }
    let pieceTriggeredClear = !clearedTilesFromPiece.isEmpty

    // Restore the board back to its previous state
    restore(restoredSnapshot)

    let animateUnplacedPiece = {
      // Ensure the unplaced piece anchor coexists with the draggable piece for a moment
      // so the matched geometry effect animation can play.
      DispatchQueue.main.asyncAfter_syncInUnitTests(deadline: .now() + 0.05) { [self] in
        unplacedPiece = nil

        // Now that the undo animation is complete, trigger any pending undo
        performPendingUndoIfNecessary()
      }
    }

    // If the undo un-clears any rows, animate those back in first.
    if pieceTriggeredClear {
      // Restore the cleared pieces of this tile back to the board
      // so they can be part of the un-clear animation
      // (the board snapshot is from before the piece was placed)
      for pieceTileInBoard in pieceTilesInBoard {
        tiles[pieceTileInBoard] = .filled(piece.piece.color)
      }

      animateAllTileUpdates()

      // Hide the unplaced piece while we wait for its clear tiles to animate back in
      unplacedPiece?.hidden = true

      // Play the piece unplace animation after the cleared tiles animate back in
      DispatchQueue.main.asyncAfter_syncInUnitTests(deadline: .now() + 0.325) {
        // Unplace the piece tiles that were added temporarily
        self.tiles = restoredSnapshot.tiles

        self.unplacedPiece?.hidden = false
        animateUnplacedPiece()
      }
    }

    else {
      animateUnplacedPiece()
    }
  }

  /// Undoes a piece deletion action
  private func undoDeletePieceAction(restoredSnapshot: UndoSnapshot) {
    // Restore the game state (this will restore the deleted piece and the powerup)
    restore(restoredSnapshot)

    // Complete the undo immediately since there's no piece animation needed
    performPendingUndoIfNecessary()
  }

  /// Generates a new bonus piece with a unique ID
  private func generateNewBonusPiece() {
    bonusPiece = RandomPiece(id: UUID(), piece: .oneByOne)
  }

  private func awardAchievement(_ achievement: Achievement) {
    guard !achievements.contains(achievement) else { return }
    achievements.append(achievement)
    GameCenterManager.report(achievement)
  }

}

extension Game {
  enum CodingKeys: CodingKey {
    case score
    case highScore
    case tiles
    case availablePieces
    case achievements
    case startDate
    case undoHistory
    case isHighScore
    case powerupPosition
    case powerupTurnsRemaining
    case lastPowerupScore
    case moveCount
    case powerups
  }

  var data: Data {
    get throws {
      let encoder = JSONEncoder()
      encoder.outputFormatting = .sortedKeys
      return try encoder.encode(self)
    }
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(score, forKey: .score)
    try container.encode(highScore, forKey: .highScore)
    try container.encode(tiles, forKey: .tiles)
    try container.encode(availablePieces, forKey: .availablePieces)

    try container.encode(achievements, forKey: .achievements)
    try container.encode(startDate, forKey: .startDate)
    try container.encode(undoHistory, forKey: .undoHistory)
    try container.encode(isHighScore, forKey: .isHighScore)
    try container.encode(powerupPosition, forKey: .powerupPosition)
    try container.encode(powerupTurnsRemaining, forKey: .powerupTurnsRemaining)
    try container.encode(lastPowerupScore, forKey: .lastPowerupScore)
    try container.encode(moveCount, forKey: .moveCount)
    try container.encode(powerups, forKey: .powerups)
  }
}

extension Game {
  static var saved: Result<Game?, Error> {
    guard let data = NSUbiquitousKeyValueStore().data(forKey: "game") else {
      return .success(nil)
    }

    return Result {
      try JSONDecoder().decode(Game.self, from: data)
    }
  }

  static func save(data: Data) throws {
    NSUbiquitousKeyValueStore().set(data, forKey: "game")
  }
}

// MARK: - UndoSnapshot

// MARK: - UndoAction

/// The type of action that created this undo snapshot
enum UndoAction: Codable {
  case placePiece(piece: RandomPiece, point: Point, source: DraggablePiece)
  case deletePiece(slot: Int)
}

/// A snapshot of game state that can be restored later
struct UndoSnapshot: Codable {
  let score: Int
  let tiles: [[Tile]]
  let availablePieces: [RandomPiece?]
  let bonusPiece: RandomPiece

  /// The action that was taken when this snapshot was created
  let action: UndoAction

  /// Powerup state when snapshot was created
  let powerupPosition: Point?
  let powerupTurnsRemaining: Int
  let lastPowerupScore: Int
  let moveCount: Int
  let powerups: [Powerup: Int]

  /// Whether or not this move can be undone during normal gameplay.
  /// We don't allow undoing a move after the random pieces are regenerated.
  /// From the game over screen, any move can be undone.
  var canBeUndoneDuringGameplay: Bool {
    switch action {
    case .placePiece(_, _, let source):
      switch source {
      case .slot:
        // For regular pieces, check if there are still pieces available
        availablePieces.count(where: { $0 != nil }) > 1
      case .bonusPiece:
        // Bonus piece moves can always be undone during gameplay
        true
      }

    case .deletePiece:
      // Delete actions can always be undone during gameplay
      true
    }
  }

  /// Legacy computed properties for backward compatibility
  var placedPiece: RandomPiece {
    switch action {
    case .placePiece(let piece, _, _):
      piece
    case .deletePiece:
      fatalError("No placed piece for delete action")
    }
  }

  var placedPiecePoint: Point {
    switch action {
    case .placePiece(_, let point, _):
      point
    case .deletePiece:
      fatalError("No placed piece point for delete action")
    }
  }

  var placedPieceSource: DraggablePiece {
    switch action {
    case .placePiece(_, _, let source):
      source
    case .deletePiece:
      fatalError("No placed piece source for delete action")
    }
  }
}

extension Game {
  private func restore(_ undoSnapshot: UndoSnapshot) {
    score = undoSnapshot.score
    tiles = undoSnapshot.tiles
    availablePieces = undoSnapshot.availablePieces
    bonusPiece = undoSnapshot.bonusPiece
    powerupPosition = undoSnapshot.powerupPosition
    powerupTurnsRemaining = undoSnapshot.powerupTurnsRemaining
    lastPowerupScore = undoSnapshot.lastPowerupScore
    moveCount = undoSnapshot.moveCount
    powerups = undoSnapshot.powerups
  }
}

// MARK: Helpers

extension DispatchQueue {
  func async_syncInUnitTests(excute: @escaping () -> Void) {
    if NSClassFromString("XCTest") != nil {
      excute()
    } else {
      async(execute: excute)
    }
  }

  func asyncAfter_syncInUnitTests(
    deadline: DispatchTime,
    excute: @escaping () -> Void,
  ) {
    if NSClassFromString("XCTest") != nil {
      excute()
    } else {
      asyncAfter(deadline: deadline, execute: excute)
    }
  }
}

extension CGPoint {
  func distance(to point: CGPoint) -> CGFloat {
    sqrt(pow(point.x - x, 2) + pow(point.y - y, 2))
  }
}

extension Point {
  func distance(to point: Point) -> CGFloat {
    CGPoint(x: x, y: y).distance(to: CGPoint(x: point.x, y: point.y))
  }
}

extension RandomAccessCollection where Index == Int {
  /// Returns a random element in this collection, using the given random seed.
  func randomElement(seed: Int) -> Element {
    assert(!isEmpty)

    let distribution = GKRandomDistribution(
      randomSource: GKMersenneTwisterRandomSource(seed: UInt64(abs(seed))),
      lowestValue: indices.first!,
      highestValue: indices.last!,
    )

    return self[distribution.nextInt()]
  }
}
