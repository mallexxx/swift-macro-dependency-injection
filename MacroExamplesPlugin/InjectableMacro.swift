import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct InjectableMacro: MemberMacro {

  // Add members to Injectable
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {

    guard let declaration = declaration.as(StructDeclSyntax.self) else { return [] } //.description.trimmingCharacters(in: .whitespacesAndNewlines)

    //    guard let i = declaration.as(InitializerDeclSyntax.self) else { return [] }

//    let memberList = MemberDeclListSyntax(
//      declaration.memberBlock.members
//      //        .filter {
//      //        $0.decl.isObservableStoredProperty
//      //      }
//    )
//    let members = declaration.memberBlock.members.map { "\($0.decl.kind): " + $0.decl.description }

    let injectedDependenciesInjectables = try declaration.attributes?.lazy
      .compactMap {
        $0.as(AttributeSyntax.self)
      }
      .first(where: {
        $0.attributeName.description == "InjectedDependencies"
      })
      .map { attribute -> [String] in
        guard case let .argumentList(arguments) = attribute.argument else {
          throw CustomError.message("InjectedDependencies invalid declaration")
        }
        return arguments.compactMap {
          $0.expression.as(MemberAccessExprSyntax.self)?.base?.as(IdentifierExprSyntax.self)?.identifier.text
        }
      } ?? []
    let compositions = injectedDependenciesInjectables.isEmpty ? "" : "& " + injectedDependenciesInjectables.map {
      $0 + ".DependencyProvider"
    }.joined(separator: " & ")
    let dynamicCompositions = injectedDependenciesInjectables.isEmpty ? "" : "& " + injectedDependenciesInjectables.map {
      $0 + ".DynamicDependencyProvider"
    }.joined(separator: " & ")
    let keyPathsGetters = injectedDependenciesInjectables.map {
      "result.formUnion(\($0).getAllDependencyProviderKeyPaths(from: dependencyProvider))"
    }.joined(separator: "\n")


    var paramList: FunctionParameterListSyntax!
    for member in declaration.memberBlock.members {
      guard let initializer = member.decl.as(InitializerDeclSyntax.self) else { continue }
      guard initializer.modifiers?.contains(where: { $0.name.text == "private" }) == true else {
        // TODO: File/Line
        throw CustomError.message("Initializer for @Injectable should be declared `private`")
      }
//        let modifier = initializer.modifiers!.first(where: { $0.name.text == "private" })!
//        let modifier = initializer.modifiers!.first!.name //.as(DeclModifierSyntax.self)!
      paramList = initializer.signature.input.parameterList
//      initializer.
    }


    //    throw CustomError.message("\(i.description)")
    //    guard let property = member.as(VariableDeclSyntax.self),
    //          property.isStoredProperty
    //    else {
    //      return []
    //    }

    //    guard case let .argumentList(arguments) = node.argument,
    //          let firstElement = arguments.first,
    //          let stringLiteral = firstElement.expression
    //      .as(StringLiteralExprSyntax.self),
    //          stringLiteral.segments.count == 1,
    //          case let .stringSegment(wrapperName)? = stringLiteral.segments.first else {
    //      throw CustomError.message("macro requires a string literal containing the name of an attribute")
    //    }

//    let storage: DeclSyntax = """
//      @AddCompletionHandler
//        func test(a: Int, for b: String, _ value: Double) async -> String {
//        return b
//      }
//    """
//    let storage: DeclSyntax = "var _storage: [String: Any] = [:]"

//    return [
//      storage.with(\.leadingTrivia, [.newlines(1), .spaces(2)])
//    ]


//    return [
      //      "init(a: Int, b: Int) { fatalError() }"

      //      AttributeSyntax(i)!
      //      AttributeSyntax(
      //        attributeName: SimpleTypeIdentifierSyntax(
      //          name: .identifier(wrapperName.content.text)
      //        )
      //      )
      //      .with(\.leadingTrivia, [.newlines(1), .spaces(2)])
//    ]

    let members = declaration.memberBlock.members.compactMap {
      $0.decl.as(VariableDeclSyntax.self)
    }.filter {
      $0.attributes?.first?.trimmed.description == "@Injected"
    }
    let vars = members.map {
      let binding = $0.bindings.first!
      return (name: binding.pattern.as(IdentifierPatternSyntax.self)!.identifier.text,
              type: binding.typeAnnotation!.type.as(SimpleTypeIdentifierSyntax.self)!.name.text)
    }

//    let vars = members.map {
//      $0.description
//        .trimmingCharacters(in: .whitespacesAndNewlines)
//        .dropping(prefix: "@Injected")
//        .trimmingCharacters(in: .whitespacesAndNewlines)
////        + " { fatalError() }"
//    }
    let initVars = paramList.map {
      let varName = $0.firstName.text
      return "\(varName): \(varName)"
    }.joined(separator: ", ")
//    throw CustomError.message("`\(initVars)`")

    let dependencyInitArguments = vars.map {
      "\($0.name): \($0.type)"
    }.joined(separator: ", ")
    let dynamicDependencyProviderInitArguments = dependencyInitArguments
      + (dynamicCompositions.isEmpty ? "" : ", nested nestedProvider: ") + dynamicCompositions.dropping(prefix: "& ")
    var storageInitLiteral = "[\n" + vars.map {
      "\\\(declaration.identifier.text)_DependencyProvider.\($0.name): \($0.name)"
    }.joined(separator: ",\n") + "\n]"
    if !dynamicCompositions.isEmpty {
      storageInitLiteral = "nestedProvider._storage.merging(\(storageInitLiteral)) { $1 }"
    }



//    \(raw: vars.joined(separator: "\n"))
    let identifier = declaration.identifier.text
//    return ["""
//      typealias DependencyProvider = \(raw: declaration.identifier.text)_DependencyProvider
//
//      @dynamicMemberLookup
//      struct Dependencies: DependencyProvider {
//        var _storage = [AnyKeyPath: Any]()
//
//        init() {
//          self.init(with: \(raw: declaration.identifier.text)._currentDependencies)
//        }
//
//        init(with dependencyProvider: DependencyProvider) {
//          (raw: initVarsFromProvider)
//        }
//
//        subscript<T>(dynamicMember keyPath: KeyPath<Extension, T>) -> T {
//            self.value[keyPath: keyPath]
//        }
//
//      }
//      let dependencyProvider = Dependencies()
//
//      @TaskLocal private static var _currentDependencies: DependencyProvider!
//    """]
    return ["""
      typealias DependencyProvider = \(raw: identifier)_DependencyProvider \(raw: compositions)
      typealias DynamicDependencyProvider = \(raw: identifier)_DynamicDependencyProvider \(raw: dynamicCompositions)

      static func getAllDependencyProviderKeyPaths(from dependencyProvider: DependencyProvider) -> Set<AnyKeyPath> {
        var result = Set<AnyKeyPath>()
        result.formUnion(\(raw: identifier)_DependencyProvider_allKeyPaths())
        \(raw: keyPathsGetters)
        return result
      }

      @dynamicMemberLookup
      struct DynamicDependencies: DynamicDependencyProvider {
        var _storage: [AnyKeyPath: Any]

        init() {
          self._storage = \(raw: identifier)._currentDependencies._storage
        }
        init(_ storage: [AnyKeyPath: Any]) {
          self._storage = storage
        }
        init(_ dependencyProvider: DependencyProvider) {
          self._storage = \(raw: identifier).getAllDependencyProviderKeyPaths(from: dependencyProvider).reduce(into: [:]) {
            $0[$1] = dependencyProvider[keyPath: $1]
          }
        }
        init(_ dependencyProvider: DynamicDependencyProvider) {
          self._storage = dependencyProvider._storage
        }

        subscript<T>(dynamicMember keyPath: KeyPath<\(raw: identifier)_DependencyProvider, T>) -> T {
          self._storage[keyPath] as! T
        }
      }

      static func makeDependencies(\(raw: dynamicDependencyProviderInitArguments)) -> DynamicDependencies {
          DynamicDependencies(\(raw: storageInitLiteral))
      }

      let dependencyProvider = DynamicDependencies()
      @TaskLocal private static var _currentDependencies: DynamicDependencies!

      static func make(with dependencies: DependencyProvider, \(paramList)\(paramList.isEmpty ? "" : ",") updateValues: ((MutableDynamicDependencies<\(raw: identifier)_DependencyProvider>) throws -> Void)? = nil) rethrows -> Self {
        var dependencies = DynamicDependencies(dependencies)
        try updateValues?(MutableDynamicDependencies(&dependencies._storage))
        return self.$_currentDependencies.withValue(dependencies) {
          return self.init(\(raw: initVars))
        }
      }

      static func make(with dependencies: DynamicDependencyProvider, \(paramList)\(paramList.isEmpty ? "" : ",") updateValues: ((MutableDynamicDependencies<\(raw: identifier)_DependencyProvider>) throws -> Void)? = nil) rethrows -> Self {
        var dependencies = DynamicDependencies(dependencies)
        try updateValues?(MutableDynamicDependencies(&dependencies._storage))
        return self.$_currentDependencies.withValue(dependencies) {
          return self.init(\(raw: initVars))
        }
      }
    """]
  }

}


extension InjectableMacro: MemberAttributeMacro {

  public static func expansion(
    of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax,
    providingAttributesFor member: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AttributeSyntax] {

    guard let initializer = member.as(InitializerDeclSyntax.self) else { return [] }

    let descr = member.description.trimmingCharacters(in: .whitespacesAndNewlines)
//    guard let property = member.as(VariableDeclSyntax.self),
//          property.isStoredProperty,
//          !descr.hasPrefix("@"), !descr.contains("<"), !descr.contains("z"),
//          descr.hasPrefix("var z: Int")
//    else {
      return []
//    }

    return [
      AttributeSyntax(
        attributeName: SimpleTypeIdentifierSyntax(
          name: .identifier("InjectableInit")
        )
      )
      .with(\.leadingTrivia, [.newlines(1), .spaces(2)])
    ]
  }

}

extension String {
  func dropping(prefix: String) -> String {
    return hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
  }
}
//var injectableProtocolVars = [String: Set<String>]()
extension InjectableMacro: PeerMacro {
  
  public static func expansion<Context, Declaration>(of node: AttributeSyntax, providingPeersOf declaration: Declaration, in context: Context) throws -> [DeclSyntax] where Context : MacroExpansionContext, Declaration : DeclSyntaxProtocol {

    guard let decl = declaration.as(StructDeclSyntax.self) else { return [] } //.description.trimmingCharacters(in: .whitespacesAndNewlines)
    let a: AttributeListSyntax!
//    a.description

    let vars = decl.memberBlock.members.compactMap {
      $0.decl.as(VariableDeclSyntax.self)
    }.filter {
      $0.attributes?.first?.trimmed.description == "@Injected"
    }.map {
      $0.description
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .dropping(prefix: "@Injected")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
//    injectableProtocolVars[decl.identifier.text, default: []].formUnion(vars)

    let identifier = decl.identifier.text

    let protocolVars = vars.map { $0 + " { get }" }
    let keyPaths = vars.map {
      "\\" + identifier + "_DependencyProvider." + $0.split(separator: " ", maxSplits: 1).last!.components(separatedBy: ":").first! // TODO: get identifier
    }
//    throw CustomError.message("`\(d)`")

//    let memberList = try MemberDeclListSyntax(
//      decl.memberBlock.members.filter {
//
//        if let property = $0.as(VariableDeclSyntax.self),
//           property.attributes?.isEmpty == false {
//          throw CustomError.message("`\(property.attributes!.first!.description)`")
//          return true
//        } //.contains(where: { $0. })
//        return false
////        $0.decl.isObservableStoredProperty
//      }
//    )
//    throw CustomError.message("`\(memberList.first!.description)`")

//    let descr = decl.identifier.text

//    throw CustomError.message("`\(descr)`")

    return ["""
      protocol \(raw: identifier)_DependencyProvider {
        \(raw: protocolVars.joined(separator: "\n"))
      }
      func \(raw: identifier)_DependencyProvider_allKeyPaths() -> Set<AnyKeyPath> {
        [
          \(raw: keyPaths.joined(separator: ",\n"))
        ]
      }

      protocol \(raw: identifier)_DynamicDependencyProvider {
        var _storage: [AnyKeyPath: Any] { get set }
      }

    """]
//    return [
//      """
//        protocol \(raw: decl.identifier.text)_DependencyProvider {
//          \(raw: protocolVars.joined(separator: "\n"))
//        }
//      """
//    ]
  }

}


public struct InjectedMacro {
}

// TODO: Cache injections for InjectedDependenciesMacro
extension InjectedMacro: AccessorMacro {
  public static func expansion<
    Context: MacroExpansionContext,
    Declaration: DeclSyntaxProtocol
  >(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: Declaration,
    in context: Context
  ) throws -> [AccessorDeclSyntax] {
    guard let varDecl = declaration.as(VariableDeclSyntax.self),
          let binding = varDecl.bindings.first,
          let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier
    else {
      return []
    }

//    if injectables.contains("ChildStruct2") {
//      throw CustomError.message("ChildStruct2 `\(vars)`")
//    }

    // TODO: allow default value
//    guard let defaultValue = binding.initializer?.value else {
//      throw CustomError.message("stored property must have an initializer")
//    }

    return [
      """
        get {
          dependencyProvider.\(raw: identifier.text)
        }
      """
    ]
  }
}

struct InjectedDependenciesMacro: MemberMacro {

  static func expansion<Declaration, Context>(of node: AttributeSyntax, providingMembersOf declaration: Declaration, in context: Context) throws -> [DeclSyntax] where Declaration : DeclGroupSyntax, Context : MacroExpansionContext {

    guard case let .argumentList(arguments) = node.argument else {
      throw CustomError.message("InjectedDependencies invalid declaration")
    }

//    let injectables = arguments.compactMap { $0.expression.as(MemberAccessExprSyntax.self)?.base?.as(IdentifierExprSyntax.self)?.identifier.text }

//    let mapping = injectables.map { "id `\($0)`: \(injectableProtocolVars[$0]?.joined(separator: ",") ?? "nil")" }

//    let commonSet = injectables.reduce(into: Set<String>()) { $0.formUnion(injectableProtocolVars[$1, default: []]) }

//    let vars = commonSet.map { $0 + " { fatalError() }" }

//    if injectables.contains("ChildStruct2") {
//
//
//      throw CustomError.message("ChildStruct2 `\(vars)`")
//    }

//    let labels = arguments.map { $0.expression.as(MemberAccessExprSyntax.self)?.base?.as(IdentifierExprSyntax.self).ra }

//       let optionEnumNameArg = arguments.first(labeled: optionsEnumNameArgumentLabel) {


//    guard let argument = node.argument else { //. .argumentList.first?.expression else {
//      throw CustomError.message("InjectedDependencies invalid declaration")
//    }

//    throw CustomError.message("`\(labels)`")

    return [
//      "\(raw: vars.joined(separator: "\n"))"
    ]
  }

}

extension InjectedDependenciesMacro: ConformanceMacro {

  public static func expansion(
    of attribute: AttributeSyntax,
    providingConformancesOf decl: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {

//    guard case let .argumentList(arguments) = attribute.argument else {
//      throw CustomError.message("InjectedDependencies invalid declaration")
//    }

//    let injectables = arguments.compactMap { $0.expression.as(MemberAccessExprSyntax.self)?.base?.as(IdentifierExprSyntax.self) }

    // TODO: filter out reduntant conformance
//    // If there is an explicit conformance to OptionSet already, don't add one.
//    if let inheritedTypes = structDecl.inheritanceClause?.inheritedTypeCollection,
//       inheritedTypes.contains(where: { inherited in inherited.typeName.trimmedDescription == "OptionSet" }) {
//      return []
//    }

//    throw CustomError.message("`\(context)`")
//    return injectables.map { ("\($0).DependencyProvider", nil) }
    return []
  }

}

//extension InjectedDependenciesMacro: DeclarationMacro {
//
//  static func expansion<Node, Context>(of node: Node, in context: Context) throws -> [DeclSyntax] where Node : FreestandingMacroExpansionSyntax, Context : MacroExpansionContext {
//
//    guard let argument = node.argumentList.first?.expression else {
//      throw CustomError.message("InjectedDependencies invalid declaration")
//    }
////        let segments = argument.as(StringLiteralExprSyntax.self)?.segments,
////          segments.count == 1,
////          case .stringSegment(let literalSegment)? = segments.first
////    else {
////      throw CustomError.message("#URL requires a static string literal")
////    }
//
//
//    throw CustomError.message("`\(argument)`")
//
//  }
//
//}
