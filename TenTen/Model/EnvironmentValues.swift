//
//  EnvironmentValues.swift
//  TenTen
//
//  Created by Cal Stephens on 4/19/25.
//

import SwiftUI

extension EnvironmentValues {
  @Entry var game = Game()
  @Entry var boardLayout = BoardLayout()
  @Entry var placedPieceNamespace: () -> Namespace.ID = { fatalError() }
  @Entry var showingGameOverScreen = false
  @Entry var showingSettingsOverlay = false
}
