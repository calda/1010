//
//  GameCenterManager.swift
//  TenTen
//
//  Created by Cal Stephens on 4/20/25.
//

import GameKit
import UIKit

// MARK: - GameCenterManager

enum GameCenterManager {
  /// Authenticates the current user with Game Center on app startup
  static func authenticateUser() {
    // Do nothing in simulator builds, since authentication will always fail
    #if !targetEnvironment(simulator)
    let localPlayer = GKLocalPlayer.local

    localPlayer.authenticateHandler = { loginViewController, _ in
      if let loginViewController {
        UIApplication.shared.rootViewController?.present(loginViewController, animated: true)
      }
    }
    #endif
  }

  /// Records the game's final score and submits it to the high score leaderboard
  static func recordFinalScore(_ score: Int) {
    #if !targetEnvironment(simulator)
    Task {
      try await GKLeaderboard.submitScore(
        score,
        context: 0,
        player: GKLocalPlayer.local,
        leaderboardIDs: [Leaderboard.highScore.rawValue])
    }
    #endif
  }

  /// Reports the given achievement as being achieved
  static func report(_ achievement: Achievement) {
    #if !targetEnvironment(simulator)
    Task {
      let achievement = GKAchievement(
        identifier: achievement.rawValue,
        player: GKLocalPlayer.local)

      achievement.percentComplete = 100.0

      do {
        try await GKAchievement.report([achievement])
      } catch {
        print("Failed to report achievement")
      }
    }
    #endif
  }

  static func displayLeaderboards() {
    GKAccessPoint().trigger(state: .leaderboards) { }
  }

  static func displayAchievements() {
    GKAccessPoint().trigger(state: .achievements) { }
  }
}

// MARK: - Leaderboard

enum Leaderboard: String {
  case highScore = "HighScore"
}

// MARK: - Achievement

enum Achievement: String, Hashable, Codable {
  case oneThousandPoints = "1000Points"
  case tenThousandPoints = "10000Points"
  case twentyOneThousandPoints = "21000Points"
  case oneHundredThousandPoints = "100000Points"
  case oneMillionPoints = "1000000Points"
  case allOneByOnes = "AllOneByOnes"
  case allThreeByThrees = "AllThreeByThrees"
  case clearEntireBoard = "ClearEntireBoard"
  case sixClears = "SixClears"
}

extension UIApplication {
  var scene: UIWindowScene? {
    UIApplication.shared.connectedScenes.first as? UIWindowScene
  }

  var rootViewController: UIViewController? {
    scene?.windows.first?.rootViewController
  }
}
