import SwiftData
import SwiftUI

@main
struct GREWordGroupsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WordProgress.self, Stats.self])
    }
}
