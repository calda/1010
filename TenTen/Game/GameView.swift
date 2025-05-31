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
        .padding(.bottom, 20)
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
