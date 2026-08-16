import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
@testable import RawGenerableMacros

@Suite("RawGenerable macro expansion")
struct RawGenerableMacroTests {

    @Test("RawGenerable mirrors stored properties as optionals")
    func rawGenerableMirrorsStoredPropertiesAsOptionals() {
        assertMacroExpansion(
            """
            @RawGenerable
            struct Profile: Codable {
                let id: String
                var displayName: String?
                var computed: String { id }
                let inferred = "ignored"
            }
            """,
            expandedSource:
            """
            struct Profile: Codable {
                let id: String
                var displayName: String?
                var computed: String { id }
                let inferred = "ignored"
            }

            struct RawProfile: Codable {
                var id: String?
                var displayName: String?
            }
            """,
            macros: rawMacros()
        )
    }

    @Test("RawGenerable preserves public access")
    func rawGenerablePreservesPublicAccess() {
        assertMacroExpansion(
            """
            @RawGenerable
            public struct AppConfig: Codable {
                public let apiKey: String
            }
            """,
            expandedSource:
            """
            public struct AppConfig: Codable {
                public let apiKey: String
            }

            public struct RawAppConfig: Codable {
                var apiKey: String?
            }
            """,
            macros: rawMacros()
        )
    }

    @Test("NestedRaw rewrites collection and member types")
    func nestedRawRewritesCollectionAndMemberTypes() {
        assertMacroExpansion(
            """
            @RawGenerable
            struct Survey: Codable {
                @NestedRaw var pages: [SurveyPage]?
                @NestedRaw var localizedPages: [String: Module.SurveyPage]
                var title: String?
            }
            """,
            expandedSource:
            """
            struct Survey: Codable {
                var pages: [SurveyPage]?
                var localizedPages: [String: Module.SurveyPage]
                var title: String?
            }

            struct RawSurvey: Codable {
                var pages: [RawSurveyPage]?
                var localizedPages: [String: Module.RawSurveyPage]?
                var title: String?
            }
            """,
            macros: rawMacros()
        )
    }

    @Test("NestedRaw attribute itself does not emit peers")
    func nestedRawAttributeItselfDoesNotEmitPeers() {
        assertMacroExpansion(
            """
            struct Container {
                @NestedRaw var page: Page
            }
            """,
            expandedSource:
            """
            struct Container {
                var page: Page
            }
            """,
            macros: rawMacros()
        )
    }

    @Test("RawGenerable on non-struct declarations emits no peers")
    func rawGenerableOnNonStructDeclarationsEmitsNoPeers() {
        assertMacroExpansion(
            """
            @RawGenerable
            enum Route: Codable {
                case home
            }
            """,
            expandedSource:
            """
            enum Route: Codable {
                case home
            }
            """,
            macros: rawMacros()
        )
    }
}

private func rawMacros() -> [String: Macro.Type] {
    [
        "RawGenerable": RawGenerableMacro.self,
        "NestedRaw": NestedRawMacro.self
    ]
}
