import Foundation

/// Generates the 4 walking/running programs from compact rules so we don't
/// hand-write 200+ session definitions.
enum RunningProgramLibrary {
    static let all: [RunningProgram] = [
        walkToLoseWeight(),
        runToLoseWeight(),
        paceAcademy(),
        firstFiveK(),
    ]

    static func program(id: String) -> RunningProgram? {
        all.first { $0.id == id }
    }

    // MARK: - Helpers

    private static func mins(_ m: Int) -> Int { m * 60 }
    private static func secs(_ s: Int) -> Int { s }

    private static func interval(_ kind: IntervalKind, _ duration: Int) -> ProgramInterval {
        ProgramInterval(kind: kind, duration: duration)
    }

    /// Builds a day: warmup walk + body + cooldown walk.
    private static func day(_ n: Int, warmup: Int, body: [ProgramInterval], cooldown: Int) -> ProgramDay {
        var iv: [ProgramInterval] = []
        iv.append(interval(.warmup, warmup))
        iv.append(contentsOf: body)
        iv.append(interval(.cooldown, cooldown))
        return ProgramDay(dayNumber: n, intervals: iv)
    }

    /// Repeat a block N times.
    private static func repeated(_ blocks: [ProgramInterval], times: Int) -> [ProgramInterval] {
        Array(repeating: blocks, count: times).flatMap { $0 }
    }

    // MARK: - Program 1: Walk to lose weight (20 weeks)

    private static func walkToLoseWeight() -> RunningProgram {
        var weeks: [ProgramWeek] = []

        // Phase 1: Weeks 1-2 — adapt to active life. Steady walking, growing duration.
        for w in 1...2 {
            let baseSec = w == 1 ? mins(17) : mins(19)
            let days = (1...3).map { d -> ProgramDay in
                let extra = (d - 1) * mins(2)
                return day(d, warmup: mins(3),
                           body: [interval(.walk, baseSec + extra)],
                           cooldown: mins(3))
            }
            weeks.append(ProgramWeek(weekNumber: w, days: days))
        }

        // Phase 2: Weeks 3-14 — calorie burner. Brisk-walk intervals, growing volume.
        for w in 3...14 {
            // walk/brisk-walk pattern: more brisk walking each week.
            let cycles = min(4 + (w - 3) / 2, 9)
            let walkSec = max(60 - (w - 3) * 3, 30)
            let briskSec = min(60 + (w - 3) * 6, 150)
            let days = (1...3).map { d -> ProgramDay in
                let bonus = (d - 1) * 30
                return day(d, warmup: mins(5),
                           body: repeated([interval(.walk, walkSec + bonus),
                                           interval(.briskWalk, briskSec + bonus)],
                                          times: cycles),
                           cooldown: mins(5))
            }
            weeks.append(ProgramWeek(weekNumber: w, days: days))
        }

        // Phase 3: Weeks 15-20 — burn faster. Add jog bursts on top of brisk walks.
        for w in 15...20 {
            let cycles = 5 + (w - 15)
            let briskSec = 90
            let jogSec = 30 + (w - 15) * 10
            let days = (1...3).map { d -> ProgramDay in
                let bonus = (d - 1) * 20
                return day(d, warmup: mins(5),
                           body: repeated([interval(.briskWalk, briskSec),
                                           interval(.jog, jogSec + bonus)],
                                          times: cycles),
                           cooldown: mins(5))
            }
            weeks.append(ProgramWeek(weekNumber: w, days: days))
        }

        let phases: [ProgramPhase] = [
            ProgramPhase(weekStart: 1, weekEnd: 2,
                         titleKey: "program.walk.phase1.title",
                         bodyKey:  "program.walk.phase1.body",
                         icon: "heart.fill"),
            ProgramPhase(weekStart: 3, weekEnd: 14,
                         titleKey: "program.walk.phase2.title",
                         bodyKey:  "program.walk.phase2.body",
                         icon: "flame.fill"),
            ProgramPhase(weekStart: 15, weekEnd: 20,
                         titleKey: "program.walk.phase3.title",
                         bodyKey:  "program.walk.phase3.body",
                         icon: "target"),
        ]

        return RunningProgram(
            id: "walk_to_lose_weight",
            nameKey: "program.walk.name",
            subtitleKey: "program.walk.subtitle",
            headerImageName: "program_walk_lose_weight",
            weeks: weeks,
            phases: phases,
            goalKeys: [
                "program.walk.goal1",
                "program.walk.goal2",
                "program.walk.goal3",
            ],
            badgeKeys: [
                "badge.lowImpact",
                "badge.scienceBacked",
                "badge.beginnerFriendly",
                "badge.gradualDuration",
            ],
            endurance: .easy,
            speed: .veryEasy
        )
    }

    // MARK: - Program 2: Run to lose weight (12 weeks)

    private static func runToLoseWeight() -> RunningProgram {
        var weeks: [ProgramWeek] = []
        for w in 1...12 {
            // Start with walk/jog 1:1, ramp toward jog/run 1:2 by week 12.
            let cycles = min(6 + (w - 1) / 2, 12)
            let walkSec = max(60 - (w - 1) * 3, 30)
            let jogSec = min(60 + (w - 1) * 8, 180)
            let runSec = w >= 6 ? min((w - 5) * 30, 120) : 0
            let days = (1...3).map { d -> ProgramDay in
                let bonus = (d - 1) * 15
                var body: [ProgramInterval] = []
                for _ in 0..<cycles {
                    body.append(interval(.briskWalk, walkSec))
                    body.append(interval(.jog, jogSec + bonus))
                    if runSec > 0 { body.append(interval(.run, runSec)) }
                }
                return day(d, warmup: mins(5), body: body, cooldown: mins(5))
            }
            weeks.append(ProgramWeek(weekNumber: w, days: days))
        }

        let phases: [ProgramPhase] = [
            ProgramPhase(weekStart: 1, weekEnd: 4,
                         titleKey: "program.run.phase1.title",
                         bodyKey:  "program.run.phase1.body",
                         icon: "heart.fill"),
            ProgramPhase(weekStart: 5, weekEnd: 9,
                         titleKey: "program.run.phase2.title",
                         bodyKey:  "program.run.phase2.body",
                         icon: "flame.fill"),
            ProgramPhase(weekStart: 10, weekEnd: 12,
                         titleKey: "program.run.phase3.title",
                         bodyKey:  "program.run.phase3.body",
                         icon: "bolt.fill"),
        ]

        return RunningProgram(
            id: "run_to_lose_weight",
            nameKey: "program.run.name",
            subtitleKey: "program.run.subtitle",
            headerImageName: "program_run_lose_weight",
            weeks: weeks,
            phases: phases,
            goalKeys: [
                "program.run.goal1",
                "program.run.goal2",
                "program.run.goal3",
            ],
            badgeKeys: [
                "badge.fatBurning",
                "badge.scienceBacked",
                "badge.progressive",
            ],
            endurance: .medium,
            speed: .easy
        )
    }

    // MARK: - Program 3: Pace academy (8 weeks)

    private static func paceAcademy() -> RunningProgram {
        var weeks: [ProgramWeek] = []
        for w in 1...8 {
            let cycles = 4 + (w / 2)
            let jogSec = max(120 - (w - 1) * 5, 60)
            let fastSec = min(60 + (w - 1) * 10, 150)
            let days = (1...3).map { d -> ProgramDay in
                let bonus = (d - 1) * 15
                var body: [ProgramInterval] = []
                for _ in 0..<cycles {
                    body.append(interval(.jog, jogSec + bonus))
                    body.append(interval(.fastRun, fastSec))
                }
                // Add a sprint finisher in later weeks.
                if w >= 5 {
                    body.append(interval(.sprint, 20 + (w - 5) * 5))
                    body.append(interval(.jog, 60))
                }
                return day(d, warmup: mins(6), body: body, cooldown: mins(5))
            }
            weeks.append(ProgramWeek(weekNumber: w, days: days))
        }

        let phases: [ProgramPhase] = [
            ProgramPhase(weekStart: 1, weekEnd: 3,
                         titleKey: "program.pace.phase1.title",
                         bodyKey:  "program.pace.phase1.body",
                         icon: "speedometer"),
            ProgramPhase(weekStart: 4, weekEnd: 6,
                         titleKey: "program.pace.phase2.title",
                         bodyKey:  "program.pace.phase2.body",
                         icon: "stopwatch"),
            ProgramPhase(weekStart: 7, weekEnd: 8,
                         titleKey: "program.pace.phase3.title",
                         bodyKey:  "program.pace.phase3.body",
                         icon: "bolt.fill"),
        ]

        return RunningProgram(
            id: "pace_academy",
            nameKey: "program.pace.name",
            subtitleKey: "program.pace.subtitle",
            headerImageName: "program_pace_academy",
            weeks: weeks,
            phases: phases,
            goalKeys: [
                "program.pace.goal1",
                "program.pace.goal2",
                "program.pace.goal3",
            ],
            badgeKeys: [
                "badge.tempoTraining",
                "badge.intervalScience",
                "badge.intermediate",
            ],
            endurance: .medium,
            speed: .hard
        )
    }

    // MARK: - Program 4: My first 5K (12 weeks) — Couch-to-5K style

    private static func firstFiveK() -> RunningProgram {
        var weeks: [ProgramWeek] = []
        for w in 1...12 {
            // Walk-run pattern that progressively swaps in more running until
            // the runner can cover 5K (~30 min) non-stop.
            let days: [ProgramDay] = (1...3).map { d -> ProgramDay in
                var body: [ProgramInterval] = []
                switch w {
                case 1:
                    body = repeated([interval(.briskWalk, 90), interval(.jog, 60)], times: 8)
                case 2:
                    body = repeated([interval(.briskWalk, 90), interval(.jog, 90)], times: 6)
                case 3:
                    body = repeated([interval(.briskWalk, 90), interval(.jog, 180)], times: 4)
                case 4:
                    body = [interval(.jog, 180), interval(.briskWalk, 90),
                            interval(.jog, 300), interval(.briskWalk, 150),
                            interval(.jog, 180), interval(.briskWalk, 90),
                            interval(.jog, 300)]
                case 5:
                    body = [interval(.jog, 300), interval(.briskWalk, 180),
                            interval(.jog, 480), interval(.briskWalk, 300),
                            interval(.jog, 300)]
                case 6:
                    body = [interval(.jog, 480), interval(.briskWalk, 300),
                            interval(.jog, 480)]
                case 7:
                    body = [interval(.jog, 1500)]   // 25 min jog
                case 8:
                    body = [interval(.jog, 1680)]   // 28 min
                case 9:
                    body = [interval(.run, 1500)]   // 25 min run
                case 10:
                    body = [interval(.run, 1680)]   // 28 min run
                case 11:
                    body = [interval(.run, 1800)]   // 30 min run
                case 12:
                    body = [interval(.run, 1800), interval(.fastRun, 120)]
                default:
                    body = [interval(.jog, 600)]
                }
                let bonus = (d - 1) * 60
                if !body.isEmpty {
                    var copy = body
                    if let last = copy.last {
                        let extended = ProgramInterval(kind: last.kind, duration: last.duration + bonus)
                        copy[copy.count - 1] = extended
                    }
                    body = copy
                }
                return day(d, warmup: mins(5), body: body, cooldown: mins(5))
            }
            weeks.append(ProgramWeek(weekNumber: w, days: days))
        }

        let phases: [ProgramPhase] = [
            ProgramPhase(weekStart: 1, weekEnd: 3,
                         titleKey: "program.5k.phase1.title",
                         bodyKey:  "program.5k.phase1.body",
                         icon: "figure.walk"),
            ProgramPhase(weekStart: 4, weekEnd: 8,
                         titleKey: "program.5k.phase2.title",
                         bodyKey:  "program.5k.phase2.body",
                         icon: "figure.run"),
            ProgramPhase(weekStart: 9, weekEnd: 12,
                         titleKey: "program.5k.phase3.title",
                         bodyKey:  "program.5k.phase3.body",
                         icon: "flag.checkered"),
        ]

        return RunningProgram(
            id: "first_5k",
            nameKey: "program.5k.name",
            subtitleKey: "program.5k.subtitle",
            headerImageName: "program_first_5k",
            weeks: weeks,
            phases: phases,
            goalKeys: [
                "program.5k.goal1",
                "program.5k.goal2",
                "program.5k.goal3",
            ],
            badgeKeys: [
                "badge.beginnerFriendly",
                "badge.scienceBacked",
                "badge.couchTo5k",
            ],
            endurance: .medium,
            speed: .medium
        )
    }
}
