//
//  BoardView.swift
//  TenTen
//
//  Created by Cal Stephens on 4/23/25.
//

import SwiftUI

// MARK: - BoardView

struct BoardView: View {

  // MARK: Internal

  var body: some View {
    ZStack(alignment: .topLeading) {
      board
      placedPiece
      unplacedPiece
    }
    .onGeometryChange(in: .named("GameView")) { boardFrame in
      boardLayout.boardFrame = boardFrame
    }
  }

  // MARK: Private

  @Environment(\.game) private var game
  @Environment(\.boardLayout) private var boardLayout
  @Environment(\.placedPieceNamespace) private var placedPieceNamespace
  @Environment(\.showingSettingsOverlay) private var showingSettingsOverlay

  private var board: some View {
    VStack(spacing: boardLayout.tileSpacing) {
      ForEach(0 ..< 10) { y in
        HStack(spacing: boardLayout.tileSpacing) {
          ForEach(0 ..< 10) { x in
            let point = Point(x: x, y: y)
            let tile = game.tiles[point]

            TileView(
              color: tile.color?.color,
              emptyTileColor: Color(white: 0.9),
              hidden: showingSettingsOverlay,
              animation: game.tileAnimations[point])
              .onGeometryChange(in: .named("GameView")) { tileFrame in
                boardLayout.tileFrames[point] = tileFrame
              }
          }
        }
      }
    }
  }

  @ViewBuilder
  private var placedPiece: some View {
    if let placedPiece = game.placedPiece {
      PieceView(piece: placedPiece.piece.piece, tileSize: boardLayout.boardTileSize, scale: 1)
        .opacity(0) // This piece is only a destination anchor for the dragged piece
        .matchedGeometryEffect(id: "placed piece", in: placedPieceNamespace(), anchor: .topLeading)
        .offset(boardLayout.offsetInBoard(of: placedPiece.targetTile))
    }
  }

  @ViewBuilder
  private var unplacedPiece: some View {
    if let unplacedPiece = game.unplacedPiece {
      PieceView(piece: unplacedPiece.piece.piece, tileSize: boardLayout.boardTileSize, scale: 1)
        .opacity(0) // This piece is only a destination anchor for the dragged piece
        .matchedGeometryEffect(id: "unplaced piece", in: placedPieceNamespace(), anchor: .topLeading)
        .offset(boardLayout.offsetInBoard(of: unplacedPiece.tile))
    }
  }
}

// MARK: - PieceView

struct PieceView: View {

  // MARK: Internal

  let piece: Piece
  let tileSize: CGFloat
  let scale: CGFloat

  var body: some View {
    VStack(spacing: boardLayout.tileSpacing * scale) {
      ForEach(0 ..< piece.height, id: \.self) { y in
        HStack(spacing: boardLayout.tileSpacing * scale) {
          ForEach(0 ..< piece.width, id: \.self) { x in
            let tile = piece.tiles[Point(x: x, y: y)]
            TileView(
              color: tile.isFilled ? tile.color?.color : .clear,
              scale: scale)
              .frame(width: tileSize, height: tileSize)
          }
        }
      }
    }
  }

  // MARK: Private

  @Environment(\.boardLayout) private var boardLayout
}

// MARK: - TileView

struct TileView: View {
  var color: Color?
  var scale = 1.0
  var emptyTileColor: Color?
  var hidden = false
  var animation: Animation?

  var body: some View {
    ZStack {
      if let emptyTileColor {
        SingleTile(color: emptyTileColor, scale: scale)
      }

      if let color {
        SingleTile(color: color, scale: scale)
          .transition(.scale(scale: 0).combined(with: .opacity))
          .scaleEffect(hidden ? 0 : 1)
          .opacity(hidden ? 0 : 1)
          .animation(.spring, value: hidden)
          // If a piece is placed on a tile while a removal animation is still playing,
          // ensure the two tiles are treated as different views. Otherwise there can
          // be an unexpected insertion animation on the newly added piece.
          .id(color)
          // Ensure the filled tile is above the empty tile,
          // even when the removal animation is playing.
          .zIndex(10)
      }
    }
    .animation(animation, value: isFilled)
  }

  var isFilled: Bool {
    color != nil
  }
}

// MARK: - SingleTile

struct SingleTile: View {
  let color: Color
  let scale: Double

  var body: some View {
    Rectangle()
      .fill(color)
      .aspectRatio(1, contentMode: .fit)
      .clipShape(RoundedRectangle(
        cornerSize: CGSize(width: 5 * scale, height: 5 * scale),
        style: .continuous))
  }
}

extension View {
  func onGeometryChange(
    in coordinateSpace: CoordinateSpaceProtocol,
    _ handle: @escaping (CGRect) -> Void)
    -> some View
  {
    overlay {
      GeometryReader { proxy in
        let frame = proxy.frame(in: coordinateSpace)
        Color.clear.onChange(of: frame, initial: true) { _, newValue in
          handle(newValue)
        }
      }
    }
  }
}
