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
      }
      .padding(.top, 32)
      .padding(.horizontal, 24)
      .padding(.bottom, 12)
      .frame(maxHeight: 425)
    }
    .background(Color.accent.quaternary)
    .presentationDetents([.height(425), .height(55)], selection: $selectedDetent)
    .presentationContentInteraction(.resizes)
    .presentationCornerRadius(50)
    .interactiveDismissDisabled()
  }

  // MARK: Private

  @Environment(\.dismiss) private var dismiss
  @State private var selectedDetent = PresentationDetent.height(425)
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
