/*
 Copyright (c) 2026, Hippocrates Technologies Sagl. All rights reserved.

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

import Foundation
import OTFCloudClientAPI
import OTFTemplateBox
import SwiftUI
import Testing
@testable import OTFMagicBox

@Suite("App shell")
struct AppShellTests {
    @Test("App bundle declares SDK-required scene and launch metadata")
    func appBundleDeclaresSDKRequiredSceneAndLaunchMetadata() throws {
        let info = try #require(Bundle.main.infoDictionary)

        #expect(info["UILaunchStoryboardName"] as? String == "LaunchScreen")
        #expect(info["UIDesignRequiresCompatibility"] as? Bool == true)

        let sceneManifest = try #require(info["UIApplicationSceneManifest"] as? [String: Any])
        #expect(sceneManifest["UIApplicationSupportsMultipleScenes"] as? Bool == false)

        let sceneConfigurations = try #require(sceneManifest["UISceneConfigurations"] as? [String: Any])
        let applicationScenes = try #require(
            sceneConfigurations["UIWindowSceneSessionRoleApplication"] as? [[String: Any]]
        )
        let defaultScene = try #require(applicationScenes.first)

        #expect(defaultScene["UISceneConfigurationName"] as? String == "Default Configuration")
        #expect(defaultScene["UISceneDelegateClassName"] == nil)
    }

    @Test("OTFMagicBox app delegates network configuration to runtime")
    func appDelegatesNetworkConfigurationToRuntime() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "app-shell")
        defer { defaultsFixture.cleanup() }
        let probe = AppRuntimeProbe()

        _ = OTFMagicBoxApp(runtime: probe.runtime(userDefaults: defaultsFixture.defaults))

        #expect(probe.configureNetworkCallCount == 1)
    }

    @Test("Content view model exposes default API key state")
    func contentViewModelExposesDefaultAPIKeyState() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "app-shell")
        defer { defaultsFixture.cleanup() }
        defaultsFixture.defaults.set(true, forKey: Constants.Storage.kOnboardingCompleted)
        let probe = AppRuntimeProbe(appConfiguration: .fallback)

        let model = ContentViewModel(runtime: probe.runtime(userDefaults: defaultsFixture.defaults))

        #expect(model.isDefaultAPIKey)
        #expect(model.isOnboardingCompleted)
        #expect(model.config.apiKey == AppConfiguration.fallback.apiKey)
    }

    @Test("Content view model reads onboarding defaults for valid API key")
    func contentViewModelReadsOnboardingDefaultsForValidAPIKey() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "app-shell")
        defer { defaultsFixture.cleanup() }
        defaultsFixture.defaults.set(true, forKey: Constants.Storage.kOnboardingCompleted)
        let probe = AppRuntimeProbe(appConfiguration: makeAppConfiguration(apiKey: "<your-api-key>"))

        let model = ContentViewModel(runtime: probe.runtime(userDefaults: defaultsFixture.defaults))

        #expect(!model.isDefaultAPIKey)
        #expect(model.isOnboardingCompleted)
    }

    @Test("Content view model subscribes to SSE after refresh success")
    func contentViewModelSubscribesToSSEAfterRefreshSuccess() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "app-shell")
        defer { defaultsFixture.cleanup() }
        let auth = makeAuth(token: "access-token", refreshToken: "refresh-token")
        let probe = AppRuntimeProbe(
            appConfiguration: makeAppConfiguration(apiKey: "<your-api-key>"),
            refreshResult: .success(Response.Login(error: false, message: nil, data: makeUser(), accessToken: auth))
        )

        _ = ContentViewModel(runtime: probe.runtime(userDefaults: defaultsFixture.defaults))

        #expect(probe.refreshTokenCallCount == 1)
        #expect(probe.subscribedAuth?.token == "access-token")
        #expect(probe.moveToOnboardingCallCount == 0)
    }

    @Test("Content view model moves to onboarding only for deleted user refresh failure")
    func contentViewModelMovesToOnboardingOnlyForDeletedUserRefreshFailure() {
        let deletedDefaultsFixture = makeIsolatedUserDefaults(prefix: "app-shell")
        defer { deletedDefaultsFixture.cleanup() }
        let deletedProbe = AppRuntimeProbe(
            appConfiguration: makeAppConfiguration(apiKey: "<your-api-key>"),
            refreshResult: .failure(makeForgeError(statusCode: 410))
        )

        _ = ContentViewModel(runtime: deletedProbe.runtime(userDefaults: deletedDefaultsFixture.defaults))

        let otherDefaultsFixture = makeIsolatedUserDefaults(prefix: "app-shell")
        defer { otherDefaultsFixture.cleanup() }
        let otherProbe = AppRuntimeProbe(
            appConfiguration: makeAppConfiguration(apiKey: "<your-api-key>"),
            refreshResult: .failure(makeForgeError(statusCode: 500))
        )

        _ = ContentViewModel(runtime: otherProbe.runtime(userDefaults: otherDefaultsFixture.defaults))

        #expect(deletedProbe.moveToOnboardingCallCount == 1)
        #expect(otherProbe.moveToOnboardingCallCount == 0)
    }

    @Test("Content view model handles onboarding completion notifications")
    func contentViewModelHandlesOnboardingCompletionNotifications() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "app-shell")
        defer { defaultsFixture.cleanup() }
        let probe = AppRuntimeProbe(appConfiguration: makeAppConfiguration(apiKey: "<your-api-key>"))
        let model = ContentViewModel(runtime: probe.runtime(userDefaults: defaultsFixture.defaults))

        model.handleOnboardingCompletedNotification(Notification(name: .onboardingCompleted, object: true))

        #expect(model.isOnboardingCompleted)
        #expect(defaultsFixture.defaults.bool(forKey: Constants.Storage.kOnboardingCompleted))

        model.handleOnboardingCompletedNotification(Notification(name: .onboardingCompleted, object: false))

        #expect(!model.isOnboardingCompleted)
        #expect(!defaultsFixture.defaults.bool(forKey: Constants.Storage.kOnboardingCompleted))
    }

    @Test("Content routing depends on onboarding completion and user availability")
    func contentRoutingDependsOnOnboardingCompletionAndUserAvailability() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "app-shell")
        defer { defaultsFixture.cleanup() }
        let probe = AppRuntimeProbe(appConfiguration: makeAppConfiguration(apiKey: "<your-api-key>"))
        let model = ContentViewModel(runtime: probe.runtime(userDefaults: defaultsFixture.defaults))

        #expect(model.contentRoute(hasUser: true) == .onboarding)

        model.setOnboarding(completed: true)

        #expect(model.contentRoute(hasUser: true) == .tabs)
        #expect(model.contentRoute(hasUser: false) == .onboarding)
    }

    @Test("Active app shell event delegates app lock and foreground sync")
    func activeAppShellEventDelegatesAppLockAndForegroundSync() {
        let defaultsFixture = makeIsolatedUserDefaults(prefix: "app-shell")
        defer { defaultsFixture.cleanup() }
        let probe = AppRuntimeProbe(appConfiguration: makeAppConfiguration(apiKey: "<your-api-key>"))
        let model = ContentViewModel(runtime: probe.runtime(userDefaults: defaultsFixture.defaults))

        model.applicationDidBecomeActive()

        #expect(probe.presentAppLockCallCount == 1)
        #expect(probe.syncOnForegroundCallCount == 1)
    }

    @Test("Root destination visible tabs follow app configuration")
    func rootDestinationVisibleTabsFollowAppConfiguration() {
        let expected: [RootDestination] = [.schedule, .contacts, .checkup, .ui, .profile]

        #expect(RootDestination.visibleTabs(for: makeAppConfiguration()) == expected)
        #expect(RootDestination.visibleTabs(
            for: makeAppConfiguration(useCareKit: false, showCheckupScreen: false, showUIScreen: false)
        ) == [.profile])
        #expect(RootDestination.visibleTabs(for: makeAppConfiguration(playgroundMode: true)) == [.playground])
    }

    @Test("Root destination titles and symbols come from app configuration")
    func rootDestinationTitlesAndSymbolsComeFromAppConfiguration() {
        let config = makeAppConfiguration(
            scheduleTitle: "Care Plan",
            scheduleSymbol: "calendar.badge.clock"
        )

        #expect(RootDestination.schedule.title(from: config) == "Care Plan")
        #expect(RootDestination.schedule.symbol(from: config) == "calendar.badge.clock")
    }
}

private final class AppRuntimeProbe {
    var configureNetworkCallCount = 0
    var refreshTokenCallCount = 0
    var moveToOnboardingCallCount = 0
    var presentAppLockCallCount = 0
    var syncOnForegroundCallCount = 0
    var subscribedAuth: Auth?
    var user: Response.User?

    private let appConfiguration: AppConfiguration
    private let refreshResult: Result<Response.Login, ForgeError>?

    init(
        appConfiguration: AppConfiguration = makeAppConfiguration(),
        refreshResult: Result<Response.Login, ForgeError>? = nil,
        user: Response.User? = makeUser()
    ) {
        self.appConfiguration = appConfiguration
        self.refreshResult = refreshResult
        self.user = user
    }

    func runtime(
        userDefaults: UserDefaults,
        notificationCenter: NotificationCenter = NotificationCenter()
    ) -> AppRuntime {
        AppRuntime(
            appConfiguration: appConfiguration,
            styleConfiguration: .fallback,
            userDefaults: userDefaults,
            notificationCenter: notificationCenter,
            configureNetwork: { self.configureNetworkCallCount += 1 },
            loadUser: { self.user },
            refreshToken: { completion in
                self.refreshTokenCallCount += 1
                if let refreshResult = self.refreshResult {
                    completion(refreshResult)
                }
            },
            subscribeToSSE: { auth in
                self.subscribedAuth = auth
            },
            moveToOnboarding: {
                self.moveToOnboardingCallCount += 1
            },
            presentAppLock: {
                self.presentAppLockCallCount += 1
            },
            syncOnForeground: {
                self.syncOnForegroundCallCount += 1
            }
        )
    }
}

private func makeUser() -> Response.User {
    Response.User(
        id: "user-1",
        email: "test@example.com",
        firstName: "Test",
        lastName: "User",
        type: .patient,
        gender: .other,
        dob: "2000-01-01",
        encryptedMasterKey: nil,
        encryptedConfidentialStorageKey: nil,
        encryptedDefaultStorageKey: nil
    )
}

private func makeForgeError(statusCode: Int) -> ForgeError {
    ForgeError(error: .init(statusCode: statusCode, name: "Test", message: "Test error", code: nil))
}
