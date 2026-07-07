import SwiftUI

/// Catalog of structured walk/run programs. Tap a card to open the detail.
struct RunningProgramsView: View {
    @Environment(\.dismiss) private var dismiss

    private let programs = RunningProgramLibrary.all

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        ForEach(programs) { program in
                            NavigationLink(destination: RunningProgramDetailView(program: program)) {
                                ProgramCatalogCard(program: program)
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(verbatim: PT("Walk & Run Programs"))
                        .font(SBFont.heading(16))
                        .foregroundColor(.sbTextPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.sbTextSecondary)
                            .font(.system(size: 20))
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: PT("Pick a program and start today"))
                .font(SBFont.heading(20))
                .foregroundColor(.sbTextPrimary)
            Text(verbatim: PT("Voice-guided sessions adapt walks, jogs, and runs over weeks so you build up safely."))
                .font(SBFont.caption())
                .foregroundColor(.sbTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Card

private struct ProgramCatalogCard: View {
    @ObservedObject private var progress = RunProgramStore.shared
    let program: RunningProgram

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(format: NSLocalizedString("%lld-week program", comment: ""), program.totalWeeks))
                    .font(SBFont.label(10))
                    .foregroundColor(.sbAccent)
                    .textCase(.uppercase)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.sbAccent.opacity(0.15))
                    .cornerRadius(6)
                Spacer()
                Text("\(Int(progress.progress(in: program) * 100))%")
                    .font(SBFont.label(11))
                    .foregroundColor(.sbTextSecondary)
            }

            Text(verbatim: PT(program.nameKey))
                .font(SBFont.display(22))
                .foregroundColor(.sbTextPrimary)
                .multilineTextAlignment(.leading)

            Text(verbatim: PT(program.subtitleKey))
                .font(SBFont.caption())
                .foregroundColor(.sbTextSecondary)

            HStack(spacing: 16) {
                LevelDots(label: "Endurance", level: program.endurance)
                LevelDots(label: "Speed",     level: program.speed)
            }
            .padding(.top, 2)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sbSurface)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.sbBorder, lineWidth: 1))
    }
}

struct LevelDots: View {
    let label: String
    let level: ProgramLevel

    var body: some View {
        HStack(spacing: 6) {
            Text(verbatim: PT(label))
                .font(SBFont.label(10))
                .foregroundColor(.sbTextSecondary)
                .textCase(.uppercase)
            HStack(spacing: 3) {
                ForEach(1...4, id: \.self) { i in
                    Capsule()
                        .fill(i <= level.rawValue ? Color.sbAccent : Color.sbSurfaceRaised)
                        .frame(width: 14, height: 5)
                }
            }
        }
    }
}
