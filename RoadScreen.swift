import SwiftUI

struct RoadmapScreen: View {
    @ObservedObject var vm: RoadmapViewModel

    var body: some View {
        let nodes = GraphLayout.makeNodes(from: vm.roadmap)
        GraphView(nodes: nodes)
            .toolbar {
                Button("Пересобрать план") { vm.recomputeSprint() }
            }
    }
}
