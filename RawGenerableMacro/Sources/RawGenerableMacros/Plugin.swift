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

import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// The compiler plugin entry point that registers macros provided by this package.
///
/// This plugin exposes:
/// - `RawRepresentableModelMacro`: A peer macro that synthesizes a `Raw…`
///   companion type for a model struct.
/// - `NoopMarkerMacro`: An auxiliary marker macro (no-op), typically used for
///   feature gating or as an annotation recognized by other tools in the build.
///
/// Notes
/// - Clients typically import a lightweight client module that declares the
///   public-facing macro attributes, for example:
///   `public macro RawRepresentableModel() = #externalMacro(module: "…", type: "RawRepresentableModelMacro")`.
/// - This plugin target must be built as a Swift macro plugin and is loaded by
///   the Swift compiler during expansion.
@main
struct RawRepresentableModelPlugin: CompilerPlugin {
    /// The set of macros this plugin provides to the compiler.
    let providingMacros: [Macro.Type] = [
        RawGenerableMacro.self,
        NestedRawMacro.self
    ]
}
