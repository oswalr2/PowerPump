import Foundation

/// What a chat question is about, found by keywords in the five app
/// languages. Kept free of app types so it can be tested on its own.
///
/// Some topics are answered with fixed, reviewed text even when Apple
/// Intelligence is on: the on-device model is small and, asked about brands,
/// pain or crash diets, it invents prices, certifications and even
/// supplements. Those topics are `curated`.
enum CoachTopic: String, CaseIterable {
    case health, pain, loseFast
    case proteinChoose, creatine, supplements, proteinAmount, water
    case eatToday, trainToday, volume
    case preWorkout, postWorkout, loseFat, gainMuscle, sleep, plateau
    // Basic-mode answers for iPhones without Apple Intelligence; with it,
    // the model answers these.
    case recomp, bellyFat, lateEating, cheatMeal, fasting, alcohol, eatingOut, cheapFood, cravings, snacks,
         breakfast, restSets, repsWeight, warmUp, stretching, trainingDays, homeWorkout, beginner, cardio, steps,
         soreness, scaleWeight, motivation
    case contactStrength, strength, power, endurance
    /// Requests that change the plan; Spartan answers with buttons.
    case shortToday, easyToday, moveWorkout, swapMeal
    /// A training question no other topic covers: answered with advice for
    /// the user's sport instead of "I didn't understand".
    case generalTraining
    /// Someone who may be in danger: always help lines, never training tips.
    case crisis
    /// Answered from the app's own exercise and food data, so they work the
    /// same on every iPhone.
    case exerciseHowTo, exerciseSwap, muscleExercises, foodInfo, calorieNeeds
    case carbs, trainingTime, cycle, teen, olderAdult, cramps, comeback, failure, deload, stress, appHelp
    /// "I did 100 push-ups": something to celebrate, not a question.
    case brag

    /// Answered with our own text in every mode.
    var isCurated: Bool {
        switch self {
        case .health, .pain, .loseFast, .proteinChoose, .creatine, .supplements, .proteinAmount, .water,
             .crisis, .teen, .cycle,
             // Built from the plan's exact numbers; the model miscounted them.
             .eatToday, .trainToday, .volume, .shortToday, .easyToday, .moveWorkout, .swapMeal,
             // From the app's own exercise and food tables.
             .exerciseHowTo, .exerciseSwap, .muscleExercises, .foodInfo, .calorieNeeds:
            return true
        default: return false
        }
    }

    static func detect(_ question: String) -> CoachTopic? {
        let q = " " + question.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .replacingOccurrences(of: "?", with: " ").replacingOccurrences(of: "¿", with: " ") + " "
        if crisisWords.contains(where: q.contains) { return .crisis }
        // Health and pain right after a crisis: "solo tengo 20 minutos, me
        // duele el pecho" needs the pain answer, not a shorter workout.
        if let hit = keywords.prefix(2).first(where: { _, words in words.contains { q.contains($0) } }) { return hit.0 }
        if isCrashDiet(q) { return .loseFast }
        if isShortOnTime(q) { return .shortToday }
        if isWeightLoss(q) { return .loseFat }
        if isRecomp(q) { return .recomp }
        if let age = age(in: q) {
            if age < 18 { return .teen }
            if age >= 40 { return .olderAdult }
        }
        if let intent = dataIntent(q) { return intent }
        if let hit = keywords.first(where: { _, words in words.contains { q.contains($0) } }) { return hit.0 }
        if bragWords.contains(where: q.contains) { return .brag }
        // "¿El aguacate engorda?": a food question with no other subject.
        if ["engorda", "fattening", "fait grossir", "fa ingrassare", "ingrassa"].contains(where: q.contains) { return .foodInfo }
        if ["protein", "proteina", "proteine"].contains(where: q.contains) { return .proteinAmount }
        if trainingWords.contains(where: q.contains) { return .generalTraining }
        return fuzzy(q)
    }

    // MARK: Safety

    /// Words that may mean the person is thinking of hurting themselves.
    static let crisisWords = ["suicid", "quitarme la vida", "no quiero vivir", "no quiero seguir viviendo", "matarme",
                              "hacerme dano", "autolesion", "kill myself", "end my life", "want to die", "self harm",
                              "self-harm", "hurt myself", "me tuer", "en finir", "me faire du mal", "uccidermi",
                              "farla finita", "farmi del male", "me matar", "tirar minha vida", "me machucar",
                              "quero morrer", "quiero morir", "veux mourir", "voglio morire"]

    static let bragWords = [" hice ", "he hecho", "acabo de terminar", "acabo de hacer", "termine el entreno",
                            "nuevo record", "mi record", "logre", "lo consegui", "i did ", "i just did", "just finished",
                            "i finished", "new pr", "new record", "personal best", "i hit ", "j'ai fait", "j'ai fini",
                            "nouveau record", "ho fatto", "ho finito", "nuovo record", "fiz ", "terminei", "novo recorde",
                            "consegui"]

    // MARK: Age

    /// "tengo 15 años", "I'm 52", "j'ai 45 ans": the age, when the user says it.
    static func age(in q: String) -> Int? {
        let pattern = try! NSRegularExpression(pattern:
            #"\b(?:tengo|i'm|i am|im|j'ai|ho|tenho|edad de|age of|aged)\s+(\d{1,2})\s*(?:anos|ano|years|year|yo|ans|anni|y/o)\b"#)
        guard let m = pattern.firstMatch(in: q, range: NSRange(q.startIndex..., in: q)),
              let r = Range(m.range(at: 1), in: q), let n = Int(q[r]) else {
            let older = ["soy mayor", "a mi edad", "tercera edad", "jubilad", "menopaus", "at my age", "over 50",
                         "over 60", "retired", "a mon age", "alla mia eta", "na minha idade", "aposentad"]
            return older.contains(where: q.contains) ? 60 : nil
        }
        // "tengo 30 minutos" and "I'm 80 kg" aren't ages.
        let after = q[r.upperBound...].trimmingCharacters(in: .whitespaces)
        if ["min", "kg", "kilo", "lb", "libra", "pound", "cm", "dia", "day", "semana", "week", "rep", "serie", "set",
            "vez", "time", "%"].contains(where: after.hasPrefix) { return nil }
        return n
    }

    // MARK: Exercises and food

    /// Exercise names, so "how do I do X" and "an alternative to X" are told
    /// apart from other questions. The answer finds X in the exercise library.
    static let exerciseWords = ["sentadilla", "squat", "agachamento", "peso muerto", "deadlift", "souleve", "stacco",
                                "levantamento terra", " press", "banca", "bench", "developpe", " panca", "supino",
                                "dominada", "pull up", "pull-up", "pullup", " traction", "trazion", "barra fixa",
                                " flexion", "push up", "push-up", "pushup", "pompe", "piegament", "flexao", "plancha",
                                "plank", "planche", "prancha", "zancada", "lunge", " fente", "affond", "afundo", " remo ",
                                " row", "rowing", "rematore", "remada", "curl", "rosca", "hip thrust", "puente de glute",
                                "puentes de glute", "glute bridge", "pont fessier", "ponte de glute", "fondos", "dips", " dip ", "jalon", "pulldown",
                                "tirage", "lat machine", "puxada", "elevaciones laterales", "lateral raise",
                                "elevations laterales", "alzate laterali", "elevacao lateral", "militar", "crunch",
                                "russian twist", "giro ruso", "burpee", "escalador", "mountain climber", "grimpeur",
                                "salto al cajon", "box jump", "la comba", "saltar la cuerda", "jump rope", "corde a sauter",
                                "pular corda", "aperturas", "cable fly", "croci", "crucifixo", "skull crusher",
                                "extension de triceps", "martillo", "hammer curl", "kettlebell", "swing", "goblet",
                                "leg raise", "elevacion de piernas", "releve de jambes", "sollevamento gambe",
                                "elevacao de pernas", "ecarte", "barre au front", "triceps testa", "epaule", "cargada",
                                "slancio", "arranco", "saut sur boite", "salto sul box", "salto na caixa",
                                "salto con la corda", "lento avanti", "desenvolvimento", "ponte per glutei", "mergulho",
                                "abdominal", "rotacao russa", "elevacao de quadril"]
    static let howToWords = ["como se hace", "como hago", "como hacer", "como realizo", "como realizar", "tecnica",
                             "forma correcta", "bien hech", "hacer bien", "how to do", "how do i do", "how to perform",
                             "proper form", "good form", "technique", "form for", "form on", "my form", "comment faire",
                             "comment on fait", "comment bien", "come si fa", "come fare", "come eseguire", "esecuzione",
                             "como fazer", "como faz", "como executar", "execucao", "forma correta", "explica",
                             "explain", "explique", "spiega", "paso a paso", "step by step"]
    static let swapWords = ["alternativa", "alternative", "sustitu", "substitu", "sostitu", "reemplaz", "remplac",
                            "replace", "en vez de", "en lugar de", "instead of", "a la place", "invece di", "al posto",
                            "em vez de", "no puedo hacer", "can't do", "cant do", "je n'arrive pas a faire",
                            "non riesco a fare", "nao consigo fazer", "otro ejercicio", "another exercise",
                            "autre exercice", "altro esercizio", "outro exercicio", "cambiar el ejercicio",
                            "cambiar ejercicio", "swap the exercise"]
    /// Muscle words, keyed by the app's muscle group names.
    static let muscleWords: [(String, [String])] = [
        ("Glutes", ["glute", "gluteo", "fessier", "fesse", "bumbum", "nalga", "booty", "butt"]),
        ("Chest", ["pecho", "pectoral", "chest", " pecs", "poitrine", "petto", "peito"]),
        ("Back", ["espalda", "dorsal", "back muscle", "back workout", "back day", "my back", "le dos", "du dos", "mon dos", "schiena", "costas", " lats"]),
        ("Shoulders", ["hombro", "shoulder", "deltoid", "epaule", "spall", "ombro"]),
        ("Arms", ["brazo", "bicep", "tricep", " arms", " arm ", " bras", "braccia", "braccio", "braco"]),
        ("Core", ["abdomin", " abs", " core", "abdos", "addominal", "oblicu", "oblique", "six pack", "tableta"]),
        ("Legs", ["pierna", "cuadricep", " quad", "femoral", "hamstring", " legs", " leg ", "jambe", "cuisse",
                  "gambe", "perna", "coxa", "pantorrill", "gemelo", "calves", "mollet", "polpacc", "panturrilha"]),
    ]
    private static let muscleTrainWords = ["ejercicio", "exercise", "exercice", "esercizi", "exercicio", "rutina",
                                           "routine", "entrenar", "entreno", "train", "trabajar", "trabajo", " work",
                                           "travailler", "muscler", "allenare", "trabalhar", "treinar", "crecer",
                                           "grow", "aumentar", "agrandar", "bigger", "tonificar", "tone", "fortalecer",
                                           "strengthen", "renforcer", "rafforzare", "fortalecer", "dia de", "day"]
    private static let foodInfoWords = ["calorias tiene", "calorias tienen", "calorias hay", "calorias de un",
                                        "calorias de una", "calorias del", "calorias de la", "proteina tiene",
                                        "proteinas tiene", "proteina hay", "proteina de un", "proteina de una",
                                        "proteina del", "proteina de la", "carbohidratos tiene", "grasa tiene",
                                        "macros de", "macros del", "valor nutricional", "calories in", "calories does",
                                        "calories are in", "calories of", "protein in", "protein does", "protein is in",
                                        "carbs in", "macros of", "macros in", "calories dans",
                                        "proteines dans", "proteine dans", "glucides dans", "calories d'un",
                                        "calorie ha", "calorie ci sono", "proteine ha", "proteine ci sono",
                                        "calorias tem", "proteina tem", "proteinas tem", "calorias de um", "proteina de um"]

    /// Questions answered from the exercise or food library.
    private static func dataIntent(_ q: String) -> CoachTopic? {
        if foodInfoWords.contains(where: q.contains), !q.contains("intake") { return .foodInfo }
        let exercise = exerciseWords.contains(where: q.contains)
        if swapWords.contains(where: q.contains), exercise || muscleGroup(in: q) != nil { return .exerciseSwap }
        if exercise, howToWords.contains(where: q.contains) { return .exerciseHowTo }
        if muscleGroup(in: q) != nil, muscleTrainWords.contains(where: q.contains),
           !keywords.first(where: { $0.0 == .volume })!.1.contains(where: q.contains) { return .muscleExercises }
        return nil
    }

    /// The muscle group named in the question, as the app's raw value.
    static func muscleGroup(in q: String) -> String? {
        let padded = " " + q + " "
        return muscleWords.first { _, words in words.contains(where: padded.contains) }?.0
    }

    // MARK: Typos

    /// Second chance for "protiena" or "creatiña": keywords one typo away.
    /// Only words of seven letters or more, so "como" never passes for "comer".
    private static func fuzzy(_ q: String) -> CoachTopic? {
        let words = q.split(whereSeparator: { !$0.isLetter }).map(String.init)
        guard !words.isEmpty else { return nil }
        func near(_ kw: Substring, _ w: String) -> Bool {
            // A shorter word is a different word ("jeune" is not "jeûner").
            guard kw.count >= 7, w.count >= kw.count else { return false }
            let a = Array(kw)
            return [kw.count - 1, kw.count, kw.count + 1].contains { n in
                n <= w.count && distance(a, Array(w.prefix(n))) <= 1
            }
        }
        let extra: [(CoachTopic, [String])] = [(.proteinAmount, ["proteina", "protein"]),
                                                 (.generalTraining, trainingWords.map { $0.trimmingCharacters(in: .whitespaces) })]
        for (topic, list) in keywords + extra {
            for kw in list {
                let parts = kw.split(separator: " ")
                // One-word keywords, or phrases whose other words match exactly.
                guard let long = parts.first(where: { $0.count >= 7 }) else { continue }
                let rest = parts.filter { $0 != long }
                if words.contains(where: { near(long, $0) }), rest.allSatisfy({ r in words.contains { $0.hasPrefix(r) } }) {
                    return topic
                }
            }
        }
        return nil
    }

    /// Edit distance where swapping two neighbouring letters counts as one.
    private static func distance(_ a: [Character], _ b: [Character]) -> Int {
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var d = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in 0...a.count { d[i][0] = i }
        for j in 0...b.count { d[0][j] = j }
        for i in 1...a.count {
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                d[i][j] = min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost)
                if i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] {
                    d[i][j] = min(d[i][j], d[i - 2][j - 2] + 1)
                }
            }
        }
        return d[a.count][b.count]
    }

    /// "lose 5 kg in 2 weeks" and the like: a weight-loss verb, a number of
    /// kilos or pounds, and a span of time short enough to be unhealthy.
    private static func isCrashDiet(_ q: String) -> Bool {
        guard loseVerbs.contains(where: q.contains) else { return false }

        func days(_ word: Substring, _ n: Double) -> Double? {
            if ["semana", "week", "semaine", "settiman"].contains(where: word.hasPrefix) { return n * 7 }
            if ["mes", "month", "mois"].contains(where: word.hasPrefix) { return n * 30 }
            if ["dia", "day", "jour", "giorn"].contains(where: word.hasPrefix) { return n }
            return nil
        }
        // Number–word pairs: "5 kilos", "5kg", "2 semanas".
        let pattern = try! NSRegularExpression(pattern: #"(\d+(?:[.,]\d+)?)\s*([a-z]+)"#)
        var kilos: Double?, span: Double?
        for m in pattern.matches(in: q, range: NSRange(q.startIndex..., in: q)) {
            guard let nr = Range(m.range(at: 1), in: q), let wr = Range(m.range(at: 2), in: q),
                  let n = Double(q[nr].replacingOccurrences(of: ",", with: ".")) else { continue }
            let word = q[wr]
            if ["kilo", "kg", "lb", "libra", "pound"].contains(where: word.hasPrefix) {
                kilos = word.hasPrefix("lb") || word.hasPrefix("libra") || word.hasPrefix("pound") ? n * 0.45 : n
            } else if span == nil, let d = days(word, n) { span = d }
        }
        // "in a week", "en un mes": the span without a number.
        if span == nil {
            for word in q.split(whereSeparator: { !$0.isLetter }) { if let d = days(word, 1) { span = d; break } }
        }
        guard let kilos, let span else { return false }
        // More than about 1 kg a week is faster than is healthy for most people.
        return kilos / max(span / 7, 0.1) > 1.2
    }

    /// Whether the question is about food, so today's intake is worth
    /// sending along. Sent with every question, the small model worked the
    /// numbers into unrelated answers ("I'm not motivated" → a macro list).
    static func isAboutFood(_ question: String) -> Bool {
        let q = question.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        return ["comer", "comid", "como hoy", "ceno", "cenar", "cena ", "desayun", "almuerz", "merend", "caloria",
                "calorie", "kcal", "prote", "carbo", "carbs", "grasa", " fat", "dieta", "diet", " eat", "food", "meal",
                "snack", "manger", "repas", "mangia", "pasto", "cibo", "gras", "refei", "lanche", "jantar", "almoco",
                "pizza", "hambre", "hungry", "faim", "fame", "fome", "macro"]
            .contains(where: q.contains)
    }

    /// Fat and muscle in one question ("¿pierdo grasa y gano músculo?"),
    /// whatever the verbs' conjugation.
    private static func isRecomp(_ q: String) -> Bool {
        ["grasa", " fat", "gras ", "graisse", "grasso", "gordura"].contains(where: q.contains)
            && ["muscul", "muscle", "muscol", "massa"].contains(where: q.contains)
            && !keywords[0].1.contains(where: q.contains) && !keywords[1].1.contains(where: q.contains)
    }

    /// "solo tengo 30 minutos", "poco tiempo hoy": a time word plus a limit.
    private static func isShortOnTime(_ q: String) -> Bool {
        let time = ["minuto", " min ", "tiempo", "prisa", "minute", "hurry", "temps", "tempo", "pressa", "pressé"]
        let limit = ["solo ", "solamente", "poco ", "only ", "little ", "seulement", "peu de", "pouco", "apenas",
                     "no tengo", "don't have", "no time", "pas le temps", "non ho", "nao tenho", "não tenho", "tengo prisa",
                     "in a hurry", "hoy", "today", "aujourd", "oggi", "hoje"]
        let gym = ["entren", "gym", "train", "workout", "entrain", "allen", "trein", "seance", "sesion", "minuto",
                   "minute", "min "]
        return time.contains(where: q.contains) && limit.contains(where: q.contains) && gym.contains(where: q.contains)
    }

    /// "lose 10 kg in 3 months": a loss at a reasonable pace.
    private static func isWeightLoss(_ q: String) -> Bool {
        loseVerbs.contains(where: q.contains) && ["kilo", "kg", "libra", "pound", "lb"].contains(where: q.contains)
            && !keywords[0].1.contains(where: q.contains) && !keywords[1].1.contains(where: q.contains)
    }

    private static let loseVerbs = ["bajar", "perder", "adelgazar", "lose", "drop", "perdre", "maigrir", "perdere",
                                    "dimagrire", "emagrecer", "eliminar"]

    /// A second subject in the same message ("my knee hurts, how do I get
    /// stronger?"), so both parts get an answer. Safety topics excluded.
    static func secondary(_ question: String, besides first: CoachTopic?) -> CoachTopic? {
        // Precise answers stand alone; a crisis never gets a second subject.
        if let first, [.crisis, .exerciseHowTo, .exerciseSwap, .muscleExercises, .foodInfo, .calorieNeeds].contains(first) {
            return nil
        }
        let q = " " + question.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil) + " "
        // Words already used by the first topic don't count again:
        // "descanso entre series" is about rest between sets, not sleep.
        let used = keywords.first { $0.0 == first }?.1.filter { q.contains($0) } ?? []
        return keywords.first { topic, words in
            topic != first && topic != .health && topic != .pain
                && words.contains { w in q.contains(w) && !used.contains { $0.contains(w) } }
        }?.0
    }

    /// Topics where a cheerful opener would sound careless.
    var isSensitive: Bool {
        [.pain, .health, .loseFast, .easyToday, .crisis, .stress, .cycle].contains(self)
    }

    /// Words that make a question about training even when no topic fits.
    static let trainingWords = ["entren", "ejercicio", "rutina", "mejorar", "gimnasio", " gym", "workout", " train",
                                "exercise", "routine", "improve", "entrain", "exercice", "seance", "progresser",
                                "allen", "esercizi", "migliorare", "trein", "exercicio", "melhorar", "academia",
                                "musculo", "muscle", "muscol", "rendimiento", "performance", "rendimento"]

    /// Checked in order: safety first, then the specific topics.
    static let keywords: [(CoachTopic, [String])] = [
        (.health, ["embaraz", "pregnan", "enceinte", "incinta", "gravida", "lactan", "breastfeed", "allait", "allatt", "amament",
                   "diabet", "hipertens", "hypertens", "ipertens", "tension alta", "pressao alta", "presion alta", "blood pressure",
                   "cardiopat", "arritm", "arrhythm", "heart condition", "heart disease", "problemas de corazon", "problema de corazon",
                   "maladie cardiaque", "malattia cardiaca", "doenca cardiaca", "rinon", "kidney", "reins", "renale", "renal",
                   "medicament", "medication", "farmac", "remedio", "pastilla", "antidepres",
                   "anorex", "bulim", "atracon", "binge", "vomit", "purg", "trastorno alimen", "eating disorder",
                   "trouble alimentaire", "disturbo alimentare", "transtorno alimentar", "esteroid", "steroid", "anabolic", "anabolizant"]),
        (.pain, ["duele", "dolor", "lesion", "lesionad", "painful", "pain in", "pain when", "back pain", "knee pain",
                 "shoulder pain", "hurt", "injur", "douleur", "blessure", "mal au",
                 "dolore", "fa male", "infortun", "doi ", "doendo", " dor ", " dores ", "machuc", "lesao", "tendin", "esguince", "sprain", "entorse",
                 "distorsion", "hernia", "ciatic", "sciatic", "sciati"]),
        (.moveWorkout, ["mueve el entreno", "mover el entreno", "pasa el entreno", "pasar el entreno",
                        "cambiar el dia", "cambia el dia", "hoy no puedo entrenar", "hoy no puedo ir", "otro dia",
                        "move today", "move my workout", "move the workout", "can't train today", "cant train today",
                        "another day", "deplace", "deplacer", "pas m'entrainer aujourd", "sposta", "spostare",
                        "oggi non posso", "mover o treino", "mudar o dia", "hoje nao posso", "hoje não posso"]),
        (.easyToday, ["estoy cansad", "muy cansad", "reventad", "agotad", "destrozad", "sin energia", "fundido",
                      "dia suave", "dia ligero", "entreno suave", "algo suave", "im tired", "i'm tired", "so tired",
                      "exhausted", "no energy", "easy day", "light day", "je suis fatigu", "creve", "epuise",
                      "journee legere", "sono stanc", "esaust", "giornata leggera", "estou cansad", "exaust",
                      "dia leve", "treino leve"]),
        (.swapMeal, ["no me gusta", "no me gustan", "cambia la cena", "cambia la comida", "cambia el desayuno",
                     "cambia el almuerzo", "cambiar la cena", "cambiar la comida", "cambiar el desayuno",
                     "otra cena", "otra comida", "otro desayuno", "don't like", "dont like", "swap my", "change my dinner",
                     "change my lunch", "change my breakfast", "another dinner", "je n'aime pas", "change mon",
                     "change le diner", "non mi piace", "cambia la", "nao gosto", "não gosto", "troca o", "trocar o"]),
        (.creatine, ["creatin"]),
        (.proteinChoose, ["marca", "brand", "marque", "whey", "suero", "polvo", "powder", "poudre", "in polvere", "em po", "isolat", "aislad",
                          "mejor proteina", "best protein", "meilleure proteine", "migliore proteina", "melhor proteina",
                          "que proteina", "which protein", "quelle proteine", "quale proteina", "qual proteina",
                          // Common supplement brands: the model makes up facts about them.
                          "optimum", "gold standard", "myprotein", "my protein", "dymatize", "muscletech", "bsn", "scitec",
                          "prozis", "weider", "hsn", "isopure", "ghost", "transparent labs", "rule 1", "rule1", "cellucor",
                          "musclepharm", "foodspring", "nutrex", "orgain", "garden of life", "integralmedica", "max titanium", "probiotica", "black skull", "enervit", "yamamoto",
                          "biotech", "applied nutrition", "insane labz", "ronnie coleman", "birdman", "premier protein"]),
        (.supplements, ["suplement", "supplement", "complement", "integrator", "preentreno", "pre-entreno", "pre workout",
                        "pre-workout", "quemador", "burner", "bruleur", "brucia", "queimador", "vitamina", "vitamin", "multivit",
                        "bcaa", "glutamin", "colageno", "collagen", "omega 3", "omega-3", "ashwagandha", "testosteron",
                        "l-carnitin", "carnitin", "termogen", "thermogen", "detox", "zma", "cafeina", "caffeine", "cafeine"]),
        (.water, ["cuanta agua", "cuantos litros", "how much water", "combien d'eau", "quanta acqua", "quanta agua",
                  // Whole words: "hidrat" alone would catch "carbohidratos".
                  "hidratar", "hidratacion", "hidratado", "hydrate", "hydration", "hydrater", "idratar", "idratazione",
                  "hidratacao"]),
        (.proteinAmount, ["cuanta proteina", "cuantas proteinas", "how much protein", "combien de proteine",
                          "quante proteine", "quanta proteina", "proteina al dia", "protein a day", "protein per day"]),
        (.volume, ["series por semana", "cuantas series", "sets per week", "how many sets", "combien de series",
                   "series par semaine", "quante serie", "serie a settimana", "quantas series", "series por semana"]),
        (.calorieNeeds, ["cuantas calorias necesito", "cuantas calorias debo", "cuantas calorias tengo que",
                         "cuantas calorias al dia", "cuantas calorias como al dia", "calorias al dia", "calorias diarias",
                         "how many calories should", "how many calories do i need", "how many calories a day",
                         "calories a day", "calories per day", "daily calories", "combien de calories par jour",
                         "combien de calories dois", "quante calorie devo", "quante calorie al giorno",
                         "calorie giornaliere", "quantas calorias devo", "quantas calorias por dia", "calorias por dia"]),
        (.cycle, ["menstrua", "mestrua", "la regla", "mi regla", "con la regla", "mi periodo", "con el periodo",
                  "ciclo menstrual", "my period", "on my period", "period cramps", "menstrual", "mes regles",
                  "pendant les regles", "ciclo mestruale", "minha menstruacao", "tpm",
                  "sindrome premenstrual", "pms"]),
        (.cramps, ["calambre", "cramp", "crampe", "crampo", "caimbra", "caibra"]),
        (.trainingTime, ["por la manana o", "manana o por la noche", "manana o tarde", "mejor hora", "a que hora",
                         "entrenar de noche", "entrenar por la noche", "entrenar tarde", "entrenar temprano",
                         "best time to", "morning or evening", "morning or night", "train at night", "workout at night",
                         "meilleur moment", "le soir ou le matin", "matin ou soir", "quelle heure", "orario migliore",
                         "mattina o sera", "allenarsi la sera", "melhor horario", "de manha ou a noite",
                         "treinar a noite", "treinar de noite"]),
        (.comeback, ["volver a entrenar", "volver al gym", "vuelvo al gym", "retomar", "llevo meses sin",
                     "llevo semanas sin", "llevo un ano sin", "deje el gym", "deje de entrenar", "hace mucho que no entreno",
                     "get back into", "back to the gym", "haven't trained in", "havent trained", "stopped training",
                     "reprendre", "recommencer le sport", "ricominciare", "riprendere", "tornare in palestra",
                     "voltar a treinar", "voltar pra academia", "parei de treinar"]),
        (.failure, ["al fallo", "hasta el fallo", "fallo muscular", "to failure", "until failure", "jusqu'a l'echec",
                    "a cedimento", "ate a falha", "falha muscular", " rir ", "reps en reserva", "reps in reserve"]),
        (.deload, ["descarga", "deload", "semana de descanso", "semana suave", "decharge", "scarico", "semana leve"]),
        (.recomp, ["recomposicion", "recomp", "perder grasa y ganar musculo", "ganar musculo y perder grasa",
                   "lose fat and gain muscle", "gain muscle and lose fat", "build muscle and lose fat", "skinny fat",
                   "perdre du gras et prendre du muscle", "perdere grasso e mettere massa", "perder gordura e ganhar massa"]),
        (.bellyFat, ["barriga", "tripa", "abdomen plano", "grasa abdominal", "belly", "flat stomach", "love handles",
                     "michelin", "ventre plat", "graisse du ventre", "pancia", "girovita", "gordura abdominal",
                     "pneuzinho", "six pack", "abdominales marcados", "tableta"]),
        (.lateEating, ["comer de noche", "cenar tarde", "comer tarde", "eat at night", "eating late", "eat late",
                       "late night", "tard le soir", "manger le soir", "mangiare la sera", "di notte", "a noite",
                       "antes de dormir", "before bed", "avant de dormir", "prima di dormire"]),
        (.cheatMeal, ["cheat", "comida trampa", "comida libre", "dia libre", "me pase", "me he pasado", "comi demasiado",
                      "me comi una", "me comi un", "pizza", "hamburguesa", "burger", "j'ai trop mange", "ho mangiato una",
                      "comi uma",
                      "comi mucho", "overate", "ate too much", "trop mange", "mangiato troppo", "exagerei", "comi demais"]),
        (.eatingOut, ["restaurante", "restaurant", "comer fuera", "eating out", "eat out", "de viaje", "viajando", "travel",
                      "voyage", "viaggio", "viagem", "fast food", "comida rapida", "manger dehors", "mangiare fuori", "comer fora"]),
        (.fasting, [" ayuno", "en ayunas", "fasting", " jeuner", "jeune intermittent", "periode de jeune", "digiun", "jejum", "16:8", "16/8"]),
        (.alcohol, ["alcohol", "alcool", "alcol", "cerveza", "vino", "beer", "wine", "biere", "birra", "cerveja", "vinho", "copas"]),
        (.cheapFood, ["barato", "cheap", "budget", "presupuesto", "poco dinero", "pas cher", "economi", "risparmi",
                      "costa poco", "sem gastar"]),
        (.cravings, ["dulce", "azucar", "sugar", "craving", "antojo", "ansiedad por comer", "sucre", "zuccher", "acucar",
                     "doces", "doce ", "vontade de doce", "chocolate", "postre", "dessert", "dolci"]),
        (.carbs, ["carbohidrat", "hidratos", "carbs", "carbohydrate", "low carb", "keto", "glucid", "carboidrat",
                  "pan engorda", " pan ", "el arroz", "la pasta", "bread", " rice", "pasta ", " riz", "pane ",
                  "riso", " pao ", "arroz"]),
        (.stress, ["estres", "estresad", "ansiedad", "agobiad", "burnout", "salud mental", "depres", "stress",
                   "anxiety", "anxious", "mental health", "anxiete", "angoisse", "sante mentale", "ansia",
                   "salute mentale", "ansiedade", "saude mental"]),
        (.snacks, ["snack", "en-cas", "encas", "picar", "picoteo", "entre horas", "merienda", "tentempie", "grignot", "spuntin", "lanche"]),
        (.warmUp, ["calentar", "caliento", "calentamiento", "warm up", "warm-up", "warmup", "echauff", "riscald", "aquec"]),
        (.stretching, ["estir", "stretch", "flexib", "movilidad", "mobility", "etire", "etirement", "mobilite", "allung",
                       "mobilita", "alongamento", "mobilidade"]),
        (.preWorkout, ["antes de entrenar", "antes del entreno", "antes de ir al gym", "before training", "before workout",
                       "before the gym", "avant l'entrainement", "avant la seance", "prima dell'allenamento", "antes do treino"]),
        (.postWorkout, ["despues de entrenar", "despues del entreno", "after training", "after workout", "post entreno",
                        "post-entreno", "apres l'entrainement", "apres la seance", "dopo l'allenamento", "depois do treino",
                        "pos-treino", "pos treino"]),
        (.trainToday, ["que entreno", "que entrenar", "rutina de hoy", "entreno de hoy", "what should i train", "what do i train", "workout today",
                       "today's workout", "quoi entrainer", "seance du jour", "cosa alleno", "allenamento di oggi",
                       "treino de hoje", "o que treino", "je travaille aujourd", "travailler aujourd", "seance d'aujourd"]),
        (.eatToday, ["que como", "que comer", "que ceno", "que desayuno", "what should i eat", "what to eat", "menu",
                     "dieta de hoy", "que manger", "quoi manger", "cosa mangio", "cosa mangiare", "o que como", "o que comer"]),
        (.breakfast, ["desayun", "breakfast", "petit dej", "colazione", "cafe da manha"]),
        (.restSets, ["descanso entre series", "descansar entre series", "cuanto descanso", "riposo tra", "quanto riposo", "rest between sets",
                     "how long to rest", "repos entre", "recupero tra", "descanso entre"]),
        (.repsWeight, ["cuantas repeticiones", "how many reps", "cuanto peso levant", "cuanto peso uso", "cuanto peso pongo",
                       "how much weight should i", "how much weight to", "rango de repeticiones", "rep range",
                       "combien de rep", "quel poids", "quante ripetizioni", "quanto peso uso", "quantas repeticoes"]),
        (.trainingDays, ["cuantos dias", "how many days", "combien de jours", "combien de fois", "quanti giorni",
                         "quantos dias", "veces por semana", "times a week", "fois par semaine", "volte a settimana",
                         "vezes por semana"]),
        (.homeWorkout, ["en casa", "at home", "sin equipo", "sin material", "sin pesas", "sin gimnasio", "no equipment",
                        "without a gym", "a la maison", "sans materiel", "a casa", "senza attrezz", "em casa", "sem equipamento"]),
        (.beginner, ["principiante", "beginner", "debutant", "iniciante", "soy nuevo", "soy nueva", "novato", "just started",
                     "nunca he entrenado", "never trained", "empezando", "comenzando", "je commence", "comincio"]),
        (.cardio, ["cardio", "hiit", "correr", "running", "run ", "courir", "correre", "corsa", "corrida", "bici", "bike",
                   "eliptica", "elliptical"]),
        (.steps, ["pasos", "combien de pas", "nombre de pas", "pas par jour", "steps", "caminar", "walk", "marcher", "camminare", "passi", "caminhar", "passos"]),
        (.soreness, ["agujetas", "sore", "courbature", "indolenziment", "dor muscular"]),
        (.scaleWeight, ["bascula", "balanza", "the scale", "peso sube", "subi de peso", "subo de peso", "retencion",
                        "retention", "ritenzione", "retencao", "fluctu", "la balance", "bilancia", "balanca"]),
        (.motivation, ["motivac", "motivat", "motivaz", "ganas de entrenar", "pereza", "flojera", "lazy", "flemme",
                       "voglia", "preguica"]),
        (.endurance, ["aguante", "resistencia", "fondo fisico", "endurance", "stamina", "me canso", "me ahogo",
                      "cansarme", "get tired", "out of breath", "souffle", "fatigue vite", "resistenza", "fiato",
                      "folego", "canso rapido"]),
        (.contactStrength, ["contacto", "contact", "agarre", "grip", " prise", "presa", "pegada", "cuello", "neck",
                            " cou ", "collo", "pescoco", "lucha", "grappl", "bjj", "jiu", "judo", "boxeo", "boxe",
                            "boxing", " mma", "combate", "combat", "pelea", "fight", "lotta", " luta"]),
        (.power, ["explosiv", "potencia", "potenza", "puissance", " power ", "saltar mas", "jump higher",
                  "salto vertical", "vertical jump", "sauter plus", "saltare di piu", "pular mais", "velocidad",
                  "mas rapido", "faster", "plus rapide", "piu veloce", "mais rapido"]),
        (.strength, ["fuerza", "fuerte", "strength", "stronger", "strong", " force", "plus fort", "forza",
                     "piu forte", "forca", "mais forte"]),
        (.loseFat, ["perder grasa", "bajar de peso", "perder peso", "adelgazar", "quemar grasa", "definir", "lose fat",
                    "lose weight", "burn fat", "perdre du poids", "perdre de la graisse", "maigrir", "dimagrire",
                    "perdere peso", "emagrecer", "secar"]),
        (.gainMuscle, ["ganar musculo", "masa muscular", "ganar masa", "hipertrofia", "volumen", "build muscle", "gain muscle",
                       "bulk up", "prendre du muscle", "masse musculaire", "massa muscolare", "ganhar massa", "ganhar musculo"]),
        (.plateau, ["estanc", "plateau", "stall", "stuck", "no bajo", "no avanzo", "no progreso", "no sube", "no me sube",
                     "no mejoro", "not improving", "not going up", "ne progresse pas", "non migliora", "nao sobe", "stagn", "stallo", "estagn"]),
        (.sleep, ["dormir", "sueno", "sleep", "sommeil", "sonno", "descans", "recuper", "recover"]),
        (.appHelp, ["como uso", "como funciona la app", "como funciona powerpump", "como registro", "como apunto",
                    "como anado", "como cambio mi", "como cambiar mi", "donde veo", "donde esta", "donde cambio",
                    "powerpump", "la app", "esta app", "how do i use", "how does the app", "how do i log", "where do i",
                    "where can i", "how do i change", "this app", "the app", "comment utiliser", "l'appli",
                    "cette app", "come uso", "come funziona l'app", "dove trovo", "l'app", "como usar",
                    "o app", "este app", "onde vejo", "onde fica"]),
    ]
}
