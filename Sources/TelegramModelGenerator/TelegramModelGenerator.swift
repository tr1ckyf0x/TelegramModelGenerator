import Alamofire
import ArgumentParser
import Foundation
import SwiftSoup

@main
struct TelegramModelGenerator: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "telegram-model-generator",
        abstract: "Generates Telegram API models",
        version: "0.1.0"
    )

    @Argument(help: "Path to which models will be generated")
    var path: String

    func run() async throws {
        try await generateModels()
    }
}

// MARK: - Private

extension TelegramModelGenerator {
    private func generateModels() async throws {
        let apiDocsHtml = try await fetchApiHtml()
        let document: Document = try SwiftSoup.parse(apiDocsHtml)
        let elements = try document.getElementsByTag("h4")
        for element: Element in elements {
            let title = try element.text()
            guard
                title.split(separator: .space).count == 1,
                !Constants.excludedTypes.contains(title),
                title.first?.isUppercase == true
            else {
                continue
            }

            try generateModelFile(for: element)
        }
    }

    private func fetchApiHtml() async throws -> String {
        try await AF.request("https://core.telegram.org/bots/api")
            .validate()
            .serializingString()
            .value
    }

    private func generateModelFile(for element: Element) throws {
        var propertiesBlock = String()
        var initArgumentsBlock = String()
        var initBlock = String()
        var codingKeysBlock = String()
        var result = String()

        let propertyDescriptionSpaces = Constants.Spaces.spaces(for: 1)
        let propertySpaces = Constants.Spaces.spaces(for: 1)
        let initArgumentsBlockSpaces = Constants.Spaces.spaces(for: 2)
        let initBlockSpaces = Constants.Spaces.spaces(for: 2)
        let codingKeysSpaces = Constants.Spaces.spaces(for: 2)

        let typeName = try element.text()

        var element = element
        let description = try fetchDescription(for: &element)
        element = try element.nextElementSibling()!
        for element: Element in try element.getElementsByTag("tr") {
            let td = try element.getElementsByTag("td")
            guard
                !td.isEmpty(),
                !["Field", "Parameters"].contains(try td.first()?.text())
            else {
                continue
            }
            let propertyName = try td[0].text()
            let propertyType = try td[1].text()
            let propertyDescription = try td[2].text()
            let isPropertyOptional = propertyDescription.starts(with: "Optional")

            let swiftType = convertToSwiftType(
                name: propertyName,
                description: propertyDescription,
                type: propertyType,
                isOptional: isPropertyOptional
            )

            let swiftTypeInitSuffix = swiftType.last == "?" ? " = nil" : String()
            let swiftTypeInit = swiftType.appending(swiftTypeInitSuffix)
            let camelCasedPropertyName = propertyName.camelCasedLower(with: "_")

            propertyDescription.split(separator: "\n").forEach { (line: Substring) in
                let line = line.trimmingCharacters(in: .whitespacesAndNewlines)
                propertiesBlock.append("\(propertyDescriptionSpaces)/// \(line)\n")
            }

            propertiesBlock.append("\(propertySpaces)public var \(camelCasedPropertyName): \(swiftType)\n\n")

            initArgumentsBlock.append("\(initArgumentsBlockSpaces)\(camelCasedPropertyName): \(swiftTypeInit),\n")

            initBlock.append("\(initBlockSpaces)self.\(camelCasedPropertyName) = \(camelCasedPropertyName)\n")

            codingKeysBlock.append("\(codingKeysSpaces)case \(camelCasedPropertyName) = \"\(propertyName)\"\n")
        }

        result.append("/**\n")
        description.split(separator: "\n").forEach { (line: Substring) in
            result.append(" \(line)\n")
        }
        result.append("\n")
        result.append(" SeeAlso Telegram Bot API Reference:\n")
        result.append(" [\(typeName)](https://core.telegram.org/bots/api#\(typeName.lowercased()))\n")
        result.append(" */\n")
        result.append("public struct \(typeName): Codable {\n\n")

        if !propertiesBlock.isEmpty {
            let initSpaces = Constants.Spaces.spaces(for: 1)
            let codingKeysSpaces = Constants.Spaces.spaces(for: 1)
            result.append(propertiesBlock)
            let initArgumentsBlock = initArgumentsBlock.split(separator: ", ").joined(separator: ", ")
            result.append("\(initSpaces)public init(\n")
            result.append("\(initArgumentsBlock)")
            result.append("\(initSpaces)) {\n")
            result.append(initBlock)
            result.append("\(initSpaces)}\n")
            result.append("\n")
            result.append("\(codingKeysSpaces)enum CodingKeys: String, CodingKey {\n")
            result.append(codingKeysBlock)
            result.append("\(codingKeysSpaces)}\n")
        }

        result.append("}\n")

        writeFile(name: "\(typeName).swift", content: result)
    }

    private func fetchDescription(for element: inout Element) throws -> String {
        var description = [String]()
        while let sibling = try element.nextElementSibling(),
              !["table", "h4"].contains(sibling.tagName()) {
            let text = try sibling.text().trimmingCharacters(in: .whitespacesAndNewlines)
            description.append(text)
            element = sibling
        }
        return description.joined(separator: "\n")
    }

    private func convertToSwiftType(
        name: String,
        description: String,
        type: String,
        isOptional: Bool
    ) -> String {
        // Edge case
        if name == "type" {
            if description.contains("Type of chat") {
                return "ChatType"
            }
            if description.contains("Type of the entity") {
                return "MessageEntityType"
            }
        }

        // Edge case
        if type == "True" && !isOptional {
            return "Bool = true"
        }

        var swiftType: String?

        // Edge case
        if type == "Integer or String" && name.contains("chat_id") {
            swiftType = "ChatId"
        }

        if swiftType == nil {
            swiftType = Constants.swiftTypes[type]
        }

        if swiftType == nil {
            let twoDimensionalArrayPrefix = "Array of Array of "
            let arrayPrefix = "Array of "

            if type.hasPrefix(twoDimensionalArrayPrefix) {
                swiftType = "[[\(type.trimmingPrefix(twoDimensionalArrayPrefix))]]"
            } else if type.hasPrefix(arrayPrefix) {
                let trimmedType = String(type.trimmingPrefix(arrayPrefix))
                let correctedType = Constants.swiftTypes[trimmedType] ?? trimmedType
                swiftType = "[\(correctedType)]"
            }
        }

        if swiftType == nil {
            swiftType = type
        }

        let suffix = isOptional ? "?" : String()

        return (swiftType ?? type).appending(suffix)
    }

    private func writeFile(name: String, content: String) {
        let path = URL(filePath: path).appending(path: name).path()
        let data = content.data(using: .utf8)

        FileManager.default.createFile(atPath: path, contents: data)
    }

}

// MARK: - Constants

extension TelegramModelGenerator {
    enum Constants {
        static let excludedTypes = [
            "InlineQueryResult",
            "InputFile",
            "InputMedia",
            "InputMessageContent",
            "PassportElementError"
        ]

        static let swiftTypes: [String: String] = [
            "String": "String",
            "InputFile or String": "FileInfo",
            "Integer": "Int64",
            "Float number": "Double",
            "Float": "Double",
            "Boolean": "Bool",
            "True": "Bool", // edge case True optional
            "Integer or String": "String"
        ]
    }
}

extension TelegramModelGenerator.Constants {
    enum Spaces {
        static func spaces(for level: Int) -> String {
            String(repeating: " ", count: level * 4)
        }
    }
}
