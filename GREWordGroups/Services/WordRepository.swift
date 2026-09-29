import Foundation

enum WordRepository {
    enum LoadError: LocalizedError {
        case missingResource

        var errorDescription: String? {
            "gre_groups.json is missing from the app bundle."
        }
    }

    static func loadBundledGroups(from bundle: Bundle = .main) throws -> [WordGroup] {
        guard let url = bundle.url(forResource: "gre_groups", withExtension: "json") else {
            throw LoadError.missingResource
        }
        return try decode(Data(contentsOf: url))
    }

    static func decode(_ data: Data) throws -> [WordGroup] {
        try JSONDecoder().decode([WordGroup].self, from: data)
    }
}
