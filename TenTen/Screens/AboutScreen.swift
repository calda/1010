//
//  AboutScreen.swift
//  TenTen
//
//  Created by Cal Stephens on 4/23/25.
//

import SwiftUI

// MARK: - AboutScreen

struct AboutScreen: View {

  // MARK: Internal

  var body: some View {
    ScrollView {
      VStack {
        Image(.logo)
          .resizable()
          .scaledToFit()
          .frame(maxWidth: .infinity)
          .padding(30)

        Text("Version \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
          .font(.title3.weight(.medium))
          .opacity(0.6)

        Spacer(minLength: 30)

        Text("Made by Cal Stephens")
          .font(.title2.weight(.semibold))
          .opacity(0.6)

        Link(
          "calstephens.tech",
          destination: URL(string: "https://calstephens.tech")!)
          .font(.title3.weight(.semibold))
          .opacity(0.8)
      }
      .padding(30)
    }
    .background(Color.accent.quaternary)
    .presentationDragIndicator(.visible)
    .presentationDetents([.height(425)])
    .presentationCornerRadius(50)
  }

  // MARK: Private

  @Environment(\.dismiss) private var dismiss

}

extension Bundle {
  var appVersion: String {
    infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
  }

  var buildNumber: String {
    infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
  }
}
