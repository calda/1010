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
  
  // TODO: Write tests
  func addPiece(inSlot slot: Int, at point: Point) {
    guard
      let piece = availablePieces[slot]?.piece,
      canAddPiece(piece, at: point)
    else { return }
    
    addPiece(piece, at: point)
    
    availablePieces[slot] = nil
    
    if availablePieces.allSatisfy({ $0 == nil }) {
      availablePieces = [
        RandomPiece(),
        RandomPiece(),
        RandomPiece(),
      ]
    }
  }
  
}

struct RandomPiece: Identifiable {
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
  
  var color: Color {
    switch self {
    case .filled(let color):
      color
    case .empty:
      Color(white: 0.9)
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
