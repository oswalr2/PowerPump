import Foundation

struct RecipeDatabase {
    static let all: [Recipe] = muscleGain + weightLoss + maintenance

    // MARK: - Muscle Gain

    static let muscleGain: [Recipe] = [
        Recipe(
            id: "chicken_rice_bowl",
            name: "Chicken & Rice Bowl",
            goal: .muscleGain,
            emoji: "🍚",
            prepMinutes: 25,
            servings: 1,
            tags: ["High Protein", "Classic", "Meal Prep"],
            ingredients: [
                Ingredient(amount: "200g", name: "Chicken breast"),
                Ingredient(amount: "150g", name: "White rice (cooked)"),
                Ingredient(amount: "1 cup", name: "Broccoli"),
                Ingredient(amount: "1 tbsp", name: "Olive oil"),
                Ingredient(amount: "to taste", name: "Salt, pepper, garlic powder"),
            ],
            steps: [
                "Season chicken breast with salt, pepper, and garlic powder.",
                "Heat olive oil in a pan over medium-high heat.",
                "Cook chicken 6-7 min per side until golden and cooked through. Rest 2 min, then slice.",
                "Steam or microwave broccoli for 3 minutes.",
                "Serve sliced chicken over rice with broccoli on the side.",
            ],
            nutrition: NutritionInfo(calories: 620, protein: 55, carbs: 65, fat: 12)
        ),
        Recipe(
            id: "egg_white_omelette",
            name: "Egg White Omelette",
            goal: .muscleGain,
            emoji: "🍳",
            prepMinutes: 10,
            servings: 1,
            tags: ["High Protein", "Quick", "Low Fat"],
            ingredients: [
                Ingredient(amount: "6 large", name: "Egg whites"),
                Ingredient(amount: "1/2 cup", name: "Spinach"),
                Ingredient(amount: "1/4 cup", name: "Bell pepper, diced"),
                Ingredient(amount: "30g", name: "Mozzarella"),
                Ingredient(amount: "1 tsp", name: "Olive oil"),
            ],
            steps: [
                "Beat egg whites with a pinch of salt until slightly frothy.",
                "Heat oil in a non-stick pan over medium heat.",
                "Pour in egg whites and let set for 1-2 minutes.",
                "Add spinach, pepper, and mozzarella to one half.",
                "Fold over and cook 1 more minute. Serve immediately.",
            ],
            nutrition: NutritionInfo(calories: 220, protein: 32, carbs: 5, fat: 8)
        ),
        Recipe(
            id: "tuna_pasta",
            name: "Tuna Pasta",
            goal: .muscleGain,
            emoji: "🍝",
            prepMinutes: 20,
            servings: 2,
            tags: ["High Protein", "Budget", "Meal Prep"],
            ingredients: [
                Ingredient(amount: "200g", name: "Whole wheat pasta"),
                Ingredient(amount: "2 cans (160g each)", name: "Tuna in water, drained"),
                Ingredient(amount: "1 cup", name: "Cherry tomatoes, halved"),
                Ingredient(amount: "2 tbsp", name: "Olive oil"),
                Ingredient(amount: "2 cloves", name: "Garlic, minced"),
                Ingredient(amount: "to taste", name: "Salt, pepper, chili flakes"),
            ],
            steps: [
                "Cook pasta according to package instructions. Reserve ¼ cup pasta water.",
                "In a pan, sauté garlic in olive oil for 1 minute over medium heat.",
                "Add cherry tomatoes and cook 3-4 minutes until softened.",
                "Add tuna and stir gently to combine.",
                "Toss with drained pasta, adding pasta water if needed. Season and serve.",
            ],
            nutrition: NutritionInfo(calories: 540, protein: 48, carbs: 62, fat: 10)
        ),
        Recipe(
            id: "greek_yogurt_bowl",
            name: "Greek Yogurt Protein Bowl",
            goal: .muscleGain,
            emoji: "🥣",
            prepMinutes: 5,
            servings: 1,
            tags: ["High Protein", "No Cook", "Breakfast"],
            ingredients: [
                Ingredient(amount: "250g", name: "Greek yogurt (0%)"),
                Ingredient(amount: "1 scoop (30g)", name: "Whey protein (vanilla)"),
                Ingredient(amount: "50g", name: "Oats"),
                Ingredient(amount: "1 medium", name: "Banana, sliced"),
                Ingredient(amount: "1 tbsp", name: "Peanut butter"),
                Ingredient(amount: "1 tsp", name: "Honey"),
            ],
            steps: [
                "Mix Greek yogurt with whey protein until smooth.",
                "Stir in oats.",
                "Top with banana slices and a drizzle of peanut butter.",
                "Finish with honey. Serve immediately or refrigerate overnight.",
            ],
            nutrition: NutritionInfo(calories: 580, protein: 52, carbs: 68, fat: 10)
        ),
        Recipe(
            id: "beef_bowl",
            name: "Lean Beef & Sweet Potato Bowl",
            goal: .muscleGain,
            emoji: "🥩",
            prepMinutes: 30,
            servings: 2,
            tags: ["High Protein", "Iron Rich", "Meal Prep"],
            ingredients: [
                Ingredient(amount: "300g", name: "Lean ground beef (90%)"),
                Ingredient(amount: "2 medium", name: "Sweet potatoes"),
                Ingredient(amount: "1 cup", name: "Mixed greens"),
                Ingredient(amount: "1 tbsp", name: "Olive oil"),
                Ingredient(amount: "1 tsp each", name: "Cumin, paprika, garlic powder"),
            ],
            steps: [
                "Pierce sweet potatoes and microwave 8-10 min until tender. Slice open.",
                "Brown ground beef in a pan over medium-high heat, breaking it apart.",
                "Season with cumin, paprika, and garlic powder. Cook until no pink remains.",
                "Serve beef over sweet potato halves with mixed greens on the side.",
            ],
            nutrition: NutritionInfo(calories: 590, protein: 46, carbs: 42, fat: 22)
        ),
        Recipe(
            id: "protein_pancakes",
            name: "Protein Pancakes",
            goal: .muscleGain,
            emoji: "🥞",
            prepMinutes: 15,
            servings: 1,
            tags: ["High Protein", "Breakfast", "Quick"],
            ingredients: [
                Ingredient(amount: "1 scoop (30g)", name: "Whey protein"),
                Ingredient(amount: "50g", name: "Oats"),
                Ingredient(amount: "2 whole", name: "Eggs"),
                Ingredient(amount: "1/2 medium", name: "Banana"),
                Ingredient(amount: "1/2 tsp", name: "Baking powder"),
                Ingredient(amount: "splash", name: "Milk"),
            ],
            steps: [
                "Blend oats into flour. Mash banana.",
                "Mix all ingredients until a smooth batter forms. Add milk if too thick.",
                "Heat a non-stick pan over medium heat with a little cooking spray.",
                "Pour small circles of batter. Cook 2-3 min per side until golden.",
                "Serve with berries or a drizzle of honey.",
            ],
            nutrition: NutritionInfo(calories: 480, protein: 42, carbs: 48, fat: 12)
        ),
    ]

    // MARK: - Weight Loss

    static let weightLoss: [Recipe] = [
        Recipe(
            id: "grilled_chicken_salad",
            name: "Grilled Chicken Salad",
            goal: .weightLoss,
            emoji: "🥗",
            prepMinutes: 15,
            servings: 1,
            tags: ["Low Calorie", "High Protein", "Quick"],
            ingredients: [
                Ingredient(amount: "150g", name: "Chicken breast"),
                Ingredient(amount: "2 cups", name: "Mixed greens"),
                Ingredient(amount: "1/2 cup", name: "Cherry tomatoes"),
                Ingredient(amount: "1/4", name: "Cucumber, sliced"),
                Ingredient(amount: "1 tbsp", name: "Olive oil + lemon juice"),
                Ingredient(amount: "to taste", name: "Salt, pepper, oregano"),
            ],
            steps: [
                "Season chicken and grill or pan-sear 6 min per side. Let rest, then slice.",
                "Arrange greens, tomatoes, and cucumber in a bowl.",
                "Top with sliced chicken.",
                "Drizzle with olive oil and lemon juice. Season and toss.",
            ],
            nutrition: NutritionInfo(calories: 310, protein: 38, carbs: 10, fat: 12)
        ),
        Recipe(
            id: "tuna_salad_wrap",
            name: "Tuna Salad Lettuce Wraps",
            goal: .weightLoss,
            emoji: "🥬",
            prepMinutes: 8,
            servings: 1,
            tags: ["Low Carb", "No Cook", "Quick"],
            ingredients: [
                Ingredient(amount: "1 can (160g)", name: "Tuna in water, drained"),
                Ingredient(amount: "2 tbsp", name: "Greek yogurt (instead of mayo)"),
                Ingredient(amount: "1 stalk", name: "Celery, diced"),
                Ingredient(amount: "1 tbsp", name: "Dijon mustard"),
                Ingredient(amount: "4 large", name: "Romaine lettuce leaves"),
                Ingredient(amount: "to taste", name: "Salt, pepper, lemon juice"),
            ],
            steps: [
                "Mix tuna, Greek yogurt, celery, mustard, and lemon juice in a bowl.",
                "Season with salt and pepper.",
                "Spoon mixture into lettuce leaves.",
                "Fold and eat like a taco.",
            ],
            nutrition: NutritionInfo(calories: 220, protein: 35, carbs: 6, fat: 4)
        ),
        Recipe(
            id: "veggie_omelette",
            name: "Veggie Omelette",
            goal: .weightLoss,
            emoji: "🫑",
            prepMinutes: 12,
            servings: 1,
            tags: ["Low Calorie", "Vegetarian", "Quick"],
            ingredients: [
                Ingredient(amount: "3 whole", name: "Eggs"),
                Ingredient(amount: "1/2 cup", name: "Spinach"),
                Ingredient(amount: "1/4 cup", name: "Mushrooms, sliced"),
                Ingredient(amount: "1/4 cup", name: "Tomato, diced"),
                Ingredient(amount: "1 tsp", name: "Olive oil"),
                Ingredient(amount: "to taste", name: "Salt, pepper, herbs"),
            ],
            steps: [
                "Sauté mushrooms and tomato in olive oil over medium heat for 3 min.",
                "Add spinach and cook until wilted.",
                "Beat eggs with salt and pepper. Pour over vegetables.",
                "Let set on the bottom, then fold over. Cook 1 more minute.",
            ],
            nutrition: NutritionInfo(calories: 280, protein: 22, carbs: 6, fat: 18)
        ),
        Recipe(
            id: "salmon_zucchini",
            name: "Salmon & Zucchini Noodles",
            goal: .weightLoss,
            emoji: "🐟",
            prepMinutes: 20,
            servings: 1,
            tags: ["Low Carb", "Omega-3", "Gourmet"],
            ingredients: [
                Ingredient(amount: "150g", name: "Salmon fillet"),
                Ingredient(amount: "2 medium", name: "Zucchini (spiralized or sliced thin)"),
                Ingredient(amount: "2 cloves", name: "Garlic, minced"),
                Ingredient(amount: "1 tbsp", name: "Olive oil"),
                Ingredient(amount: "1/2", name: "Lemon (juice + zest)"),
                Ingredient(amount: "to taste", name: "Salt, pepper, dill"),
            ],
            steps: [
                "Season salmon with salt, pepper, and lemon zest.",
                "Sear salmon in olive oil 4 min per side. Remove and flake.",
                "In the same pan, sauté garlic 30 seconds. Add zucchini noodles.",
                "Cook zucchini 2-3 min. Add lemon juice and dill.",
                "Plate zucchini, top with flaked salmon.",
            ],
            nutrition: NutritionInfo(calories: 350, protein: 34, carbs: 10, fat: 18)
        ),
        Recipe(
            id: "turkey_soup",
            name: "Turkey & Vegetable Soup",
            goal: .weightLoss,
            emoji: "🍲",
            prepMinutes: 35,
            servings: 3,
            tags: ["Low Calorie", "Meal Prep", "Filling"],
            ingredients: [
                Ingredient(amount: "300g", name: "Turkey breast, diced"),
                Ingredient(amount: "2 cups", name: "Broccoli florets"),
                Ingredient(amount: "2 medium", name: "Carrots, sliced"),
                Ingredient(amount: "1 stalk", name: "Celery, chopped"),
                Ingredient(amount: "1L", name: "Chicken broth (low sodium)"),
                Ingredient(amount: "1 tsp each", name: "Thyme, garlic powder, onion powder"),
            ],
            steps: [
                "Bring broth to a boil in a large pot.",
                "Add turkey, carrots, and celery. Simmer 15 minutes.",
                "Add broccoli and season with thyme, garlic, and onion powder.",
                "Simmer 10 more minutes until vegetables are tender.",
                "Adjust seasoning and serve hot.",
            ],
            nutrition: NutritionInfo(calories: 260, protein: 36, carbs: 14, fat: 4)
        ),
    ]

    // MARK: - Maintenance

    static let maintenance: [Recipe] = [
        Recipe(
            id: "overnight_oats",
            name: "Overnight Oats",
            goal: .maintenance,
            emoji: "🌙",
            prepMinutes: 5,
            servings: 1,
            tags: ["Meal Prep", "Breakfast", "No Cook"],
            ingredients: [
                Ingredient(amount: "80g", name: "Oats"),
                Ingredient(amount: "200ml", name: "Milk (or plant milk)"),
                Ingredient(amount: "100g", name: "Greek yogurt"),
                Ingredient(amount: "1 tbsp", name: "Chia seeds"),
                Ingredient(amount: "1 tbsp", name: "Honey"),
                Ingredient(amount: "1/2 cup", name: "Mixed berries"),
            ],
            steps: [
                "Combine oats, milk, Greek yogurt, chia seeds, and honey in a jar.",
                "Stir well. Cover and refrigerate overnight (at least 6 hours).",
                "In the morning, top with mixed berries.",
                "Enjoy cold straight from the jar.",
            ],
            nutrition: NutritionInfo(calories: 450, protein: 20, carbs: 70, fat: 8)
        ),
        Recipe(
            id: "sweet_potato_salmon",
            name: "Sweet Potato & Salmon",
            goal: .maintenance,
            emoji: "🍠",
            prepMinutes: 35,
            servings: 2,
            tags: ["Balanced", "Omega-3", "Meal Prep"],
            ingredients: [
                Ingredient(amount: "2 fillets (150g each)", name: "Salmon"),
                Ingredient(amount: "2 large", name: "Sweet potatoes"),
                Ingredient(amount: "1 cup", name: "Broccoli"),
                Ingredient(amount: "2 tbsp", name: "Olive oil"),
                Ingredient(amount: "1 tsp each", name: "Paprika, garlic powder"),
                Ingredient(amount: "to taste", name: "Salt, pepper, lemon"),
            ],
            steps: [
                "Preheat oven to 200°C. Cube sweet potatoes, toss with 1 tbsp oil and paprika.",
                "Roast sweet potatoes 25-30 min, flipping halfway.",
                "Season salmon with garlic, salt, and pepper. Pan-sear 4 min per side.",
                "Steam broccoli 4 minutes.",
                "Plate with a squeeze of lemon over the salmon.",
            ],
            nutrition: NutritionInfo(calories: 520, protein: 38, carbs: 44, fat: 20)
        ),
        Recipe(
            id: "quinoa_bowl",
            name: "Rainbow Quinoa Bowl",
            goal: .maintenance,
            emoji: "🌈",
            prepMinutes: 20,
            servings: 2,
            tags: ["Balanced", "Vegetarian", "Colorful"],
            ingredients: [
                Ingredient(amount: "150g", name: "Quinoa (dry)"),
                Ingredient(amount: "1/2", name: "Avocado, sliced"),
                Ingredient(amount: "1 cup", name: "Cherry tomatoes"),
                Ingredient(amount: "1 cup", name: "Cucumber, diced"),
                Ingredient(amount: "100g", name: "Chickpeas (canned, drained)"),
                Ingredient(amount: "2 tbsp", name: "Lemon-tahini dressing"),
            ],
            steps: [
                "Cook quinoa according to package (usually 2:1 water ratio, 15 min).",
                "Fluff quinoa with a fork and let cool slightly.",
                "Arrange quinoa in bowls and top with avocado, tomatoes, cucumber, and chickpeas.",
                "Drizzle with lemon-tahini dressing and serve.",
            ],
            nutrition: NutritionInfo(calories: 480, protein: 18, carbs: 62, fat: 16)
        ),
        Recipe(
            id: "avocado_eggs_toast",
            name: "Avocado & Eggs Toast",
            goal: .maintenance,
            emoji: "🥑",
            prepMinutes: 10,
            servings: 1,
            tags: ["Quick", "Breakfast", "Healthy Fats"],
            ingredients: [
                Ingredient(amount: "2 slices", name: "Whole wheat bread, toasted"),
                Ingredient(amount: "1 medium", name: "Avocado"),
                Ingredient(amount: "2 whole", name: "Eggs (poached or fried)"),
                Ingredient(amount: "1/4 tsp", name: "Chili flakes"),
                Ingredient(amount: "to taste", name: "Salt, pepper, lemon juice"),
            ],
            steps: [
                "Toast bread until golden.",
                "Mash avocado with salt, pepper, and a squeeze of lemon.",
                "Poach or fry eggs to your liking.",
                "Spread avocado over toast and top with eggs.",
                "Finish with chili flakes.",
            ],
            nutrition: NutritionInfo(calories: 440, protein: 20, carbs: 38, fat: 24)
        ),
        Recipe(
            id: "stir_fry_tofu",
            name: "Tofu Stir-Fry",
            goal: .maintenance,
            emoji: "🥦",
            prepMinutes: 20,
            servings: 2,
            tags: ["Vegetarian", "Quick", "Balanced"],
            ingredients: [
                Ingredient(amount: "250g", name: "Firm tofu, cubed"),
                Ingredient(amount: "1 cup", name: "Broccoli florets"),
                Ingredient(amount: "1 cup", name: "Bell pepper, sliced"),
                Ingredient(amount: "150g", name: "White rice (cooked)"),
                Ingredient(amount: "2 tbsp", name: "Soy sauce (low sodium)"),
                Ingredient(amount: "1 tbsp", name: "Sesame oil"),
                Ingredient(amount: "1 tsp", name: "Ginger, grated"),
            ],
            steps: [
                "Pat tofu dry and cut into cubes.",
                "Pan-fry tofu in sesame oil over high heat until golden on all sides, ~8 min.",
                "Add broccoli and bell pepper. Stir-fry 4 minutes.",
                "Add soy sauce and ginger. Toss for 1 minute.",
                "Serve over rice.",
            ],
            nutrition: NutritionInfo(calories: 420, protein: 22, carbs: 48, fat: 14)
        ),
    ]
}
