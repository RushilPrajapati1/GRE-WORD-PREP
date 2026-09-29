import Foundation

/// A set of GRE words that share a meaning, as listed in `gre_groups.json`.
struct WordGroup: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let name: String
    let description: String
    let words: [String]
}
