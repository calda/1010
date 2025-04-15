//
//  Game.swift
//  TenTen
//
//  Created by Cal Stephens on 4/13/25.
//

import Observation
import SwiftUI

@Observable
final class Game {
  
  init() { }
  
  private(set) var tiles: [[Tile]] = Array(
    repeating: Array(repeating: .empty, count: 10),
    count: 10)
  
  private(set) var availablePieces: [RandomPiece?] = [
    RandomPiece(),
    RandomPiece(),
    RandomPiece(),
  ]
  
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
  
  func removePiece(inSlot slot: Int) {
    availablePieces[slot] = nil
    
    if availablePieces.allSatisfy({ $0 == nil }) {
      availablePieces = [
        RandomPiece(),
        RandomPiece(),
        RandomPiece(),
      ]
    }
  }
  
  func clearFilledRows() {
    // Compute all of the tiles that are eligible to be cleared before we remove any.
    var tilesToClear = [(point: Point, delay: Double)]()
    
    for x in 0...9 {
      let column = Array(0...9).map { y in Point(x: x, y: y) }
      let shouldClearColumn = column.allSatisfy { tiles[$0].isFilled }
      
      if shouldClearColumn {
        for point in column {
          let delay = 0.025 * Double(point.y)
          tilesToClear.append((point: point, delay: delay))
        }
      }
    }
    
    for y in 0...9 {
      let row = Array(0...9).map { x in Point(x: x, y: y) }
      let shouldClearRow = row.allSatisfy { tiles[$0].isFilled }
      
      if shouldClearRow {
        for point in row {
          let delay = 0.025 * Double(point.x)
          tilesToClear.append((point: point, delay: delay))
        }
      }
    }
    
    // Remove the tiles with a staggered delay.
    // TODO: Have the animation propagate out from the location where the clear was made.
    for (tileToClear, delay) in tilesToClear {
      DispatchQueue.main.asyncAfter_syncInUnitTests(deadline: .now() + delay) {
        self.tiles[tileToClear] = .empty
      }
    }
  }
  
}

struct RandomPiece: Hashable, Identifiable {
  let id: UUID
  let piece: Piece
  
  init() {
    id = UUID()
    piece = Piece.all.randomElement()!
  }
}

struct Piece: Hashable {
  var tiles: [[Tile]]
}

enum Tile: Hashable {
  case empty
  case filled(Color)
}

struct Point: Hashable {
  let x: Int
  var y: Int
  
  init(x: Int, y: Int) {
    assert((0...9).contains(x))
    assert((0...9).contains(y))
    
    self.x = x
    self.y = y
  }
}

extension [[Tile]] {
  subscript(point: Point) -> Tile {
    get {
      self[point.y][point.x]
    }
    set {
      self[point.y][point.x] = newValue
    }
  }
}

extension Piece {
  init(color: Color, tiles: [[Int]]) {
    self.tiles = tiles.map { row in
      row.map { isFilled in
        if isFilled > 0 {
          .filled(color)
        } else {
          .empty
        }
      }
    }
  }
  
  var width: Int {
    tiles[0].count
  }
  
  var height: Int {
    tiles.count
  }
}

extension Tile {
  var isEmpty: Bool {
    switch self {
    case .empty:
      true
    case .filled:
      false
    }
  }
  
  var isFilled: Bool {
    !isEmpty
  }
  
  var color: Color? {
    switch self {
    case .filled(let color):
      color
    case .empty:
      nil
    }
  }
}

extension Piece {
  static let all: [Piece] = [
    .oneByOne,
    .twoByTwo,
    .threeByThree,
    .oneByTwo,
    .oneByThree,
    .oneByFour,
    .oneByFive,
    .twoByTwoElbow,
  ]
  
  static let oneByOne = Piece(
    color: .cyan,
    tiles: [
      [1],
    ])
  
  static let twoByTwo = Piece(
    color: .red,
    tiles: [
      [1, 1],
      [1, 1],
    ])
  
  static let threeByThree = Piece(
    color: .green,
    tiles: [
      [1, 1, 1],
      [1, 1, 1],
      [1, 1, 1],
    ])
  
  static let oneByTwo = Piece(
    color: .purple,
    tiles: [
      [1, 1],
    ])
  
  static let oneByThree = Piece(
    color: .orange,
    tiles: [
      [1, 1, 1],
    ])
  
  static let oneByFour = Piece(
    color: .indigo,
    tiles: [
      [1, 1, 1, 1],
    ])
  
  static let oneByFive = Piece(
    color: .pink,
    tiles: [
      [1, 1, 1, 1, 1],
    ])
  
  static let twoByTwoElbow = Piece(
    color: .cyan,
    tiles: [
      [1, 0],
      [1, 1],
    ])
}

extension DispatchQueue {
  func asyncAfter_syncInUnitTests(
    deadline: DispatchTime,
    excute: @escaping () -> Void)
  {
    if NSClassFromString("XCTest") != nil {
      excute()
    } else {
      asyncAfter(deadline: deadline, execute: excute)
    }
  }
}
