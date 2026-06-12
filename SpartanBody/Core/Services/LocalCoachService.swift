import Foundation

// Generates a personalised fitness plan locally — no API key, no internet needed.
struct LocalCoachService {

    static func generatePlan(
        goal: FitnessGoal,
        activityLevel: ActivityLevel,
        weightKg: Double,
        heightCm: Double,
        bmi: Double,
        bmiCategory: String,
        dailyCalories: Int,
        dailyProtein: Int,
        extraContext: String
    ) -> FitnessPlan {
        var plan = FitnessPlan(
            analysis:       analysis(goal: goal, bmi: bmi, bmiCategory: bmiCategory, weightKg: weightKg,
                                     activityLevel: activityLevel, extraContext: extraContext),
            weeklySchedule: applyVariety(schedule(goal: goal, activityLevel: activityLevel)),
            nutritionPlan:  nutrition(goal: goal, dailyCalories: dailyCalories, dailyProtein: dailyProtein),
            tips:           tips(goal: goal).shuffled(),
            motivation:     motivation(goal: goal),
            weeklyMeals:    weeklyMeals(goal: goal)
        )
        if !extraContext.trimmingCharacters(in: .whitespaces).isEmpty {
            plan = applyContext(plan, context: extraContext.lowercased())
        }
        return plan
    }

    // MARK: - Language helper

    private static var lang: String { LanguageManager.shared.selectedCode }

    // MARK: - Analysis

    private static func analysis(goal: FitnessGoal, bmi: Double, bmiCategory: String,
                                 weightKg: Double, activityLevel: ActivityLevel,
                                 extraContext: String) -> String {
        let base: String
        switch goal {
        case .loseWeight:
            let fmt = NSLocalizedString("coach.analysis.loseWeight", comment: "")
            base = String(format: fmt, bmi, bmiCategory)
        case .gainMuscle:
            let fmt = NSLocalizedString("coach.analysis.gainMuscle", comment: "")
            base = String(format: fmt, Int(weightKg))
        case .stayFit:
            base = NSLocalizedString("coach.analysis.stayFit", comment: "")
        }
        let suffix = activitySuffix(activityLevel)
        let contextNote = contextAnalysisNote(extraContext.lowercased())
        return [base, suffix, contextNote].filter { !$0.isEmpty }.joined(separator: " ")
    }

    private static func activitySuffix(_ level: ActivityLevel) -> String {
        switch (level, lang) {
        case (.sedentary, "es"): return "Este plan está adaptado para comenzar desde cero con ejercicios seguros y progresivos."
        case (.light,     "es"): return "El plan incluye una progresión gradual adaptada a tu nivel de actividad."
        case (.active,    "es"): return "Dado tu nivel activo, el plan es de alta intensidad con mayor volumen."
        case (.sedentary, "it"): return "Questo piano è pensato per iniziare da zero con esercizi sicuri e progressivi."
        case (.light,     "it"): return "Il piano include una progressione graduale adatta al tuo livello di attività."
        case (.active,    "it"): return "Data la tua elevata attività, il piano è ad alta intensità con maggiore volume."
        case (.sedentary, "pt-BR"): return "Este plano foi adaptado para começar do zero com exercícios seguros e progressivos."
        case (.light,     "pt-BR"): return "O plano inclui uma progressão gradual adaptada ao seu nível de atividade."
        case (.active,    "pt-BR"): return "Dado seu alto nível de atividade, o plano é de alta intensidade com maior volume."
        case (.sedentary, "fr"): return "Ce plan est adapté pour commencer de zéro avec des exercices sûrs et progressifs."
        case (.light,     "fr"): return "Le plan inclut une progression graduelle adaptée à ton niveau d'activité."
        case (.active,    "fr"): return "Vu ton niveau actif, le plan est haute intensité avec plus de volume."
        case (.sedentary, _): return "This plan is designed to start from scratch with safe, progressive exercises."
        case (.light,     _): return "The plan includes gradual progression adapted to your activity level."
        case (.active,    _): return "Given your active lifestyle, this plan is high intensity with greater volume."
        default: return ""
        }
    }

    private static func contextAnalysisNote(_ ctx: String) -> String {
        var notes: [String] = []
        if hasKneeKeyword(ctx)  { notes.append(kneeNote()) }
        if hasHomeKeyword(ctx)  { notes.append(homeNote()) }
        if hasBackKeyword(ctx)  { notes.append(backNote()) }
        return notes.joined(separator: " ")
    }

    private static func kneeNote() -> String {
        switch lang {
        case "es":    return "Se han sustituido ejercicios de alto impacto para proteger tus rodillas."
        case "it":    return "Gli esercizi ad alto impatto sono stati sostituiti per proteggere le ginocchia."
        case "pt-BR": return "Exercícios de alto impacto foram substituídos para proteger seus joelhos."
        case "fr":    return "Les exercices à fort impact ont été remplacés pour protéger tes genoux."
        default:      return "High-impact exercises have been replaced to protect your knees."
        }
    }

    private static func homeNote() -> String {
        switch lang {
        case "es":    return "El plan usa ejercicios con peso corporal y mancuernas para hacerlo desde casa."
        case "it":    return "Il piano usa esercizi a corpo libero e manubri per allenarsi a casa."
        case "pt-BR": return "O plano usa exercícios com peso corporal e halteres para treinar em casa."
        case "fr":    return "Le plan utilise des exercices au poids du corps et haltères pour s'entraîner à la maison."
        default:      return "The plan uses bodyweight and dumbbell exercises for home training."
        }
    }

    private static func backNote() -> String {
        switch lang {
        case "es":    return "Se han evitado movimientos de carga espinal pesada para cuidar tu espalda."
        case "it":    return "I movimenti con carico spinale pesante sono stati evitati per proteggere la schiena."
        case "pt-BR": return "Movimentos com carga espinal pesada foram evitados para proteger suas costas."
        case "fr":    return "Les mouvements avec charge spinale lourde ont été évités pour protéger ton dos."
        default:      return "Heavy spinal loading movements have been avoided to protect your back."
        }
    }

    // MARK: - Day names

    private static var days: [String] {
        switch lang {
        case "es":    return ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
        case "it":    return ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"]
        case "pt-BR": return ["Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado", "Domingo"]
        case "fr":    return ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
        default:      return ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        }
    }

    // MARK: - Weekly schedule (varies by activity level)

    private static func schedule(goal: FitnessGoal, activityLevel: ActivityLevel) -> [DayPlan] {
        let d = days
        let isBeginner = activityLevel == .sedentary || activityLevel == .light
        let isAdvanced = activityLevel == .active

        switch goal {
        case .loseWeight:
            return isBeginner ? loseWeightBeginner(d) : loseWeightSchedule(d)
        case .gainMuscle:
            if isBeginner { return gainMuscleBeginner(d) }
            if isAdvanced { return gainMuscleAdvanced(d) }
            return gainMuscleSchedule(d)
        case .stayFit:
            return isBeginner ? stayFitBeginner(d) : stayFitSchedule(d)
        }
    }

    // MARK: - Lose Weight schedules

    private static func loseWeightSchedule(_ d: [String]) -> [DayPlan] {
        let f = loseWeightFocus()
        return [
            DayPlan(day: d[0], type: "workout", focus: f[0],
                    exercises: ["Jump Rope 3×3 min", "Squat 4×15", "Push-ups 3×15", "Mountain Climbers 3×30 sec", "Plank 3×45 sec"]),
            DayPlan(day: d[1], type: "rest",    focus: f[1], exercises: activeRecoveryExercises()),
            DayPlan(day: d[2], type: "workout", focus: f[2],
                    exercises: ["Jump Rope 2×3 min", "Push-ups 4×12", "Dumbbell Row 3×12", "Lateral Raise 3×15", "Crunch 3×20", "Leg Raise 3×15"]),
            DayPlan(day: d[3], type: "workout", focus: f[3],
                    exercises: ["Mountain Climbers 4×30 sec", "Russian Twist 3×20", "Crunch 3×20", "Leg Raise 3×15", "Plank 3×60 sec", "Jump Rope 2×3 min"]),
            DayPlan(day: d[4], type: "workout", focus: f[4],
                    exercises: ["Squat 4×12", "Walking Lunge 3×12", "Romanian Deadlift 3×12", "Glute Bridge 3×20", "Box Jump 3×10"]),
            DayPlan(day: d[5], type: "rest",    focus: f[1], exercises: lightRecoveryExercises()),
            DayPlan(day: d[6], type: "rest",    focus: f[5], exercises: fullRestExercises()),
        ]
    }

    private static func loseWeightBeginner(_ d: [String]) -> [DayPlan] {
        let f = loseWeightFocus()
        return [
            DayPlan(day: d[0], type: "workout", focus: f[0],
                    exercises: ["March in Place 3×3 min", "Wall Squat 3×12", "Knee Push-ups 3×10", "Plank 3×20 sec"]),
            DayPlan(day: d[1], type: "rest",    focus: f[1], exercises: activeRecoveryExercises()),
            DayPlan(day: d[2], type: "rest",    focus: f[1], exercises: lightRecoveryExercises()),
            DayPlan(day: d[3], type: "workout", focus: f[2],
                    exercises: ["March in Place 2×3 min", "Knee Push-ups 3×10", "Dumbbell Row 3×10", "Crunch 3×15", "Glute Bridge 3×15"]),
            DayPlan(day: d[4], type: "rest",    focus: f[1], exercises: lightRecoveryExercises()),
            DayPlan(day: d[5], type: "workout", focus: f[4],
                    exercises: ["Wall Squat 3×12", "Step-up 3×10 each leg", "Glute Bridge 3×15", "Plank 3×25 sec"]),
            DayPlan(day: d[6], type: "rest",    focus: f[5], exercises: fullRestExercises()),
        ]
    }

    // MARK: - Gain Muscle schedules

    private static func gainMuscleSchedule(_ d: [String]) -> [DayPlan] {
        let f = gainMuscleFocus()
        return [
            DayPlan(day: d[0], type: "workout", focus: f[0],
                    exercises: ["Bench Press 4×8", "Incline Dumbbell Press 3×10", "Cable Fly 3×12", "Push-ups 3×15", "Skull Crusher 3×10", "Tricep Dip 3×12"]),
            DayPlan(day: d[1], type: "workout", focus: f[1],
                    exercises: ["Pull-ups 4×8", "Lat Pulldown 3×10", "Barbell Row 4×8", "Dumbbell Row 3×10", "Barbell Curl 3×10", "Hammer Curl 3×12"]),
            DayPlan(day: d[2], type: "rest",    focus: f[2], exercises: restAndRecoveryExercises()),
            DayPlan(day: d[3], type: "workout", focus: f[3],
                    exercises: ["Overhead Press 4×8", "Lateral Raise 4×15", "Pike Push-up 3×12", "Plank 4×60 sec", "Russian Twist 3×20", "Leg Raise 3×15"]),
            DayPlan(day: d[4], type: "workout", focus: f[4],
                    exercises: ["Squat 5×5", "Romanian Deadlift 4×8", "Goblet Squat 3×12", "Walking Lunge 3×12", "Hip Thrust 4×12", "Calf Raise 4×20"]),
            DayPlan(day: d[5], type: "workout", focus: f[5],
                    exercises: ["Deadlift 4×5", "Clean & Press 3×5", "Box Jump 4×8", "Push-ups 3×20", "Pull-ups 3×6", "Plank 3×60 sec"]),
            DayPlan(day: d[6], type: "rest",    focus: f[6], exercises: fullRestExercises()),
        ]
    }

    private static func gainMuscleBeginner(_ d: [String]) -> [DayPlan] {
        let f = gainMuscleFocus()
        return [
            DayPlan(day: d[0], type: "workout", focus: f[0],
                    exercises: ["Push-ups 3×8", "Dumbbell Press 3×10", "Tricep Dip (assisted) 3×10", "Plank 3×20 sec"]),
            DayPlan(day: d[1], type: "rest",    focus: f[2], exercises: lightRestExercises()),
            DayPlan(day: d[2], type: "workout", focus: f[1],
                    exercises: ["Resistance Band Row 3×12", "Dumbbell Curl 3×12", "Hammer Curl 3×12", "Dead Hang 3×20 sec"]),
            DayPlan(day: d[3], type: "rest",    focus: f[2], exercises: lightRecoveryExercises()),
            DayPlan(day: d[4], type: "workout", focus: f[4],
                    exercises: ["Goblet Squat 3×10", "Hip Thrust 3×12", "Glute Bridge 3×15", "Calf Raise 3×15"]),
            DayPlan(day: d[5], type: "rest",    focus: f[2], exercises: restAndRecoveryExercises()),
            DayPlan(day: d[6], type: "rest",    focus: f[6], exercises: fullRestExercises()),
        ]
    }

    private static func gainMuscleAdvanced(_ d: [String]) -> [DayPlan] {
        let f = gainMuscleFocus()
        return [
            DayPlan(day: d[0], type: "workout", focus: f[0],
                    exercises: ["Bench Press 5×5", "Incline DB Press 4×10", "Cable Fly 4×12", "Push-ups 3×20", "Skull Crusher 4×10", "Tricep Dip 4×12", "Close-grip Bench 3×10"]),
            DayPlan(day: d[1], type: "workout", focus: f[1],
                    exercises: ["Weighted Pull-ups 5×5", "Pendlay Row 4×6", "Lat Pulldown 4×10", "Seated Row 3×12", "Barbell Curl 4×10", "Preacher Curl 3×12"]),
            DayPlan(day: d[2], type: "workout", focus: f[4],
                    exercises: ["Squat 5×5", "Romanian Deadlift 4×8", "Leg Press 4×12", "Leg Curl 3×12", "Hip Thrust 4×12", "Calf Raise 5×20"]),
            DayPlan(day: d[3], type: "rest",    focus: f[2], exercises: restAndRecoveryExercises()),
            DayPlan(day: d[4], type: "workout", focus: f[0],
                    exercises: ["Incline Bench 4×8", "Dumbbell Fly 3×12", "Push-ups 3×20", "Overhead Tricep 4×10", "Tricep Pushdown 3×12"]),
            DayPlan(day: d[5], type: "workout", focus: f[1],
                    exercises: ["Deadlift 4×5", "Barbell Row 4×8", "Chin-ups 4×8", "Face Pull 3×15", "Hammer Curl 4×12"]),
            DayPlan(day: d[6], type: "workout", focus: f[3],
                    exercises: ["Overhead Press 5×5", "Arnold Press 3×12", "Lateral Raise 4×15", "Plank 4×60 sec", "Ab Wheel 3×10", "Russian Twist 3×20"]),
        ]
    }

    // MARK: - Stay Fit schedules

    private static func stayFitSchedule(_ d: [String]) -> [DayPlan] {
        let f = stayFitFocus()
        return [
            DayPlan(day: d[0], type: "workout", focus: f[0],
                    exercises: ["Squat 3×12", "Bench Press 3×10", "Barbell Row 3×10", "Overhead Press 3×10", "Plank 3×45 sec"]),
            DayPlan(day: d[1], type: "workout", focus: f[1],
                    exercises: ["Jump Rope 3×3 min", "Mountain Climbers 3×30 sec", "Crunch 3×20", "Russian Twist 3×20", "Leg Raise 3×15"]),
            DayPlan(day: d[2], type: "rest",    focus: f[2], exercises: lightRestExercises()),
            DayPlan(day: d[3], type: "workout", focus: f[3],
                    exercises: ["Pull-ups or Lat Pulldown 3×10", "Push-ups 4×15", "Dumbbell Row 3×10", "Lateral Raise 3×15", "Hammer Curl 3×12"]),
            DayPlan(day: d[4], type: "workout", focus: f[4],
                    exercises: ["Goblet Squat 3×15", "Walking Lunge 3×12", "Romanian Deadlift 3×12", "Glute Bridge 3×20", "Plank 3×60 sec"]),
            DayPlan(day: d[5], type: "rest",    focus: f[5], exercises: lightRecoveryExercises()),
            DayPlan(day: d[6], type: "rest",    focus: f[6], exercises: fullRestExercises()),
        ]
    }

    private static func stayFitBeginner(_ d: [String]) -> [DayPlan] {
        let f = stayFitFocus()
        return [
            DayPlan(day: d[0], type: "workout", focus: f[0],
                    exercises: ["Wall Squat 3×10", "Knee Push-ups 3×10", "Dumbbell Row 3×10", "Plank 3×20 sec"]),
            DayPlan(day: d[1], type: "rest",    focus: f[2], exercises: lightRecoveryExercises()),
            DayPlan(day: d[2], type: "workout", focus: f[1],
                    exercises: ["March in Place 2×3 min", "Crunch 3×15", "Glute Bridge 3×15", "Leg Raise 3×12"]),
            DayPlan(day: d[3], type: "rest",    focus: f[2], exercises: lightRestExercises()),
            DayPlan(day: d[4], type: "workout", focus: f[4],
                    exercises: ["Step-up 3×10 each leg", "Glute Bridge 3×15", "Plank 3×25 sec", "Seated Dumbbell Curl 3×12"]),
            DayPlan(day: d[5], type: "rest",    focus: f[5], exercises: lightRecoveryExercises()),
            DayPlan(day: d[6], type: "rest",    focus: f[6], exercises: fullRestExercises()),
        ]
    }

    // MARK: - Focus strings per goal + language

    private static func loseWeightFocus() -> [String] {
        switch lang {
        case "es":    return ["Circuito Cuerpo Completo", "Recuperación Activa", "Parte Superior + Cardio",
                              "Core y Cardio", "Parte Inferior", "Descanso Total"]
        case "it":    return ["Circuito Corpo Completo", "Recupero Attivo", "Parte Superiore + Cardio",
                              "Core e Cardio", "Parte Inferiore", "Riposo Totale"]
        case "pt-BR": return ["Circuito Corpo Todo", "Recuperação Ativa", "Parte Superior + Cardio",
                              "Core e Cardio", "Parte Inferior", "Descanso Total"]
        case "fr":    return ["Circuit Corps Entier", "Récupération Active", "Haut du Corps + Cardio",
                              "Gainage & Cardio", "Bas du Corps", "Repos Total"]
        default:      return ["Full Body Circuit", "Active Recovery", "Upper Body + Cardio",
                              "Core & Cardio", "Lower Body", "Full Rest"]
        }
    }

    private static func gainMuscleFocus() -> [String] {
        switch lang {
        case "es":    return ["Pecho y Tríceps", "Espalda y Bíceps", "Descanso y Recuperación",
                              "Hombros y Core", "Piernas", "Fuerza Cuerpo Completo", "Descanso Total"]
        case "it":    return ["Petto e Tricipiti", "Schiena e Bicipiti", "Riposo e Recupero",
                              "Spalle e Core", "Gambe", "Forza Corpo Completo", "Riposo Totale"]
        case "pt-BR": return ["Peito e Tríceps", "Costas e Bíceps", "Descanso e Recuperação",
                              "Ombros e Core", "Pernas", "Força Corpo Todo", "Descanso Total"]
        case "fr":    return ["Pectoraux & Triceps", "Dos & Biceps", "Repos & Récupération",
                              "Épaules & Gainage", "Jambes", "Force Corps Entier", "Repos Total"]
        default:      return ["Chest & Triceps", "Back & Biceps", "Rest & Recovery",
                              "Shoulders & Core", "Legs", "Full Body Power", "Full Rest"]
        }
    }

    private static func stayFitFocus() -> [String] {
        switch lang {
        case "es":    return ["Fuerza Cuerpo Completo", "Cardio y Core", "Descanso",
                              "Parte Superior", "Parte Inferior y Core", "Recuperación Activa", "Descanso Total"]
        case "it":    return ["Forza Corpo Completo", "Cardio e Core", "Riposo",
                              "Parte Superiore", "Parte Inferiore e Core", "Recupero Attivo", "Riposo Totale"]
        case "pt-BR": return ["Força Corpo Todo", "Cardio e Core", "Descanso",
                              "Parte Superior", "Parte Inferior e Core", "Recuperação Ativa", "Descanso Total"]
        case "fr":    return ["Force Corps Entier", "Cardio & Gainage", "Repos",
                              "Haut du Corps", "Bas du Corps & Gainage", "Récupération Active", "Repos Total"]
        default:      return ["Full Body Strength", "Cardio & Core", "Rest",
                              "Upper Body", "Lower Body + Core", "Active Recovery", "Full Rest"]
        }
    }

    // MARK: - Rest day activities

    private static func activeRecoveryExercises() -> [String] {
        switch lang {
        case "es":    return ["Caminata rápida 30 min", "Estiramientos 10 min", "Foam roller piernas y espalda"]
        case "it":    return ["Camminata veloce 30 min", "Stretching 10 min", "Foam roller gambe e schiena"]
        case "pt-BR": return ["Caminhada rápida 30 min", "Alongamento 10 min", "Foam roller pernas e costas"]
        case "fr":    return ["Marche rapide 30 min", "Étirements 10 min", "Foam roller jambes et dos"]
        default:      return ["30-min brisk walk", "10-min full-body stretch", "Foam roll legs & back"]
        }
    }

    private static func lightRecoveryExercises() -> [String] {
        switch lang {
        case "es":    return ["Trote suave 20 min o bicicleta", "Yoga o estiramientos 10 min"]
        case "it":    return ["Jogging leggero 20 min o bici", "Yoga o stretching 10 min"]
        case "pt-BR": return ["Trote leve 20 min ou bicicleta", "Yoga ou alongamento 10 min"]
        case "fr":    return ["Jogging léger 20 min ou vélo", "Yoga ou étirements 10 min"]
        default:      return ["20-min light jog or cycling", "10-min yoga or stretching"]
        }
    }

    private static func fullRestExercises() -> [String] {
        switch lang {
        case "es":    return ["Descanso y recuperación", "Caminata suave si lo deseas", "Prepara comidas para la semana"]
        case "it":    return ["Riposo e recupero", "Camminata leggera se vuoi", "Prepara i pasti per la settimana"]
        case "pt-BR": return ["Descanso e recuperação", "Caminhada leve se desejar", "Prepare as refeições da semana"]
        case "fr":    return ["Repos et récupération", "Marche légère si souhaité", "Prépare tes repas pour la semaine"]
        default:      return ["Rest & recover", "Light walk if desired", "Prep meals for the week"]
        }
    }

    private static func restAndRecoveryExercises() -> [String] {
        switch lang {
        case "es":    return ["Descanso completo o caminata 20 min", "Comidas ricas en proteína", "Estiramientos hombros y espalda 10 min"]
        case "it":    return ["Riposo o camminata 20 min", "Pasti ricchi di proteine", "Stretching spalle e schiena 10 min"]
        case "pt-BR": return ["Descanso completo ou caminhada 20 min", "Refeições ricas em proteína", "Alongamento ombros e costas 10 min"]
        case "fr":    return ["Repos ou marche 20 min", "Repas riches en protéines", "Étirements épaules et dos 10 min"]
        default:      return ["Full rest or 20-min walk", "Protein-focused meals", "10-min shoulder & back stretch"]
        }
    }

    private static func lightRestExercises() -> [String] {
        switch lang {
        case "es":    return ["Descanso completo o caminata 20 min", "Trabajo de movilidad", "Foam rolling"]
        case "it":    return ["Riposo o camminata 20 min", "Lavoro di mobilità", "Foam rolling"]
        case "pt-BR": return ["Descanso ou caminhada 20 min", "Trabalho de mobilidade", "Foam rolling"]
        case "fr":    return ["Repos ou marche 20 min", "Travail de mobilité", "Foam rolling"]
        default:      return ["Full rest or 20-min walk", "Mobility work", "Foam rolling"]
        }
    }

    // MARK: - ExtraContext processing

    private static func applyContext(_ plan: FitnessPlan, context: String) -> FitnessPlan {
        let hasKnee = hasKneeKeyword(context)
        let hasHome = hasHomeKeyword(context)
        let hasBack = hasBackKeyword(context)

        guard hasKnee || hasHome || hasBack else { return plan }

        let newSchedule = plan.weeklySchedule.map { day -> DayPlan in
            let modifiedExercises = day.exercises.map { ex -> String in
                var result = ex
                if hasKnee { result = applyKneeSubstitution(result) }
                if hasHome { result = applyHomeSubstitution(result) }
                if hasBack { result = applyBackSubstitution(result) }
                return result
            }
            return DayPlan(day: day.day, type: day.type, focus: day.focus, exercises: modifiedExercises)
        }

        return FitnessPlan(
            analysis:       plan.analysis,
            weeklySchedule: newSchedule,
            nutritionPlan:  plan.nutritionPlan,
            tips:           plan.tips,
            motivation:     plan.motivation,
            weeklyMeals:    plan.weeklyMeals
        )
    }

    // MARK: - Variety (so regenerating doesn't feel identical)

    // Interchangeable exercises with the same target — applied at random
    // on each generation so two plans rarely look the same.
    private static let varietySwaps: [(String, String)] = [
        ("Jump Rope",         "High Knees"),
        ("Mountain Climbers", "Burpees"),
        ("Crunch",            "Bicycle Crunch"),
        ("Walking Lunge",     "Reverse Lunge"),
        ("Lateral Raise",     "Front Raise"),
        ("Hammer Curl",       "Dumbbell Curl"),
        ("Glute Bridge",      "Single-leg Glute Bridge"),
        ("Cable Fly",         "Dumbbell Fly"),
        ("Russian Twist",     "Heel Touch"),
        ("Plank 3",           "Side Plank 3"),
    ]

    private static func applyVariety(_ schedule: [DayPlan]) -> [DayPlan] {
        // Pick a random subset of swaps for this generation.
        let active = varietySwaps.filter { _ in Bool.random() }
        guard !active.isEmpty else { return schedule }
        return schedule.map { day in
            let varied = day.exercises.map { ex in
                active.reduce(ex) { $0.replacingOccurrences(of: $1.0, with: $1.1) }
            }
            return DayPlan(day: day.day, type: day.type, focus: day.focus, exercises: varied)
        }
    }

    // MARK: - Weekly meal suggestions (from the recipe library, goal-matched)

    private static func weeklyMeals(goal: FitnessGoal) -> [DayMeals] {
        let recipeGoal: RecipeGoal = {
            switch goal {
            case .loseWeight: return .weightLoss
            case .gainMuscle: return .muscleGain
            case .stayFit:    return .maintenance
            }
        }()

        let breakfasts = RecipeDatabase.all
            .filter { $0.tags.contains("Breakfast") }
            .map(\.name).shuffled()
        let goalMains = RecipeDatabase.all
            .filter { $0.goal == recipeGoal && !$0.tags.contains("Breakfast") }
            .map(\.name).shuffled()
        let otherMains = RecipeDatabase.all
            .filter { $0.goal != recipeGoal && !$0.tags.contains("Breakfast") }
            .map(\.name).shuffled()
        let mains = goalMains + otherMains

        guard !breakfasts.isEmpty, mains.count >= 2 else { return [] }

        let d = days
        return (0..<7).map { i in
            DayMeals(
                day:       d[i],
                breakfast: breakfasts[i % breakfasts.count],
                lunch:     mains[i % mains.count],
                dinner:    mains[(i + mains.count / 2) % mains.count]
            )
        }
    }

    private static func hasKneeKeyword(_ ctx: String) -> Bool {
        ["knee", "rodilla", "ginocchio", "genou", "joelho", "knie"].contains { ctx.contains($0) }
    }

    private static func hasHomeKeyword(_ ctx: String) -> Bool {
        ["home", "casa", "maison", "chez moi", "domicilio", "casa mia"].contains { ctx.contains($0) }
    }

    private static func hasBackKeyword(_ ctx: String) -> Bool {
        ["back pain", "dolor de espalda", "mal au dos", "mal di schiena", "dor nas costas",
         "bad back", "espalda", "schiena", "costas"].contains { ctx.contains($0) }
    }

    private static func applyKneeSubstitution(_ ex: String) -> String {
        let subs: [(String, String)] = [
            ("Jump Rope", "March in Place"),
            ("High Knees", "March in Place"),
            ("Burpees", "March in Place"),
            ("Box Jump", "Step-up (no jump)"),
            ("Walking Lunge", "Hip Thrust"),
            ("Reverse Lunge", "Hip Thrust"),
            ("Squat 4×15", "Wall Squat 4×15"),
            ("Squat 4×12", "Wall Squat 4×12"),
            ("Squat 5×5",  "Leg Press 5×5"),
            ("Squat 3×12", "Leg Press 3×12"),
        ]
        return subs.reduce(ex) { $0.replacingOccurrences(of: $1.0, with: $1.1) }
    }

    private static func applyHomeSubstitution(_ ex: String) -> String {
        let subs: [(String, String)] = [
            ("Barbell Row",      "Dumbbell Row"),
            ("Barbell Curl",     "Dumbbell Curl"),
            ("Bench Press",      "Dumbbell Press"),
            ("Incline Bench",    "Incline Push-ups"),
            ("Lat Pulldown",     "Resistance Band Pulldown"),
            ("Cable Fly",        "Dumbbell Fly"),
            ("Skull Crusher",    "Dumbbell Overhead Extension"),
            ("Tricep Pushdown",  "Tricep Kickback"),
            ("Leg Press",        "Goblet Squat"),
            ("Leg Curl",         "Nordic Curl"),
            ("Pendlay Row",      "Dumbbell Row"),
            ("Seated Row",       "Resistance Band Row"),
            ("Preacher Curl",    "Incline Dumbbell Curl"),
            ("Clean & Press",    "Dumbbell Clean & Press"),
            ("Deadlift",         "Romanian Deadlift"),
        ]
        return subs.reduce(ex) { $0.replacingOccurrences(of: $1.0, with: $1.1) }
    }

    private static func applyBackSubstitution(_ ex: String) -> String {
        let subs: [(String, String)] = [
            ("Deadlift 4×5",           "Hip Thrust 4×10"),
            ("Deadlift 4×8",           "Hip Thrust 4×10"),
            ("Romanian Deadlift 4×8",  "Hip Thrust 4×10"),
            ("Romanian Deadlift 3×12", "Hip Thrust 3×12"),
            ("Barbell Row 4×8",        "Dumbbell Row 4×10"),
            ("Barbell Row 3×10",       "Dumbbell Row 3×12"),
            ("Overhead Press 4×8",     "Lateral Raise 4×12"),
            ("Overhead Press 5×5",     "Lateral Raise 4×15"),
        ]
        return subs.reduce(ex) { $0.replacingOccurrences(of: $1.0, with: $1.1) }
    }

    // MARK: - Nutrition

    private static func nutrition(goal: FitnessGoal, dailyCalories: Int, dailyProtein: Int) -> AINutritionPlan {
        let carbs = Int(Double(dailyCalories) * 0.45 / 4)
        let fat   = Int(Double(dailyCalories) * 0.25 / 9)
        return AINutritionPlan(
            calories: dailyCalories, protein: dailyProtein, carbs: carbs, fat: fat,
            tips: nutritionTips(goal: goal)
        )
    }

    private static func nutritionTips(goal: FitnessGoal) -> [String] {
        switch (goal, lang) {
        case (.loseWeight, "es"):
            return ["Come proteínas en cada comida para mantener la saciedad y preservar músculo",
                    "Bebe 3 L de agua al día — el hambre suele ser sed disfrazada",
                    "Prioriza verduras y fibra para reducir el hambre con déficit calórico",
                    "Evita calorías líquidas: jugos, refrescos y alcohol suman rápido",
                    "Prepara comidas el domingo para evitar elecciones impulsivas durante la semana"]
        case (.gainMuscle, "es"):
            return ["Come 30–40 g de proteína en los 45 min posteriores al entrenamiento",
                    "Distribuye la proteína en 4–5 comidas para maximizar la síntesis muscular",
                    "No omitas los carbohidratos — alimentan tu entrenamiento y la recuperación",
                    "Bebe al menos 3 L de agua al día; el músculo es 75% agua",
                    "Considera un batido de caseína antes de dormir para alimentar los músculos de noche"]
        case (.stayFit, "es"):
            return ["Sigue la regla 80/20: 80% alimentos reales, 20% flexibilidad",
                    "Incluye omega-3 (salmón, nueces) para la salud articular y reducir inflamación",
                    "Bebe 2.5–3 L de agua al día",
                    "Come 5 o más porciones de verduras y frutas al día",
                    "Mantén horarios de comidas consistentes para regular las hormonas del hambre"]
        case (.loseWeight, "it"):
            return ["Mangia proteine ad ogni pasto per restare sazio e preservare il muscolo",
                    "Bevi 3 L d'acqua al giorno — spesso la fame è sete travestita",
                    "Privilegia verdure e fibre per ridurre la fame con deficit calorico",
                    "Evita le calorie liquide: succhi, bevande gassate e alcol si accumulano velocemente",
                    "Prepara i pasti la domenica per evitare scelte impulsive durante la settimana"]
        case (.gainMuscle, "it"):
            return ["Consuma 30–40 g di proteine entro 45 minuti dall'allenamento",
                    "Distribuisci le proteine in 4–5 pasti per massimizzare la sintesi muscolare",
                    "Non saltare i carboidrati — alimentano l'allenamento e il recupero",
                    "Bevi almeno 3 L d'acqua al giorno; il muscolo è composto al 75% d'acqua",
                    "Considera un frullato di caseina prima di dormire per nutrire i muscoli di notte"]
        case (.stayFit, "it"):
            return ["Segui la regola 80/20: 80% cibi interi, 20% flessibilità",
                    "Includi omega-3 (salmone, noci) per la salute delle articolazioni",
                    "Bevi 2.5–3 L d'acqua al giorno",
                    "Mangia 5 o più porzioni di verdure e frutta al giorno",
                    "Mantieni orari dei pasti costanti per regolare gli ormoni della fame"]
        case (.loseWeight, "pt-BR"):
            return ["Coma proteínas em cada refeição para manter a saciedade e preservar músculo",
                    "Beba 3 L de água por dia — a fome muitas vezes é sede disfarçada",
                    "Priorize vegetais e fibras para reduzir a fome com déficit calórico",
                    "Evite calorias líquidas: sucos, refrigerantes e álcool somam rápido",
                    "Prepare refeições no domingo para evitar escolhas impulsivas durante a semana"]
        case (.gainMuscle, "pt-BR"):
            return ["Coma 30–40 g de proteína nos 45 minutos após o treino",
                    "Distribua a proteína em 4–5 refeições para maximizar a síntese muscular",
                    "Não pule os carboidratos — eles alimentam seu treino e a recuperação",
                    "Beba pelo menos 3 L de água por dia; o músculo é 75% água",
                    "Considere um shake de caseína antes de dormir para nutrir os músculos à noite"]
        case (.stayFit, "pt-BR"):
            return ["Siga a regra 80/20: 80% alimentos naturais, 20% flexibilidade",
                    "Inclua ômega-3 (salmão, nozes) para saúde articular e reduzir inflamação",
                    "Beba 2,5–3 L de água por dia",
                    "Coma 5 ou mais porções de vegetais e frutas por dia",
                    "Mantenha horários de refeições consistentes para regular os hormônios da fome"]
        case (.loseWeight, "fr"):
            return ["Mange des protéines à chaque repas pour rester rassasié et préserver le muscle",
                    "Bois 3 L d'eau par jour — la faim est souvent de la soif déguisée",
                    "Privilégie les légumes et les fibres pour réduire la faim en déficit calorique",
                    "Évite les calories liquides : jus, sodas et alcool s'accumulent vite",
                    "Prépare tes repas le dimanche pour éviter les choix impulsifs en semaine"]
        case (.gainMuscle, "fr"):
            return ["Consomme 30–40 g de protéines dans les 45 min après l'entraînement",
                    "Répartis les protéines sur 4–5 repas pour maximiser la synthèse musculaire",
                    "Ne saute pas les glucides — ils alimentent tes séances et la récupération",
                    "Bois au moins 3 L d'eau par jour ; le muscle est composé à 75% d'eau",
                    "Pense à un shake de caséine avant de dormir pour nourrir les muscles la nuit"]
        case (.stayFit, "fr"):
            return ["Suis la règle 80/20 : 80% d'aliments naturels, 20% de flexibilité",
                    "Inclus des oméga-3 (saumon, noix) pour la santé articulaire",
                    "Bois 2,5–3 L d'eau par jour",
                    "Mange 5 portions ou plus de légumes et de fruits par jour",
                    "Maintiens des horaires de repas réguliers pour équilibrer les hormones de la faim"]
        case (.loseWeight, _):
            return ["Eat protein in every meal to stay full and preserve muscle",
                    "Drink 3 L of water per day — hunger is often thirst in disguise",
                    "Prioritise vegetables and fibre to reduce hunger on a deficit",
                    "Avoid liquid calories: juices, sodas, and alcohol add up fast",
                    "Meal-prep on Sunday to avoid impulsive food choices during the week"]
        case (.gainMuscle, _):
            return ["Eat 30–40 g of protein within 45 minutes post-workout",
                    "Spread protein intake evenly across 4–5 meals for maximum synthesis",
                    "Don't skip carbs — they fuel your workouts and aid recovery",
                    "Drink at least 3 L of water daily; muscles are 75% water",
                    "Consider a casein protein shake before bed to feed muscles overnight"]
        case (.stayFit, _):
            return ["Follow the 80/20 rule: 80% whole foods, 20% flexibility",
                    "Include omega-3s (salmon, walnuts) for joint health and inflammation",
                    "Drink 2.5–3 L of water daily",
                    "Eat 5+ servings of vegetables and fruits per day",
                    "Aim for consistent meal times to regulate hunger hormones"]
        }
    }

    // MARK: - Tips

    private static func tips(goal: FitnessGoal) -> [String] {
        switch (goal, lang) {
        case (.loseWeight, "es"):
            return ["Duerme 7–9 horas — el mal sueño aumenta las hormonas del hambre hasta un 30%",
                    "Toma fotos de progreso cada 2 semanas, no solo la báscula — el músculo pesa más que la grasa",
                    "Añade caminatas de 10 min después de las comidas para potenciar la quema de grasa",
                    "Sube el peso un 2.5–5% cuando completes todas las repeticiones con buena técnica"]
        case (.gainMuscle, "es"):
            return ["Registra tus levantamientos en cada sesión — la sobrecarga progresiva es el motor nº1 del crecimiento muscular",
                    "Duerme 8+ horas — el 70% de la hormona del crecimiento se libera durante el sueño profundo",
                    "Descansa 2–3 min entre series pesadas para una recuperación completa de fuerza",
                    "Descarga cada 6–8 semanas: reduce el volumen un 40% para que tendones y articulaciones se recuperen"]
        case (.stayFit, "es"):
            return ["La consistencia supera la intensidad — 3 sesiones moderadas a la semana valen más que una brutal",
                    "Incluye trabajo de movilidad dos veces por semana para prevenir lesiones y mejorar el rendimiento",
                    "Monitorea tus niveles de energía — ajusta los días de descanso según cómo se siente tu cuerpo",
                    "Varía el cardio (bicicleta, natación, running) para evitar el aburrimiento y las lesiones"]
        case (.loseWeight, "it"):
            return ["Dormi 7–9 ore — il sonno scarso aumenta gli ormoni della fame fino al 30%",
                    "Scatta foto di progresso ogni 2 settimane — il muscolo pesa più del grasso",
                    "Aggiungi camminate di 10 min dopo i pasti per potenziare la combustione dei grassi",
                    "Aumenta i pesi del 2.5–5% quando riesci a completare tutte le ripetizioni con buona forma"]
        case (.gainMuscle, "it"):
            return ["Registra i tuoi sollevamenti ad ogni sessione — il sovraccarico progressivo è il principale motore della crescita muscolare",
                    "Dormi 8+ ore — il 70% dell'ormone della crescita viene rilasciato durante il sonno profondo",
                    "Riposati 2–3 min tra le serie pesanti per un recupero completo della forza",
                    "Scarica ogni 6–8 settimane: riduci il volume del 40%"]
        case (.stayFit, "it"):
            return ["La costanza supera l'intensità — 3 sessioni moderate a settimana valgono più di una brutale",
                    "Includi lavoro di mobilità due volte a settimana per prevenire infortuni",
                    "Monitora i tuoi livelli di energia — adatta i giorni di riposo in base a come si sente il tuo corpo",
                    "Varia il cardio (ciclismo, nuoto, corsa) per evitare noia e infortuni"]
        case (.loseWeight, "pt-BR"):
            return ["Durma 7–9 horas — o sono ruim aumenta os hormônios da fome em até 30%",
                    "Tire fotos de progresso a cada 2 semanas — músculo pesa mais que gordura",
                    "Adicione caminhadas de 10 min após as refeições para potencializar a queima de gordura",
                    "Aumente o peso em 2,5–5% quando completar todas as repetições com boa forma"]
        case (.gainMuscle, "pt-BR"):
            return ["Registre seus levantamentos em cada sessão — a sobrecarga progressiva é o principal motor do crescimento muscular",
                    "Durma 8+ horas — 70% do hormônio do crescimento é liberado durante o sono profundo",
                    "Descanse 2–3 min entre séries pesadas para recuperação completa de força",
                    "Faça deload a cada 6–8 semanas: reduza o volume em 40%"]
        case (.stayFit, "pt-BR"):
            return ["Consistência supera intensidade — 3 sessões moderadas por semana valem mais do que uma brutal",
                    "Inclua trabalho de mobilidade duas vezes por semana para prevenir lesões",
                    "Monitore seus níveis de energia — ajuste os dias de descanso conforme seu corpo",
                    "Varie o cardio (bike, natação, corrida) para evitar tédio e lesões"]
        case (.loseWeight, "fr"):
            return ["Dors 7–9 heures — le manque de sommeil augmente les hormones de la faim jusqu'à 30%",
                    "Prends des photos de progression toutes les 2 semaines — le muscle pèse plus que la graisse",
                    "Ajoute des marches de 10 min après les repas pour booster la combustion des graisses",
                    "Augmente les charges de 2,5–5% quand tu complètes toutes les reps avec une bonne forme"]
        case (.gainMuscle, "fr"):
            return ["Note tes soulevés à chaque séance — la surcharge progressive est le principal moteur de la croissance musculaire",
                    "Dors 8+ heures — 70% de l'hormone de croissance est libérée pendant le sommeil profond",
                    "Repose-toi 2–3 min entre les séries lourdes pour une récupération complète de la force",
                    "Fais un décharge toutes les 6–8 semaines : réduis le volume de 40%"]
        case (.stayFit, "fr"):
            return ["La régularité bat l'intensité — 3 séances modérées par semaine valent mieux qu'une séance brutale",
                    "Inclus du travail de mobilité deux fois par semaine pour prévenir les blessures",
                    "Surveille ton niveau d'énergie — adapte les jours de repos selon ce que ressent ton corps",
                    "Varie le cardio (vélo, natation, course) pour éviter l'ennui et les blessures"]
        case (.loseWeight, _):
            return ["Sleep 7–9 hours — poor sleep increases hunger hormones by up to 30%",
                    "Take progress photos every 2 weeks, not just the scale — muscle weighs more than fat",
                    "Add 10-minute walks after meals to boost fat burning and digestion",
                    "Increase weights by 2.5–5% when you can complete all reps with good form"]
        case (.gainMuscle, _):
            return ["Log your lifts every session — progressive overload is the #1 driver of muscle growth",
                    "Sleep 8+ hours — 70% of growth hormone is released during deep sleep",
                    "Rest 2–3 min between heavy compound sets for full strength recovery",
                    "Deload every 6–8 weeks: reduce volume by 40% to let your tendons and joints recover"]
        case (.stayFit, _):
            return ["Consistency beats intensity — 3 moderate sessions per week beat 1 brutal one",
                    "Include mobility work twice a week to prevent injury and improve performance",
                    "Track your energy levels — adjust rest days based on how your body feels",
                    "Vary your cardio (cycling, swimming, running) to prevent boredom and overuse injuries"]
        }
    }

    // MARK: - Motivation

    private static func motivation(goal: FitnessGoal) -> String {
        // Three phrasings per goal — one picked at random per generation.
        let variant = ["", ".v2", ".v3"].randomElement() ?? ""
        let key: String
        switch goal {
        case .loseWeight: key = "coach.motivation.loseWeight"
        case .gainMuscle: key = "coach.motivation.gainMuscle"
        case .stayFit:    key = "coach.motivation.stayFit"
        }
        return NSLocalizedString(key + variant, comment: "")
    }
}
