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
    #expect(!game.canUndoLastMove)
    #expect(!game.isHighScore)
  }

  @Test
  func deserializedSaveStateFromV1_1() {
    let dataFromV1_1 = """
      {"achievements":["1000Points","10000Points","21000Points"],"availablePieces":[null,{"id":"60CF90E6-724F-4E62-8B90-A6684AC2084B","piece":{"tiles":[[{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}}],[{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}}]]}},{"id":"70042C20-4766-4DC7-87EA-3ADC7BC65737","piece":{"tiles":[[{"filled":{"_0":{"orange":{}}}},{"filled":{"_0":{"orange":{}}}},{"filled":{"_0":{"orange":{}}}}]]}}],"highScore":21004,"score":21004,"startDate":766982431.877754,"tiles":[[{"filled":{"_0":{"blue":{}}}},{"filled":{"_0":{"cyan":{}}}},{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"indigo":{}}}},{"filled":{"_0":{"orange":{}}}},{"filled":{"_0":{"pink":{}}}},{"filled":{"_0":{"purple":{}}}},{"filled":{"_0":{"red":{}}}},{"filled":{"_0":{"teal":{}}}},{"empty":{}}],[{"empty":{}},{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}]],"undoHistory":[{"availablePieces":[{"id":"84472D29-3AFB-4940-931C-EC9D88493F9E","piece":{"tiles":[[{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}}],[{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}}]]}},{"id":"60CF90E6-724F-4E62-8B90-A6684AC2084B","piece":{"tiles":[[{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}}],[{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}}]]}},{"id":"70042C20-4766-4DC7-87EA-3ADC7BC65737","piece":{"tiles":[[{"filled":{"_0":{"orange":{}}}},{"filled":{"_0":{"orange":{}}}},{"filled":{"_0":{"orange":{}}}}]]}}],"placedPiece":{"id":"84472D29-3AFB-4940-931C-EC9D88493F9E","piece":{"tiles":[[{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}}],[{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}}]]}},"placedPiecePoint":{"x":1,"y":1},"score":21000,"tiles":[[{"filled":{"_0":{"blue":{}}}},{"filled":{"_0":{"cyan":{}}}},{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"indigo":{}}}},{"filled":{"_0":{"orange":{}}}},{"filled":{"_0":{"pink":{}}}},{"filled":{"_0":{"purple":{}}}},{"filled":{"_0":{"red":{}}}},{"filled":{"_0":{"teal":{}}}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}]]}]}
      """

    let game = try! JSONDecoder().decode(Game.self, from: Data(dataFromV1_1.utf8))
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

    #expect(game.score == 21004)
    #expect(game.highScore == 21004)
    #expect(game.achievements == [.oneThousandPoints, .tenThousandPoints, .twentyOneThousandPoints])
    #expect(game.startDate == Date(timeIntervalSinceReferenceDate: 766982431.877754))
    #expect(game.isHighScore)
  }

  @Test
  func deserializedSaveStateFromV1_2() {
    let dataFromV1_2 = """
      {"achievements":["1000Points","10000Points","21000Points"],"availablePieces":[null,{"id":"60CF90E6-724F-4E62-8B90-A6684AC2084B","piece":{"tiles":[[{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}}],[{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}}]]}},{"id":"70042C20-4766-4DC7-87EA-3ADC7BC65737","piece":{"tiles":[[{"filled":{"_0":{"orange":{}}}},{"filled":{"_0":{"orange":{}}}},{"filled":{"_0":{"orange":{}}}}]]}}],"highScore":21004,"isHighScore":true,"lastPowerupScore":0,"moveCount":0,"powerupPosition":null,"powerupTurnsRemaining":0,"powerups":["bonusPiece",3,"deletePiece",2],"score":21004,"startDate":766982431.877754,"tiles":[[{"filled":{"_0":{"blue":{}}}},{"filled":{"_0":{"cyan":{}}}},{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"indigo":{}}}},{"filled":{"_0":{"orange":{}}}},{"filled":{"_0":{"pink":{}}}},{"filled":{"_0":{"purple":{}}}},{"filled":{"_0":{"red":{}}}},{"filled":{"_0":{"teal":{}}}},{"empty":{}}],[{"empty":{}},{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}]],"undoHistory":[{"availablePieces":[null,{"id":"60CF90E6-724F-4E62-8B90-A6684AC2084B","piece":{"tiles":[[{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}}],[{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}}]]}},{"id":"70042C20-4766-4DC7-87EA-3ADC7BC65737","piece":{"tiles":[[{"filled":{"_0":{"orange":{}}}},{"filled":{"_0":{"orange":{}}}},{"filled":{"_0":{"orange":{}}}}]]}}],"bonusPiece":{"id":"6CE5819B-A85B-40FC-96D8-0229D6F4EAA1","piece":{"tiles":[[{"filled":{"_0":{"blue":{}}}}]]}},"lastPowerupScore":0,"moveCount":0,"placedPiece":{"id":"F181FCEA-1861-447E-83E9-62CB95BB2FEF","piece":{"tiles":[[{"filled":{"_0":{"blue":{}}}}]]}},"placedPiecePoint":{"x":6,"y":6},"placedPieceSource":{"slot":{"_0":0}},"powerupTurnsRemaining":0,"powerups":["bonusPiece",3,"deletePiece",2],"score":21004,"tiles":[[{"filled":{"_0":{"blue":{}}}},{"filled":{"_0":{"cyan":{}}}},{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"indigo":{}}}},{"filled":{"_0":{"orange":{}}}},{"filled":{"_0":{"pink":{}}}},{"filled":{"_0":{"purple":{}}}},{"filled":{"_0":{"red":{}}}},{"filled":{"_0":{"teal":{}}}},{"empty":{}}],[{"empty":{}},{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"filled":{"_0":{"green":{}}}},{"filled":{"_0":{"green":{}}}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}],[{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}},{"empty":{}}]]}]}
      """

    let game = try! JSONDecoder().decode(Game.self, from: Data(dataFromV1_2.utf8))
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

    #expect(game.score == 21004)
    #expect(game.highScore == 21004)
    #expect(game.achievements == [.oneThousandPoints, .tenThousandPoints, .twentyOneThousandPoints])
    #expect(game.startDate == Date(timeIntervalSinceReferenceDate: 766982431.877754))
    #expect(game.isHighScore)
    #expect(game.powerups == [.bonusPiece: 3, .deletePiece: 2])
  }

}
