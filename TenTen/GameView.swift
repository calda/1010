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
      Text("1010")
      
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
            
            TileView(color: tile.color)
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
            PieceView(game: game, piece: piece, slot: slot, tileFrames: tileFrames)
          } else {
            Spacer()
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .id(piece)
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
  
  var body: some View {
    VStack(spacing: 2) {
      ForEach(0 ..< piece.height, id: \.self) { y in
        HStack(spacing: 2) {
          ForEach(0 ..< piece.width, id: \.self) { x in
            let tile = piece.tiles[Point(x: x, y: y)]
            TileView(color: tile.isFilled ? tile.color : .clear)
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
    .animation(.spring, value: scale)
    .offset(x: dragOffset.width, y: dragOffset.height)
    .gesture(dragGesture)
  }
  
  private var tileSize: Double {
    (tileFrames.values.first?.width ?? 10) * 2.0/3.0
  }
  
  private var scale: Double {
    if dragOffset == .zero {
      1
    } else {
      3/2
    }
  }
  
  private var dragGesture: some Gesture {
    DragGesture()
      .onChanged { value in
        dragOffset = value.translation
      }
      .onEnded { _ in
        let targetTile = tileFrames.min { lhs, rhs in
          let lhsScreenPoint = lhs.value.origin
          let rhsScreenPoint = rhs.value.origin
          return lhsScreenPoint.distance(to: frame.origin) < rhsScreenPoint.distance(to: frame.origin)
        }!
        
        let point = targetTile.key
        game.addPiece(inSlot: slot, at: point)
        
        dragOffset = .zero
      }
  }
}

struct TileView: View {
  let color: Color
  
  var body: some View {
    Rectangle()
      .fill(color)
      .aspectRatio(1, contentMode: .fit)
      .clipShape(RoundedRectangle(
        cornerSize: CGSize(width: 5, height: 5),
        style: .continuous))
  }
}

extension CGPoint {
  func distance(to point: CGPoint) -> CGFloat {
    return sqrt(pow((point.x - x), 2) + pow((point.y - y), 2))
  }
}

#Preview {
  GameView()
}
