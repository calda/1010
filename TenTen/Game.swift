//
//  Game.swift
//  TenTen
//
//  Created by Cal Stephens on 4/13/25.
//

import Observation
import SwiftUI

// MARK: - Game

@Observable
final class Game {

  // MARK: Lifecycle

  init() { }

  // MARK: Internal

  /// A 10x10 grid of tiles that start empty and are filled by the randomly generated pieces
  private(set) var tiles: [[Tile]] = Array(
    repeating: Array(repeating: .empty, count: 10),
    count: 10)

  /// Three slots of randomly generated pieces that can be dragged to the board
  private(set) var availablePieces: [RandomPiece?] = [
    RandomPiece(),
    RandomPiece(),
    RandomPiece(),
  ]

  /// The frame of each individual tile within the global coordinate space
  var tileFrames: [Point: CGRect] = [:]

  /// The piece that has just been selected and placed on the board
  private(set) var placedPiece: (piece: Piece, targetTile: Point)? = (piece: .twoByTwo, targetTile: .init(x: 1, y: 1))

  /// The size of tiles on the game board
  var boardTileSize: CGFloat {
    tileFrames.values.first?.width ?? 10
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

  /// Adds the piece in the given slot to the board at the given point
  func addPiece(inSlot slot: Int, at point: Point) {
    guard let piece = availablePieces[slot]?.piece else { return }

    placedPiece = (piece: piece, targetTile: point)

    DispatchQueue.main.asyncAfter_syncInUnitTests(deadline: .now() + 0.2) { [self] in
      withAnimation(nil) {
        self.removePiece(inSlot: slot)
      }

      placedPiece = nil
      addPiece(piece, at: point)
      clearFilledRows()
    }
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

  /// Removes the piece that is currently available in the given slot,
  /// and refills the slots with new random pieces if necessary.
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

  /// Clears any row or column of the board that is fully filled with pieces
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

// MARK: - RandomPiece

struct RandomPiece: Hashable, Identifiable {
  let id: UUID
  let piece: Piece

  init() {
    id = UUID()
    piece = Piece.all.randomElement()!
  }
}

// MARK: - Piece

struct Piece: Hashable {
  var tiles: [[Tile]]
}

// MARK: - Tile

enum Tile: Hashable {
  case empty
  case filled(Color)
}

// MARK: - Point

struct Point: Hashable {
  let x: Int
  var y: Int

  init(x: Int, y: Int) {
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

  // MARK: Lifecycle

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

  // MARK: Internal

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
