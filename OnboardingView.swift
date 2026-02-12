import SwiftUI

struct OnboardingView: View {
    @State private var prompt = ""
    @StateObject private var vm = RoadmapViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("Расскажи, чего хочешь достичь")
                .font(.title3).bold()
            TextField("Например: хочу за год уехать в Европу, подтянуть английский и программирование",
                      text: $prompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(5, reservesSpace: true)

            Button {
                Task { await vm.generate(from: prompt) }
            } label: {
                Label("Собрать карту", systemImage: "chart.xyaxis.line")
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isLoading || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if vm.isLoading { ProgressView() }
            if let err = vm.errorText {
                Text(err).foregroundStyle(.red)
            }

            NavigationLink("Перейти к карте") {
                RoadmapScreen(vm: vm)
            }
            .disabled(vm.roadmap.goals.isEmpty)
        }
        .padding()
    }
}
