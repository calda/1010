//
//  ErrorScreen.swift
//  TenTen
//
//  Created by Cal Stephens on 4/23/25.
//

import SwiftUI

// MARK: - ErrorContent

struct ErrorContent: Identifiable {
  let id: UUID
  let error: Error
}

// MARK: - ErrorScreen

/// Allow the user to recover by creating a new game if the data is corrupted.
/// Don't automatically overrwrite existing data.
struct ErrorScreen: View {

  let error: Error
  @Binding var savedGame: Result<Game, Error>?
  @Binding var showErrorDetails: ErrorContent?

  var body: some View {
    ZStack(alignment: .center) {
      VStack {
        Text("Could not load previously saved game: \(error.localizedDescription)")
          .padding(.bottom, 32)

        RoundedButton(color: .accent) {
          do {
            let newGame = Game()
            try Game.save(data: try newGame.data)
            savedGame = .success(newGame)
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
