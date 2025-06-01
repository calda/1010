//
//  ContentView.swift
//  TenTen
//
//  Created by Cal Stephens on 4/13/25.
//

import DebouncedOnChange
import SwiftUI

// MARK: - GameView

struct GameView: View {

  // MARK: Internal

  @Binding var game: Game

  var body: some View {
    VStack(alignment: .center) {
      TopControls(game: $game, presentSettingsOverlay: $presentSettingsOverlay)
        .padding(.horizontal, 10)
        .padding(.top, 20)
        .padding(.bottom, 10)

      Spacer()

      BoardView()
        .overlay {
          SettingsOverlay(isPresented: $presentSettingsOverlay, game: $game)
        }
        .padding(.all, 10)

      Spacer()

      PiecesTray()
        .padding(.bottom, 10)
      
      PowerupButtons()
        .padding(.bottom, 10)
    }
    .overlay {
      PowerupOverlay()
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: game.powerupPosition)
    }
    .coordinateSpace(.named("GameView"))
    .environment(\.game, game)
    .environment(\.boardLayout, boardLayout)
    .environment(\.placedPieceNamespace) { placedPiece }
    .environment(\.showingSettingsOverlay, presentSettingsOverlay)
    .environment(\.showingGameOverScreen, presentGameOverSheet)
    .animation(
      game.placedPiece?.dragDecelerationAnimation ?? .interpolatingSpring(),
      value: game.placedPiece?.piece)
    .animation(.spring, value: game.unplacedPiece?.piece)
    .onChange(of: try? game.data, debounceTime: .seconds(0.5)) { _, gameData in
      if let gameData {
        do {
          try Game.save(data: gameData)
        } catch {
          print("Error saving game data: \(error.localizedDescription)")
        }
      }
    }
    .onChange(of: game.hasPlayableMove, initial: true, debounceTime: .seconds(0.5)) { _, _ in
      presentGameOverSheet = !game.hasPlayableMove
    }
    .sheet(isPresented: $presentGameOverSheet) {
      GameOverScreen(game: $game)
    }
  }

  // MARK: Private

  @State private var boardLayout = BoardLayout()
  @State private var presentGameOverSheet = false
  @State private var presentSettingsOverlay = false
  @Namespace private var placedPiece

}

// MARK: - PowerupButtons

struct PowerupButtons: View {
  @Environment(\.game) private var game
  
  var body: some View {
    HStack(spacing: 20) {
      PowerupButton(powerupType: .bonusPiece)
      PowerupButton(powerupType: .deletePiece)
    }
  }
}

// MARK: - PowerupButton

struct PowerupButton: View {
  let powerupType: Powerup
  @State private var badgeVisible = false
  
  var body: some View {
    ZStack {
      Button(action: action) {
        VStack(spacing: 4) {
          ZStack {
            Circle()
              .fill(Color.gray.opacity(0.15))
              .frame(width: 50, height: 50)
            
            Image(systemName: iconName)
              .font(.system(size: 20, weight: .bold))
              .foregroundColor(.gray)
          }
          .overlay(alignment: .bottomTrailing) {
              Text(count.formatted(.number))
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(minWidth: 18, minHeight: 18)
                .background(Circle().fill(.blue))
                .offset(x: 4, y: 4)
                .scaleEffect(badgeVisible ? 1 : 0.4)
                .opacity(badgeVisible ? 1 : 0)
                .animation(.bouncy, value: badgeVisible)
          }
        }
      }
      .disabled(!isEnabled || powerupType == .bonusPiece)
      .onChange(of: isEnabled) { oldValue, newValue in
        DispatchQueue.main.async {
          badgeVisible = newValue
        }
      }
      .onAppear {
        badgeVisible = isEnabled
      }
      // Invisible draggable bonus piece for bonus piece button
      if powerupType == .bonusPiece, (game.powerups[.bonusPiece] ?? 0) > 0 {
        DraggablePieceView(
          piece: game.bonusPiece.piece,
          id: game.bonusPiece.id,
          draggablePiece: .bonusPiece
        )
        .frame(width: 50, height: 50)
      }
    }
  }
  
  @Environment(\.game) private var game
  
  var count: Int {
    game.powerups[powerupType] ?? 0
  }
  
  private var isEnabled: Bool {
    count > 0
  }
  
  private func action() {
    switch powerupType {
    case .bonusPiece:
      break
    case .deletePiece:
      if game.isInDeleteMode {
        // Cancel delete mode if already active
        game.exitDeleteMode()
      } else {
        // Enter delete mode
        game.enterDeleteMode()
      }
    }
  }
  
  private var iconName: String {
    switch powerupType {
    case .bonusPiece:
      return "plus.square.fill"
    case .deletePiece:
      return "trash.fill"
    }
  }
}
