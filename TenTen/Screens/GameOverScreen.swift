//
//  GameOverScreen.swift
//  TenTen
//
//  Created by Cal Stephens on 4/19/25.
//

import SwiftUI

// MARK: - GameOverScreen

struct GameOverScreen: View {

  // MARK: Internal

  @Binding var game: Game

  var body: some View {
    ScrollView {
      VStack {
        Text("No More Room!")
          .font(.system(size: 24, weight: .bold, design: .rounded))
          .foregroundStyle(Color(white: 0, opacity: 0.4))

        Spacer(minLength: 32)

        Image(.gameOverTryAgain)
          .resizable()
          .scaledToFit()

        Spacer(minLength: 32)

        RoundedButton(color: .accent) {
          game = game.newGame()
          dismiss()
        } label: {
          Text("New Game")
            .font(.system(size: 20, weight: .bold, design: .rounded))
        }

        RoundedButton(color: Color(white: 0, opacity: 0.3)) {
          // TODO: Dismiss the game over sheet before playing the animation
          game.undoLastMove()
        } label: {
          Text("Undo Last Move")
            .font(.system(size: 20, weight: .bold, design: .rounded))
        }
      }
      .padding(.top, 32)
      .padding(.horizontal, 24)
      .padding(.bottom, 12)
      .frame(maxHeight: GameOverScreen.height)
    }
    .background(Color.accent.quaternary)
    .presentationDetents([.height(GameOverScreen.height), .height(55)], selection: $selectedDetent)
    .presentationContentInteraction(.resizes)
    .presentationCornerRadius(50)
    .interactiveDismissDisabled()
  }

  // MARK: Private

  private static let height = 465.0

  @Environment(\.dismiss) private var dismiss
  @State private var selectedDetent = PresentationDetent.height(GameOverScreen.height)

}

// MARK: - RoundedButton

struct RoundedButton<Content: View>: View {

  // MARK: Lifecycle

  init(color: Color, action: @escaping () -> Void, @ViewBuilder label: () -> Content) {
    self.color = color
    self.action = action
    content = label()
  }

  // MARK: Internal

  var body: some View {
    Button {
      action()
    } label: {
      content
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(color))
    }
    .buttonStyle(PressableTextColorStyle())
  }

  // MARK: Private

  private let color: Color
  private let content: Content
  private let action: () -> Void

}

// MARK: - PressableTextColorStyle

struct PressableTextColorStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundColor(configuration.isPressed ? Color.white.opacity(0.3) : .white)
  }
}
