//
//  SettingsScreen.swift
//  TenTen
//
//  Created by Cal Stephens on 4/21/25.
//

import GameKit
import SwiftUI

// MARK: - SettingsOverlay

struct SettingsOverlay: View {

  // MARK: Internal

  @Binding var isPresented: Bool
  @Binding var game: Game

  var body: some View {
    ZStack(alignment: .topLeading) {
      OverlayPiece(visible: isPresented, height: 3, width: 3, color: .red, point: Point(x: 1, y: 1)) {
        Button {
          if game.score >= 500, game.hasPlayableMove {
            showNewGameAlert = true
          } else {
            startNewGame()
          }
        } label: {
          Text("New Game")
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }

      OverlayPiece(visible: isPresented, height: 3, width: 4, color: .purple, point: Point(x: 5, y: 2)) {
        Button {
          GameCenterManager.displayLeaderboards()
        } label: {
          Text("Leaderboards")
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .lineLimit(1)
        }
      }

      OverlayPiece(visible: isPresented, height: 3, width: 3, color: .cyan, point: Point(x: 1, y: 5)) {
        Button {
          showAboutScreen = true
        } label: {
          Text("About")
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .lineLimit(1)
        }
      }

      OverlayPiece(visible: isPresented, height: 3, width: 4, color: .indigo, point: Point(x: 5, y: 6)) {
        Button {
          GameCenterManager.displayAchievements()
        } label: {
          Text("Achievements")
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .lineLimit(1)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .animation(.spring, value: isPresented)
    .sheet(isPresented: $showAboutScreen) {
      AboutScreen()
    }
    // If the current game has above a point threshold, show a confirmation alert
    .alert("Start a New Game?", isPresented: $showNewGameAlert) {
      Button("New Game", role: .destructive) {
        startNewGame()
      }
      Button("Cancel", role: .cancel) { }
    } message: {
      Text("\(game.score.formatted(.number)) points will be lost")
    }
  }

  // MARK: Private

  @State private var showNewGameAlert = false
  @State private var showAboutScreen = false

  private func startNewGame() {
    isPresented = false

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
      game = game.newGame()
    }
  }

}

// MARK: - OverlayPiece

private struct OverlayPiece<Content: View>: View {

  // MARK: Lifecycle

  init(
    visible: Bool,
    height: Int,
    width: Int,
    color: Color,
    point: Point,
    @ViewBuilder content: () -> Content)
  {
    self.visible = visible
    self.height = height
    self.width = width
    self.color = color
    self.point = point
    self.content = content()
  }

  // MARK: Internal

  let visible: Bool
  let height: Int
  let width: Int
  let color: Color
  let point: Point
  let content: Content

  var body: some View {
    let size = boardLayout.pieceSize(height: height, width: width)
    let offset = boardLayout.offsetInBoard(of: point)

    ZStack {
      if visible {
        RoundedRectangle(cornerSize: CGSize(width: 5, height: 5), style: .continuous)
          .foregroundStyle(color)
          .frame(width: size.width, height: size.height)
          .overlay {
            content
              .foregroundStyle(Color.white)
              .minimumScaleFactor(0.5)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .padding(15)
          }
          .transition(.scale(scale: 0).combined(with: .opacity))
      }
    }
    .offset(offset)
  }

  // MARK: Private

  @Environment(\.boardLayout) private var boardLayout

}
