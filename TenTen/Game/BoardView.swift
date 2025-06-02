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

// MARK: - PowerupStarView

struct PowerupStarView: View {

  // MARK: Internal

  var body: some View {
    ZStack {
      Image(systemName: "star.fill")
        .font(.system(size: 20, weight: .bold))
        .foregroundStyle(
          LinearGradient(
            colors: [.yellow, .orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing))
        .shadow(color: .black.opacity(0.5), radius: 1)
    }
    .scaleEffect(visible ? 1.0 : 0)
    .opacity(visible ? 1.0 : 0)
    .scaleEffect(pulsing ? 1.2 : 1.0)
    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulsing)
    .animation(.spring(duration: 0.3), value: visible)
    .onAppear {
      DispatchQueue.main.async {
        visible = true
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        pulsing = true
      }
    }
  }

  // MARK: Private

  @State private var visible = true
  @State private var pulsing = false
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

// MARK: - JiggleModifier

struct JiggleModifier: ViewModifier {

  // MARK: Internal

  let isJiggling: Bool

  func body(content: Content) -> some View {
    content
      .rotationEffect(.degrees(jiggleRotation))
      .animation(.easeInOut(duration: 0.1), value: jiggleRotation)
      .onChange(of: isJiggling) { _, isJiggling in
        if isJiggling {
          startJiggle()
        } else {
          stopJiggle()
        }
      }
      .onChange(of: jiggleDirection) { _, _ in
        if isJiggling {
          withAnimation(.easeInOut(duration: 0.1)) {
            jiggleRotation = jiggleDirection * 2
          }
        }
      }
  }

  // MARK: Private

  @State private var jiggleRotation: Double = 0
  @State private var jiggleDirection = 1.0
  @State private var timer: Timer?

  private func startJiggle() {
    // Stop any existing timer first
    stopJiggle()
    
    // Reset state
    jiggleDirection = 1.0
    jiggleRotation = 2.0 // Start with initial rotation
    
    // Create new timer
    timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
      if isJiggling {
        jiggleDirection *= -1
      } else {
        stopJiggle()
      }
    }
  }

  private func stopJiggle() {
    // Invalidate timer
    timer?.invalidate()
    timer = nil
    
    // Reset rotation with animation
    withAnimation(.easeInOut(duration: 0.1)) {
      jiggleRotation = 0
    }
  }
}

extension View {
  func jiggle(_ isJiggling: Bool) -> some View {
    modifier(JiggleModifier(isJiggling: isJiggling))
  }
}

// MARK: - PowerupOverlay

struct PowerupOverlay: View {
  var body: some View {
    let powerupVisible = game.powerupPosition != nil
      && !showingSettingsOverlay

    ZStack {
      if powerupVisible, let powerupPosition = game.powerupPosition {
        let tileFrame = boardLayout.tileFrames[powerupPosition] ?? .zero
        let isCollecting = game.collectingPowerup != nil
        let targetFrame = isCollecting ? (boardLayout.powerupButtonFrames[game.collectingPowerup!] ?? .zero) : .zero
        
        PowerupStarView()
          .scaleEffect(animationScale)
          .rotationEffect(.degrees(animatingToButton ? 360 : 0))
          .position(
            x: animatingToButton ? targetFrame.midX : tileFrame.midX,
            y: animatingToButton ? targetFrame.midY : tileFrame.midY
          )
          .transition(.opacity)
          .onChange(of: game.collectingPowerup) { _, newValue in
            if newValue != nil {
              // Start animation when collection begins
              withAnimation(.easeInOut(duration: 1.0)) {
                animatingToButton = true
              }
              
              // Animate scale up then down
              withAnimation(.easeOut(duration: 0.4)) {
                animationScale = 3.0
              }
              
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeIn(duration: 0.6)) {
                  animationScale = 1.0
                }
              }
            }
          }
          .onAppear {
            // Reset animation state when showing new powerup
            animatingToButton = false
            animationScale = 1.0
          }
      }
    }
    .animation(.spring, value: powerupVisible)
    .onChange(of: game.collectingPowerup) { _, newValue in
      if newValue == nil {
        animatingToButton = false
        animationScale = 1.0
      }
    }
  }

  @State private var animatingToButton = false
  @State private var animationScale = 1.0
  @Environment(\.game) private var game
  @Environment(\.boardLayout) private var boardLayout
  @Environment(\.powerupAnimationNamespace) private var powerupAnimationNamespace
  @Environment(\.showingSettingsOverlay) private var showingSettingsOverlay
}

