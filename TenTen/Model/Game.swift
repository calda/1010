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
final class Game: Codable {

  // MARK: Lifecycle

  init(highScore: Int = 0) {
    score = 0
    self.highScore = highScore

    tiles = Array(
      repeating: Array(repeating: .empty, count: 10),
      count: 10)

    availablePieces = [
      RandomPiece(),
      RandomPiece(),
      RandomPiece(),
    ]
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    score = try container.decode(Int.self, forKey: .score)
    highScore = try container.decode(Int.self, forKey: .highScore)
    tiles = try container.decode([[Tile]].self, forKey: .tiles)
    availablePieces = try container.decode([RandomPiece?].self, forKey: .availablePieces)
  }

  // MARK: Internal

  /// The highest score every achieved in any game
  private(set) var highScore: Int

  /// A 10x10 grid of tiles that start empty and are filled by the randomly generated pieces
  private(set) var tiles: [[Tile]]

  /// Three slots of randomly generated pieces that can be dragged to the board
  private(set) var availablePieces: [RandomPiece?]

  /// The piece that has just been selected and placed on the board
  private(set) var placedPiece: (piece: Piece, targetTile: Point)?

  /// The number of points scored so far in this game. You score
  /// one point for every tile placed on the board.
  private(set) var score: Int {
    didSet {
      if score > highScore {
        highScore = score
      }
    }
  }

  /// Whether or not there is a playable move based on the available pieces
  var hasPlayableMove: Bool {
    // Don't end the game in the brief moment where the pieces haven't been reloaded yet
    if reloadingPieces {
      return true
    }

    for availablePiece in availablePieces.compactMap({ $0?.piece }) {
      for tile in tiles.allPoints {
        if canAddPiece(availablePiece, at: tile) {
          return true
        }
      }
    }

    return false
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

    score += piece.points
    placedPiece = (piece: piece, targetTile: point)

    DispatchQueue.main.asyncAfter_syncInUnitTests(deadline: .now() + 0.2) { [self] in
      withAnimation(nil) {
        self.removePiece(inSlot: slot)
      }

      placedPiece = nil
      addPiece(piece, at: point)
      clearFilledRows(placedPiece: piece, placedLocation: point)
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
      reloadingPieces = true
      availablePieces[0] = RandomPiece()

      DispatchQueue.main.asyncAfter_syncInUnitTests(deadline: .now() + 0.075) {
        self.availablePieces[1] = RandomPiece()
      }

      DispatchQueue.main.asyncAfter_syncInUnitTests(deadline: .now() + 0.15) {
        self.availablePieces[2] = RandomPiece()
        self.reloadingPieces = false
      }
    }
  }

  /// Clears any row or column of the board that is fully filled with pieces
  func clearFilledRows(placedPiece: Piece, placedLocation: Point) {
    // Compute all of the tiles that are eligible to be cleared before we remove any.
    var tilesToClear = [(point: Point, delay: Double)]()

    for x in 0...9 {
      let column = Array(0...9).map { y in Point(x: x, y: y) }
      let shouldClearColumn = column.allSatisfy { tiles[$0].isFilled }

      if shouldClearColumn {
        for point in column {
          let delay = clearDelay(for: point, placedPiece: placedPiece, placedLocation: placedLocation)
          tilesToClear.append((point: point, delay: delay))
        }
      }
    }

    for y in 0...9 {
      let row = Array(0...9).map { x in Point(x: x, y: y) }
      let shouldClearRow = row.allSatisfy { tiles[$0].isFilled }

      if shouldClearRow {
        for point in row {
          let delay = clearDelay(for: point, placedPiece: placedPiece, placedLocation: placedLocation)
          tilesToClear.append((point: point, delay: delay))
        }
      }
    }

    // Remove the tiles with a staggered delay from the clear point
    for (tileToClear, delay) in tilesToClear {
      DispatchQueue.main.asyncAfter_syncInUnitTests(deadline: .now() + delay) {
        self.tiles[tileToClear] = .empty
      }
    }
  }

  /// The delay for removing a piece from the board after clearing a row.
  /// Radiates outwards from the placed piece.
  func clearDelay(for tile: Point, placedPiece: Piece, placedLocation: Point) -> Double {
    // The tiles on the board that are filled in the placed piece
    let tilesInPiece = placedPiece.tiles.allPoints
      .filter { placedPiece.tiles[$0].isFilled }
      .map { Point(x: placedLocation.x + $0.x, y: placedLocation.y + $0.y) }

    let distanceToClosestPointInPiece = tilesInPiece.map { tile.distance(to: $0) }.min()
    return (distanceToClosestPointInPiece ?? 0) * 0.025
  }

  // MARK: Private

  /// Whether the available pieces are being reloaded with an animation
  private var reloadingPieces = false

}

extension Game {
  enum CodingKeys: CodingKey {
    case score
    case highScore
    case tiles
    case availablePieces
  }

  var data: Data {
    get throws {
      try JSONEncoder().encode(self)
    }
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(score, forKey: .score)
    try container.encode(highScore, forKey: .highScore)
    try container.encode(tiles, forKey: .tiles)
    try container.encode(availablePieces, forKey: .availablePieces)
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
