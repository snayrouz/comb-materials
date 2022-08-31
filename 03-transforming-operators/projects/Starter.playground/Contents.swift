import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

/*
 COLLECT
 Be careful when working with collect() and other buffering operators that do not require specifying a count or limit. They will use an unbounded amount of memory to store received values as they won’t emit before the upstream finishes.
 */

example(of: "collect") {
  ["A", "B", "C", "D", "E"].publisher
        .collect()
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print($0) })
    .store(in: &subscriptions)
}

/*
 MAP
 Works just like Swift’s standard map, except that it operates on values emitted from a publisher.
 
 1. Create a number formatter to spell out each number.
 2. Create a publisher of integers.
3.  Use map, passing a closure that gets upstream values and returns the result of using the formatter to return the number’s spelled out string.
 */

example(of: "map") {
    // 1
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    
    // 2
    [123, 4, 56].publisher
    // 3
        .map {
            formatter.string(for: NSNumber(integerLiteral: $0)) ?? ""
        }
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
    
}

/*
 MAPPING KEY PATHS
 
    1. Create a publisher of Coordinates that will never emit an error.
    2. Begin a subscription to the publisher.
    3. Map into the x and y properties of Coordinate using their key paths.
    4. Print a statement that indicates the quadrant of the provide x and y values.
    5. Send some coordinates through the publisher.
 */
example(of: "Mapping key paths") {
    // 1
    let publisher = PassthroughSubject<Coordinate, Never>()
    // 2
    publisher
    // 3
        .map(\.x, \.y)
        .sink(receiveValue: { x, y in
            // 4
            print(
            "The coordinate at (\(x), \(y)) is in quadrant", quadrantOf(x: x, y: y)
            )
        })
        .store(in: &subscriptions)
    // 5
    publisher.send(Coordinate(x: 10, y: -8))
    publisher.send(Coordinate(x: 0, y: -5))
}

/*
 tryMap(_:)
 Several operators, including map, have a counterpart with a try prefix that takes a throwing closure. If you throw an error, the operator will emit that error downstream.
 */
example(of: "tryMap") {
    // 1
    Just("Directory name that does not exist")
    // 2
        .tryMap { try FileManager.default.contentsOfDirectory(atPath: $0)}
    // 3
        .sink(receiveCompletion: { print($0)}, receiveValue: { print($0) })
        .store(in: &subscriptions)
}

/*
 flatMap
 
 The flatMap operator flattens multiple upstream publishers into a single downstream publisher — or more specifically, flatten the emissions from those publishers.

 The publisher returned by flatMap does not — and often will not — be of the same type as the upstream publishers it receives.

 A common use case for flatMap in Combine is when you want to pass elements emitted by one publisher to a method that itself returns a publisher, and ultimately subscribe to the elements emitted by that second publisher.
 
 1. Define a function that takes an array of integers, each representing an ASCII code, and returns a type-erased publisher of strings that never emits errors.
 2. Create a Just publisher that converts the character code into a string if it’s within the range of 0.255, which includes standard and extended printable ASCII characters.
 3. Join the strings together.
 4.  Type erase the publisher to match the return type for the fuction.
 */

example(of: "flatMap") {
  // 1
  func decode(_ codes: [Int]) -> AnyPublisher<String, Never> {
    // 2
    Just(
      codes
        .compactMap { code in
          guard (32...255).contains(code) else { return nil }
          return String(UnicodeScalar(code) ?? " ")
        }
        // 3
        .joined()
    )
    // 4
    .eraseToAnyPublisher()
  }
  
  // 5
  [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33]
    .publisher
    .collect()
    // 6
    .flatMap(decode)
    // 7
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

/// Copyright (c) 2021 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.
