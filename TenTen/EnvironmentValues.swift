//
//  EnvironmentValues.swift
//  TenTen
//
//  Created by Cal Stephens on 4/19/25.
//

import SwiftUI

extension EnvironmentValues {
  @Entry var game = Game()
  @Entry var boardLayout = BoardLayout()
  @Entry var placedPieceNamespace: () -> Namespace.ID = { fatalError() }
}

@Observable
final class BoardLayout {
  /// The frame of each individual tile within the global coordinate space
  var tileFrames: [Point: CGRect] = [:]

  /// The size of tiles on the game board
  var boardTileSize: CGFloat {
    tileFrames.values.first?.width ?? 10
  }
}
