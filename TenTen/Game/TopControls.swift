//
//  TopControls.swift
//  TenTen
//
//  Created by Cal Stephens on 4/19/25.
//

import SwiftUI

// MARK: - TopControls

struct TopControls: View {

  @Binding var game: Game
  @Binding var presentSettingsOverlay: Bool

  var body: some View {
    HStack {
      ZStack {
        Button {
          presentSettingsOverlay.toggle()
        } label: {
          HamburgerButton(isOpen: presentSettingsOverlay)
            .frame(width: 30, height: 25)
            .foregroundStyle(Color(white: 0.7))
        }
      }
      .frame(maxWidth: .infinity)

      ZStack {
        Image(.logo)
          .resizable()
          .scaledToFit()
          .frame(maxWidth: 150)
      }
      .frame(maxWidth: .infinity)

      VStack {
        ScoreText(game.score.formatted(.number))
          .foregroundStyle(Color(white: 0.3))

        ZStack {
          if game.score == game.highScore {
            ScoreText("HIGH SCORE")
              .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale),
                removal: .identity))
          } else {
            ScoreText(game.highScore.formatted(.number))
          }
        }
        .foregroundStyle(Color(white: 0.7))
        .scaleEffect(0.8)
        .animation(
          .bouncy(duration: 0.8, extraBounce: 0.4),
          value: game.score == game.highScore)
        // Ensure we don't do a bouncy animation after losing
        // and resetting the current score
        .id(ObjectIdentifier(game))
      }
      .frame(maxWidth: .infinity)
    }
  }

}

// MARK: - ScoreText

struct ScoreText: View {

  // MARK: Lifecycle

  init(_ text: String) {
    self.text = text
  }

  // MARK: Internal

  let text: String

  var body: some View {
    Text(text)
      .font(.system(size: fontSize, weight: .semibold, design: .rounded))
      .lineLimit(1)
      .minimumScaleFactor(0.5)
      .scaleEffect(scoreScale)
      .monospacedDigit()
      .onChange(of: text) { _, _ in
        withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
          scoreScaled = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          withAnimation(.spring()) {
            scoreScaled = false
          }
        }
      }
  }

  var scoreScale: Double {
    guard scoreScaled else { return 1 }

    switch scoreNumberOfDigits {
    case ...4:
      return 1.05
    case 5...6:
      return 1.04
    case 7...:
      return 1.03
    default:
      return 1
    }
  }

  // MARK: Private

  @State private var scoreScaled = false

  private var fontSize: Double {
    switch scoreNumberOfDigits {
    case ...4:
      24
    case 5...6:
      22
    case 7...:
      20
    default:
      24
    }
  }

  private var scoreNumberOfDigits: Int {
    text.count
  }

}

// MARK: - HamburgerButton

struct HamburgerButton: View {
  let isOpen: Bool

  var body: some View {
    VStack(spacing: 5) {
      // Top bar
      RoundedRectangle(cornerRadius: 2)
        .frame(width: 24, height: 3)
        .rotationEffect(.degrees(isOpen ? 45 : 0), anchor: .center)
        .offset(y: isOpen ? 8 : 0)

      // Middle bar
      RoundedRectangle(cornerRadius: 2)
        .frame(width: 24, height: 3)
        .opacity(isOpen ? 0 : 1)

      // Bottom bar
      RoundedRectangle(cornerRadius: 2)
        .frame(width: 24, height: 3)
        .rotationEffect(.degrees(isOpen ? -45 : 0), anchor: .center)
        .offset(y: isOpen ? -8 : 0)
    }
    .animation(.spring(duration: 0.2), value: isOpen)
  }
}
