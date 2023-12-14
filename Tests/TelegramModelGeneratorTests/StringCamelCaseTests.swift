//
//  StringCamelCaseTests.swift
//
//
//  Created by Vladislav Lisianskii on 14.12.2023.
//

import Foundation
import Quick
import Nimble
@testable import TelegramModelGenerator

final class StringCamelCaseTests: QuickSpec {
    override class func spec() {
        describe("String.camelCased(with:)") {
            let dataSet: [(input: String, expected: String)] = [
                (input: "total_count", expected: "TotalCount"),
                (input: "total", expected: "Total")
            ]
            dataSet.forEach { (input: String, expected: String) in
                context("for input: \(input)") {
                    it("should equal \(expected)") {
                        let result = input.camelCased(with: "_")
                        expect(result).to(equal(expected))
                    }
                }
            }
        }

        describe("String.camelCasedLower(with:)") {
            let dataSet: [(input: String, expected: String)] = [
                (input: "total_count", expected: "totalCount"),
                (input: "total", expected: "total")
            ]
            dataSet.forEach { (input: String, expected: String) in
                context("for input: \(input)") {
                    it("should equal \(expected)") {
                        let result = input.camelCasedLower(with: "_")
                        expect(result).to(equal(expected))
                    }
                }
            }
        }
    }
}
