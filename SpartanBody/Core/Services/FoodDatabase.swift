import Foundation

struct FoodDatabase {
    static let all: [FoodItem] = protein + carbs + fats + vegetables + dairy + fruits + other + extras

    // MARK: - Protein
    static let protein: [FoodItem] = [
        food("chicken_breast",   "Chicken Breast",      .protein,    165, 31.0, 0.0,  3.6),
        food("eggs_whole",       "Eggs (whole)",         .protein,    155, 13.0, 1.1, 11.0),
        food("egg_whites",       "Egg Whites",           .protein,     52, 11.0, 0.7,  0.2),
        food("tuna_canned",      "Tuna (canned)",        .protein,    116, 26.0, 0.0,  1.0),
        food("salmon",           "Salmon",               .protein,    208, 20.0, 0.0, 13.0),
        food("ground_beef_lean", "Ground Beef (lean)",   .protein,    215, 26.0, 0.0, 12.0),
        food("turkey_breast",    "Turkey Breast",        .protein,    135, 30.0, 0.0,  1.0),
        food("shrimp",           "Shrimp",               .protein,     99, 24.0, 0.2,  0.3),
        food("whey_protein",     "Whey Protein",         .protein,    370, 75.0, 8.0,  4.0),
        food("tofu",             "Tofu",                 .protein,     76,  8.0, 1.9,  4.8),
    ]

    // MARK: - Carbs
    static let carbs: [FoodItem] = [
        food("white_rice",       "White Rice (cooked)",  .carbs,      130,  2.7, 28.0,  0.3),
        food("oats",             "Oats",                 .carbs,      389, 17.0, 66.0,  7.0),
        food("sweet_potato",     "Sweet Potato",         .carbs,       86,  1.6, 20.0,  0.1),
        food("whole_bread",      "Whole Wheat Bread",    .carbs,      247, 13.0, 41.0,  4.2),
        food("pasta_cooked",     "Pasta (cooked)",       .carbs,      158,  5.8, 31.0,  0.9),
        food("quinoa_cooked",    "Quinoa (cooked)",      .carbs,      120,  4.4, 21.0,  1.9),
        food("potato",           "Potato",               .carbs,       77,  2.0, 17.0,  0.1),
        food("corn",             "Corn",                 .carbs,       86,  3.3, 19.0,  1.4),
    ]

    // MARK: - Fats
    static let fats: [FoodItem] = [
        food("avocado",          "Avocado",              .fats,       160,  2.0,  9.0, 15.0),
        food("almonds",          "Almonds",              .fats,       579, 21.0, 22.0, 50.0),
        food("peanut_butter",    "Peanut Butter",        .fats,       588, 25.0, 20.0, 50.0),
        food("olive_oil",        "Olive Oil",            .fats,       884,  0.0,  0.0,100.0),
        food("walnuts",          "Walnuts",              .fats,       654, 15.0, 14.0, 65.0),
        food("cashews",          "Cashews",              .fats,       553, 18.0, 30.0, 44.0),
    ]

    // MARK: - Vegetables
    static let vegetables: [FoodItem] = [
        food("broccoli",         "Broccoli",             .vegetables,  34,  2.8,  7.0,  0.4),
        food("spinach",          "Spinach",              .vegetables,  23,  2.9,  3.6,  0.4),
        food("mixed_salad",      "Mixed Salad",          .vegetables,  20,  1.5,  3.0,  0.3),
        food("bell_pepper",      "Bell Pepper",          .vegetables,  31,  1.0,  6.0,  0.3),
        food("cucumber",         "Cucumber",             .vegetables,  16,  0.7,  3.6,  0.1),
        food("tomato",           "Tomato",               .vegetables,  18,  0.9,  3.9,  0.2),
        food("zucchini",         "Zucchini",             .vegetables,  17,  1.2,  3.1,  0.3),
    ]

    // MARK: - Dairy
    static let dairy: [FoodItem] = [
        food("greek_yogurt",     "Greek Yogurt (0%)",    .dairy,       59, 10.0,  3.6,  0.4),
        food("cottage_cheese",   "Cottage Cheese",       .dairy,       98, 11.0,  3.4,  4.3),
        food("milk_whole",       "Whole Milk",           .dairy,       61,  3.2,  4.8,  3.3),
        food("milk_skim",        "Skim Milk",            .dairy,       35,  3.4,  5.0,  0.1),
        food("mozzarella",       "Mozzarella",           .dairy,      280, 28.0,  2.2, 17.0),
        food("cheddar",          "Cheddar",              .dairy,      402, 25.0,  1.3, 33.0),
    ]

    // MARK: - Fruits
    static let fruits: [FoodItem] = [
        food("banana",           "Banana",               .fruits,      89,  1.1, 23.0,  0.3),
        food("apple",            "Apple",                .fruits,      52,  0.3, 14.0,  0.2),
        food("blueberries",      "Blueberries",          .fruits,      57,  0.7, 14.0,  0.3),
        food("orange",           "Orange",               .fruits,      47,  0.9, 12.0,  0.1),
        food("strawberries",     "Strawberries",         .fruits,      32,  0.7,  7.7,  0.3),
        food("mango",            "Mango",                .fruits,      60,  0.8, 15.0,  0.4),
    ]

    // MARK: - Other
    static let other: [FoodItem] = [
        food("protein_bar",      "Protein Bar",          .other,      340, 20.0, 40.0, 10.0),
        food("dark_chocolate",   "Dark Chocolate 70%",   .other,      598,  8.0, 46.0, 43.0),
        food("honey",            "Honey",                .other,      304,  0.3, 82.0,  0.0),
        food("granola",          "Granola",              .other,      489,  9.0, 64.0, 22.0),
    ]

    // MARK: - Extras (+40 foods)

    static let extras: [FoodItem] = [
        // More protein
        food("cod",               "Cod",                  .protein,     82, 18.0,  0.0,  0.7),
        food("tilapia",           "Tilapia",              .protein,    128, 26.0,  0.0,  2.7),
        food("pork_loin",         "Pork Loin",            .protein,    143, 26.0,  0.0,  4.0),
        food("edamame",           "Edamame",              .protein,    121, 11.0,  8.9,  5.2),
        food("cottage_cheese",    "Cottage Cheese",       .protein,     98, 11.0,  3.4,  4.3),
        food("tempeh",            "Tempeh",               .protein,    193, 19.0,  9.4, 11.0),
        food("sardines",          "Sardines (canned)",    .protein,    208, 25.0,  0.0, 11.0),
        // More carbs
        food("white_rice",        "White Rice",           .carbs,      130,  2.7, 28.0,  0.3),
        food("pasta_whole",       "Whole Wheat Pasta",    .carbs,      174,  7.5, 35.0,  1.4),
        food("cornmeal",          "Cornmeal",             .carbs,      362,  8.1, 77.0,  3.6),
        food("bagel",             "Bagel",                .carbs,      270, 10.0, 53.0,  1.7),
        food("pita_bread",        "Pita Bread",           .carbs,      275,  9.1, 55.0,  1.2),
        food("lentils",           "Lentils (cooked)",     .carbs,      116,  9.0, 20.0,  0.4),
        food("chickpeas",         "Chickpeas (cooked)",   .carbs,      164,  8.9, 27.0,  2.6),
        food("corn",              "Corn",                 .carbs,       86,  3.2, 19.0,  1.2),
        // More fats
        food("cashews",           "Cashews",              .fats,       553, 18.0, 30.0, 44.0),
        food("pumpkin_seeds",     "Pumpkin Seeds",        .fats,       446, 19.0, 54.0, 19.0),
        food("coconut_oil",       "Coconut Oil",          .fats,       862,  0.0,  0.0, 100.0),
        food("flaxseeds",         "Flaxseeds",            .fats,       534, 18.0, 29.0, 42.0),
        // More vegetables
        food("kale",              "Kale",                 .vegetables,  35,  2.9,  4.4,  0.5),
        food("zucchini",          "Zucchini",             .vegetables,  17,  1.2,  3.1,  0.3),
        food("bell_pepper",       "Bell Pepper",          .vegetables,  31,  1.0,  6.0,  0.3),
        food("mushrooms",         "Mushrooms",            .vegetables,  22,  3.1,  3.3,  0.3),
        food("asparagus",         "Asparagus",            .vegetables,  20,  2.2,  3.7,  0.1),
        food("peas",              "Green Peas",           .vegetables,  81,  5.4, 14.0,  0.4),
        food("celery",            "Celery",               .vegetables,  16,  0.7,  3.0,  0.2),
        food("cucumber",          "Cucumber",             .vegetables,  15,  0.7,  3.6,  0.1),
        food("beets",             "Beets",                .vegetables,  43,  1.6,  9.6,  0.2),
        // More dairy
        food("cheddar",           "Cheddar Cheese",       .dairy,      402, 25.0,  1.3, 33.0),
        food("mozzarella",        "Mozzarella",           .dairy,      280, 28.0,  3.1, 17.0),
        food("butter",            "Butter",               .dairy,      717,  0.9,  0.1, 81.0),
        food("cream_cheese",      "Cream Cheese",         .dairy,      342,  6.0,  4.1, 34.0),
        // More fruits
        food("watermelon",        "Watermelon",           .fruits,      30,  0.6,  7.6,  0.2),
        food("grapes",            "Grapes",               .fruits,      67,  0.6, 17.0,  0.4),
        food("kiwi",              "Kiwi",                 .fruits,      61,  1.1, 15.0,  0.5),
        food("pineapple",         "Pineapple",            .fruits,      50,  0.5, 13.0,  0.1),
        food("peach",             "Peach",                .fruits,      39,  0.9,  9.5,  0.3),
        // More other
        food("rice_cakes",        "Rice Cakes",           .other,      387,  8.0, 81.0,  3.5),
        food("peanut_butter_pb",  "Peanut Butter",        .other,      588, 25.0, 20.0, 50.0),
        food("hummus",            "Hummus",               .other,      166,  8.0, 14.0,  9.6),
        food("tortilla_wrap",     "Tortilla Wrap",        .other,      300,  7.5, 54.0,  6.0),
        food("sports_drink",      "Sports Drink",         .other,       21,  0.0,  5.2,  0.0),
    ]

    // MARK: - Helper

    private static func food(_ id: String, _ name: String, _ cat: FoodCategory,
                              _ kcal: Double, _ p: Double, _ c: Double, _ f: Double) -> FoodItem {
        FoodItem(id: id, name: name, category: cat,
                 per100g: NutritionInfo(calories: kcal, protein: p, carbs: c, fat: f))
    }

    static func search(_ query: String) -> [FoodItem] {
        guard !query.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}
