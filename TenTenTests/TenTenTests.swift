//
//  TenTenTests.swift
//  TenTenTests
//
//  Created by Cal Stephens on 4/13/25.
//

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
    let initialPieces = game.availablePieces
    var expectedScore = 0
    #expect(game.availablePieces[0] != nil)
    #expect(game.availablePieces[1] != nil)
    #expect(game.availablePieces[2] != nil)

    game.addPiece(inSlot: 0, at: Point(x: 0, y: 0))
    #expect(game.availablePieces[0] == nil)
    #expect(game.availablePieces[1] != nil)
    #expect(game.availablePieces[2] != nil)

    expectedScore += initialPieces[0]?.piece.points ?? 0
    #expect(game.score == expectedScore)

    game.addPiece(inSlot: 1, at: Point(x: 4, y: 4))
    #expect(game.availablePieces[0] == nil)
    #expect(game.availablePieces[1] == nil)
    #expect(game.availablePieces[2] != nil)

    expectedScore += initialPieces[1]?.piece.points ?? 0
    #expect(game.score == expectedScore)

    game.addPiece(inSlot: 2, at: Point(x: 7, y: 7))
    #expect(game.availablePieces[0] != nil)
    #expect(game.availablePieces[1] != nil)
    #expect(game.availablePieces[2] != nil)

    expectedScore += initialPieces[2]?.piece.points ?? 0
    #expect(game.score == expectedScore)

    #expect(game.availablePieces != initialPieces)
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
