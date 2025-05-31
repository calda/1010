//
//  PiecesTray.swift
//  TenTen
//
//  Created by Cal Stephens on 4/23/25.
//

import SwiftUI

// MARK: - PiecesTray

struct PiecesTray: View {

  // MARK: Internal

  var body: some View {
    VStack(spacing: 10) {
      // Main piece tray
      HStack {
        ForEach(0..<3) { slot in
          PieceSlot(slot: slot, piece: game.availablePieces[slot])
            .scaleEffect(showingSettingsOverlay ? 0 : 1)
            .opacity(showingSettingsOverlay ? 0 : 1)
            .animation(.spring, value: showingSettingsOverlay)
        }
      }
      
      // Bonus piece slot
      if game.bonusPiece != nil {
        HStack {
          BonusPieceSlot(piece: game.bonusPiece)
            .scaleEffect(showingSettingsOverlay ? 0 : 1)
            .opacity(showingSettingsOverlay ? 0 : 1)
            .animation(.spring, value: showingSettingsOverlay)
          
          Spacer()
          Spacer()
          Spacer()
        }
      }
    }
    .padding(.all, 10)
  }

  // MARK: Private

  @Environment(\.game) private var game
  @Environment(\.showingSettingsOverlay) private var showingSettingsOverlay

}

// MARK: - PieceSlot

struct PieceSlot: View {

  // MARK: Internal

  let slot: Int
  let piece: RandomPiece?

  var body: some View {
    ZStack {
      if let piece {
        DraggablePieceView(piece: piece.piece, id: piece.id, slot: slot)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .identity))
          // Use a random UUID as the ID for each random piece's view.
          // This prevents the pieces from before and after generating new pieces
          // from being considered the same view, and the new piece receiving
          // animations from the piece that was just placed on the board.
          .id(piece.id)
      } else {
        Color.clear
      }
    }
    .aspectRatio(1, contentMode: .fit)
    // Animate an appearance animation, except after following an undo
    .animation(
      game.unplacedPiece?.piece == piece
        ? nil
        : .bouncy(duration: 0.35, extraBounce: 0.1).delay(0.075 * Double(slot)),
      value: piece)
  }

  // MARK: Private

  @Environment(\.game) private var game
}

// MARK: - BonusPieceSlot

struct BonusPieceSlot: View {
  
  let piece: RandomPiece?
  
  var body: some View {
    ZStack {
      if let piece {
        DraggableBonusPieceView(piece: piece.piece, id: piece.id)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .identity))
          .id(piece.id)
      } else {
        Color.clear
      }
    }
    .aspectRatio(1, contentMode: .fit)
    .animation(.bouncy(duration: 0.35, extraBounce: 0.1), value: piece)
  }
  
  @Environment(\.game) private var game
}

// MARK: - DraggableBonusPieceView

struct DraggableBonusPieceView: View {
  
  let piece: Piece
  let id: UUID
  
  var body: some View {
    ZStack {
      // Golden background to indicate it's a bonus piece
      Circle()
        .fill(LinearGradient(
          colors: [.yellow.opacity(0.3), .orange.opacity(0.2)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing))
        .stroke(Color.yellow, lineWidth: 2)
      
      PieceView(
        piece: piece,
        tileSize: boardLayout.boardTileSize * defaultScale,
        scale: defaultScale)
        .scaleEffect(scale)
        .offset(
          x: dragOffset.width + selectionOffset.width,
          y: dragOffset.height + selectionOffset.height)
    }
    .onGeometryChange(in: .named("GameView")) { frame in
      self.frame = frame
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .contentShape(Rectangle())
    .gesture(dragGesture)
    .onGeometryChange(in: .local) { draggableFrame in
      self.draggableFrame = draggableFrame
    }
    .onChange(of: showingGameOverScreen) { _, showingGameOverScreen in
      if showingGameOverScreen {
        resetDragState(velocityMagnitude: 0)
      }
    }
    .disabled(showingGameOverScreen)
  }
  
  @Environment(\.game) private var game
  @Environment(\.boardLayout) private var boardLayout
  @Environment(\.showingGameOverScreen) private var showingGameOverScreen
  @State private var dragOffset = CGSize.zero
  @State private var selectionOffset = CGSize.zero
  @State private var frame = CGRect.zero
  @State private var draggableFrame = CGRect.zero
  @State private var selected = false
  
  private let defaultScale: Double = 3 / 5
  
  private var scale: Double {
    selected ? 1 / defaultScale : 1
  }
  
  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        let pieceHeight = boardLayout.size(of: piece).height
        let verticalPaddingInTouchArea = (draggableFrame.height - pieceHeight) / 2
        let bottomOfPieceInDraggableArea = draggableFrame.height - verticalPaddingInTouchArea
        
        let selectionYOffset = (value.startLocation.y - bottomOfPieceInDraggableArea) - 40
        let selectionXOffset = value.startLocation.x - draggableFrame.width / 2
        
        withAnimation(.interactiveSpring(response: selected ? 0.02 : 0.2)) {
          selected = true
          dragOffset = value.translation
          selectionOffset = CGSize(width: selectionXOffset, height: selectionYOffset)
        }
      }
      .onEnded { value in
        let targetTile = boardLayout.tileFrames
          .filter { tile in
            game.canAddPiece(piece, at: tile.key)
              && abs(tile.value.origin.distance(to: frame.origin)) < boardLayout.boardTileSize * 1.5
          }
          .min { lhs, rhs in
            let lhsScreenPoint = lhs.value.origin
            let rhsScreenPoint = rhs.value.origin
            return lhsScreenPoint.distance(to: frame.origin) < rhsScreenPoint.distance(to: frame.origin)
          }
        
        let velocityMagnitude = sqrt(
          value.velocity.width * value.velocity.width +
            value.velocity.height * value.velocity.height)
        
        guard
          let point = targetTile?.key,
          game.canAddPiece(piece, at: point)
        else {
          resetDragState(velocityMagnitude: velocityMagnitude)
          return
        }
        
        game.addBonusPiece(at: point)
        resetDragState(velocityMagnitude: 0)
      }
  }
  
  private func resetDragState(velocityMagnitude: CGFloat) {
    let returnToSlotAnimation = Animation.interpolatingSpring(
      duration: 0.5,
      initialVelocity: velocityMagnitude / 1000)
    
    withAnimation(returnToSlotAnimation) {
      dragOffset = .zero
      selectionOffset = .zero
      selected = false
    }
  }
}

// MARK: - DraggablePieceView

struct DraggablePieceView: View {

  // MARK: Internal

  let piece: Piece
  let id: UUID
  let slot: Int

  var body: some View {
    PieceView(
      piece: piece,
      tileSize: boardLayout.boardTileSize * defaultScale,
      scale: defaultScale)
      .matchedGeometryEffect(
        id: game.placedPiece?.piece.id == id ? "placed piece" : "\(slot)",
        in: placedPieceNamespace(),
        anchor: .topLeading,
        isSource: false)
      .matchedGeometryEffect(
        id: game.unplacedPiece?.piece.id == id ? "unplaced piece" : "\(slot)",
        in: placedPieceNamespace(),
        anchor: .topLeading,
        isSource: false)
      .opacity(game.unplacedPiece?.piece.id == id && game.unplacedPiece?.hidden == true ? 0 : 1)
      // Track the view's frame in the global coordinate space
      .onGeometryChange(in: .named("GameView")) { frame in
        self.frame = frame
      }
      .scaleEffect(scale)
      .offset(
        x: dragOffset.width + selectionOffset.width,
        y: dragOffset.height + selectionOffset.height)
      // Enable the drag gesture. Have the entire space around the piece be draggable.
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .contentShape(Rectangle())
      .gesture(dragGesture)
      .onGeometryChange(in: .local) { draggableFrame in
        self.draggableFrame = draggableFrame
      }
      // When the game over sheet is presented, it can cancel any active drag gesture,
      // which would leave the piece floating above the board. To avoid this, manually
      // reset the gesture state.
      .onChange(of: showingGameOverScreen) { _, showingGameOverScreen in
        if showingGameOverScreen {
          resetDragState(velocityMagnitude: 0)
        }
      }
      // Ensure that the drag gesture is definitely ended when the game over screen
      // is presented, or it could be possible to continue dragging the piece underneath
      // the game over sheet.
      .disabled(showingGameOverScreen)
      // To avoid race conditions when placing a piece immediately after performing an undo,
      // cancel any active drag gesture when triggering an undo.
      .disabled(game.unplacedPiece != nil)
      .onChange(of: game.unplacedPiece != nil) { _, performingUndo in
        if performingUndo {
          resetDragState(velocityMagnitude: 0)
        }
      }
  }

  // MARK: Private

  @Environment(\.game) private var game
  @Environment(\.boardLayout) private var boardLayout
  @Environment(\.placedPieceNamespace) private var placedPieceNamespace
  @Environment(\.showingGameOverScreen) private var showingGameOverScreen
  @State private var dragOffset = CGSize.zero
  @State private var selectionOffset = CGSize.zero
  @State private var frame = CGRect.zero
  @State private var draggableFrame = CGRect.zero
  @State private var selected = false
  @State private var placed = false

  /// The amount to scale down pieces in the tray by, compared to
  /// the tiles of the game board board itself.
  /// Must be small enough for 15 tiles (three 1x5 pieces) can
  /// fit in the width of the 10 tile board, when accounting for
  /// the fact that there is also some additional spacing.
  private let defaultScale: Double = 3 / 5

  /// The current scale of this piece. When selected, scale the
  /// piece up by the inverse of `defaultScale` so the piece's
  /// tiles are the same size as the board tiles.
  private var scale: Double {
    if selected || game.unplacedPiece?.piece.id == id {
      1 / defaultScale
    } else {
      1
    }
  }

  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        let pieceHeight = boardLayout.size(of: piece).height
        let verticalPaddingInTouchArea = (draggableFrame.height - pieceHeight) / 2
        let bottomOfPieceInDraggableArea = draggableFrame.height - verticalPaddingInTouchArea

        // Offset the piece to act like it was always selected from the bottom of the piece,
        // plus an additional offset so the piece isn't covered by the user's finge
        let selectionYOffset = (value.startLocation.y - bottomOfPieceInDraggableArea) - 40

        // Offset the piece to act like it was always selected from the center
        let selectionXOffset = value.startLocation.x - draggableFrame.width / 2

        withAnimation(.interactiveSpring(response: selected ? 0.02 : 0.2)) {
          selected = true
          dragOffset = value.translation
          selectionOffset = CGSize(width: selectionXOffset, height: selectionYOffset)
        }
      }
      .onEnded { value in
        let targetTile = boardLayout.tileFrames
          // Only consider tiles where the piece can be played.
          // This allows drags to be less precise as long as the target is still unambiguous
          .filter { tile in
            game.canAddPiece(piece, at: tile.key)
              // Ensure the piece is reasonably close to this tile
              && abs(tile.value.origin.distance(to: frame.origin)) < boardLayout.boardTileSize * 1.5
          }
          .min { lhs, rhs in
            let lhsScreenPoint = lhs.value.origin
            let rhsScreenPoint = rhs.value.origin
            return lhsScreenPoint.distance(to: frame.origin) < rhsScreenPoint.distance(to: frame.origin)
          }

        let velocityMagnitude = sqrt(
          value.velocity.width * value.velocity.width +
            value.velocity.height * value.velocity.height)

        guard
          let point = targetTile?.key,
          game.canAddPiece(piece, at: point)
        else {
          resetDragState(velocityMagnitude: velocityMagnitude)
          return
        }

        placed = true

        let dragDecelerationAnimation = Animation.interpolatingSpring(
          duration: 0.125,
          initialVelocity: velocityMagnitude / 50)

        game.addPiece(inSlot: slot, at: point, dragDecelerationAnimation: dragDecelerationAnimation)
      }
  }

  private func resetDragState(velocityMagnitude: CGFloat) {
    let returnToSlotAnimation = Animation.interpolatingSpring(
      duration: 0.5,
      initialVelocity: velocityMagnitude / 1000)

    withAnimation(returnToSlotAnimation) {
      dragOffset = .zero
      selectionOffset = .zero
      selected = false
    }
  }
}
