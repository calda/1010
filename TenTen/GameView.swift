//
//  ContentView.swift
//  TenTen
//
//  Created by Cal Stephens on 4/13/25.
//

import SwiftUI

struct GameView: View {
  let game = Game()
  @State var tileFrames = [Point: CGRect]()
  @State var selectedPiece: Int?
  
  var body: some View {
    VStack(alignment: .center) {
      HStack {
        Image(.logo)
          .resizable()
          .scaledToFit()
          .frame(maxWidth: 150)
      }
      .padding(.top, 12)
      
      Spacer()
      
      BoardView(game: game, tileFrames: $tileFrames)
        .padding(.all, 10)
      
      Spacer()
      
      PiecesTray(game: game, tileFrames: tileFrames)
        .padding(.bottom, 20)
    }
  }
}

struct BoardView: View {
  let game: Game
  @Binding var tileFrames: [Point: CGRect]
  
  var body: some View {
    VStack(spacing: 2) {
      ForEach(0 ..< 10) { y in
        HStack(spacing: 2) {
          ForEach(0 ..< 10) { x in
            let point = Point(x: x, y: y)
            let tile = game.tiles[point]
            
            TileView(color: tile.color, emptyTileColor: Color(white: 0.9))
            // Measure the frames of the tiles in the global coordinate space
              .overlay {
                GeometryReader { proxy in
                  let globalFrame = proxy.frame(in: .global)
                  
                  Color.clear
                    .onChange(of: globalFrame, initial: true) { _, tileFrame in
                      tileFrames[point] = tileFrame
                    }
                }
              }
          }
        }
      }
    }
  }
}

struct PiecesTray: View {
  let game: Game
  let tileFrames: [Point: CGRect]
  
  var body: some View {
    HStack {
      ForEach(0..<3) { slot in
        let piece = game.availablePieces[slot]
        
        Group {
          if let piece {
            PieceView(game: game, piece: piece.piece, slot: slot, tileFrames: tileFrames)
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
        .id(piece?.id)
      }
    }
    .padding(.all, 10)
  }
}

struct PieceView: View {
  let game: Game
  let piece: Piece
  let slot: Int
  let tileFrames: [Point: CGRect]
  @State private var dragOffset = CGSize.zero
  @State private var frame = CGRect.zero
  @State private var selected = false
  @State private var fadeOut = false
  
  var body: some View {
    VStack(spacing: 2 * defaultScale) {
      ForEach(0 ..< piece.height, id: \.self) { y in
        HStack(spacing: 2 * defaultScale) {
          ForEach(0 ..< piece.width, id: \.self) { x in
            let tile = piece.tiles[Point(x: x, y: y)]
            TileView(
              color: tile.isFilled ? tile.color : .clear,
              scale: defaultScale)
            .frame(width: tileSize, height: tileSize)
          }
        }
      }
    }
    // Track the view's frame in the global coordinate space
    .overlay {
      GeometryReader { proxy in
        let globalFrame = proxy.frame(in: .global)
        
        Color.clear
          .onChange(of: globalFrame, initial: true) { _, frame in
            self.frame = frame
          }
      }
    }
    // Enable the drag gesture
    .scaleEffect(scale)
    .animation(.spring, value: selected)
    .animation(.interactiveSpring, value: dragOffset)
    .offset(x: dragOffset.width, y: dragOffset.height)
    .gesture(dragGesture)
    .opacity(fadeOut ? 0 : 1)
    .animation(.linear(duration: 0.1), value: fadeOut)
  }
  
  /// The amount to scale down pieces in the tray by, compared to
  /// the tiles of the game board board itself.
  /// Must be small enough for 15 tiles (three 1x5 pieces) can
  /// fit in the width of the 10 tile board, when accounting for
  /// the fact that there is also some additional spacing.
  let defaultScale: Double = 3/5
  
  /// The width/height of tiles within the tray
  private var tileSize: Double {
    boardTileSize * defaultScale
  }
  
  /// The size of tiles on the game board
  private var boardTileSize: CGFloat {
    tileFrames.values.first?.width ?? 10
  }
  
  /// The current scale of this piece. When selected, scale the
  /// piece up by the inverse of `defaultScale` so the piece's
  /// tiles are the same size as the board tiles.
  private var scale: Double {
    if dragOffset == .zero {
      1
    } else {
      1 / defaultScale
    }
  }
  
  private var dragGesture: some Gesture {
    DragGesture()
      .onChanged { value in
        selected = true
        dragOffset = value.translation
      }
      .onEnded { _ in
        let targetTile = tileFrames.min { lhs, rhs in
          let lhsScreenPoint = lhs.value.origin
          let rhsScreenPoint = rhs.value.origin
          return lhsScreenPoint.distance(to: frame.origin) < rhsScreenPoint.distance(to: frame.origin)
        }!
        
        let point = targetTile.key
        
        guard
          game.canAddPiece(piece, at: point),
          // Ensure the piece is reasonably close to the closest tile
          abs(targetTile.value.origin.distance(to: frame.origin)) < boardTileSize
        else {
          dragOffset = .zero
          selected = false
          return
        }
        
        // Move the piece to the location on the board
        let additionalOffsetToNearestTile = CGSize(
          width: targetTile.value.origin.x - frame.origin.x,
          height: targetTile.value.origin.y - frame.origin.y)
        
        dragOffset = CGSize(
          width: dragOffset.width + additionalOffsetToNearestTile.width,
          height: dragOffset.height + additionalOffsetToNearestTile.height)
        
        // Once the piece settles at the target tile, commit it to the game board
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          game.addPiece(piece, at: point)
          
          // Since the piece may not precicely align with the tiles on the board,
          // fade it out rather than having it disappear immediately.
          fadeOut = true
          
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            game.removePiece(inSlot: slot)
            game.clearFilledRows()
          })
        }
      }
  }
}

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

extension CGPoint {
  func distance(to point: CGPoint) -> CGFloat {
    return sqrt(pow((point.x - x), 2) + pow((point.y - y), 2))
  }
}
