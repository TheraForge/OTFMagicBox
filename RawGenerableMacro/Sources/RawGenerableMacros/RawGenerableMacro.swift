/*
 Copyright (c) 2025, Hippocrates Technologies Sagl. All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.

 3. Neither the name of the copyright holder(s) nor the names of any contributor(s) may
 be used to endorse or promote products derived from this software without specific
 prior written permission. No license is granted to the trademarks of the copyright
 holders even if such marks are included in this software.

 4. Commercial redistribution in any form requires an explicit license agreement with the
 copyright holder(s). Please contact support@hippocratestech.com for further information
 regarding licensing.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 OF SUCH DAMAGE.
 */

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A peer macro that synthesizes a `Raw…` companion type for a model.
///
/// Overview
/// - Attach `@RawGenerable` to a `struct` that represents your
///   high-level, strongly-typed model. The macro generates a peer type named
///   `RawOriginalName` that:
///   - Mirrors the stored properties of the original struct.
///   - Makes each mirrored property optional.
///   - Optionally rewrites property types to their `Raw…` counterparts when the
///     property declaration is annotated with `@NestedRaw`.
///   - Conforms to `Codable`.
///   - Inherits the same access control as the original struct (`public`/`open`
///     yields a `public` raw type; otherwise internal).
///
/// Usage
/// ```swift
/// @RawGenerable
/// struct Onboarding: Codable {
///     let version: String
///     @NestedRaw let pages: [OnboardingPage]
///     let primaryButtonTitle: OTFStringLocalized
/// }
/// // Expands to:
/// // struct RawOnboarding: Codable {
/// //     var version: String?
/// //     var pages: [RawOnboardingPage]?
/// //     var primaryButtonTitle: OTFStringLocalized?
/// // }
/// ```
///
/// Type Rewriting Rules
/// - If a property declaration is annotated with `@NestedRaw`, the macro:
///   - Strips a single top-level optional from the declared type (if present),
///     then recursively rewrites the type to its `Raw…` form.
///   - Rewriting traverses:
///     - Identifier types, prefixing with `Raw` (e.g., `User` -> `RawUser`)
///     - Member types, preserving module qualification (e.g., `Module.User` -> `Module.RawUser`)
///     - Generic types (e.g., `Result<User, Error>` -> `RawResult<RawUser, Error>`)
///     - Collections (e.g., `[User]` -> `[RawUser]`, `[String: User]` -> `[String: RawUser]`)
/// - If a property declaration is not annotated with `@NestedRaw`, the macro:
///   - Keeps the type as-is, but removes a single top-level optional if present.
/// - In all cases, the resulting property in the `Raw…` type is declared as
///   optional (`?`) to reflect partial decoding.
///
/// Access Control
/// - If the annotated struct is `public` or `open`, the generated `Raw…` type
///   is marked `public`. Otherwise, it remains internal.
///
/// Limitations
/// - Only peer generation is performed; the original type is not modified.
/// - Only stored properties declared directly in the struct body are mirrored.
/// - The `@NestedRaw` attribute is read at the declaration level and applies to all
///   bindings in that declaration (e.g., `@NestedRaw let a: T, b: U` affects both).
/// - Computed properties and properties without explicit type annotations are
///   ignored.
/// - The macro does not validate the existence of corresponding `Raw…` types for
///   referenced types; it only rewrites the syntax.
///
/// Diagnostics
/// - If the attribute is applied to a non-`struct` declaration, the macro
///   produces no peers (no diagnostics are emitted).
public struct RawGenerableMacro: PeerMacro {
    /// Expands `@RawGenerable` by producing a peer `Raw<StructName>` type.
    ///
    /// - Parameters:
    ///   - node: The attribute syntax (`@RawGenerable`).
    ///   - decl: The declaration to which the attribute is attached. Must be a `struct`.
    ///   - context: The macro expansion context.
    /// - Returns: A single peer declaration containing the synthesized `Raw…` type,
    ///   or an empty array if the attribute is not attached to a `struct`.
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf decl: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        guard let structDecl = decl.as(StructDeclSyntax.self) else { return [] }

        let rawName = "Raw\(structDecl.name.text)"
        let isPublic = structDecl.modifiers.contains(where: {
            $0.name.tokenKind == .keyword(.public) || $0.name.tokenKind == .keyword(.open)
        })
        let access = isPublic ? "public " : ""

        var props: [String] = []

        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }

            // Read attributes from the declaration (not the binding).
            // If `@NestedRaw` is present on the declaration, it applies to all bindings in it.
            let declHasNestedRaw: Bool = {
                return varDecl.attributes.contains { element in
                    guard let a = element.as(AttributeSyntax.self) else { return false }
                    let name = a.attributeName.trimmedDescription
                    return name == "NestedRaw" || name.hasSuffix(".NestedRaw")
                }
            }()

            for binding in varDecl.bindings {
                guard
                    let id = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                    let typeSyntax = binding.typeAnnotation?.type
                else { continue }

                // Default policy: keep the type as-is but remove a single top-level optional (if present).
                // If `@NestedRaw` is present on this declaration, recursively rewrite to `Raw…`,
                // stripping a single top-level optional before rewriting.
                let baseType = declHasNestedRaw
                ? rewriteToRawStrippingTopOptional(typeSyntax)
                : stripTopOptional(typeSyntax)

                props.append("    var \(id): \(baseType)?")
            }
        }

        let code = """
        \(access)struct \(rawName): Codable {
        \(props.joined(separator: "\n"))
        }
        """
        return [DeclSyntax(stringLiteral: code)]
    }
}

// MARK: - Helpers

/// Returns the textual type without a single top-level `?`, leaving the rest unchanged.
private func stripTopOptional(_ type: TypeSyntax) -> String {
    if let opt = type.as(OptionalTypeSyntax.self) {
        return opt.wrappedType.trimmedDescription
    }
    return type.trimmedDescription
}

/// Strips a single top-level `?` and then rewrites the inner type to its `Raw…` form.
private func rewriteToRawStrippingTopOptional(_ type: TypeSyntax) -> String {
    if let opt = type.as(OptionalTypeSyntax.self) {
        return rewriteToRaw(opt.wrappedType)
    }
    return rewriteToRaw(type)
}

/// Recursively rewrites identifier/member/generic/collection types to `Raw…`,
/// preserving module qualifiers and formatting where possible.
private func rewriteToRaw(_ type: TypeSyntax) -> String {
    if let arr = type.as(ArrayTypeSyntax.self) {
        return "[\(rewriteToRaw(arr.element))]"
    }
    if let dict = type.as(DictionaryTypeSyntax.self) {
        return "[\(rewriteToRaw(dict.key)): \(rewriteToRaw(dict.value))]"
    }
    if let member = type.as(MemberTypeSyntax.self) {
        // Keep module qualifier, prefix the final name
        return "\(member.baseType.trimmedDescription).\(rawify(member.name.text))"
    }
    if let ident = type.as(IdentifierTypeSyntax.self) {
        let name = ident.name.text
        if let clause = ident.genericArgumentClause {
            let args = clause.arguments
                .map { rewriteToRaw(TypeSyntax($0.argument)) }
                .joined(separator: ", ")
            return "\(rawify(name))<\(args)>"
        }
        return rawify(name)
    }
    if let opt = type.as(OptionalTypeSyntax.self) {
        // Already handled by stripTopOptional before; still be safe here
        return rewriteToRaw(opt.wrappedType)
    }
    return type.trimmedDescription
}

/// Prefixes a type name with `Raw` iff it appears to be a nominal type
/// (starts with an uppercase character). Otherwise, returns the name unchanged.
private func rawify(_ name: String) -> String {
    guard let f = name.first, f.isUppercase else {
        return name
    }
    return "Raw\(name)"
}

private extension SyntaxProtocol {
    /// A convenience to obtain a whitespace-trimmed textual description.
    var trimmedDescription: String { description.trimmingCharacters(in: .whitespacesAndNewlines) }
}
