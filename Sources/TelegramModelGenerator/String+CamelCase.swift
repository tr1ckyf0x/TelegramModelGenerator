//
//  String+CamelCase.swift
//
//
//  Created by Vladislav Lisianskii on 14.12.2023.
//

import Foundation

extension String {

    func camelCasedLower(with separator: Character) -> String {
        let camelCased = camelCased(with: separator)
        return camelCased.prefix(1).lowercased() + camelCased.dropFirst()
    }

    func camelCased(with separator: Character) -> String {
        self.split(separator: separator)
            .map { $0.capitalized }
            .joined()
    }
}
