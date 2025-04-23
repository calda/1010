//
//  BoardLayout.swift
//  TenTen
//
//  Created by Cal Stephens on 4/23/25.
//

import SwiftUI

@Observable
final class BoardLayout {
  let tileSpacing = 2.0

  /// The frame of each individual tile within the global coordinate space
  var tileFrames: [Point: CGRect] = [:]

  /// The frame of the board in the global coordinate space
  var boardFrame = CGRect.zero

  /// The size of tiles on the game board
  var boardTileSize: CGFloat {
    tileFrames.values.first?.width ?? 10
  }

  /// The origin in the board's coordinate space of the given point
  func offsetInBoard(of point: Point) -> CGSize {
    guard let globalOrigin = tileFrames[point]?.origin else { return .zero }

    return CGSize(
      width: globalOrigin.x - boardFrame.origin.x,
      height: globalOrigin.y - boardFrame.origin.y)
  }

  /// The size of the given piece on the board
  func size(of piece: Piece) -> CGSize {
    pieceSize(height: piece.height, width: piece.width)
  }

  /// The size of the given piece on the board
  func pieceSize(height: Int, width: Int) -> CGSize {
    let height = (Double(boardTileSize) * Double(height))
      + (Double(height - 1) * tileSpacing)

    let width = (Double(boardTileSize) * Double(width))
      + (Double(width - 1) * tileSpacing)

    return CGSize(width: width, height: height)
  }
}
