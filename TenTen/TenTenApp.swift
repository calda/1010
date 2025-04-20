//
//  TenTenApp.swift
//  TenTen
//
//  Created by Cal Stephens on 4/13/25.
//

import SwiftUI

@main
struct TenTenApp: App {
  var body: some Scene {
    WindowGroup {
      switch Game.saved {
      case .success(let game):
        GameView(game: game ?? Game())
      case .failure(let error):
        Text("Could not load previously saved game: \(error.localizedDescription)")
      }
    }
  }
}
