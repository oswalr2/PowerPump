import Foundation
var cases: [(String, CoachTopic?)] = [
    ("Que proteina es mejor, Optimum Nutrition o MyProtein? Y que ceno hoy?", .proteinChoose),
    ("Es buena la marca Gold Standard?", .proteinChoose),
    ("¿Qué ceno hoy?", .eatToday),
    ("Me duele la rodilla al hacer sentadilla, que hago?", .pain),
    ("Quiero bajar 5 kilos en 2 semanas, cuantas calorias como?", .loseFast),
    ("quiero perder 10 kg en 3 meses", .loseFat),
    ("En 2 semanas quiero bajar 4kg", .loseFast),
    ("lose 20 pounds in a month", .loseFast),
    ("perdre 3 kilos en une semaine", .loseFast),
    ("¿Me recomiendas un quemador de grasa?", .supplements),
    ("¿Cuánta creatina tomo y cuándo?", .creatine),
    ("¿Qué entreno hoy?", .trainToday),
    ("¿Cuántos carbohidratos debo comer?", .carbs),
    ("Quanti carboidrati devo mangiare?", .carbs),
    ("Est-ce que le pain complet fait grossir ?", .foodInfo),
    ("sono vegano, cosa mangio prima dell'allenamento?", .preWorkout),
    ("¿En qué zona de frecuencia cardiaca debo correr?", .cardio),
    ("tengo diabetes, puedo hacer ayuno?", .health),
    ("estoy embarazada, puedo entrenar pesas?", .health),
    ("How much protein should I eat?", .proteinAmount),
    ("Quanta proteína eu preciso por dia?", .proteinAmount),
    ("Is whey isolate better than concentrate?", .proteinChoose),
    ("My back hurts after deadlifts", .pain),
    ("J'ai mal au dos", .pain),
    ("Ho dolore alla spalla", .pain),
    ("Estou com dor no joelho", .pain),
    ("¿Cuánta agua debo beber?", .water),
    ("Should I take BCAA?", .supplements),
    ("Estoy estancado en press de banca", .plateau),
    ("¿Cómo gano masa muscular?", .gainMuscle),
    ("How do I bulk up?", .gainMuscle),
    ("¿Es malo entrenar con agujetas?", .soreness),
    ("¿Cómo pierdo grasa y gano músculo a la vez?", .recomp),
    ("How do I lose belly fat?", .bellyFat),
    ("¿Engorda comer de noche?", .lateEating),
    ("Ayer me pasé con la comida en una boda", .cheatMeal),
    ("¿Qué pido en un restaurante?", .eatingOut),
    ("¿Sirve el ayuno intermitente 16:8?", .fasting),
    ("Is intermittent fasting good?", .fasting),
    ("¿Puedo tomar cerveza el fin de semana?", .alcohol),
    ("Quiero comer sano pero barato", .cheapFood),
    ("Tengo mucha ansiedad por el dulce", .cravings),
    ("Qué snacks saludables me recomiendas", .snacks),
    ("Qu'est-ce que je mange au petit déjeuner ?", .breakfast),
    ("¿Cuánto descanso entre series?", .restSets),
    ("How many reps should I do?", .repsWeight),
    ("Come mi riscaldo prima dei pesi?", .warmUp),
    ("¿Es bueno estirar después de entrenar?", .stretching),
    ("¿Cuántos días a la semana debo entrenar?", .trainingDays),
    ("Posso allenarmi a casa senza attrezzi?", .homeWorkout),
    ("Soy principiante, ¿por dónde empiezo?", .beginner),
    ("¿Es mejor hacer cardio o pesas?", .cardio),
    ("Quantos passos devo dar por dia?", .steps),
    ("Pourquoi mon poids change sur la balance ?", .scaleWeight),
    ("No tengo ganas de entrenar, me da pereza", .motivation),
    ("Estou sem motivação", .motivation),
    ("¿Cuántas calorías tiene un plátano?", .foodInfo),
    ("¿Cuánto peso debo perder para estar sano?", nil),
    ("Quiero usar esteroides", .health),
    ("¿Quién ganó el mundial de 2022?", nil),
    ("Hola coach, como estas?", nil),
    ("me siento sin motivación para ir al gym", .motivation),
]
cases += [
    ("Como aumentar fuerza de contacto", .contactStrength),
    ("Quiero mejorar mi agarre para el jiu jitsu", .contactStrength),
    ("Cómo puedo ser más fuerte", .strength),
    ("How do I get stronger?", .strength),
    ("Comment gagner en force ?", .strength),
    ("Come aumentare la forza?", .strength),
    ("Como ganhar força?", .strength),
    ("Cómo mejoro mi explosividad para saltar", .power),
    ("Me canso muy rápido en los combates, cómo gano aguante", .endurance),
    ("Cómo mejoro mi rendimiento en el gym", .generalTraining),
    ("Qué rutina me recomiendas", .generalTraining),
    ("Cómo uso PowerPump", .appHelp),
    ("La respuesta absoluta", nil),
]
cases += [
    ("Hoy solo tengo 30 minutos para entrenar", .shortToday),
    ("I only have 20 minutes today", .shortToday),
    ("Estoy reventado, no puedo con el entreno de hoy", .easyToday),
    ("I'm exhausted", .easyToday),
    ("Hoy no puedo entrenar, mueve el entreno", .moveWorkout),
    ("No me gusta el salmón", .swapMeal),
    ("Cambia la cena por favor", .swapMeal),
    ("Solo tengo mancuernas en casa", .homeWorkout),
    ("Me canso muy rápido en los combates, cómo gano aguante", .endurance),
]
cases += [
    // Exercise library
    ("¿Cómo se hace la sentadilla?", .exerciseHowTo),
    ("Explícame la técnica del peso muerto", .exerciseHowTo),
    ("How do I do a proper push-up?", .exerciseHowTo),
    ("Comment faire le développé couché ?", .exerciseHowTo),
    ("Come si fa lo stacco da terra?", .exerciseHowTo),
    ("Como fazer agachamento corretamente?", .exerciseHowTo),
    ("Alternativa a las dominadas", .exerciseSwap),
    ("What can I do instead of bench press?", .exerciseSwap),
    ("No puedo hacer peso muerto, ¿qué hago en su lugar? otro ejercicio", .exerciseSwap),
    ("Ejercicios para glúteos", .muscleExercises),
    ("¿Cómo trabajo el pecho en casa?", .muscleExercises),
    ("Best exercises for shoulders", .muscleExercises),
    ("Exercícios para pernas", .muscleExercises),
    ("Esercizi per le braccia", .muscleExercises),
    ("Rutina de abdominales", .muscleExercises),
    // Food library
    ("¿Cuánta proteína tiene el huevo?", .foodInfo),
    ("¿Cuántas calorías tiene un plátano?", .foodInfo),
    ("How many calories in an avocado?", .foodInfo),
    ("Combien de protéines dans le poulet ?", .foodInfo),
    ("Quantas calorias tem o arroz?", .foodInfo),
    ("¿El aguacate engorda?", .foodInfo),
    ("¿Cuántas calorías necesito al día?", .calorieNeeds),
    ("How many calories should I eat?", .calorieNeeds),
    // New subjects
    ("¿Los carbohidratos engordan?", .carbs),
    ("¿Es mejor entrenar por la mañana o por la noche?", .trainingTime),
    ("Puedo entrenar con la regla?", .cycle),
    ("Can I work out on my period?", .cycle),
    ("Tengo 15 años, ¿puedo ir al gimnasio?", .teen),
    ("I'm 14 years old, can I lift weights?", .teen),
    ("Tengo 55 años, ¿puedo ganar músculo?", .olderAdult),
    ("J'ai 62 ans, est-ce trop tard ?", .olderAdult),
    ("Tengo 30 minutos para entrenar hoy", .shortToday),
    ("Me dan calambres en las piernas", .cramps),
    ("Llevo meses sin entrenar, ¿cómo vuelvo?", .comeback),
    ("¿Debo llegar al fallo en cada serie?", .failure),
    ("¿Qué es una semana de descarga?", .deload),
    ("Estoy muy estresado con el trabajo", .stress),
    ("¿Cómo registro mi peso en la app?", .appHelp),
    ("No quiero vivir más", .crisis),
    ("I want to kill myself", .crisis),
    // Typos
    ("cuanta protiena necesito", .proteinAmount),
    ("cuanta creatna tomo", .creatine),
    ("tengo agujetsa", .soreness),
    ("me duele mucho la espalda", .pain),
    // Must stay as before
    ("¿Es buena idea entrenar dos veces al día?", .generalTraining),
    ("Exercices pour le dos", .muscleExercises),
    ("¿Qué desayuno hoy?", .eatToday),
    ("hice 100 flexiones", .brag),
    ("I just did my first pull-up!", .brag),
    ("Hoy hice pierna y me duele la rodilla", .pain),
    ("Mi press de banca no sube", .plateau),
    ("How to deal with depression", .stress),
    ("Quiero mejorar mi resistencia en combate", .endurance),
]
var fails = 0
for (q, want) in cases {
    let got = CoachTopic.detect(q)
    let ok = got == want
    if !ok { fails += 1 }
    print(ok ? "  OK  " : "  FALLO", q, "→", got?.rawValue ?? "IA", ok ? "" : "(esperado \(want?.rawValue ?? "IA"))")
}
for (q, first, want) in [("¿Cuánto descanso entre series?", CoachTopic.restSets, nil as CoachTopic?),
                         ("Me duele la rodilla, ¿cómo gano fuerza?", .pain, .strength)] {
    let got = CoachTopic.secondary(q, besides: first)
    if got != want { fails += 1; print("  FALLO segunda", q, "→", got?.rawValue ?? "nada") }
}
print(fails == 0 ? "TODO OK (\(cases.count))" : "\(fails) FALLOS")
for (q, want) in [("¿Cuántas series por semana hago para pecho?", CoachTopic.volume), ("How many sets per week for back?", .volume), ("¿Qué como hoy?", .eatToday)] {
    let got = CoachTopic.detect(q); if got != want { fails += 1 }
    print(got == want ? "  OK  " : "  FALLO", q, "→", got?.rawValue ?? "IA", got?.isCurated == true ? "(fija)" : "")
}
for (q, want) in [("¿Cómo caliento antes de entrenar?", CoachTopic.warmUp), ("Je veux perdre du gras et prendre du muscle", .recomp),
                  ("Quiero bajar grasa sin perder masa muscular", .recomp), ("je suis jeune et je veux faire du sport", nil)] {
    let got = CoachTopic.detect(q); if got != want { fails += 1 }
    print(got == want ? "  OK  " : "  FALLO", q, "→", got?.rawValue ?? "IA")
}
exit(fails == 0 ? 0 : 1)
