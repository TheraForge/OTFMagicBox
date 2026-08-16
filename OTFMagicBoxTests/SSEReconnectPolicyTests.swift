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
import Testing
import OTFCloudClientAPI
import OTFCareKitStore
import OTFCDTDatastore
import OTFCloudantStore
@testable import OTFMagicBox

@Suite("SSE reconnect policy")
struct SSEReconnectPolicyTests {
    @Test("SSE Reconnect Policy Schedules Reconnect For Timeout When Event Source Does Not Request Reconnect")
    func sSEReconnectPolicySchedulesReconnectForTimeoutWhenEventSourceDoesNotRequestReconnect() {
        let auth = makeAuth(token: "token-a", refreshToken: "refresh-a")
        let policy = SSEReconnectPolicy()

        let decision = policy.reconnectDecision(
            eventSourceRequestedReconnect: false,
            error: URLError(.timedOut),
            completedOpenedStream: false,
            statusCode: nil,
            attempt: 0,
            startedWith: auth,
            currentAuth: auth
        )

        #expect(decision?.delay == 1)
        #expect(decision?.auth.token == "token-a")
    }

    @Test("SSE Reconnect Policy Reconnects When Event Source Requests Reconnect")
    func sSEReconnectPolicyReconnectsWhenEventSourceRequestsReconnect() {
        let auth = makeAuth(token: "token-a", refreshToken: "refresh-a")
        let policy = SSEReconnectPolicy()

        let decision = policy.reconnectDecision(
            eventSourceRequestedReconnect: true,
            error: nil,
            completedOpenedStream: false,
            statusCode: nil,
            attempt: 1,
            startedWith: auth,
            currentAuth: auth
        )

        #expect(decision?.delay == 2)
        #expect(decision?.auth.refreshToken == "refresh-a")
    }

    @Test("SSE Reconnect Policy Reconnects When Opened Stream Closes With 200")
    func sSEReconnectPolicyReconnectsWhenOpenedStreamClosesWithHTTP200() {
        let auth = makeAuth(token: "token-a", refreshToken: "refresh-a")
        let policy = SSEReconnectPolicy()

        let decision = policy.reconnectDecision(
            eventSourceRequestedReconnect: false,
            error: nil,
            completedOpenedStream: true,
            statusCode: 200,
            attempt: 2,
            startedWith: auth,
            currentAuth: auth
        )

        #expect(decision?.delay == 5)
        #expect(decision?.auth.token == "token-a")
    }

    @Test("SSE Reconnect Policy Does Not Reconnect Unopened Stream That Closes With 200")
    func sSEReconnectPolicyDoesNotReconnectUnopenedStreamThatClosesWithHTTP200() {
        let auth = makeAuth(token: "token-a", refreshToken: "refresh-a")
        let policy = SSEReconnectPolicy()

        let decision = policy.reconnectDecision(
            eventSourceRequestedReconnect: false,
            error: nil,
            completedOpenedStream: false,
            statusCode: 200,
            attempt: 0,
            startedWith: auth,
            currentAuth: auth
        )

        #expect((decision) == nil)
    }

    @Test("SSE Reconnect Policy Does Not Reconnect Stopped Opened Stream That Closes With 200")
    func sSEReconnectPolicyDoesNotReconnectStoppedOpenedStreamThatClosesWithHTTP200() {
        let auth = makeAuth(token: "token-a", refreshToken: "refresh-a")
        let policy = SSEReconnectPolicy()

        let decision = policy.reconnectDecision(
            eventSourceRequestedReconnect: false,
            error: nil,
            completedOpenedStream: false,
            statusCode: 200,
            attempt: 0,
            startedWith: auth,
            currentAuth: auth
        )

        #expect((decision) == nil)
    }

    @Test("SSE Reconnect Policy Does Not Reconnect When Auth Is Missing")
    func sSEReconnectPolicyDoesNotReconnectWhenAuthIsMissing() {
        let policy = SSEReconnectPolicy()

        let decision = policy.reconnectDecision(
            eventSourceRequestedReconnect: true,
            error: URLError(.timedOut),
            completedOpenedStream: false,
            statusCode: nil,
            attempt: 0,
            startedWith: makeAuth(token: "token-a", refreshToken: "refresh-a"),
            currentAuth: nil
        )

        #expect((decision) == nil)
    }

    @Test("SSE Reconnect Policy Does Not Reconnect When Auth No Longer Matches Session")
    func sSEReconnectPolicyDoesNotReconnectWhenAuthNoLongerMatchesSession() {
        let policy = SSEReconnectPolicy()

        let decision = policy.reconnectDecision(
            eventSourceRequestedReconnect: true,
            error: URLError(.timedOut),
            completedOpenedStream: false,
            statusCode: nil,
            attempt: 0,
            startedWith: makeAuth(token: "token-a", refreshToken: "refresh-a"),
            currentAuth: makeAuth(token: "token-b", refreshToken: "refresh-b")
        )

        #expect((decision) == nil)
    }

    @Test("SSE Reconnect Policy Requires Refresh For Expired Session Auth")
    func sSEReconnectPolicyRequiresRefreshForExpiredSessionAuth() {
        let startedAuth = makeAuth(token: "token-a", refreshToken: "refresh-a")
        let expiredAuth = makeAuth(token: "token-a", refreshToken: "refresh-a", expiresIn: -60)
        let policy = SSEReconnectPolicy()

        #expect(policy.requiresRefreshForReconnect(startedWith: startedAuth, currentAuth: expiredAuth))
        #expect((policy.validAuthForReconnect(startedWith: startedAuth, currentAuth: expiredAuth)) == nil)
    }

    @Test("SSE Reconnect Policy Accepts Rotated Auth After Successful Refresh")
    func sSEReconnectPolicyAcceptsRotatedAuthAfterSuccessfulRefresh() {
        let policy = SSEReconnectPolicy()
        let rotatedAuth = makeAuth(token: "token-b", refreshToken: "refresh-b")

        let reconnectAuth = policy.validAuthAfterSuccessfulRefresh(currentAuth: rotatedAuth)

        #expect(reconnectAuth?.token == "token-b")
        #expect(reconnectAuth?.refreshToken == "refresh-b")
    }

    @Test("SSE Reconnect Policy Does Not Accept Expired Auth After Successful Refresh")
    func sSEReconnectPolicyDoesNotAcceptExpiredAuthAfterSuccessfulRefresh() {
        let policy = SSEReconnectPolicy()
        let expiredAuth = makeAuth(token: "token-b", refreshToken: "refresh-b", expiresIn: -60)

        #expect((policy.validAuthAfterSuccessfulRefresh(currentAuth: expiredAuth)) == nil)
    }

    @Test("SSE Reconnect Policy Retries Recoverable Refresh Failure For Session Auth")
    func sSEReconnectPolicyRetriesRecoverableRefreshFailureForSessionAuth() {
        let startedAuth = makeAuth(token: "token-a", refreshToken: "refresh-a")
        let expiredAuth = makeAuth(token: "token-a", refreshToken: "refresh-a", expiresIn: -60)
        let policy = SSEReconnectPolicy()

        #expect(policy.shouldRetryRefreshFailure(
                URLError(.notConnectedToInternet),
                startedWith: startedAuth,
                currentAuth: expiredAuth
            ))
    }

    @Test("SSE Reconnect Policy Does Not Retry Refresh Failure When Auth Changed")
    func sSEReconnectPolicyDoesNotRetryRefreshFailureWhenAuthChanged() {
        let policy = SSEReconnectPolicy()

        #expect(!(policy.shouldRetryRefreshFailure(
                URLError(.notConnectedToInternet),
                startedWith: makeAuth(token: "token-a", refreshToken: "refresh-a"),
                currentAuth: makeAuth(token: "token-b", refreshToken: "refresh-b", expiresIn: -60)
            )))
    }

    @Test("SSE Reconnect Policy Does Not Retry Non Recoverable Refresh Failure")
    func sSEReconnectPolicyDoesNotRetryNonRecoverableRefreshFailure() {
        let startedAuth = makeAuth(token: "token-a", refreshToken: "refresh-a")
        let expiredAuth = makeAuth(token: "token-a", refreshToken: "refresh-a", expiresIn: -60)
        let policy = SSEReconnectPolicy()

        #expect(!(policy.shouldRetryRefreshFailure(
                ForgeError.missingCredential,
                startedWith: startedAuth,
                currentAuth: expiredAuth
            )))
    }

    @Test("SSE Reconnect Policy Backoff Caps At Thirty Seconds")
    func sSEReconnectPolicyBackoffCapsAtThirtySeconds() {
        let policy = SSEReconnectPolicy()

        #expect(policy.delay(forAttempt: 0) == 1)
        #expect(policy.delay(forAttempt: 1) == 2)
        #expect(policy.delay(forAttempt: 2) == 5)
        #expect(policy.delay(forAttempt: 3) == 15)
        #expect(policy.delay(forAttempt: 4) == 30)
        #expect(policy.delay(forAttempt: 100) == 30)
    }
}
