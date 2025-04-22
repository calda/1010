//
//  Deserializationtests.swift
//  TenTen
//
//  Created by Cal Stephens on 4/21/25.
//

import Foundation
import Testing
@testable import TenTen

struct DeserializationTests {

  @Test
  func deserializeSaveStateFromV1_0() {
    let dataFromV1_0 = """
      {"score":21000,"tiles":[[{"filled":{"_0":{"blue":{}}}},{"filled":{"_0":{"cyan":{}}}},{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"indigo":{}}}},{"filled":{"_0":{"orange":{}}}},{"filled":{"_0":{"pink":{}}}},{"filled":{"_0":{"purple":{}}}},{"filled":{"_0":{"red":{}}}},{"filled":{"_0":{"teal":{}}}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}]],"availablePieces":[{"piece":{"tiles":[[{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}}],[{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}}]]},"id":"84472D29-3AFB-4940-931C-EC9D88493F9E"},{"id":"60CF90E6-724F-4E62-8B90-A6684AC2084B","piece":{"tiles":[[{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}}],[{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}}]]}},{"id":"70042C20-4766-4DC7-87EA-3ADC7BC65737","piece":{"tiles":[[{"filled":{"_0":{"orange":{}}}},{"filled":{"_0":{"orange":{}}}},{"filled":{"_0":{"orange":{}}}}]]}}],"highScore":31000,"startDate":766982431.877754,"achievements":["1000Points"]}
      """

    let game = try! JSONDecoder().decode(Game.self, from: Data(dataFromV1_0.utf8))
    #expect(game.tiles[Point(x: 0, y: 0)] == .filled(.blue))
    #expect(game.tiles[Point(x: 1, y: 0)] == .filled(.cyan))
    #expect(game.tiles[Point(x: 2, y: 0)] == .filled(.green))
    #expect(game.tiles[Point(x: 3, y: 0)] == .filled(.indigo))
    #expect(game.tiles[Point(x: 4, y: 0)] == .filled(.orange))
    #expect(game.tiles[Point(x: 5, y: 0)] == .filled(.pink))
    #expect(game.tiles[Point(x: 6, y: 0)] == .filled(.purple))
    #expect(game.tiles[Point(x: 7, y: 0)] == .filled(.red))
    #expect(game.tiles[Point(x: 8, y: 0)] == .filled(.teal))
    #expect(game.tiles[Point(x: 9, y: 0)] == .empty)

    #expect(game.score == 21000)
    #expect(game.highScore == 31000)
    #expect(game.achievements == [.oneThousandPoints])
    #expect(game.startDate == Date(timeIntervalSinceReferenceDate: 766982431.877754))
  }

}
