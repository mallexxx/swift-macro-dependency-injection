//
//  main.swift
//  DependencyInjection
//
//  Created by Alexey Martemianov on 21/5/23.
//

import Foundation
import MacroExamplesLib

// MARK: - Dependencies

protocol Service {
  func request() -> Int
}
struct ServiceImp: Service {
  static var counter: Int = 1
  var a: Int = { defer { Self.counter += 1 }; return Self.counter }()

  func request() -> Int {
    3
  }
}

protocol Service1 {
  var a: Int { get }
}
struct Service1Impl: Service1 {
  static var counter: Int = 1
  var a: Int = { defer { Self.counter += 1 }; return Self.counter }()
}
protocol Service2 {
  var b: Int { get }
}
struct Service2Impl: Service2 {
  static var counter: Int = 1
  var b: Int = { defer { Self.counter += 1 }; return Self.counter }()
}
protocol Service3 {
  var c: Int { get }
}
struct Service3Impl: Service3 {
  static var counter: Int = 1
  var c: Int = { defer { Self.counter += 1 }; return Self.counter }()
}
protocol Factory1 {
  func m1()
}
struct Factory1Impl: Factory1 {
  func m1() {}
}
protocol Factory2 {
  func m2()
}
struct Factory2Impl: Factory2 {
  func m2() {}
}
protocol Factory3 {
  func m3()
}
struct Factory3Impl: Factory3 {
  func m3() {}
}


// MARK: - Root Struct

@Injectable
@InjectedDependencies(for: ChildStruct.self) // only providing dependencies used by ChildStruct
struct MyInjectableStruct {
  var a: Int
  var z: Int

  var pre: Int { 3 }

  @Injected
  var service: Service

  private init(a: Int) {
    self.a = a
    self.z = dependencyProvider.service.request()

    print("init \(type(of: self))", dependencyProvider.service, dependencyProvider._storage)
  }

  func test() {
    _=service.request()
  }

  func testMake() async {
    let cs = ChildStruct.make(with: self.dependencyProvider, val1: "val1", val2: 5) {
      $0.service1 = Service1Impl()
      print($0.service1)
    }
    cs.testMake()

    let cs2 = ChildStruct2.make(with: dependencyProvider, c: "c", d: 6, e: 7)
    cs2.test()

    // MARK: using MyInjectableStruct and appending them with missing Service3
    let deps = AnotherChildStruct.makeDependencies(service3: Service3Impl(),
                                                   nested: self.dependencyProvider)
    let acs = AnotherChildStruct.make(with: deps, b: "b", c: 9)
    acs.testMake()

  }

}

@Injectable
@InjectedDependencies(for: ChildStruct2.self)
struct ChildStruct {

  let val1: String
  let val2: Int

  @Injected
  var service1: Service1
  @Injected
  var factory1: Factory1

  private init(val1: String, val2: Int) {
    self.val1 = val1
    self.val2 = val2

    print("init \(type(of: self))", dependencyProvider.service1, dependencyProvider.factory1)
  }

  func testMake() {
    let cs2 = ChildStruct2.make(with: self.dependencyProvider, c: "hi!", d: -1, e: 3.14159) {
      print($0.service2, $0.service)
    }
    cs2.test()
  }

}

@Injectable
struct ChildStruct2 {

  @Injected
  var service: Service
  @Injected
  var service2: Service2
  @Injected
  var factory2: Factory2

  // MARK: Uncomment this to get a dependency tree updated till the root
//  @Injected
//  var factory3: Factory3

  let c: String
  let d: Int
  let e: Double

  private init(c: String, d: Int, e: Double) {
    self.c = c
    self.d = d
    self.e = e

    print("init \(type(of: self))", dependencyProvider.service, dependencyProvider.service2, dependencyProvider.factory2)
  }

  func test() {

  }

}

@Injectable
@InjectedDependencies(for: ChildStruct2.self)
struct AnotherChildStruct {

  let b: String
  let c: Int

  @Injected
  var service3: Service3

  private init(b: String, c: Int) {
    self.b = b
    self.c = c

    print("init \(type(of: self))", dependencyProvider.service3)
  }

  func testMake() {
    let cs2 = ChildStruct2.make(with: self.dependencyProvider, c: "hi!", d: -1, e: 3.14159) {
      print($0.service2, $0.service)
    }
    cs2.test()
  }

}

/// helper struct used for resolving the dependencies
@dynamicMemberLookup
public struct MutableDynamicDependencies<Root> {
  var storagePtr: UnsafeMutablePointer<[AnyKeyPath: Any]>

  public init(_ storagePtr: UnsafeMutablePointer<[AnyKeyPath: Any]>) {
    self.storagePtr = storagePtr
  }
  public subscript<T>(dynamicMember keyPath: KeyPath<Root, T>) -> T {
    get {
      self.storagePtr.pointee[keyPath] as! T
    }
    nonmutating set {
      self.storagePtr.pointee[keyPath] = newValue
    }
  }
}

// MARK: - Testing

/// Test dependency provider
struct MainDepProvider: MyInjectableStruct.DependencyProvider {

  var service: any Service

  var service1: any Service1

  var factory1: any Factory1

  var service2: any Service2

  var factory2: any Factory2

}
let mainDepProvider = MainDepProvider(service: ServiceImp(), service1: Service1Impl(), factory1: Factory1Impl(), service2: Service2Impl(), factory2: Factory2Impl())

// instantiate the root struct
let injstr = MyInjectableStruct.make(with: mainDepProvider, a: 1) {
  // modify provided depdendencies in the time of consturction
  $0.service = ServiceImp()
}

await injstr.testMake()


