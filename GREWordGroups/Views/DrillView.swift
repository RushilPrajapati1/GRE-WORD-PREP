import SwiftUI

struct DrillView: View {
    @Bindable var viewModel: DrillViewModel

    var body: some View {
        NavigationStack {
            Group {
                if let question = viewModel.question {
                    ScrollView {
                        VStack(spacing: 20) {
                            prompt(for: question)
                            options(for: question)
                            feedback
                        }
                        .padding()
                    }
                    .safeAreaInset(edge: .bottom) { actionButton }
                } else {
                    ContentUnavailableView("No Question Available", systemImage: "text.book.closed",
                                           description: Text("Word groups are still loading."))
                }
            }
            .navigationTitle("Drill")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { focusMenu }
                ToolbarItem(placement: .topBarTrailing) {
                    Label("\(viewModel.streak)", systemImage: "flame.fill")
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(.orange)
                        .accessibilityLabel("Streak \(viewModel.streak)")
                }
            }
        }
    }

    private func prompt(for question: DrillQuestion) -> some View {
        VStack(spacing: 8) {
            Text("Pick the \(DrillEngine.correctCount) words that mean")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(question.group.name)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(question.group.description)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func options(for question: DrillQuestion) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(question.options, id: \.self) { word in
                OptionButton(word: word, state: viewModel.state(for: word)) {
                    viewModel.toggle(word)
                }
            }
        }
    }

    @ViewBuilder
    private var feedback: some View {
        if let outcome = viewModel.outcome {
            Label(outcome.isCorrect ? "Correct!" : "Not quite. The answers are highlighted in green.",
                  systemImage: outcome.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.headline)
                .foregroundStyle(outcome.isCorrect ? .green : .red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var actionButton: some View {
        Group {
            if viewModel.outcome == nil {
                Button("Check Answer", action: viewModel.submit)
                    .disabled(!viewModel.canSubmit)
            } else {
                Button("Next Question", action: viewModel.nextQuestion)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
        .padding()
        .background(.bar)
    }

    private var focusMenu: some View {
        Menu {
            Picker("Groups", selection: Binding(get: { viewModel.focusGroupID },
                                                set: { viewModel.focus(on: $0) })) {
                Text("All Groups").tag(Int?.none)
                ForEach(viewModel.groups) { group in
                    Text(group.name).tag(Int?.some(group.id))
                }
            }
        } label: {
            Label(viewModel.focusGroup?.name ?? "All Groups", systemImage: "line.3.horizontal.decrease.circle")
                .labelStyle(.iconOnly)
        }
    }
}

private struct OptionButton: View {
    let word: String
    let state: DrillViewModel.OptionState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(word)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                if let icon {
                    Image(systemName: icon)
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(foreground)
            .background(background, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(border, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .opacity(state == .dimmed ? 0.5 : 1)
        .accessibilityAddTraits(state == .selected ? .isSelected : [])
    }

    private var icon: String? {
        switch state {
        case .correct: "checkmark.circle.fill"
        case .missed: "circle.dashed"
        case .wrong: "xmark.circle.fill"
        case .idle, .selected, .dimmed: nil
        }
    }

    private var foreground: Color {
        switch state {
        case .selected: .white
        case .correct, .missed: .green
        case .wrong: .red
        case .idle, .dimmed: .primary
        }
    }

    private var background: Color {
        switch state {
        case .selected: .accentColor
        case .correct, .missed: .green.opacity(0.15)
        case .wrong: .red.opacity(0.15)
        case .idle, .dimmed: Color(.secondarySystemBackground)
        }
    }

    private var border: Color {
        switch state {
        case .correct: .green
        case .missed: .green.opacity(0.6)
        case .wrong: .red
        case .idle, .selected, .dimmed: .clear
        }
    }
}

#Preview {
    DrillView(viewModel: PreviewData.drillViewModel())
        .modelContainer(PreviewData.container)
}
