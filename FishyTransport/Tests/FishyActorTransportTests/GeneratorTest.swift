//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-sample-distributed-actors-transport open source project
//
// Copyright (c) 2018 Apple Inc. and the swift-sample-distributed-actors-transport project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-sample-distributed-actors-transport project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import FishyActorsCore

final class GeneratorTest: XCTestCase {
  func test_generate_source() async {
    let generator = SourceGen(buckets: 1)
    
    for (actorDecl, expectedBuckets) in zip(TestConstants.actorDeclarations, TestConstants.expectedBuckets) {
      let generatedBuckets = generator.generate(decl: actorDecl)
      
      if generatedBuckets != expectedBuckets {
        print("\nDifferences detected between generated and expected sources for actor \(actorDecl.name)")
        printDifferenceInBuckets(expected: expectedBuckets, generated: generatedBuckets)
        
        print("\nGenerated sources:")
        for (bucketNumber, bucket) in generatedBuckets.enumerated() {
          print("Bucket \(bucketNumber)")
          print(bucket)
          print("EOF\n")
        }
        XCTFail()
      }
    }
  }
  
  private func printDifferenceInBuckets(expected: [String], generated: [String]) {
    assert(expected.count == generated.count)
    
    for (bucketNumber, (expectedBucket, generatedBucket)) in zip(expected, generated).enumerated() {
      print("Bucket \(bucketNumber):")
      let splitExpectedBucket = expectedBucket.split(separator: "\n", omittingEmptySubsequences: false)
      let splitGeneratedBucket = generatedBucket.split(separator: "\n", omittingEmptySubsequences: false)
      let difference = splitExpectedBucket.difference(from: splitGeneratedBucket)
      
      for dif in difference {
        switch dif {
        case .insert(offset: let index, element: let line, associatedWith: _):
          print(" + line \(index + 1): \"\(line)\"")
        case .remove(offset: let index, element: let line, associatedWith: _):
          print(" - line \(index + 1): \"\(line)\"")
        }
      }
    }
  }
}

private struct TestConstants {
  // Obtained from Analysis on directory with distributed actors
  static let actorDeclarations: [DistributedActorDecl] = [
    FishyActorsCore.DistributedActorDecl(access: FishyActorsCore.AccessControl.internal, name: "ChatRoom", funcs: [FishyActorsCore.FuncDecl(access: FishyActorsCore.AccessControl.internal, name: "join", params: [(Optional("chatter"), "chatter", "Chatter")], throwing: false, async: false, result: "String"), FishyActorsCore.FuncDecl(access: FishyActorsCore.AccessControl.internal, name: "message", params: [(Optional("_"), "message", "String"), (Optional("from"), "chatter", "Chatter")], throwing: false, async: false, result: "Void"), FishyActorsCore.FuncDecl(access: FishyActorsCore.AccessControl.internal, name: "leave", params: [(Optional("chatter"), "chatter", "Chatter")], throwing: false, async: false, result: "Void")]),
    FishyActorsCore.DistributedActorDecl(access: FishyActorsCore.AccessControl.internal, name: "Chatter", funcs: [FishyActorsCore.FuncDecl(access: FishyActorsCore.AccessControl.internal, name: "join", params: [(Optional("room"), "room", "ChatRoom")], throwing: true, async: true, result: "Void"), FishyActorsCore.FuncDecl(access: FishyActorsCore.AccessControl.internal, name: "chatterJoined", params: [(Optional("room"), "room", "ChatRoom"), (Optional("chatter"), "chatter", "Chatter")], throwing: true, async: true, result: "Void"), FishyActorsCore.FuncDecl(access: FishyActorsCore.AccessControl.internal, name: "chatRoomMessage", params: [(Optional("_"), "message", "String"), (Optional("from"), "chatter", "Chatter")], throwing: false, async: false, result: "Void")])
  ]
  static let expectedBuckets: [[String]] = [
    [
      #"""
      // DO NOT MODIFY: This file will be re-generated automatically.
      // Source generated by FishyActorsGenerator (version x.y.z)
      import _Distributed

      import FishyActorTransport
      import ArgumentParser
      import Logging

      import func Foundation.sleep
      import struct Foundation.Data
      import class Foundation.JSONDecoder
      extension ChatRoom: FishyActorTransport.MessageRecipient {
        enum _Message: Sendable, Codable {
      case join(chatter: Chatter)
      case message(String, from: Chatter)
      case leave(chatter: Chatter)
      }
      nonisolated func _receiveAny<Encoder, Decoder>(
        envelope: Envelope, encoder: Encoder, decoder: Decoder
      ) async throws -> Encoder.Output
        where Encoder: TopLevelEncoder, Decoder: TopLevelDecoder {
        let message = try decoder.decode(_Message.self, from: envelope.message as! Decoder.Input) // TODO: this needs restructuring to avoid the cast, we need to know what types we work with
        return try await self._receive(message: message, encoder: encoder)
      }

      nonisolated func _receive<Encoder>(
        message: _Message, encoder: Encoder
      ) async throws -> Encoder.Output where Encoder: TopLevelEncoder {
        do {
          switch message {
      case .join(let chatter):
      let result = try await self.join(chatter: chatter)
      return try encoder.encode(result)

      case .message(let message, let chatter):
      try await self.message(message, from: chatter)
      return try encoder.encode(Optional<String>.none)

      case .leave(let chatter):
      try await self.leave(chatter: chatter)
      return try encoder.encode(Optional<String>.none)

          }
        } catch {
          fatalError("Error handling not implemented; \(error)")
        }
      }
          @_dynamicReplacement(for: _remote_join(chatter:))
          nonisolated func _fishy_join(chatter: Chatter) async throws -> String {
              let message = Self._Message.join(chatter: chatter)
              return try await requireFishyTransport.send(message, to: self.id, expecting: String.self)
          }

          @_dynamicReplacement(for: _remote_message(_:from:))
          nonisolated func _fishy_message(_ message: String, from chatter: Chatter) async throws  {
              let message = Self._Message.message(message, from: chatter)
              return try await requireFishyTransport.send(message, to: self.id, expecting: Void.self)
          }

          @_dynamicReplacement(for: _remote_leave(chatter:))
          nonisolated func _fishy_leave(chatter: Chatter) async throws  {
              let message = Self._Message.leave(chatter: chatter)
              return try await requireFishyTransport.send(message, to: self.id, expecting: Void.self)
          }
      }


      """#,
    ],
    [
      #"""
      // DO NOT MODIFY: This file will be re-generated automatically.
      // Source generated by FishyActorsGenerator (version x.y.z)
      import _Distributed

      import FishyActorTransport
      import ArgumentParser
      import Logging

      import func Foundation.sleep
      import struct Foundation.Data
      import class Foundation.JSONDecoder
      extension Chatter: FishyActorTransport.MessageRecipient {
        enum _Message: Sendable, Codable {
      case join(room: ChatRoom)
      case chatterJoined(room: ChatRoom, chatter: Chatter)
      case chatRoomMessage(String, from: Chatter)
      }
      nonisolated func _receiveAny<Encoder, Decoder>(
        envelope: Envelope, encoder: Encoder, decoder: Decoder
      ) async throws -> Encoder.Output
        where Encoder: TopLevelEncoder, Decoder: TopLevelDecoder {
        let message = try decoder.decode(_Message.self, from: envelope.message as! Decoder.Input) // TODO: this needs restructuring to avoid the cast, we need to know what types we work with
        return try await self._receive(message: message, encoder: encoder)
      }

      nonisolated func _receive<Encoder>(
        message: _Message, encoder: Encoder
      ) async throws -> Encoder.Output where Encoder: TopLevelEncoder {
        do {
          switch message {
      case .join(let room):
      try await self.join(room: room)
      return try encoder.encode(Optional<String>.none)

      case .chatterJoined(let room, let chatter):
      try await self.chatterJoined(room: room, chatter: chatter)
      return try encoder.encode(Optional<String>.none)

      case .chatRoomMessage(let message, let chatter):
      try await self.chatRoomMessage(message, from: chatter)
      return try encoder.encode(Optional<String>.none)

          }
        } catch {
          fatalError("Error handling not implemented; \(error)")
        }
      }
          @_dynamicReplacement(for: _remote_join(room:))
          nonisolated func _fishy_join(room: ChatRoom) async throws  {
              let message = Self._Message.join(room: room)
              return try await requireFishyTransport.send(message, to: self.id, expecting: Void.self)
          }

          @_dynamicReplacement(for: _remote_chatterJoined(room:chatter:))
          nonisolated func _fishy_chatterJoined(room: ChatRoom, chatter: Chatter) async throws  {
              let message = Self._Message.chatterJoined(room: room, chatter: chatter)
              return try await requireFishyTransport.send(message, to: self.id, expecting: Void.self)
          }

          @_dynamicReplacement(for: _remote_chatRoomMessage(_:from:))
          nonisolated func _fishy_chatRoomMessage(_ message: String, from chatter: Chatter) async throws  {
              let message = Self._Message.chatRoomMessage(message, from: chatter)
              return try await requireFishyTransport.send(message, to: self.id, expecting: Void.self)
          }
      }


      """#,
    ],
  ]
}
