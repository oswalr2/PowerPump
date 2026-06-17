import SwiftUI

struct AICoachView: View {
    @ObservedObject private var profile  = UserProfile.shared
    @ObservedObject private var language = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var extraContext = ""
    @State private var plan: FitnessPlan?
    @State private var isGenerating = false
    @State private var selectedDay: DayPlan?

    var body: some View {
        ZStack {
            Color.sbBackground.ignoresSafeArea()
            if isGenerating        { loadingView }
            else if let p = plan   { planView(p) }
            else                   { setupView  }
        }
        .sheet(item: $selectedDay) { DayDetailSheet(day: $0) }
    }

    // MARK: - Setup

    private var setupView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Top bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.sbTextSecondary)
                            .frame(width: 34, height: 34)
                            .background(Color.sbSurface)
                            .clipShape(Circle())
                    }
                    Spacer()
                }

                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.sbAccent.opacity(0.15))
                            .frame(width: 90, height: 90)
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.sbAccent)
                    }
                    Text("Spartan Coach")
                        .font(SBFont.display(28))
                        .foregroundColor(.sbTextPrimary)
                    Text(LocalizedStringKey(CoachL.subtitle))
                        .font(SBFont.body())
                        .foregroundColor(.sbTextSecondary)
                        .multilineTextAlignment(.center)
                }

                // Profile summary card
                profileCard

                // Extra context
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey(CoachL.extraContextLabel))
                        .font(SBFont.caption())
                        .foregroundColor(.sbTextSecondary)

                    TextField(CoachL.extraContextPlaceholder,
                              text: $extraContext, axis: .vertical)
                        .lineLimit(3...6)
                        .font(SBFont.body())
                        .foregroundColor(.sbTextPrimary)
                        .padding(14)
                        .background(Color.sbSurface)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbBorder))
                }

                // Generate button
                Button { generate() } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text(LocalizedStringKey(CoachL.buildMyPlan))
                            .fontWeight(.bold)
                    }
                    .font(SBFont.body())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.sbAccent)
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 40)
            }
            .padding(20)
        }
    }

    // MARK: - Profile summary

    private var profileCard: some View {
        VStack(spacing: 10) {
            HStack {
                Label(LocalizedStringKey(CoachL.yourProfile), systemImage: "person.fill")
                    .font(SBFont.heading(15))
                    .foregroundColor(.sbTextPrimary)
                Spacer()
                Text(LocalizedStringKey(CoachL.editInProfile))
                    .font(SBFont.label(10))
                    .foregroundColor(.sbTextSecondary)
            }
            Divider().background(Color.sbBorder)
            HStack(spacing: 0) {
                profileStat(CoachL.goal,     profile.goal.rawValue)
                Divider().frame(height: 36)
                profileStat(CoachL.activity, shortActivity(profile.activityLevel))
                Divider().frame(height: 36)
                profileStat(CoachL.calories, "\(profile.dailyCalorieTarget) kcal")
                Divider().frame(height: 36)
                profileStat(CoachL.protein,  "\(profile.dailyProteinTarget) g")
            }
        }
        .padding(14)
        .background(Color.sbSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder))
    }

    private func profileStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(LocalizedStringKey(value))
                .font(SBFont.label(11))
                .fontWeight(.bold)
                .foregroundColor(.sbAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(SBFont.label(9))
                .foregroundColor(.sbTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func shortActivity(_ level: ActivityLevel) -> String {
        switch level {
        case .sedentary: return CoachL.sedentary
        case .light:     return CoachL.light
        case .moderate:  return CoachL.moderate
        case .active:    return CoachL.active
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(Color.sbAccent.opacity(0.1)).frame(width: 100, height: 100)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.sbAccent)
            }
            VStack(spacing: 8) {
                Text(LocalizedStringKey(CoachL.buildingPlan))
                    .font(SBFont.heading())
                    .foregroundColor(.sbTextPrimary)
                Text(LocalizedStringKey(CoachL.personalisingPlan))
                    .font(SBFont.body())
                    .foregroundColor(.sbTextSecondary)
            }
            Spacer()
        }
    }

    // MARK: - Plan view

    private func planView(_ p: FitnessPlan) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Top bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.sbTextSecondary)
                            .frame(width: 34, height: 34)
                            .background(Color.sbSurface)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Button {
                        withAnimation(.easeInOut) { plan = nil }
                    } label: {
                        Label(LocalizedStringKey(CoachL.newPlan), systemImage: "arrow.clockwise")
                            .font(SBFont.caption())
                            .foregroundColor(.sbAccent)
                    }
                }

                motivationBanner(p.motivation)
                analysisCard(p.analysis)
                weeklySection(p.weeklySchedule)
                nutritionSection(p.nutritionPlan)
                if !p.weeklyMeals.isEmpty { weeklyMealsSection(p.weeklyMeals) }
                if !p.tips.isEmpty { tipsSection(p.tips) }

                Spacer(minLength: 80)
            }
            .padding(20)
        }
    }

    // MARK: - Plan sub-views

    private func motivationBanner(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text(text)
                .font(SBFont.body())
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sbAccent)
        .cornerRadius(16)
    }

    private func analysisCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(LocalizedStringKey(CoachL.planOverview), systemImage: "doc.text.fill")
                .font(SBFont.heading())
                .foregroundColor(.sbTextPrimary)
            Text(text)
                .font(SBFont.body())
                .foregroundColor(.sbTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sbSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder))
    }

    private func weeklySection(_ schedule: [DayPlan]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(LocalizedStringKey(CoachL.sevenDaySchedule))
                .font(SBFont.heading())
                .foregroundColor(.sbTextPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(schedule) { DayPill(day: $0) }
                }
                .padding(.horizontal, 2)
            }

            VStack(spacing: 10) {
                ForEach(schedule) { day in
                    Button { selectedDay = day } label: { DayRow(day: day) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func nutritionSection(_ n: AINutritionPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(LocalizedStringKey(CoachL.nutritionTargets))
                .font(SBFont.heading())
                .foregroundColor(.sbTextPrimary)

            HStack(spacing: 0) {
                nutritionStat(CoachL.calories, "\(n.calories)", "kcal")
                Divider().frame(height: 40)
                nutritionStat(CoachL.protein,  "\(n.protein)",  "g")
                Divider().frame(height: 40)
                nutritionStat(CoachL.carbs,    "\(n.carbs)",    "g")
                Divider().frame(height: 40)
                nutritionStat(CoachL.fat,      "\(n.fat)",      "g")
            }
            .padding(14)
            .background(Color.sbSurface)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbBorder))

            if !n.tips.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(n.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "fork.knife.circle.fill")
                                .foregroundColor(.sbAccent).font(.system(size: 16))
                            Text(tip).font(SBFont.body()).foregroundColor(.sbTextPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(14)
                .background(Color.sbSurface)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbBorder))
            }
        }
    }

    private func tipsSection(_ tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey(CoachL.coachTips))
                .font(SBFont.heading())
                .foregroundColor(.sbTextPrimary)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.sbAccent).font(.system(size: 14)).padding(.top, 3)
                        Text(tip).font(SBFont.body()).foregroundColor(.sbTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(14)
            .background(Color.sbSurface)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbBorder))
        }
    }

    private func weeklyMealsSection(_ meals: [DayMeals]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Menu")
                .font(SBFont.heading())
                .foregroundColor(.sbTextPrimary)

            VStack(spacing: 0) {
                ForEach(Array(meals.enumerated()), id: \.element.id) { i, day in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(day.day)
                            .font(SBFont.heading(14))
                            .foregroundColor(.sbAccent)
                        mealLine(icon: "sunrise.fill",  name: day.breakfast)
                        mealLine(icon: "sun.max.fill",  name: day.lunch)
                        mealLine(icon: "moon.fill",     name: day.dinner)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    if i < meals.count - 1 {
                        Divider().background(Color.sbBorder)
                    }
                }
            }
            .background(Color.sbSurface)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbBorder))
        }
    }

    private func mealLine(icon: String, name: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.sbTextSecondary)
                .frame(width: 16)
            Text(LocalizedStringKey(name))
                .font(SBFont.body(14))
                .foregroundColor(.sbTextPrimary)
        }
    }

    private func nutritionStat(_ label: String, _ value: String, _ unit: String) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(SBFont.heading(18)).foregroundColor(.sbTextPrimary)
                Text(unit).font(SBFont.label()).foregroundColor(.sbTextSecondary)
            }
            Text(label).font(SBFont.label(10)).foregroundColor(.sbTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Generate (local — no API)

    private func buildAdaptiveContext() -> LocalCoachService.AdaptiveContext {
        let workouts = WorkoutStore.shared
        let foodLog  = FoodLogStore.shared
        let progress = ProgressStore.shared
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let weekStart = cal.date(byAdding: .day, value: -6, to: today) ?? today

        let last7Workouts = workouts.history.filter {
            $0.startedAt >= weekStart && $0.finishedAt != nil
        }.count
        let totalWorkouts = workouts.history.filter { $0.finishedAt != nil }.count

        let last7Cals = foodLog.dailyCalories(lastDays: 7).filter { $0.calories > 0 }
        let avgCals = last7Cals.isEmpty ? 0
            : Int(last7Cals.reduce(0) { $0 + $1.calories } / Double(last7Cals.count))

        let entries = progress.entries(days: 14).sorted { $0.date < $1.date }
        let weightTrend: Double? = {
            guard entries.count >= 2 else { return nil }
            return entries.last!.weightKg - entries.first!.weightKg
        }()

        return LocalCoachService.AdaptiveContext(
            pastWorkouts:         totalWorkouts,
            workoutsLast7Days:    last7Workouts,
            currentStreak:        workouts.currentStreak,
            longestStreak:        workouts.longestStreak,
            avgCaloriesLast7Days: avgCals,
            calorieTarget:        profile.dailyCalorieTarget,
            weightTrendKg:        weightTrend,
            hasLoggedWeight:      !entries.isEmpty)
    }

    private func generate() {
        isGenerating = true

        // Capture adaptive context BEFORE jumping off the main actor.
        let context = buildAdaptiveContext()

        // Brief delay for UX feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let result = LocalCoachService.generatePlan(
                goal:          profile.goal,
                activityLevel: profile.activityLevel,
                weightKg:      profile.weightKg,
                heightCm:      profile.heightCm,
                bmi:           profile.bmi,
                bmiCategory:   profile.bmiCategory,
                dailyCalories: profile.dailyCalorieTarget,
                dailyProtein:  profile.dailyProteinTarget,
                extraContext:  extraContext,
                history:       context
            )
            withAnimation(.easeInOut(duration: 0.4)) {
                plan = result
                isGenerating = false
            }
        }
    }
}

// MARK: - Day Pill

private struct DayPill: View {
    let day: DayPlan
    var body: some View {
        VStack(spacing: 6) {
            Text(String(day.day.prefix(3)))
                .font(SBFont.label(11))
                .foregroundColor(.sbTextSecondary)
            ZStack {
                Circle()
                    .fill(day.isWorkout ? Color.sbAccent : Color.sbSurface)
                    .frame(width: 38, height: 38)
                Image(systemName: day.isWorkout ? "dumbbell.fill" : "moon.zzz.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(day.isWorkout ? .white : .sbTextSecondary)
            }
        }
    }
}

// MARK: - Day Row

private struct DayRow: View {
    let day: DayPlan
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(day.isWorkout ? Color.sbAccent.opacity(0.15) : Color.sbSurface)
                    .frame(width: 46, height: 46)
                Image(systemName: day.isWorkout ? "dumbbell.fill" : "moon.zzz.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(day.isWorkout ? .sbAccent : .sbTextSecondary)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(day.day).font(SBFont.heading(15)).foregroundColor(.sbTextPrimary)
                    Spacer()
                    Text(LocalizedStringKey(day.isWorkout ? CoachL.workout : CoachL.rest))
                        .font(SBFont.label(10))
                        .foregroundColor(day.isWorkout ? .sbAccent : .sbTextSecondary)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(day.isWorkout ? Color.sbAccent.opacity(0.12) : Color.sbSurfaceRaised)
                        .cornerRadius(6)
                }
                Text(day.focus).font(SBFont.caption()).foregroundColor(.sbTextSecondary).lineLimit(1)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12)).foregroundColor(.sbBorder)
        }
        .padding(12)
        .background(Color.sbSurface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sbBorder))
    }
}

// MARK: - Day Detail Sheet

struct DayDetailSheet: View {
    let day: DayPlan
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(day.isWorkout ? Color.sbAccent : Color.sbSurface)
                                    .frame(width: 56, height: 56)
                                Image(systemName: day.isWorkout ? "dumbbell.fill" : "moon.zzz.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(day.isWorkout ? .white : .sbTextSecondary)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(day.day).font(SBFont.heading(20)).foregroundColor(.sbTextPrimary)
                                Text(day.focus).font(SBFont.body()).foregroundColor(.sbTextSecondary)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.sbSurface)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder))

                        Text(LocalizedStringKey(day.isWorkout ? CoachL.exercises : CoachL.recovery))
                            .font(SBFont.heading())
                            .foregroundColor(.sbTextPrimary)

                        VStack(spacing: 10) {
                            ForEach(Array(day.exercises.enumerated()), id: \.offset) { i, ex in
                                HStack(spacing: 14) {
                                    Text("\(i + 1)")
                                        .font(SBFont.label())
                                        .foregroundColor(.white)
                                        .frame(width: 28, height: 28)
                                        .background(day.isWorkout ? Color.sbAccent : Color.sbTextSecondary)
                                        .clipShape(Circle())
                                    Text(ex)
                                        .font(SBFont.body()).foregroundColor(.sbTextPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer()
                                }
                                .padding(14)
                                .background(Color.sbSurface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.sbBorder))
                            }
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(day.day)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(CoachL.done) { dismiss() }.foregroundColor(.sbAccent)
                }
            }
        }
    }
}

// MARK: - Localization helper

private enum CoachL {
    private static var lang: String { LanguageManager.shared.selectedCode }

    static var subtitle: String {
        switch lang {
        case "es":    return "Describe tu estado actual y objetivo. Tu coach generará un plan personalizado de 7 días al instante."
        case "it":    return "Descrivi il tuo stato attuale e l'obiettivo. Il tuo coach genererà un piano personalizzato di 7 giorni all'istante."
        case "pt-BR": return "Descreva seu estado atual e objetivo. Seu coach gerará um plano personalizado de 7 dias instantaneamente."
        case "fr":    return "Décris ton état actuel et ton objectif. Ton coach générera un plan personnalisé de 7 jours instantanément."
        default:      return "Describe your current state and any specific goal. Your coach will generate a personalised 7-day plan instantly."
        }
    }
    static var extraContextLabel: String {
        switch lang {
        case "es":    return "¿Algo más a considerar? (opcional)"
        case "it":    return "Altro da considerare? (opzionale)"
        case "pt-BR": return "Mais alguma coisa a considerar? (opcional)"
        case "fr":    return "Autre chose à prendre en compte ? (facultatif)"
        default:      return "Anything else to consider? (optional)"
        }
    }
    static var extraContextPlaceholder: String {
        switch lang {
        case "es":    return "Ej. tengo mala rodilla, prefiero ejercicios en casa, solo puedo entrenar de mañana…"
        case "it":    return "Es. ho un ginocchio dolorante, preferisco esercizi a casa, mi alleno solo al mattino…"
        case "pt-BR": return "Ex. tenho dor no joelho, prefiro treinos em casa, só posso treinar de manhã…"
        case "fr":    return "Ex. j'ai un genou douloureux, je préfère m'entraîner à la maison, seulement le matin…"
        default:      return "e.g. I have a bad knee, prefer home workouts, can train mornings only…"
        }
    }
    static var buildMyPlan: String {
        switch lang {
        case "es":    return "Crear mi Plan"
        case "it":    return "Crea il mio Piano"
        case "pt-BR": return "Criar meu Plano"
        case "fr":    return "Créer mon Plan"
        default:      return "Build My Plan"
        }
    }
    static var yourProfile: String {
        switch lang {
        case "es":    return "Tu Perfil"
        case "it":    return "Il tuo Profilo"
        case "pt-BR": return "Seu Perfil"
        case "fr":    return "Ton Profil"
        default:      return "Your Profile"
        }
    }
    static var editInProfile: String {
        switch lang {
        case "es":    return "Editar en Perfil"
        case "it":    return "Modifica nel Profilo"
        case "pt-BR": return "Editar no Perfil"
        case "fr":    return "Modifier dans Profil"
        default:      return "Edit in Profile tab"
        }
    }
    static var goal:     String { switch lang { case "es": return "Objetivo"; case "it": return "Obiettivo"; case "pt-BR": return "Objetivo"; case "fr": return "Objectif"; default: return "Goal" } }
    static var activity: String { switch lang { case "es": return "Actividad"; case "it": return "Attività";  case "pt-BR": return "Atividade"; case "fr": return "Activité"; default: return "Activity" } }
    static var calories: String { switch lang { case "es": return "Calorías"; case "it": return "Calorie";   case "pt-BR": return "Calorias";  case "fr": return "Calories"; default: return "Calories" } }
    static var protein:  String { switch lang { case "es": return "Proteína"; case "it": return "Proteine";  case "pt-BR": return "Proteína";  case "fr": return "Protéines"; default: return "Protein" } }
    static var carbs:    String { switch lang { case "es": return "Carbos";   case "it": return "Carboidrati"; case "pt-BR": return "Carbos";  case "fr": return "Glucides"; default: return "Carbs" } }
    static var fat:      String { switch lang { case "es": return "Grasa";    case "it": return "Grassi";    case "pt-BR": return "Gordura";   case "fr": return "Lipides"; default: return "Fat" } }
    static var buildingPlan: String {
        switch lang {
        case "es":    return "Creando tu plan…"
        case "it":    return "Creando il tuo piano…"
        case "pt-BR": return "Criando seu plano…"
        case "fr":    return "Création de ton plan…"
        default:      return "Building your plan…"
        }
    }
    static var personalisingPlan: String {
        switch lang {
        case "es":    return "Personalizando tu programa de 7 días"
        case "it":    return "Personalizzando il tuo programma di 7 giorni"
        case "pt-BR": return "Personalizando seu programa de 7 dias"
        case "fr":    return "Personnalisation de ton programme de 7 jours"
        default:      return "Personalising your 7-day programme"
        }
    }
    static var newPlan:         String { switch lang { case "es": return "Nuevo Plan"; case "it": return "Nuovo Piano"; case "pt-BR": return "Novo Plano"; case "fr": return "Nouveau Plan"; default: return "New Plan" } }
    static var planOverview:    String { switch lang { case "es": return "Resumen del Plan"; case "it": return "Panoramica del Piano"; case "pt-BR": return "Visão Geral do Plano"; case "fr": return "Vue d'ensemble"; default: return "Plan Overview" } }
    static var sevenDaySchedule: String { switch lang { case "es": return "Programa de 7 Días"; case "it": return "Programma di 7 Giorni"; case "pt-BR": return "Programa de 7 Dias"; case "fr": return "Programme de 7 Jours"; default: return "7-Day Schedule" } }
    static var nutritionTargets: String { switch lang { case "es": return "Objetivos Nutricionales"; case "it": return "Obiettivi Nutrizionali"; case "pt-BR": return "Metas Nutricionais"; case "fr": return "Objectifs Nutritionnels"; default: return "Nutrition Targets" } }
    static var coachTips:       String { switch lang { case "es": return "Consejos del Coach"; case "it": return "Consigli del Coach"; case "pt-BR": return "Dicas do Coach"; case "fr": return "Conseils du Coach"; default: return "Coach Tips" } }
    static var workout:         String { switch lang { case "es": return "Entrenamiento"; case "it": return "Allenamento"; case "pt-BR": return "Treino"; case "fr": return "Séance"; default: return "Workout" } }
    static var rest:            String { switch lang { case "es": return "Descanso"; case "it": return "Riposo"; case "pt-BR": return "Descanso"; case "fr": return "Repos"; default: return "Rest" } }
    static var exercises:       String { switch lang { case "es": return "Ejercicios"; case "it": return "Esercizi"; case "pt-BR": return "Exercícios"; case "fr": return "Exercices"; default: return "Exercises" } }
    static var recovery:        String { switch lang { case "es": return "Recuperación"; case "it": return "Recupero"; case "pt-BR": return "Recuperação"; case "fr": return "Récupération"; default: return "Recovery" } }
    static var done:            String { switch lang { case "es": return "Listo"; case "it": return "Fine"; case "pt-BR": return "Feito"; case "fr": return "Terminé"; default: return "Done" } }
    static var sedentary:       String { switch lang { case "es": return "Sedentario"; case "it": return "Sedentario"; case "pt-BR": return "Sedentário"; case "fr": return "Sédentaire"; default: return "Sedentary" } }
    static var light:           String { switch lang { case "es": return "Ligero"; case "it": return "Leggero"; case "pt-BR": return "Leve"; case "fr": return "Léger"; default: return "Light" } }
    static var moderate:        String { switch lang { case "es": return "Moderado"; case "it": return "Moderato"; case "pt-BR": return "Moderado"; case "fr": return "Modéré"; default: return "Moderate" } }
    static var active:          String { switch lang { case "es": return "Activo"; case "it": return "Attivo"; case "pt-BR": return "Ativo"; case "fr": return "Actif"; default: return "Active" } }
}

// MARK: - DayPlan Identifiable & Hashable

extension DayPlan: Hashable {
    static func == (lhs: DayPlan, rhs: DayPlan) -> Bool { lhs.day == rhs.day }
    func hash(into hasher: inout Hasher) { hasher.combine(day) }
}
