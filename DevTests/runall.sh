#!/bin/zsh
# Runs every test suite against the app's current sources.
# Exits 1 if any suite fails to compile, is missing, exits non-zero, or
# prints a failure line; 0 only when everything passes.
SRC="$(cd "$(dirname "$0")" && pwd)"
cd "$SRC/../SpartanBody" || exit 1
T=${TMPDIR:-/tmp}/powerpump-tests; mkdir -p $T/coachtest/matrix $T/coachtest/form $T/live $T/topics $T/ex $T/chips
U=${SIM_UDID:-booted}
SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
SC=(xcrun -sdk iphonesimulator swiftc -target arm64-apple-ios17.0-simulator -sdk "$SDK" -O)
# A test that no longer compiles must not run its old binary.
rm -f $T/coachtest/coachtest $T/coachtest/matrixtest $T/coachtest/formtest $T/live/t $T/topics/t $T/chips/t $T/ex/t
FILES=(Core/Models/FitnessPlanModels.swift Core/Services/CoachAnalyzer.swift Core/Services/WeeklyPlanner.swift Core/Services/DietPlanner.swift Core/Services/LocalCoachService.swift Core/Services/ProgressionEngine.swift Core/Models/WorkoutModels.swift Core/Models/ProgressModels.swift Core/Models/Exercise.swift Core/Services/ExerciseDatabase.swift Core/Models/RecipeModels.swift Core/Services/RecipeDatabase.swift Core/Models/FoodModels.swift Core/Services/FoodDatabase.swift Core/Models/SportActivity.swift Core/Models/UserProfile.swift Core/Services/LanguageManager.swift Core/Services/ProgramStrings.swift Core/Services/WeeklyReviewEngine.swift Core/Services/ExerciseStrings.swift)

FAILED=()

# build <name> <command...>: compiles and prints the full compiler output on error.
build() {
    local name=$1; shift
    local out
    if ! out=$("$@" 2>&1); then
        echo "=== COMPILE ERROR: $name ==="
        echo "$out"
        FAILED+=("$name (compile)")
    fi
}

# run <title> <name> <binary> <filter> <command...>: runs a suite, shows the
# lines matching <filter>, and records a failure if the binary is missing,
# exits non-zero, prints a failure marker, or never prints "TODO OK".
run() {
    local title=$1 name=$2 bin=$3 filter=$4; shift 4
    echo "=== $title ==="
    if [[ ! -x $bin ]]; then
        echo "  FAIL  binario no encontrado: $bin (¿falló la compilación?)"
        FAILED+=("$name (missing)")
        return
    fi
    local out rc
    out=$("$@" 2>&1); rc=$?
    echo "$out" | grep -E "$filter"
    if (( rc != 0 )) || echo "$out" | grep -qE "FAIL|FALLA|FALLO|signal" || ! echo "$out" | grep -q "TODO OK"; then
        echo "  FAIL  $name (exit $rc)"
        FAILED+=("$name")
    fi
}

build coach    "${SC[@]}" -o $T/coachtest/coachtest "${FILES[@]}" "$SRC/coach/main.swift"
build matrix   "${SC[@]}" -o $T/coachtest/matrixtest "${FILES[@]}" "$SRC/matrix/main.swift"
build live     "${SC[@]}" -o $T/live/t Core/Services/VideoFormEngine.swift Core/Services/LiveFormTracker.swift "$SRC/live/main.swift"
build form     "${SC[@]}" -o $T/coachtest/formtest Core/Services/VideoFormEngine.swift "$SRC/form/main.swift"
build topics   swiftc -O -o $T/topics/t Core/Services/CoachTopics.swift "$SRC/chat/main.swift"
if python3 "$SRC/chat/exercises.py" . > $T/ex/main.swift; then
    build exercises swiftc -O -o $T/ex/t Core/Services/CoachTopics.swift $T/ex/main.swift
else
    FAILED+=("exercises (generator)")
fi
if python3 "$SRC/chat/chips.py" Localizable.xcstrings > $T/chips/main.swift; then
    build chips swiftc -O -o $T/chips/t Core/Services/CoachTopics.swift $T/chips/main.swift
else
    FAILED+=("chips (generator)")
fi

run "1. Coach (escenarios)" coach $T/coachtest/coachtest "FAIL|signal|TODO OK|FALLOS" xcrun simctl spawn $U $T/coachtest/coachtest
run "2. Matriz de planes" matrix $T/coachtest/matrixtest "Planes|FALLA|TODO|signal" xcrun simctl spawn $U $T/coachtest/matrixtest
run "3. Análisis de vídeo" form $T/coachtest/formtest "FAIL|TODO|FALLOS|signal" xcrun simctl spawn $U $T/coachtest/formtest
run "4. Temas del chat" topics $T/topics/t "FALLO|TODO" $T/topics/t
run "4b. Botones de sugerencia" chips $T/chips/t "FALLO|TODO" $T/chips/t
run "4c. Preguntar a Spartan por cada ejercicio" exercises $T/ex/t "FALLO|TODO" $T/ex/t
run "5. Corrección en vivo" live $T/live/t "FAIL|TODO|FALLOS|signal" xcrun simctl spawn $U $T/live/t

echo
if (( ${#FAILED} )); then
    echo "FAIL: ${#FAILED} suite(s) failed:"
    printf '  - %s\n' "${FAILED[@]}"
    exit 1
fi
echo "ALL PASS"
