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
            GameView(game: game ?? Game())
          case .failure(let error):
            errorScreen(error: error)
          }
        }
      }
      .onAppear {
        savedGame = Game.saved
      }
      .sheet(item: $showErrorDetails) { error in
        Text(String(reflecting: error.error))
          .padding(32)
          .presentationDetents([.height(300)])
          .presentationDragIndicator(.visible)
      }
    }
  }

  // MARK: Private

  @State private var savedGame: Result<Game?, Error>?
  @State private var showErrorDetails: ErrorContent?

  /// Allow the user to recover by creating a new game if the data is corrupted.
  /// Don't automatically overrwrite existing data.
  private func errorScreen(error: Error) -> some View {
    ZStack(alignment: .center) {
      VStack {
        Text("Could not load previously saved game: \(error.localizedDescription)")
          .padding(.bottom, 32)

        RoundedButton(color: .accent) {
          do {
            try Game.save(data: try Game().data)
            savedGame = Game.saved
          } catch {
            print(error)
          }
        } label: {
          Text("New Game")
            .font(.system(size: 20, weight: .bold, design: .rounded))
        }
        .padding(.bottom, 8)

        RoundedButton(color: Color(white: 0.7)) {
          showErrorDetails = ErrorContent(id: UUID(), error: error)
        } label: {
          Text("Details")
            .font(.system(size: 20, weight: .bold, design: .rounded))
        }
      }
    }
    .padding(32)
  }

}

// MARK: - ErrorContent

struct ErrorContent: Identifiable {
  let id: UUID
  let error: Error
}
