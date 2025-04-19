//
//  ContentView.swift
//  TenTen
//
//  Created by Cal Stephens on 4/13/25.
//

import SwiftUI

// MARK: - GameView

struct GameView: View {

  // MARK: Internal

  var body: some View {
    VStack(alignment: .center) {
      TopControls()
        .padding(.all, 10)

      Spacer()

      BoardView()
        .padding(.all, 10)

      Spacer()

      PiecesTray()
        .padding(.bottom, 20)
    }
    .environment(\.game, game)
    .environment(\.placedPieceNamespace) { placedPiece }
    .animation(.interactiveSpring(), value: game.placedPiece?.piece)
  }

  // MARK: Private

  private let game = Game()
  @Namespace private var placedPiece

}

extension EnvironmentValues {
  @Entry var game = Game()
  @Entry var placedPieceNamespace: () -> Namespace.ID = { fatalError() }
}

struct TopControls: View {

  // MARK: Internal

  var body: some View {
    HStack {
      Spacer()
        .frame(maxWidth: .infinity)

      ZStack {
        Image(.logo)
          .resizable()
          .scaledToFit()
          .frame(maxWidth: 150)
      }
      .frame(maxWidth: .infinity)

      ZStack {
        Text("\(game.score)")
          .foregroundStyle(Color(white: 0.4))
          .font(.system(size: fontSize, weight: .semibold, design: .rounded))
          .scaleEffect(scoreScale)
          .monospacedDigit()
          .onChange(of: game.score) { _, _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
              scoreScaled = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
              withAnimation(.spring()) {
                scoreScaled = false
              }
            }
          }
      }
      .frame(maxWidth: .infinity)
    }
  }

  var scoreScale: Double {
    guard scoreScaled else { return 1 }

    switch scoreNumberOfDigits {
    case ...4:
      return 1.05
    case 5...6:
      return 1.04
    case 7...:
      return 1.03
    default:
      return 1
    }
  }

  // MARK: Private

  @Environment(\.game) private var game
  @State private var scoreScaled = false

  private var fontSize: Double {
    switch scoreNumberOfDigits {
    case ...4:
      24
    case 5...6:
      22
    case 7...:
      20
    default:
      24
    }
  }

  private var scoreNumberOfDigits: Int {
    String(abs(game.score)).count
  }

}

// MARK: - BoardView

struct BoardView: View {

  // MARK: Internal

  var body: some View {
    ZStack(alignment: .topLeading) {
      board
      placedPiece
    }
    .onGeometryChange(in: .global) { boardFrame in
      boardGlobalOrigin = boardFrame.origin
    }
  }

  // MARK: Private

  @State private var boardGlobalOrigin = CGPoint.zero
  @Environment(\.game) private var game
  @Environment(\.placedPieceNamespace) private var placedPieceNamespace

  private var board: some View {
    VStack(spacing: 2) {
      ForEach(0 ..< 10) { y in
        HStack(spacing: 2) {
          ForEach(0 ..< 10) { x in
            let point = Point(x: x, y: y)
            let tile = game.tiles[point]

            ZStack {
              TileView(
                color: tile.color,
                emptyTileColor: Color(white: 0.9))
                // Measure the frames of the tiles in the global coordinate space
                .onGeometryChange(in: .global) { tileFrame in
                  game.tileFrames[point] = tileFrame
                }
            }
          }
        }
      }
    }
  }

  @ViewBuilder
  private var placedPiece: some View {
    if
      let placedPiece = game.placedPiece,
      let globalOrigin = game.tileFrames[placedPiece.targetTile]
    {
      let offsetInBoard = CGSize(
        width: globalOrigin.origin.x - boardGlobalOrigin.x,
        height: globalOrigin.origin.y - boardGlobalOrigin.y)

      PieceView(piece: placedPiece.piece, tileSize: game.boardTileSize, scale: 1)
        .opacity(0) // This piece is only a destination anchor for the dragged piece
        .matchedGeometryEffect(id: "placed piece", in: placedPieceNamespace(), anchor: .topLeading)
        .offset(offsetInBoard)
    }
  }
}

// MARK: - PiecesTray

struct PiecesTray: View {

  // MARK: Internal

  var body: some View {
    HStack {
      ForEach(0..<3) { slot in
        piece(inSlot: slot)
      }
    }
    .padding(.all, 10)
  }

  // MARK: Private

  @Environment(\.game) private var game

  private func piece(inSlot slot: Int) -> some View {
    Group {
      if let piece = game.availablePieces[slot] {
        DraggablePieceView(piece: piece.piece, slot: slot)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        Color.clear
      }
    }
    .aspectRatio(1, contentMode: .fit)
    // Use a random UUID as the ID for each random piece's view.
    // This prevents the pieces from before and after generating new pieces
    // from being considered the same view, and the new piece receiving
    // animations from the piece that was just placed on the board.
    .id(game.availablePieces[slot]?.id)
  }
}

// MARK: - PieceView

struct DraggablePieceView: View {
  let piece: Piece
  let slot: Int
  @Environment(\.game) private var game
  @Environment(\.placedPieceNamespace) private var placedPieceNamespace
  @State private var dragOffset = CGSize.zero
  @State private var frame = CGRect.zero
  @State private var selected = false
  @State private var placed = false

  var body: some View {
    PieceView(
      piece: piece,
      tileSize: game.boardTileSize * defaultScale,
      scale: defaultScale)
      .matchedGeometryEffect(
        id: placed && game.placedPiece?.piece == piece ? "placed piece" : "\(slot)",
        in: placedPieceNamespace(),
        anchor: .topLeading,
        isSource: false)
      // Track the view's frame in the global coordinate space
      .onGeometryChange(in: .global) { frame in
        self.frame = frame
      }
      // Enable the drag gesture
      .scaleEffect(scale)
      .animation(.spring, value: selected)
      .animation(.interactiveSpring, value: dragOffset)
      .offset(x: dragOffset.width, y: dragOffset.height)
      .gesture(dragGesture)
  }

  /// The amount to scale down pieces in the tray by, compared to
  /// the tiles of the game board board itself.
  /// Must be small enough for 15 tiles (three 1x5 pieces) can
  /// fit in the width of the 10 tile board, when accounting for
  /// the fact that there is also some additional spacing.
  let defaultScale: Double = 3 / 5

  /// The current scale of this piece. When selected, scale the
  /// piece up by the inverse of `defaultScale` so the piece's
  /// tiles are the same size as the board tiles.
  private var scale: Double {
    if selected {
      1 / defaultScale
    } else {
      1
    }
  }

  private var dragGesture: some Gesture {
    DragGesture()
      .onChanged { value in
        selected = true
        dragOffset = value.translation
      }
      .onEnded { _ in
        let targetTile = game.tileFrames
          // Only consider tiles where the piece can be played.
          // This allows drags to be less precise as long as the target is still unambiguous
          .filter { tile in
            game.canAddPiece(piece, at: tile.key)
              // Ensure the piece is reasonably close to this tile
              && abs(tile.value.origin.distance(to: frame.origin)) < game.boardTileSize
          }
          .min { lhs, rhs in
            let lhsScreenPoint = lhs.value.origin
            let rhsScreenPoint = rhs.value.origin
            return lhsScreenPoint.distance(to: frame.origin) < rhsScreenPoint.distance(to: frame.origin)
          }

        guard
          let point = targetTile?.key,
          game.canAddPiece(piece, at: point)
        else {
          dragOffset = .zero
          selected = false
          return
        }

        placed = true
        game.addPiece(inSlot: slot, at: point)
      }
  }
}

struct PieceView: View {
  let piece: Piece
  let tileSize: CGFloat
  let scale: CGFloat

  var body: some View {
    VStack(spacing: 2 * scale) {
      ForEach(0 ..< piece.height, id: \.self) { y in
        HStack(spacing: 2 * scale) {
          ForEach(0 ..< piece.width, id: \.self) { x in
            let tile = piece.tiles[Point(x: x, y: y)]
            TileView(
              color: tile.isFilled ? tile.color : .clear,
              scale: scale)
              .frame(width: tileSize, height: tileSize)
          }
        }
      }
    }
  }
}

// MARK: - TileView

struct TileView: View {
  var color: Color?
  var scale = 1.0
  var emptyTileColor: Color?

  var body: some View {
    ZStack {
      if let emptyTileColor {
        tile(color: emptyTileColor)
      }

      if let color {
        tile(color: color)
          .transition(.asymmetric(
            insertion: .identity,
            removal: .scale(scale: 0).combined(with: .opacity)))
          // Ensure the filled tile is above the empty tile,
          // even when the removal animation is playing.
          .zIndex(10)
      }
    }
    .animation(.spring, value: isFilled)
  }

  var isFilled: Bool {
    color != nil
  }

  func tile(color: Color) -> some View {
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
