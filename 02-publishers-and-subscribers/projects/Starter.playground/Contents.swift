import Foundation
import Combine
import _Concurrency
import CoreFoundation

var subscriptions = Set<AnyCancellable>()

//A publisher emits two kinds of events:
//1. Values, also referred to as elements.
//2. A completion event.
//A publisher can emit zero or more values but only one completion event, which can either be a normal completion event or an error. Once a publisher emits a completion event, it’s finished and can no longer emit any more events.

example(of: "Publisher"){
    // 1
    let myNotification = Notification.Name("MyNotification")
    
    // 2
    let publisher = NotificationCenter.default.publisher(for: myNotification, object: nil)
    
    // 3
    let center = NotificationCenter.default

    // 4
    let observer = center.addObserver(
      forName: myNotification,
      object: nil,
      queue: nil) { notification in
        print("Notification received!")
    }

    // 5
    center.post(name: myNotification, object: nil)

    // 6
    center.removeObserver(observer)
}

example(of: "Subscriber") {
    let myNotification = Notification.Name("MyNotification")
    let center = NotificationCenter.default
    
    let publisher = center.publisher(for: myNotification, object: nil)
    
    // 1
    let subscription = publisher.sink { _ in
        print("Notification received from publisher!")
    }
    
    // 2
    center.post(name: myNotification, object: nil)
    
    // 3
    subscription.cancel()
}

example(of: "Just") {
    // 1
    let just = Just("Hello world!")
    
    // 2
    _ = just.sink(receiveCompletion: {
        print("Received completion", $0)
    }, receiveValue: {
        print("Received value", $0)
    })
    // 3 Add another subscriber
    _ = just
      .sink(
        receiveCompletion: {
          print("Received completion (another)", $0)
        },
        receiveValue: {
          print("Received value (another)", $0)
      })
}

//1. Define a class with a property that has a didSet property observer that prints the new value.
//2. Create an instance of that class.
//3. Create a publisher from an array of strings.
//4. Subscribe to the publisher, assigning each value received to the value property of the object.

example(of: "assign(to:on:)") {
  // 1
  class SomeObject {
    var value: String = "" {
      didSet {
        print(value)
      }
    }
  }
  
  // 2
  let object = SomeObject()
  
  // 3
  let publisher = ["Hello", "world!"].publisher
  
  // 4
  _ = publisher
    .assign(to: \.value, on: object)
}

example(of: "assign(to:)") {
    // 1
    class SomeObject {
        @Published var value = 0
    }
    
    let object = SomeObject()
    
    // 2
    object.$value.sink {
        print($0)
    }
    
    // 3
    (0..<10).publisher.assign(to: &object.$value)
}

//  Subscriptions return an instance of AnyCancellable as a “cancellation token,” which makes it possible to cancel the subscription when you’re done with it. AnyCancellable conforms to the Cancellable protocol, which requires the cancel() method exactly for that purpose.

//What you do here is:
//
//1. Create a publisher of integers via the range’s publisher property.
//2. Define a custom subscriber, IntSubscriber.
//3. Implement the type aliases to specify that this subscriber can receive integer inputs and will never receive errors.
//4. Implement the required methods, beginning with receive(subscription:), called by the publisher; and in that method, call .request(_:) on the subscription specifying that the subscriber is willing to receive up to three values upon subscription.
//5. Print each value as it’s received and return .none, indicating that the subscriber will not adjust its demand; .none is equivalent to .max(0).
//6. Print the completion event.
    
example(of: "Custom Subscriber") {
    // 1
    let publisher = (1...6).publisher
    // 2
    final class IntSubscriber: Subscriber {
        // 3
        typealias Input = Int
        typealias Failure = Never
        
        // 4
        func receive(subscription: Subscription) {
            subscription.request(.max(3))
        }
        
        // 5
        func receive(_ input: Int) -> Subscribers.Demand {
            print("Received value", input)
            return .none
        }
        
        // 6
        func receive(completion: Subscribers.Completion<Never>) {
            print("Received completion", completion)
        }
    }
    
    let subscriber = IntSubscriber()
    
    publisher.subscribe(subscriber)
}

//A Future is a publisher that will eventually produce a single value and finish, or it will fail. It does this by invoking a closure when a value or error is available, and that closure is, in fact, the promise.


example(of: "Future") {
  func futureIncrement(
    integer: Int,
    afterDelay delay: TimeInterval) -> Future<Int, Never> {
      Future<Int, Never> { promise in
        print("Original")
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
          promise(.success(integer + 1))
        }
      }
  }
  
  // 1
  let future = futureIncrement(integer: 1, afterDelay: 3)
  // 2
  future
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print($0) })
    .store(in: &subscriptions)
  
  future
    .sink(receiveCompletion: { print("Second", $0) },
          receiveValue: { print("Second", $0) })
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
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.
