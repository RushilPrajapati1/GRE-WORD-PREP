import SwiftUI

struct DrillView: View {
    @Bindable var viewModel: DrillViewModel

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)

            if let question = viewModel.question {
                ScrollView {
                    VStack(spacing: 16) {
                        sessionProgress
                        prompt(for: question)
                        if viewModel.outcome != nil {
                            resultBanner
                        }
                        options(for: question)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) { actionBar }
            } else {
                Spacer()
                ContentUnavailableView("No Question Available", systemImage: "text.book.closed",
                                       description: Text("Word groups are still loading."))
                Spacer()
            }
        }
        .background(Theme.background)
        .animation(.snappy(duration: 0.2), value: viewModel.outcome)
    }

    // MARK: Header

    private var topBar: some View {
        HStack {
            Menu {
                Picker("Groups", selection: Binding(get: { viewModel.focusGroupID },
                                                    set: { viewModel.focus(on: $0) })) {
                    Text("All groups").tag(Int?.none)
                    ForEach(viewModel.groups) { group in
                        Text(group.name).tag(Int?.some(group.id))
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease")
                    Text(viewModel.focusGroup?.name ?? "All groups")
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(Theme.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
            }
            .accessibilityLabel("Choose groups to drill")
            .accessibilityValue(viewModel.focusGroup?.name ?? "All groups")

            Spacer(minLength: 12)

            Label("\(viewModel.streak)", systemImage: "flame")
                .labelStyle(CompactLabelStyle())
                .font(.system(size: 16, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Theme.streak)
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(Theme.streakSoft, in: Capsule())
                .accessibilityLabel("Streak \(viewModel.streak)")
        }
    }

    private var sessionProgress: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Question \(viewModel.questionNumber) of \(viewModel.session.length)")
                Spacer()
                Text(viewModel.progressHint)
            }
            .font(.system(size: 13))
            .foregroundStyle(Theme.secondaryInk)

            HStack(spacing: 3) {
                ForEach(0..<viewModel.session.length, id: \.self) { index in
                    Capsule()
                        .fill(color(for: viewModel.segment(at: index)))
                        .frame(height: 4)
                }
            }
            .accessibilityHidden(true)
        }
    }

    private func color(for segment: DrillViewModel.SegmentState) -> Color {
        switch segment {
        case .correct: Theme.success
        case .wrong: Theme.danger
        case .current: Theme.accent
        case .upcoming: Theme.fill
        }
    }

    // MARK: Question

    private func prompt(for question: DrillQuestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pick the \(DrillEngine.correctCount) words that mean").eyebrow()
            Text(question.group.name)
                .font(Theme.serif(30, .medium, relativeTo: .title))
            Text(question.group.description)
                .font(.system(size: 15))
                .lineSpacing(2)
                .foregroundStyle(Theme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .card(radius: 22)
    }

    private var resultBanner: some View {
        let isCorrect = viewModel.outcome?.isCorrect == true
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: isCorrect ? "checkmark" : "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isCorrect ? Theme.success : Theme.danger)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.resultTitle)
                    .font(.system(size: 16, weight: .bold))
                Text(viewModel.resultMessage)
                    .font(.system(size: 14))
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(isCorrect ? Theme.successInk : Theme.dangerInk)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(isCorrect ? Theme.successSoft : Theme.dangerSoft,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func options(for question: DrillQuestion) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(question.options, id: \.self) { word in
                OptionButton(word: word,
                             caption: viewModel.caption(for: word),
                             state: viewModel.state(for: word)) {
                    viewModel.toggle(word)
                }
            }
        }
    }

    // MARK: Action

    private var actionBar: some View {
        let enabled = viewModel.outcome != nil || viewModel.canSubmit
        return Button {
            if viewModel.outcome == nil {
                viewModel.submit()
            } else {
                viewModel.nextQuestion()
            }
        } label: {
            Text(viewModel.actionTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(enabled ? .white : Theme.disabledInk)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(enabled ? Theme.accent : Theme.disabled,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, FloatingTabBar.clearance - 12)
        .background {
            Theme.background
                .overlay(alignment: .top) { Rectangle().fill(Theme.border).frame(height: 1) }
                .ignoresSafeArea()
        }
    }
}

private struct OptionButton: View {
    let word: String
    let caption: String?
    let state: DrillViewModel.OptionState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(word)
                        .font(Theme.serif(20, .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(iconColor)
                    }
                }
                .foregroundStyle(foreground)
                if let caption {
                    Text(caption)
                        .font(.system(size: 12))
                        .lineSpacing(1)
                        .foregroundStyle(captionColor)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(background, in: shape)
            .overlay(shape.strokeBorder(border, style: StrokeStyle(lineWidth: 2, dash: state == .missed ? [5, 4] : [])))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(state == .selected ? .isSelected : [])
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
    }

    private var icon: String? {
        switch state {
        case .selected, .correct, .missed: "checkmark"
        case .wrong: "xmark"
        case .idle, .trap: nil
        }
    }

    private var iconColor: Color {
        switch state {
        case .selected: Theme.accent
        case .wrong: Theme.danger
        default: Theme.success
        }
    }

    private var foreground: Color {
        switch state {
        case .idle: Theme.ink
        case .selected: Theme.accentInk
        case .correct, .missed: Theme.successInk
        case .wrong: Theme.dangerInk
        case .trap: Theme.secondaryInk
        }
    }

    private var captionColor: Color {
        switch state {
        case .correct, .missed: Theme.successInk
        case .wrong: Theme.dangerInk
        default: Theme.secondaryInk
        }
    }

    private var background: Color {
        switch state {
        case .selected: Theme.accentSoft
        case .correct: Theme.successSoft
        case .wrong: Theme.dangerSoft
        case .idle, .missed, .trap: Theme.surface
        }
    }

    private var border: Color {
        switch state {
        case .selected: Theme.accent
        case .correct, .missed: Theme.success
        case .wrong: Theme.danger
        case .idle, .trap: Theme.border
        }
    }
}

#Preview {
    DrillView(viewModel: PreviewData.drillViewModel())
        .modelContainer(PreviewData.container)
}
