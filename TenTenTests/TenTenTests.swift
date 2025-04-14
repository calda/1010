//
//  TenTenTests.swift
//  TenTenTests
//
//  Created by Cal Stephens on 4/13/25.
//

import Testing
@testable import TenTen

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
