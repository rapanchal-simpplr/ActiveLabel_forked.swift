//
//  ActiveBuilder.swift
//  ActiveLabel
//
//  Created by Pol Quintana on 04/09/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation

typealias ActiveFilterPredicate = ((String) -> Bool)

struct ActiveBuilder {

    static func createElements(type: ActiveType, from text: String, range: NSRange, filterPredicate: ActiveFilterPredicate?) -> [ElementTuple] {
        switch type {
        case .mention, .hashtag:
            return createElementsIgnoringFirstCharacter(from: text, for: type, range: range, filterPredicate: filterPredicate)
        case .url:
            return createElements(from: text, for: type, range: range, filterPredicate: filterPredicate)
        case .custom:
            return createElements(from: text, for: type, range: range, minLength: 1, filterPredicate: filterPredicate)
        case .email:
            return createElements(from: text, for: type, range: range, filterPredicate: filterPredicate)
        }
    }

    static func createURLElements(from text: String, range: NSRange, maximumLength: Int?) -> ([ElementTuple], String) {
        do {
            let type = ActiveType.url
            var text = text
            let nsstring = text as NSString
            var elements: [ElementTuple] = []

            let matches = try RegexParser.getElements(from: text, with: type.pattern, range: range)

            for match in matches where match.range.length > 2 {
                let word = nsstring.substring(with: match.range)
                    .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                guard let maxLength = maximumLength, word.count > maxLength else {
                    let range = maximumLength == nil ? match.range : (text as NSString).range(of: word)
                    let element = ActiveElement.create(with: type, text: word)
                    elements.append((range, element, type))
                    continue
                }

                let trimmedWord = word.trim(to: maxLength)
                text = text.replacingOccurrences(of: word, with: trimmedWord)

                let newRange = (text as NSString).range(of: trimmedWord)
                let element = ActiveElement.url(original: word, trimmed: trimmedWord)
                elements.append((newRange, element, type))
            }

            return (elements, text)
        } catch let _ {
            return ([], "")
        }
    }

    private static func createElements(from text: String,
                                       for type: ActiveType,
                                       range: NSRange,
                                       minLength: Int = 2,
                                       filterPredicate: ActiveFilterPredicate?) -> [ElementTuple] {

        let nsstring = text as NSString

        do {
            var elements: [ElementTuple] = []
            let matches = try RegexParser.getElements(from: text, with: type.pattern, range: range)

            for match in matches where match.range.length > minLength {
                let word = nsstring.substring(with: match.range)
                    .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if filterPredicate?(word) ?? true {
                    let element = ActiveElement.create(with: type, text: word)
                    elements.append((match.range, element, type))
                }
            }

            return elements

        } catch let _ {
            let plainPatternString = type.pattern.replacingOccurrences(of: "\\s", with: "").replacingOccurrences(of: "\\b", with: "")
            let range = nsstring.range(of: plainPatternString, options: [.caseInsensitive])

            if filterPredicate?(plainPatternString) ?? true {
                let element = ActiveElement.create(with: type, text: plainPatternString)
                return [(range, element, type)]
            } else {
                return []
            }
        }
    }

    private static func createElementsIgnoringFirstCharacter(from text: String,
                                                             for type: ActiveType,
                                                             range: NSRange,
                                                             filterPredicate: ActiveFilterPredicate?) -> [ElementTuple] {
        do {
            var elements: [ElementTuple] = []
            let nsstring = text as NSString

            let matches = try RegexParser.getElements(from: text, with: type.pattern, range: range)

            for match in matches where match.range.length > 2 {
                let range = NSRange(location: match.range.location + 1, length: match.range.length - 1)
                var word = nsstring.substring(with: range)
                if word.hasPrefix("@") {
                    word.remove(at: word.startIndex)
                }
                else if word.hasPrefix("#") {
                    word.remove(at: word.startIndex)
                }

                if filterPredicate?(word) ?? true {
                    let element = ActiveElement.create(with: type, text: word)
                    elements.append((match.range, element, type))
                }
            }

            return elements
        } catch {
            return []
        }
    }
}
