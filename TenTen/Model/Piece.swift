//
//  Piece.swift
//  TenTen
//
//  Created by Cal Stephens on 4/20/25.
//

import SwiftUI

// MARK: - Piece

struct Piece: Hashable, Codable {
  var tiles: [[Tile]]

  init(color: TileColor, tiles: [[Int]]) {
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
}

// MARK: - RandomPiece

struct RandomPiece: Hashable, Identifiable, Codable {

  // MARK: Lifecycle

  init() {
    id = UUID()

    let randomPiece = Piece.all.randomElement()!

    // Rotate the piece 0º, 90º, 180º, or 270º
    piece =
      switch (0...3).randomElement()! {
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
  }

  // MARK: Internal

  let id: UUID
  let piece: Piece

}

// MARK: - Tile

enum Tile: Hashable, Codable {
  case empty
  case filled(TileColor)
}

// MARK: - TileColor

// swiftformat:sort
enum TileColor: Hashable, Codable {
  case blue
  case cyan
  case green
  case indigo
  case orange
  case pink
  case purple
  case red
  case teal

  // MARK: Internal

  var color: Color {
    switch self {
    case .blue:
      .blue
    case .cyan:
      .cyan
    case .green:
      .green
    case .indigo:
      .indigo
    case .orange:
      .orange
    case .pink:
      .pink
    case .purple:
      .purple
    case .red:
      .red
    case .teal:
      .teal
    }
  }
}

// MARK: - Point

struct Point: Hashable, Codable {
  let x: Int
  var y: Int

  init(x: Int, y: Int) {
    self.x = x
    self.y = y
  }
}

extension [[Tile]] {
  var allPoints: [Point] {
    (0 ..< width).flatMap { x in
      (0 ..< height).map { y in
        Point(x: x, y: y)
      }
    }
  }

  var width: Int {
    self[0].count
  }

  var height: Int {
    count
  }

  var rotated: [[Tile]] {
    var rotated: [[Tile]] = Array(
      repeating: [Tile](repeating: .empty, count: height),
      count: width)

    for y in 0 ..< height {
      for x in 0 ..< width {
        let rotatedPoint = Point(x: y, y: width - 1 - x)
        rotated[rotatedPoint] = self[Point(x: x, y: y)]
      }
    }

    return rotated
  }

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

  init(tiles: [[Tile]]) {
    self.tiles = tiles
  }

  // MARK: Internal

  var height: Int {
    tiles.height
  }

  var width: Int {
    tiles.width
  }

  var points: Int {
    var points = 0

    for tile in tiles.flatMap({ $0 }) {
      if tile.isFilled {
        points += 1
      }
    }

    return points
  }

  var rotated: Piece {
    Piece(tiles: tiles.rotated)
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

  var color: TileColor? {
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
    .threeByThreeElbow,
  ]

  static let oneByOne = Piece(
    color: .blue,
    tiles: [
      [1],
    ])

  static let twoByTwo = Piece(
    color: .green,
    tiles: [
      [1, 1],
      [1, 1],
    ])

  static let threeByThree = Piece(
    color: .red,
    tiles: [
      [1, 1, 1],
      [1, 1, 1],
      [1, 1, 1],
    ])

  static let oneByTwo = Piece(
    color: .teal,
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
    color: .purple,
    tiles: [
      [1, 1, 1, 1, 1],
    ])

  static let twoByTwoElbow = Piece(
    color: .cyan,
    tiles: [
      [1, 0],
      [1, 1],
    ])

  static let threeByThreeElbow = Piece(
    color: .pink,
    tiles: [
      [1, 0, 0],
      [1, 0, 0],
      [1, 1, 1],
    ])
}
