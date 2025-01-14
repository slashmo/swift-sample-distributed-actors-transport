//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-sample-distributed-actors-transport open source project
//
// Copyright (c) 2021 Apple Inc. and the swift-sample-distributed-actors-transport project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-sample-distributed-actors-transport project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import _Distributed

import FishyActorTransport
import ArgumentParser
import Logging

import func Foundation.sleep

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: Make some chatters and start chatting!

struct Demo: ParsableCommand {
  @Flag(help: "Interactive mode")
  var interactive: Bool = false

  @Flag(help: "Log level used by (all) ActorTransport instances")
  var transportLogLevel: Logger.Level = .warning

  mutating func run() throws {
    LoggingSystem.bootstrap(PrettyDemoLogHandler.init)

    var keepAlive: Set<Chatter> = []

    // one node to keep the chat rooms:
    let roomNode = try FishyTransport(host: "127.0.0.1", port: 8001, logLevel: transportLogLevel)
    // multiple nodes for the regional chatters:
    let firstNode = try FishyTransport(host: "127.0.0.1", port: 9002, logLevel: transportLogLevel)
    let secondNode = try FishyTransport(host: "127.0.0.1", port: 9003, logLevel: transportLogLevel)

    let room = ChatRoom(topic: "Cute Capybaras", transport: roomNode)

    let alice = Chatter(transport: firstNode)
    let bob = Chatter(transport: secondNode)
    let charlie = Chatter(transport: secondNode)

    for chatter in [alice, bob, charlie] {
      keepAlive.insert(chatter)

      Task {
        // we resolve a reference to `room` using our `p.actorTransport`
        // since all chatters are on other nodes than the chat room,
        // this will always yield a remote reference.
        let remoteRoom = try ChatRoom.resolve(room.id, using: chatter.actorTransport)
        try await chatter.join(room: remoteRoom)
      }
    }

    // normally transports will ofer `await .park()` functions, but for now just sleep:
    sleep(1000)
    _ = keepAlive
  }
}

if #available(macOS 12.0, /* Linux */ *) {
  Demo.main()
} else {
  fatalError("Unsupported platform")
}

