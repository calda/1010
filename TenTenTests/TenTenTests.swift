//
//  TenTenTests.swift
//  TenTenTests
//
//  Created by Cal Stephens on 4/13/25.
//

import Foundation
import Testing
@testable import TenTen

// MARK: - TenTenTests

struct TenTenTests {

  @Test
  func addPieces() {
    let game = Game()
    #expect(game.canAddPiece(.oneByOne, at: Point(x: 0, y: 0)))
    game.addPiece(.oneByOne, at: Point(x: 0, y: 0))
    #expect(!game.canAddPiece(.oneByOne, at: Point(x: 0, y: 0)))

    #expect(game.canAddPiece(.threeByThree, at: Point(x: 1, y: 1)))
    game.addPiece(.threeByThree, at: Point(x: 1, y: 1))
    #expect(!game.canAddPiece(.threeByThree, at: Point(x: 1, y: 1)))

    #expect(game.canAddPiece(.twoByTwoElbow, at: Point(x: 5, y: 7)))
    game.addPiece(.twoByTwoElbow, at: Point(x: 5, y: 7))
    #expect(!game.canAddPiece(.twoByTwoElbow, at: Point(x: 5, y: 7)))

    #expect(game.canAddPiece(.oneByFive, at: Point(x: 0, y: 9)))
    game.addPiece(.oneByFive, at: Point(x: 0, y: 9))
    #expect(!game.canAddPiece(.oneByFive, at: Point(x: 0, y: 9)))

    #expect(game.canAddPiece(.twoByTwo, at: Point(x: 8, y: 4)))
    game.addPiece(.twoByTwo, at: Point(x: 8, y: 4))
    #expect(!game.canAddPiece(.twoByTwo, at: Point(x: 8, y: 4)))

    #expect(game.canAddPiece(.twoByTwoElbow, at: Point(x: 0, y: 3)))
    game.addPiece(.twoByTwoElbow, at: Point(x: 0, y: 3))
    #expect(!game.canAddPiece(.twoByTwoElbow, at: Point(x: 0, y: 3)))

    #expect(game.tiles.filledValues == [
      [1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 1, 1, 1, 0, 0, 0, 0, 0, 0],
      [0, 1, 1, 1, 0, 0, 0, 0, 0, 0],
      [1, 1, 1, 1, 0, 0, 0, 0, 0, 0],
      [1, 1, 0, 0, 0, 0, 0, 0, 1, 1],
      [0, 0, 0, 0, 0, 0, 0, 0, 1, 1],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 1, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 1, 1, 0, 0, 0],
      [1, 1, 1, 1, 1, 0, 0, 0, 0, 0],
    ])

    #expect(!game.canAddPiece(.threeByThree, at: Point(x: 0, y: 0)))
    #expect(!game.canAddPiece(.twoByTwoElbow, at: Point(x: 4, y: 9)))
  }

  @Test
  func reloadsSlotsAfterPlacingPieces() {
    let game = Game(highScore: 5)
    game.updateAvailablePieces(to: [.oneByOne, .twoByTwo, .threeByThree])

    #expect(game.availablePieces[0] != nil)
    #expect(game.availablePieces[1] != nil)
    #expect(game.availablePieces[2] != nil)

    game.addPiece(inSlot: 0, at: Point(x: 0, y: 0))
    #expect(game.availablePieces[0] == nil)
    #expect(game.availablePieces[1] != nil)
    #expect(game.availablePieces[2] != nil)
    #expect(game.score == 1)
    #expect(game.highScore == 5)

    game.addPiece(inSlot: 1, at: Point(x: 4, y: 4))
    #expect(game.availablePieces[0] == nil)
    #expect(game.availablePieces[1] == nil)
    #expect(game.availablePieces[2] != nil)
    #expect(game.score == 1 + 4)
    #expect(game.highScore == 5)

    game.addPiece(inSlot: 2, at: Point(x: 7, y: 7))
    #expect(game.availablePieces[0] != nil)
    #expect(game.availablePieces[1] != nil)
    #expect(game.availablePieces[2] != nil)
    #expect(game.score == 14)
    #expect(game.highScore == 14)
  }

  @Test
  func clearsFilledRows() {
    let game = Game()
    game.addPiece(.threeByThree, at: Point(x: 0, y: 0))
    game.addPiece(.threeByThree, at: Point(x: 0, y: 3))
    game.addPiece(.threeByThree, at: Point(x: 0, y: 6))
    game.addPiece(.oneByThree, at: Point(x: 0, y: 9))
    game.addPiece(.threeByThree, at: Point(x: 3, y: 0))
    game.addPiece(.threeByThree, at: Point(x: 6, y: 0))
    game.addPiece(.oneByOne, at: Point(x: 9, y: 0))
    game.addPiece(.oneByOne, at: Point(x: 9, y: 1))
    game.addPiece(.oneByOne, at: Point(x: 9, y: 2))
    #expect(game.tiles.flatMap(\.self).count(where: \.isFilled) == 51)

    game.clearFilledRows(placedPiece: .threeByThree, placedLocation: Point(x: 0, y: 0))
    #expect(game.tiles.flatMap(\.self).count(where: \.isFilled) == 0)
  }

  @Test
  func clearDelayCascadesFromPlacedPiece() {
    let game = Game()
    let clearDelay = { (point: Point) in
      game.clearDelay(for: point, placedPiece: .twoByTwo, placedLocation: Point(x: 5, y: 5))
    }

    #expect(clearDelay(Point(x: 0, y: 6)).approximatelyEquals(0.125))
    #expect(clearDelay(Point(x: 1, y: 6)).approximatelyEquals(0.1))
    #expect(clearDelay(Point(x: 2, y: 6)).approximatelyEquals(0.075))
    #expect(clearDelay(Point(x: 3, y: 6)).approximatelyEquals(0.05))
    #expect(clearDelay(Point(x: 4, y: 6)).approximatelyEquals(0.025))
    #expect(clearDelay(Point(x: 5, y: 6)).approximatelyEquals(0))
    #expect(clearDelay(Point(x: 6, y: 6)).approximatelyEquals(0))
    #expect(clearDelay(Point(x: 7, y: 6)).approximatelyEquals(0.025))
    #expect(clearDelay(Point(x: 8, y: 6)).approximatelyEquals(0.05))
    #expect(clearDelay(Point(x: 9, y: 6)).approximatelyEquals(0.075))

    #expect(clearDelay(Point(x: 5, y: 0)).approximatelyEquals(0.125))
    #expect(clearDelay(Point(x: 5, y: 1)).approximatelyEquals(0.1))
    #expect(clearDelay(Point(x: 5, y: 2)).approximatelyEquals(0.075))
    #expect(clearDelay(Point(x: 5, y: 3)).approximatelyEquals(0.05))
    #expect(clearDelay(Point(x: 5, y: 4)).approximatelyEquals(0.025))
    #expect(clearDelay(Point(x: 5, y: 5)).approximatelyEquals(0))
    #expect(clearDelay(Point(x: 5, y: 6)).approximatelyEquals(0))
    #expect(clearDelay(Point(x: 5, y: 7)).approximatelyEquals(0.025))
    #expect(clearDelay(Point(x: 5, y: 8)).approximatelyEquals(0.05))
    #expect(clearDelay(Point(x: 5, y: 9)).approximatelyEquals(0.075))
  }

  @Test
  func noPlayableMove() {
    let game = Game()

    // Fill the board with a checkerboard pattern. Only 1x1 pieces will be playable.
    for tile in game.tiles.allPoints {
      if (tile.x + tile.y) % 2 == 0 {
        game.addPiece(.oneByOne, at: tile)
      }
    }

    game.updateAvailablePieces(to: [.oneByOne, .threeByThree, .threeByThree])
    #expect(game.hasPlayableMove)

    game.updateAvailablePieces(to: [.threeByThree, .threeByThree, .threeByThree])
    #expect(!game.hasPlayableMove)
  }

  @Test
  func rotatePieces() {
    #expect(Piece.oneByTwo.rotated == Piece(
      color: Piece.oneByTwo.color,
      tiles: [
        [1],
        [1],
      ],
    ))

    #expect(Piece.oneByTwo.rotated.rotated == .oneByTwo)

    #expect(Piece.oneByFive.rotated == Piece(
      color: Piece.oneByFive.color,
      tiles: [
        [1],
        [1],
        [1],
        [1],
        [1],
      ],
    ))

    #expect(Piece.oneByFive.rotated.rotated == .oneByFive)

    #expect(Piece.twoByTwoElbow.rotated == Piece(
      color: Piece.twoByTwoElbow.color,
      tiles: [
        [0, 1],
        [1, 1],
      ],
    ))

    #expect(Piece.twoByTwoElbow.rotated.rotated == Piece(
      color: Piece.twoByTwoElbow.color,
      tiles: [
        [1, 1],
        [0, 1],
      ],
    ))

    #expect(Piece.twoByTwoElbow.rotated.rotated.rotated == Piece(
      color: Piece.twoByTwoElbow.color,
      tiles: [
        [1, 1],
        [1, 0],
      ],
    ))

    #expect(Piece.twoByTwoElbow.rotated.rotated.rotated.rotated == .twoByTwoElbow)

    #expect(Piece.oneByOne.rotated == .oneByOne)
    #expect(Piece.twoByTwo.rotated == .twoByTwo)
    #expect(Piece.threeByThree.rotated == .threeByThree)
  }

  @Test
  func scoreAchievements() {
    let game = Game()
    #expect(game.achievements.isEmpty)

    game.updateScore(to: 999)
    #expect(game.achievements.isEmpty)

    game.updateScore(to: 1_010)
    #expect(game.achievements == [
      .oneThousandPoints
    ])

    game.updateScore(to: 1_025)
    #expect(game.achievements == [
      .oneThousandPoints
    ])

    game.updateScore(to: 11_000)
    #expect(game.achievements == [
      .oneThousandPoints,
      .tenThousandPoints,
    ])

    game.updateScore(to: 21_000)
    #expect(game.achievements == [
      .oneThousandPoints,
      .tenThousandPoints,
      .twentyOneThousandPoints,
    ])

    game.updateScore(to: 123_456)
    #expect(game.achievements == [
      .oneThousandPoints,
      .tenThousandPoints,
      .twentyOneThousandPoints,
      .oneHundredThousandPoints,
    ])

    game.updateScore(to: 1_000_001)
    #expect(game.achievements == [
      .oneThousandPoints,
      .tenThousandPoints,
      .twentyOneThousandPoints,
      .oneHundredThousandPoints,
      .oneMillionPoints,
    ])
  }

  @Test
  func undoLastMove() {
    let game = Game()
    game.updateAvailablePieces(to: [.oneByOne, .oneByOne, .oneByOne])
    #expect(!game.canUndoLastMove)
    #expect(game.isHighScore)

    let firstPiece = game.availablePieces[0]
    let emptyBoard = game.tiles

    game.addPiece(inSlot: 0, at: Point(x: 0, y: 0))
    #expect(game.canUndoLastMove)
    #expect(game.availablePieces[0] == nil)
    #expect(game.tiles != emptyBoard)
    #expect(game.score == 1)
    #expect(game.highScore == 1)
    #expect(game.isHighScore)

    // Undo a single move
    game.undoLastMove()
    #expect(!game.canUndoLastMove)
    #expect(game.availablePieces[0] == firstPiece)
    #expect(game.tiles == emptyBoard)
    #expect(game.score == 0)
    #expect(game.highScore == 1)
    #expect(game.isHighScore)

    // Undo two moves in a row
    game.addPiece(inSlot: 0, at: Point(x: 1, y: 1))
    game.addPiece(inSlot: 1, at: Point(x: 2, y: 2))
    #expect(game.tiles != emptyBoard)
    #expect(game.canUndoLastMove)
    game.undoLastMove()
    #expect(game.canUndoLastMove)
    game.undoLastMove()

    #expect(!game.canUndoLastMove)
    #expect(game.tiles == emptyBoard)

    // During gameplay you can't undo after regenerating new pieces
    game.addPiece(inSlot: 0, at: Point(x: 1, y: 1))
    game.addPiece(inSlot: 1, at: Point(x: 2, y: 2))
    game.addPiece(inSlot: 2, at: Point(x: 5, y: 5))
    #expect(!game.canUndoLastMove)
    #expect(game.isHighScore)
  }

  @Test
  func canUndoThroughRegeneratedPiecesAtEndOfGame() {
    let game = Game()

    // Fill the board with a checkerboard pattern. Only 1x1 pieces will be playable.
    for tile in game.tiles.allPoints {
      if (tile.x + tile.y) % 2 == 0 {
        game.addPiece(.oneByOne, at: tile)
      }
    }

    // Place the three pieces
    let initialBoard = game.tiles
    game.updateAvailablePieces(to: [.oneByOne, .oneByOne, .oneByOne])
    game.addPiece(inSlot: 0, at: Point(x: 1, y: 0))
    #expect(game.canUndoLastMove)

    game.addPiece(inSlot: 1, at: Point(x: 3, y: 0))
    #expect(game.canUndoLastMove)

    let boardBeforeLosing = game.tiles
    game.addPiece(inSlot: 2, at: Point(x: 5, y: 0))

    /// The pieces that were actually randomly generated after placing the last piece.
    /// These are stored in the undo snapshot.
    let actuallyRandomlyGeneratedPiece = game.availablePieces.map { $0?.piece }

    // If the game had generated playable pieces, then the user can't undo the last move
    game.updateAvailablePieces(to: [.oneByOne, .oneByOne, .oneByOne])
    #expect(game.hasPlayableMove)
    #expect(!game.canUndoLastMove)

    // If the game had generated unplayable pieces, let the user undo the last move
    // from the undo screen.
    game.updateAvailablePieces(to: [.threeByThree, .threeByThree, .threeByThree])
    #expect(!game.hasPlayableMove)
    #expect(game.canUndoLastMove)

    game.undoLastMove()
    #expect(game.tiles == boardBeforeLosing)

    game.undoLastMove()
    game.undoLastMove()
    #expect(game.tiles == initialBoard)

    // Place the pieces again and regenerate more pieces. Since the piece generation
    // is seeded, we should get the same random pieces both times.
    game.addPiece(inSlot: 0, at: Point(x: 1, y: 0))
    game.addPiece(inSlot: 1, at: Point(x: 3, y: 0))
    game.addPiece(inSlot: 2, at: Point(x: 5, y: 0))
    #expect(game.availablePieces.map { $0?.piece } == actuallyRandomlyGeneratedPiece)
  }

  @Test
  func miscAchievements() {
    let game = Game()
    #expect(game.achievements.isEmpty)

    game.updateAvailablePieces(to: [.oneByOne, .twoByTwo, .threeByThree])
    #expect(game.achievements.isEmpty)

    game.updateAvailablePieces(to: [.oneByOne, .oneByOne, .oneByOne])
    #expect(game.achievements.last == .allOneByOnes)

    game.updateAvailablePieces(to: [.threeByThree, .threeByThree, .threeByThree])
    #expect(game.achievements.last == .allThreeByThrees)

    game.addPiece(.threeByThree, at: Point(x: 0, y: 0))
    game.addPiece(.threeByThree, at: Point(x: 0, y: 3))
    game.addPiece(.threeByThree, at: Point(x: 0, y: 6))
    game.addPiece(.oneByThree, at: Point(x: 0, y: 9))
    game.clearFilledRows(placedPiece: .oneByThree, placedLocation: Point(x: 0, y: 9))
    #expect(game.achievements.last == .clearEntireBoard)

    game.addPiece(.threeByThree, at: Point(x: 0, y: 3))
    game.addPiece(.threeByThree, at: Point(x: 0, y: 6))
    game.addPiece(.oneByThree, at: Point(x: 0, y: 9))
    game.addPiece(.threeByThree, at: Point(x: 3, y: 0))
    game.addPiece(.threeByThree, at: Point(x: 6, y: 0))
    game.addPiece(.oneByThree.rotated, at: Point(x: 9, y: 0))
    game.addPiece(.threeByThree, at: Point(x: 0, y: 0))
    game.clearFilledRows(placedPiece: .threeByThree, placedLocation: Point(x: 0, y: 0))
    #expect(game.achievements.last == .sixClears)
  }

  @Test
  func spawnRates() {
    // Generate 1,000,000 random pieces and ensure that the distribution
    // matches the expected spawn rates
    var randomPieces = [Piece]()
    for i in 0 ..< 1_000_000 {
      randomPieces.append(Piece.spawnTable.randomElement(seed: 21 + i))
    }

    for (piece, expectedSpawnRate) in Piece.spawnRates {
      let experiencedSpawnRate = Double(randomPieces.count(where: { $0 == piece })) / Double(randomPieces.count)
      let expectedSpawnRate = Double(expectedSpawnRate) / 100.0
      #expect(experiencedSpawnRate.approximatelyEquals(expectedSpawnRate, within: 0.001))
    }
  }

  @Test
  func powerupTimerDecrementsWithMoves() {
    let game = Game()
    game.updateScore(to: 500)
    #expect(game.powerupPosition != nil)
    #expect(game.powerupTurnsRemaining == 5)

    // Place pieces to decrement timer
    game.updateAvailablePieces(to: [.oneByOne, .oneByOne, .oneByOne])

    game.addPiece(inSlot: 0, at: Point(x: 0, y: 0))
    #expect(game.powerupTurnsRemaining == 4)
    #expect(game.powerupPosition != nil)

    game.addPiece(inSlot: 1, at: Point(x: 1, y: 0))
    #expect(game.powerupTurnsRemaining == 3)
    #expect(game.powerupPosition != nil)

    game.addPiece(inSlot: 2, at: Point(x: 2, y: 0))
    #expect(game.powerupTurnsRemaining == 2)
    #expect(game.powerupPosition != nil)

    game.updateAvailablePieces(to: [.oneByOne, .oneByOne, .oneByOne])

    game.addPiece(inSlot: 0, at: Point(x: 3, y: 0))
    #expect(game.powerupTurnsRemaining == 1)
    #expect(game.powerupPosition != nil)

    game.addPiece(inSlot: 1, at: Point(x: 4, y: 0))
    #expect(game.powerupTurnsRemaining == 0)
    #expect(game.powerupPosition == nil) // Powerup expires
  }

  @Test
  func earnPowerupOnLastTurn() throws {
    let game = Game()
    game.spawnPowerupIfNeeded(newPowerupPosition: Point(x: 0, y: 0))
    #expect(game.powerupPosition != nil)
    #expect(game.powerupTurnsRemaining == 5)
    #expect(game.powerups.isEmpty)

    game.updateAvailablePieces(to: [.threeByThree, .threeByThree, .threeByThree])

    game.addPiece(inSlot: 0, at: Point(x: 0, y: 0))
    #expect(game.powerupTurnsRemaining == 4)
    #expect(game.powerupPosition != nil)

    game.addPiece(inSlot: 1, at: Point(x: 3, y: 0))
    #expect(game.powerupTurnsRemaining == 3)
    #expect(game.powerupPosition != nil)

    game.addPiece(inSlot: 2, at: Point(x: 6, y: 0))
    #expect(game.powerupTurnsRemaining == 2)
    #expect(game.powerupPosition != nil)

    game.updateAvailablePieces(to: [.oneByOne, .oneByOne, .oneByOne])

    game.addPiece(inSlot: 0, at: Point(x: 5, y: 5))
    #expect(game.powerupTurnsRemaining == 1)
    #expect(game.powerupPosition != nil)

    game.addPiece(inSlot: 1, at: Point(x: 9, y: 0))
    #expect(game.powerups.count == 1)
    #expect(game.powerupTurnsRemaining == 0)
    #expect(game.powerupPosition == nil)
  }

  @Test
  func powerupCollectionWhenRowCleared() {
    let game = Game()
    game.updateScore(to: 500)

    let powerupPosition = game.powerupPosition!

    // Fill the row containing the powerup except for one spot
    for x in 0..<10 {
      if Point(x: x, y: powerupPosition.y) != powerupPosition {
        game.addPiece(.oneByOne, at: Point(x: x, y: powerupPosition.y))
      }
    }

    // Place the final piece to complete the row
    game.addPiece(.oneByOne, at: powerupPosition)
    game.clearFilledRows(placedPiece: .oneByOne, placedLocation: powerupPosition)

    // Powerup should be collected
    #expect(game.powerupPosition == nil)
    #expect(game.powerupTurnsRemaining == 0)
    #expect(game.powerups.values.contains(where: { $0 == 1 }))
  }

  @Test
  func powerupCollectionWhenColumnCleared() {
    let game = Game()
    game.updateScore(to: 500)

    let powerupPosition = game.powerupPosition!

    // Fill the column containing the powerup except for one spot
    for y in 0..<10 {
      if Point(x: powerupPosition.x, y: y) != powerupPosition {
        game.addPiece(.oneByOne, at: Point(x: powerupPosition.x, y: y))
      }
    }

    // Place the final piece to complete the column
    game.addPiece(.oneByOne, at: powerupPosition)
    game.clearFilledRows(placedPiece: .oneByOne, placedLocation: powerupPosition)

    // Powerup should be collected and bonus points awarded
    #expect(game.powerupPosition == nil)
    #expect(game.powerupTurnsRemaining == 0)
    #expect(game.powerups.values.contains(where: { $0 == 1 }))
  }

  @Test
  func powerupStatePreservedInUndoSnapshot() {
    let game = Game()
    game.updateScore(to: 500)
    game.updateAvailablePieces(to: [.oneByOne, .oneByOne, .oneByOne])

    let originalPowerupPosition = game.powerupPosition!
    let originalTurns = game.powerupTurnsRemaining

    // Place a piece (this creates an undo snapshot and decrements powerup timer)
    game.addPiece(inSlot: 0, at: Point(x: 0, y: 0))
    #expect(game.powerupTurnsRemaining == originalTurns - 1)

    // Undo the move
    game.undoLastMove()

    // Powerup state should be restored
    #expect(game.powerupPosition == originalPowerupPosition)
    #expect(game.powerupTurnsRemaining == originalTurns)
  }

  @Test
  func deletePowerupFunctionality() {
    let game = Game()

    // Start with no delete powerups
    #expect((game.powerups[.deletePiece] ?? 0) == 0)
    #expect(!game.isInDeleteMode)
    #expect(!game.enterDeleteMode()) // Should fail with no powerups

    // Award a delete powerup
    game.awardPowerup(.deletePiece)
    #expect(game.powerups[.deletePiece] == 1)

    // Enter delete mode should succeed and not consume powerup yet
    #expect(game.enterDeleteMode())
    #expect(game.isInDeleteMode)
    #expect(game.powerups[.deletePiece] == 1) // Not consumed yet

    // Set up some pieces to delete
    game.updateAvailablePieces(to: [.oneByOne, .twoByTwo, .threeByThree])
    #expect(game.availablePieces[0] != nil)
    #expect(game.availablePieces[1] != nil)
    #expect(game.availablePieces[2] != nil)
  }

  @Test
  func deletePowerupCancellation() {
    let game = Game()
    game.awardPowerup(.deletePiece)

    // Enter delete mode
    #expect(game.enterDeleteMode())
    #expect(game.isInDeleteMode)
    #expect(game.powerups[.deletePiece] == 1) // Not consumed

    // Exit delete mode without using it
    game.exitDeleteMode()
    #expect(!game.isInDeleteMode)
    #expect(game.powerups[.deletePiece] == 1) // Should still have powerup
  }

  @Test
  func undoCancelsDeleteMode() {
    let game = Game()
    game.awardPowerup(.deletePiece)

    // Enter delete mode
    game.enterDeleteMode()
    #expect(game.isInDeleteMode)

    // Undo should exit delete mode
    game.undoLastMove()
    #expect(!game.isInDeleteMode)
    #expect(game.powerups[.deletePiece] == 1) // Should not consume powerup
  }

  @Test
  func undoDeletePowerup() {
    let game = Game()
    game.updateAvailablePieces(to: [.oneByOne, .twoByTwo, .threeByThree])

    // Award a delete powerup
    game.awardPowerup(.deletePiece)
    let initialPowerups = game.powerups[.deletePiece]!
    let initialPieces = game.availablePieces.map { $0?.id }

    // Enter delete mode and delete a piece
    game.enterDeleteMode()
    game.deletePieceInSlot(1)

    // Verify the delete happened
    #expect(game.powerups[.deletePiece] == 0)
    #expect(!game.isInDeleteMode)

    // Should be able to undo the delete
    #expect(game.canUndoLastMove)
    game.undoLastMove()

    // Should restore the powerup and pieces
    #expect(game.powerups[.deletePiece] == initialPowerups)
    #expect(game.availablePieces.map { $0?.id } == initialPieces)
  }

  @Test
  func deletePieceUndoCanBeDoneAfterPieceRegeneration() {
    let game = Game()
    game.updateAvailablePieces(to: [.oneByOne, .twoByTwo, .threeByThree])

    // Place two pieces (leaving one slot)
    game.addPiece(inSlot: 0, at: Point(x: 0, y: 0))
    game.addPiece(inSlot: 1, at: Point(x: 1, y: 1))

    // Delete the remaining piece
    game.awardPowerup(.deletePiece)
    game.enterDeleteMode()
    game.deletePieceInSlot(2)

    // This triggers piece regeneration since all slots are now empty
    #expect(game.availablePieces.allSatisfy { $0 != nil })

    // Delete actions can be undone even after piece regeneration
    #expect(game.canUndoLastMove)
    game.undoLastMove()

    // Should restore the powerup
    #expect(game.powerups[.deletePiece] == 1)
  }

  @Test
  func deletePowerupMultipleAwards() {
    let game = Game()

    // Award multiple delete powerups
    game.awardPowerup(.deletePiece)
    game.awardPowerup(.deletePiece)
    game.awardPowerup(.deletePiece)
    #expect(game.powerups[.deletePiece] == 3)

    // Use one
    game.updateAvailablePieces(to: [.oneByOne, .twoByTwo, .threeByThree])
    game.enterDeleteMode()
    game.deletePieceInSlot(0)
    #expect(game.powerups[.deletePiece] == 2)

    // Use another
    game.enterDeleteMode()
    game.deletePieceInSlot(1)
    #expect(game.powerups[.deletePiece] == 1)

    // Cancel the third
    game.enterDeleteMode()
    game.exitDeleteMode()
    #expect(game.powerups[.deletePiece] == 1) // Should not consume
  }

  @Test
  func bonusPieceCanBePlacedOnBoard() {
    let game = Game()
    let initialScore = game.score

    // Award a bonus piece powerup
    game.awardPowerup(.bonusPiece)
    #expect(game.powerups[.bonusPiece] == 1)

    // Place the bonus piece using the new DraggablePiece method
    game.addPiece(from: .bonusPiece, at: Point(x: 0, y: 0))

    // Powerup should be consumed
    #expect(game.powerups[.bonusPiece] == 0)

    // Score should increase by 1 (1x1 piece = 1 point)
    #expect(game.score == initialScore + 1)

    // Board should have the piece placed
    #expect(game.tiles[0][0].isFilled)
  }

  @Test
  func bonusPieceCannotBePlacedWithoutPowerup() {
    let game = Game()
    let initialScore = game.score

    // No bonus piece powerups
    #expect((game.powerups[.bonusPiece] ?? 0) == 0)

    // Try to place bonus piece - should fail silently
    game.addPiece(from: .bonusPiece, at: Point(x: 0, y: 0))

    // Nothing should have changed
    #expect(game.score == initialScore)
    #expect(!game.tiles[0][0].isFilled)
  }

  @Test
  func bonusPieceIncludedInPlayableMoveCheck() {
    let game = Game()

    // Fill board with checkerboard pattern (only 1x1 pieces can be placed)
    for tile in game.tiles.allPoints {
      if (tile.x + tile.y) % 2 == 0 {
        game.addPiece(.oneByOne, at: tile)
      }
    }

    // Set up unplayable regular pieces
    game.updateAvailablePieces(to: [.threeByThree, .threeByThree, .threeByThree])
    #expect(!game.hasPlayableMove)

    // Adding a bonus piece powerup should make the game playable again
    game.awardPowerup(.bonusPiece)
    #expect(game.hasPlayableMove)

    // Place the bonus piece
    let emptyTile = game.tiles.allPoints.first { game.tiles[$0].isEmpty }!
    game.addPiece(from: .bonusPiece, at: emptyTile)

    // Game should be unplayable again
    #expect(!game.hasPlayableMove)
  }

  @Test
  func bonusPieceUndoFunctionality() {
    let game = Game()
    game.updateAvailablePieces(to: [.oneByOne, .oneByOne, .oneByOne])

    // Award and place a bonus piece
    game.awardPowerup(.bonusPiece)
    let initialTiles = game.tiles
    let initialScore = game.score
    let initialPowerups = game.powerups[.bonusPiece]!

    // Place bonus piece
    game.addPiece(from: .bonusPiece, at: Point(x: 5, y: 5))
    #expect(game.powerups[.bonusPiece] == 0) // Powerup consumed
    #expect(game.score == initialScore + 1)
    #expect(game.tiles != initialTiles)

    // Should be able to undo bonus piece placement
    #expect(game.canUndoLastMove)
    game.undoLastMove()

    // State should be restored
    #expect(game.powerups[.bonusPiece] == initialPowerups) // Powerup restored
    #expect(game.score == initialScore)
    #expect(game.tiles == initialTiles)
  }

  @Test
  func bonusPieceWithRegularPiecesUndo() {
    let game = Game()
    game.updateAvailablePieces(to: [.oneByOne, .twoByTwo, .threeByThree])

    let initialState = (
      tiles: game.tiles,
      score: game.score,
      pieces: game.availablePieces.map { $0 },
      powerups: game.powerups[.bonusPiece] ?? 0,
    )

    // Place a regular piece
    game.addPiece(inSlot: 0, at: Point(x: 0, y: 0))
    #expect(game.canUndoLastMove)

    // Award and place a bonus piece
    game.awardPowerup(.bonusPiece)
    game.addPiece(from: .bonusPiece, at: Point(x: 1, y: 1))

    // Should be able to undo bonus piece (last move)
    #expect(game.canUndoLastMove)
    game.undoLastMove()

    // Should still be able to undo the regular piece
    #expect(game.canUndoLastMove)
    game.undoLastMove()

    // Should be back to initial state
    #expect(game.tiles == initialState.tiles)
    #expect(game.score == initialState.score)
    #expect(game.availablePieces.map { $0?.id } == initialState.pieces.map { $0?.id })
  }

  @Test
  func bonusPieceCanBeUndoneDuringGameplay() {
    let game = Game()
    game.updateAvailablePieces(to: [.oneByOne, .oneByOne, .oneByOne])

    // Place all regular pieces to trigger new piece generation
    game.addPiece(inSlot: 0, at: Point(x: 0, y: 0))
    game.addPiece(inSlot: 1, at: Point(x: 1, y: 1))
    game.addPiece(inSlot: 2, at: Point(x: 2, y: 2))

    // Regular pieces have been regenerated, so normally can't undo
    #expect(!game.canUndoLastMove)

    // Award and place a bonus piece
    game.awardPowerup(.bonusPiece)
    game.addPiece(from: .bonusPiece, at: Point(x: 3, y: 3))

    // Bonus piece moves can be undone even after piece regeneration
    #expect(game.canUndoLastMove)
    game.undoLastMove()

    // Should restore the powerup
    #expect(game.powerups[.bonusPiece] == 1)
  }
}

// MARK: Helpers

extension Game {
  func addPiece(inSlot slot: Int, at point: Point) {
    addPiece(from: .slot(slot), at: point)
  }

  func removePiece(inSlot slot: Int) {
    removePiece(.slot(slot))
  }

  func updateScore(to score: Int) {
    increaseScore(by: score - self.score)
  }

  func updateAvailablePieces(to availablePieces: [Piece]) {
    removePiece(inSlot: 0)
    removePiece(inSlot: 1)
    removePiece(inSlot: 2)

    reloadAvailablePiecesIfNeeded(
      newPieces: availablePieces.map { RandomPiece(id: UUID(), piece: $0) }
    )
  }
}

extension [[Tile]] {
  var filledValues: [[Int]] {
    map { row in
      row.map { tile in
        tile.isEmpty ? 0 : 1
      }
    }
  }
}

extension FloatingPoint {
  public func approximatelyEquals(_ other: Self, within delta: Self = .ulpOfOne) -> Bool {
    abs(self - other) < delta
  }
}
