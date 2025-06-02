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
        DraggablePieceView(piece: piece.piece, id: piece.id, draggablePiece: .slot(slot))
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

// MARK: - DraggablePieceView

struct DraggablePieceView: View {

  // MARK: Internal

  let piece: Piece
  let id: UUID
  let draggablePiece: DraggablePiece

  var body: some View {
    PieceView(
      piece: piece,
      tileSize: boardLayout.boardTileSize * defaultScale,
      scale: defaultScale)
      .matchedGeometryEffect(
        id: game.placedPiece?.piece.id == id ? "placed piece" : draggablePieceIdentifier,
        in: placedPieceNamespace(),
        anchor: .topLeading,
        isSource: false)
      .matchedGeometryEffect(
        id: game.unplacedPiece?.piece.id == id ? "unplaced piece" : draggablePieceIdentifier,
        in: placedPieceNamespace(),
        anchor: .topLeading,
        isSource: false)
      .opacity(opacity)
      // Track the view's frame in the global coordinate space
      .onGeometryChange(in: .named("GameView")) { frame in
        self.frame = frame
      }
      .scaleEffect(scale)
      .offset(
        x: dragOffset.width + selectionOffset.width,
        y: dragOffset.height + selectionOffset.height)
      // X delete button overlay (only for slot pieces in delete mode)
      .overlay(alignment: .topTrailing) {
        if game.isInDeleteMode, canDelete {
          DeleteXButton()
            .scaleEffect(scale)
            .offset(x: 8, y: -8) // Offset to position at top-right corner
            .allowsHitTesting(false) // Let taps pass through to the piece
        }
      }
      // Enable the drag gesture. Have the entire space around the piece be draggable.
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .contentShape(Rectangle())
      .gesture(game.isInDeleteMode ? nil : dragGesture)
      .onTapGesture {
        if game.isInDeleteMode {
          switch draggablePiece {
          case .slot(let slot):
            game.deletePieceInSlot(slot)
          case .bonusPiece:
            // Bonus pieces can't be deleted in delete mode
            break
          }
        }
      }
      // Add jiggle animation when in delete mode
      .jiggle(game.isInDeleteMode)
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

  /// Unique identifier for this draggable piece for matched geometry effects
  private var draggablePieceIdentifier: String {
    switch draggablePiece {
    case .slot(let slot):
      "\(slot)"
    case .bonusPiece:
      "bonusPiece"
    }
  }

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

  /// The opacity of this piece. Bonus pieces start invisible and become visible when dragged.
  /// Regular pieces are always visible unless hidden during undo.
  private var opacity: Double {
    if let unplacedPiece = game.unplacedPiece, unplacedPiece.piece.id == id {
      return unplacedPiece.hidden ? 0 : 1
    }

    if case .bonusPiece = draggablePiece {
      return selected ? 1 : 0
    }

    // Regular slot pieces are always visible
    return 1
  }

  /// Whether this piece can be deleted in delete mode
  private var canDelete: Bool {
    switch draggablePiece {
    case .slot:
      true
    case .bonusPiece:
      false // Bonus pieces can't be deleted
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

        game.addPiece(from: draggablePiece, at: point, dragDecelerationAnimation: dragDecelerationAnimation)
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

// MARK: - DeleteXButton

struct DeleteXButton: View {
  var body: some View {
    ZStack {
      // Background circle
      Circle()
        .fill(Color.red)
        .frame(width: 20, height: 20)
        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)

      // X symbol
      Image(systemName: "xmark")
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(.white)
    }
    .transition(.scale.combined(with: .opacity))
  }
}
