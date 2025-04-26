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
    let game = Game()
    game.updateAvailablePieces(to: [.oneByOne, .twoByTwo, .threeByThree])

    #expect(game.availablePieces[0] != nil)
    #expect(game.availablePieces[1] != nil)
    #expect(game.availablePieces[2] != nil)

    game.addPiece(inSlot: 0, at: Point(x: 0, y: 0))
    #expect(game.availablePieces[0] == nil)
    #expect(game.availablePieces[1] != nil)
    #expect(game.availablePieces[2] != nil)
    #expect(game.score == 1)

    game.addPiece(inSlot: 1, at: Point(x: 4, y: 4))
    #expect(game.availablePieces[0] == nil)
    #expect(game.availablePieces[1] == nil)
    #expect(game.availablePieces[2] != nil)
    #expect(game.score == 1 + 4)

    game.addPiece(inSlot: 2, at: Point(x: 7, y: 7))
    #expect(game.availablePieces[0] != nil)
    #expect(game.availablePieces[1] != nil)
    #expect(game.availablePieces[2] != nil)
    #expect(game.score == 1 + 4 + 9)
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
      ]))

    #expect(Piece.oneByTwo.rotated.rotated == .oneByTwo)

    #expect(Piece.oneByFive.rotated == Piece(
      color: Piece.oneByFive.color,
      tiles: [
        [1],
        [1],
        [1],
        [1],
        [1],
      ]))

    #expect(Piece.oneByFive.rotated.rotated == .oneByFive)

    #expect(Piece.twoByTwoElbow.rotated == Piece(
      color: Piece.twoByTwoElbow.color,
      tiles: [
        [0, 1],
        [1, 1],
      ]))

    #expect(Piece.twoByTwoElbow.rotated.rotated == Piece(
      color: Piece.twoByTwoElbow.color,
      tiles: [
        [1, 1],
        [0, 1],
      ]))

    #expect(Piece.twoByTwoElbow.rotated.rotated.rotated == Piece(
      color: Piece.twoByTwoElbow.color,
      tiles: [
        [1, 1],
        [1, 0],
      ]))

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
      .oneThousandPoints,
    ])

    game.updateScore(to: 1_025)
    #expect(game.achievements == [
      .oneThousandPoints,
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
    #expect(!game.canUndoLastMove)

    let firstPiece = game.availablePieces[0]
    let emptyBoard = game.tiles

    game.addPiece(inSlot: 0, at: Point(x: 0, y: 0))
    #expect(game.canUndoLastMove)
    #expect(game.availablePieces[0] == nil)
    #expect(game.tiles != emptyBoard)

    // Undo a single move
    game.undoLastMove()
    #expect(!game.canUndoLastMove)
    #expect(game.availablePieces[0] == firstPiece)
    #expect(game.tiles == emptyBoard)

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

}

// MARK: Helpers

extension Game {
  func updateScore(to score: Int) {
    increaseScore(by: score - self.score)
  }

  func updateAvailablePieces(to availablePieces: [Piece]) {
    removePiece(inSlot: 0)
    removePiece(inSlot: 1)
    removePiece(inSlot: 2)

    reloadAvailablePiecesIfNeeded(
      newPieces: availablePieces.map { RandomPiece(id: UUID(), piece: $0) })
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
