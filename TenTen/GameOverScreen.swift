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

  let startNewGame: () -> Void

  var body: some View {
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
        startNewGame()
      } label: {
        Text("New Game")
          .font(.system(size: 20, weight: .bold, design: .rounded))
      }
    }
    .padding(.top, 32)
    .padding(.horizontal, 24)
    .padding(.bottom, 12)
    .background(Color.accent.quaternary)
  }

  // MARK: Private

  @Environment(\.game) private var game

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
