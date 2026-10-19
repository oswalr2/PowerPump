import SwiftUI

/// Shown at launch when a run or a walk/run program session was still going
/// when the app was closed: it reopens the same screen so the user carries on
/// instead of finding the run gone.
struct ResumedRunView: View {
    @ObservedObject private var run = RunStore.shared

    var body: some View {
        if let context = run.program,
           let program = RunningProgramLibrary.all.first(where: { $0.id == context.programID }),
           let day = program.weeks.first(where: { $0.weekNumber == context.weekNumber })?
               .days.first(where: { $0.dayNumber == context.dayNumber }) {
            ProgramSessionView(program: program, weekNumber: context.weekNumber,
                               day: day, resuming: true)
        } else {
            RunningView()
        }
    }
}
