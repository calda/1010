//
//  TenTenApp.swift
//  TenTen
//
//  Created by Cal Stephens on 4/13/25.
//

import SwiftUI

// MARK: - TenTenApp

@main
struct TenTenApp: App {

  // MARK: Internal

  var body: some Scene {
    WindowGroup {
      ZStack {
        if let savedGame {
          switch savedGame {
          case .success(let game):
            GameView(game: Binding(
              get: { game },
              set: { newGame in
                self.savedGame = .success(newGame)
              }))

          case .failure(let error):
            ErrorScreen(
              error: error,
              savedGame: $savedGame,
              showErrorDetails: $showErrorDetails)
          }
        }
      }
      .onAppear {
        savedGame = Game.saved.map { existingGame in
          existingGame ?? Game()
        }

        GameCenterManager.authenticateUser()
      }
      .sheet(item: $showErrorDetails) { error in
        Text(String(reflecting: error.error))
          .padding(32)
          .presentationDetents([.height(300)])
          .presentationDragIndicator(.visible)
      }
      .preferredColorScheme(.light)
    }
  }

  // MARK: Private

  @State private var savedGame: Result<Game, Error>?
  @State private var showErrorDetails: ErrorContent?

}
