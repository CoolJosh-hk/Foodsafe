import SwiftUI

struct SafetyCheckerView: View {

    enum PageState {
        case home, form, analyzing, result
    }

    @State private var page: PageState = .home
    @State private var riskScore: Int = 0
    @State private var resultText: String = ""

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            switch page {
            case .home:
                HomePage(page: $page)
            case .form:
                FormPage(page: $page, riskScore: $riskScore, resultText: $resultText)
            case .analyzing:
                AnalyzingPage()
            case .result:
                ResultPage(page: $page, score: riskScore, explanation: resultText)
            }
        }
    }
}

// MARK: - Home

struct HomePage: View {
    @Binding var page: SafetyCheckerView.PageState

    let tips = [
        "Tip: Bananas with brown spots are ripe, not rotten!",
        "Tip: Slimy meat is often unsafe to consume.",
        "Tip: “Best before” is about quality, not safety."
    ]

    var randomTip: String { tips.randomElement() ?? tips[0] }

    var body: some View {
        VStack(spacing: 40) {
            Text("Food Safety Checker")
                .font(.title)
                .foregroundColor(.primary)

            Button {
                page = .form
            } label: {
                Text("Start Checking")
                    .padding()
                    .frame(width: 200)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Text(randomTip)
                .foregroundColor(.secondary)
                .padding()
        }
        .padding()
    }
}

// MARK: - Assessment Model (pure logic)

private struct FoodObservation {
    var category: String
    var type: String

    var moldy: Bool
    var discoloration: Bool
    var cloudy: Bool

    var sour: Bool
    var rottenEgg: Bool
    var alcoholic: Bool
    var fishy: Bool

    var slimy: Bool
    var sticky: Bool
    var mushy: Bool
    var dry: Bool

    var storageMinutesTotal: Int
    var storageTempC: Int

    var leaked: Bool
}

private struct Assessment {
    var score: Int            // 0...100
    var headline: String      // short decision
    var reasons: [String]     // “rules fired”
}

private func isPerishable(category: String, type: String) -> Bool {
    // NOTE (assumption): simple mapping for a prototype to reduce uncertainty-driven waste.
    // - Meat/Dairy/Fruits+Veg are perishable.
    // - Carbohydrates are perishable when “Fresh” or “Opened”.
    // - Snacks/Beverages are usually less perishable unless “Opened”.
    let alwaysPerishable: Set<String> = ["Meat", "Dairy", "Vegetables/Fruits"]
    if alwaysPerishable.contains(category) { return true }

    if category == "Carbohydrates" {
        return type == "Fresh" || type == "Opened (after opening)"
    }

    if category == "Snacks" || category == "Beverages" {
        return type == "Opened (after opening)"
    }

    // Fallback
    return type == "Fresh" || type == "Opened (after opening)"
}

private func assess(_ obs: FoodObservation) -> Assessment {
    var reasons: [String] = []
    let daysStored = obs.storageMinutesTotal / (24 * 60)
    let perishable = isPerishable(category: obs.category, type: obs.type)

    // Key public-health concepts (high level):
    // “Danger zone” roughly 4–60°C; time matters (2 hours, or 1 hour if very hot).
    // We only use this as a conservative hard-stop for perishables.
    let dangerZoneLow = 4
    let dangerZoneHigh = 60
    let hotDayThreshold = 32.0
    let maxHoursOut = (Double(obs.storageTempC) >= hotDayThreshold) ? 1.0 : 2.0

    // Hard-stop rules
    if obs.leaked {
        return Assessment(score: 100,
                          headline: "Discard immediately.",
                          reasons: ["Leaking/damaged packaging can signal contamination."])
    }

    if obs.rottenEgg {
        return Assessment(score: 100,
                          headline: "Discard immediately.",
                          reasons: ["Rotten-egg odor is a strong spoilage/contamination warning sign."])
    }

    if obs.moldy && perishable {
        return Assessment(score: 100,
                          headline: "Discard immediately.",
                          reasons: ["Mold on perishable food is high risk."])
    }

    if perishable,
       obs.storageTempC >= dangerZoneLow,
       obs.storageTempC <= dangerZoneHigh,
       obs.hoursAtRoomTemp > maxHoursOut {
        return Assessment(score: 100,
                          headline: "Discard immediately.",
                          reasons: ["Perishable food stayed in room temperature for over 2 hours"])
    }

    if perishable && daysStored >= 7 {
    return Assessment(
        score: 100,
        headline: "Discard immediately.",
        reasons: ["Perishable food stored over 7 days."]
    )
}
    
    if obs.fishy && obs.category == "Meat" {
        return Assessment(score: 100,
                          headline: "Discard immediately.",
                          reasons: ["Fishy/rancid odor in meat/seafood-like items is a strong warning sign."])
    }

    // Additive heuristic score (quality/spoilage signals)
    var score = 0

    func add(_ points: Int, _ reason: String, if condition: Bool) {
        guard condition else { return }
        score += points
        reasons.append(reason)
    }

    add(30, "Visible mold.", if: obs.moldy)
    add(10, "Unusual discoloration.", if: obs.discoloration)
    add(10, "Cloudy liquid.", if: obs.cloudy)

    add(15, "Sour smell.", if: obs.sour)
    add(10, "Alcoholic smell.", if: obs.alcoholic)
    add(15, "Fishy smell.", if: obs.fishy)

    add(25, "Slimy texture.", if: obs.slimy)
    add(15, "Sticky texture.", if: obs.sticky)
    add(10, "Mushy texture.", if: obs.mushy)
    add(5,  "Dry/cracked texture.", if: obs.dry)

    add(8, "Higher-risk category: Meat.", if: obs.category == "Meat")
    add(5, "Higher-risk category: Dairy.", if: obs.category == "Dairy")

    if perishable {
    if daysStored > 3 {
        let extraDays = daysStored - 3
        score += min(extraDays * 10, 60)
        reasons.append("Stored for \(daysStored) days (perishable).")
    }
}

    if obs.storageTempC > 4 && obs.storageTempC <= 40 {

    let tempRisk = obs.storageTempC - 4   // how far above fridge temp

    // add 2 points per °C above 4°C
    score += min(tempRisk * 2, 70)

    reasons.append("Stored at \(obs.storageTempC)°C (above safe fridge range).")
}

    score = min(score, 100)

    let headline: String
    switch score {
    case 0...25: headline = "Likely safe (based on your inputs)."
    case 26...55: headline = "Caution advised."
    case 56...80: headline = "High risk of spoilage."
    default: headline = "Discard immediately."
    }

    if reasons.isEmpty {
        reasons = ["No strong spoilage signs selected."]
    }

    return Assessment(score: score, headline: headline, reasons: reasons)
}

// MARK: - Form

struct FormPage: View {

    @Binding var page: SafetyCheckerView.PageState
    @Binding var riskScore: Int
    @Binding var resultText: String

    private let categories = ["Carbohydrates", "Vegetables/Fruits", "Meat", "Dairy", "Snacks", "Beverages"]
    private let types = ["Fresh", "Packaged (unopened)", "Canned (unopened)", "Opened (after opening)"]

    @State private var category = ""
    @State private var type = ""

    @State private var moldy = false
    @State private var discoloration = false
    @State private var cloudy = false

    @State private var sour = false
    @State private var rottenEgg = false
    @State private var alcoholic = false
    @State private var fishy = false

    @State private var slimy = false
    @State private var sticky = false
    @State private var mushy = false
    @State private var dry = false

    @State private var leaked = false

    @State private var storageDay = 0
    @State private var storageHour = 0
    @State private var storageMinute = 0
    @State private var storageTemp = 5

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {

                Text("Food Conditions")
                    .font(.title)
                    .foregroundColor(.primary)

                GroupBox("Food Type") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(MenuPickerStyle())

                        Picker("Type", selection: $type) {
                            ForEach(types, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }

                GroupBox("Appearance") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Moldy", isOn: $moldy)
                        Toggle("Discoloration", isOn: $discoloration)
                        Toggle("Cloudy liquid", isOn: $cloudy)
                    }
                }

                GroupBox("Smell") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Sour smell", isOn: $sour)
                        Toggle("Rotten-egg smell", isOn: $rottenEgg)
                        Toggle("Alcoholic smell", isOn: $alcoholic)
                        Toggle("Fishy smell", isOn: $fishy)
                    }
                }

                GroupBox("Texture") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Slimy", isOn: $slimy)
                        Toggle("Sticky", isOn: $sticky)
                        Toggle("Mushy", isOn: $mushy)
                        Toggle("Dry / cracked", isOn: $dry)
                    }
                }


               GroupBox("Storage Details") {

               VStack(alignment: .leading, spacing: 15) {
                   
                   Text("Storage Time")
                   
               HStack {
               Picker("Day", selection: $storageDay) {
                   ForEach(0..<31) { Text("\($0) d").font(.caption) }
               }
               .pickerStyle(.wheel)

               Picker("Hour", selection: $storageHour) {
                  ForEach(0..<24) { Text("\($0) h").font(.caption) }
               }
               .pickerStyle(.wheel)

            Picker("Minute", selection: $storageMinute) {
                ForEach(0..<60) { Text("\($0) m").font(.caption) }
            }
            .pickerStyle(.wheel)
        }
        .frame(height: 120)


        Stepper("Storage Temperature: \(storageTemp)°C",
                value: $storageTemp,
                step = 5,
                in: -30...80)

        Text("Tip: Time at room temperature matters most for perishables.")
            .font(.footnote)
            .foregroundColor(.secondary)
    }
}
                        
        GroupBox("Packaging") {
                    Toggle("Leaking / damaged", isOn: $leaked)
                }

                
                Button("Start Analysis") {
                    analyze()
                    page = .analyzing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        page = .result
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .foregroundColor(.primary)
            .padding()
        }
        .onAppear {
            if category.isEmpty { category = categories[0] }
            if type.isEmpty { type = types[0] }
        }
    }

    func analyze() {
        let totalMinutes =
        storageDay * 24 * 60 +
        storageHour * 60 +
        storageMinute
        let obs = FoodObservation(
            category: category,
            type: type,
            moldy: moldy,
            discoloration: discoloration,
            cloudy: cloudy,
            sour: sour,
            rottenEgg: rottenEgg,
            alcoholic: alcoholic,
            fishy: fishy,
            slimy: slimy,
            sticky: sticky,
            mushy: mushy,
            dry: dry,
            leaked: leaked,
            storageTotalMinutes: storageDays,
            storageTempC: storageTemp,
        )

        let a = assess(obs)
        riskScore = a.score

        // Keep it readable: headline + top reasons (max 4)
        let topReasons = Array(a.reasons.prefix(4))
        if topReasons.isEmpty {
            resultText = a.headline
        } else {
            resultText = a.headline + "\n\nWhy:\n- " + topReasons.joined(separator: "\n- ")
        }
    }
}

// MARK: - Analyzing / Result

struct AnalyzingPage: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
            Text("Analyzing...")
                .foregroundColor(.primary)
        }
        .padding()
    }
}

struct ResultPage: View {

    @Binding var page: SafetyCheckerView.PageState
    var score: Int
    var explanation: String

    var body: some View {
        VStack(spacing: 22) {

            Text("Analysis Results")
                .font(.title)
                .foregroundColor(.primary)

            Gauge(value: Double(score), in: 0...100) { Text("") }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(Gradient(colors: [.green, .yellow, .orange, .red]))

            Text(explanation)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)

            Text("General guidance only. Spoilage signs can help reduce uncertainty, but they can’t guarantee safety (some harmful germs/toxins may have no smell or visible signs). When in doubt, discard or ask a professional.")
                .foregroundColor(.secondary)
                .font(.footnote)
                .padding(.horizontal)

            Button("Back to Safety Checker") {
                page = .home
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding(.vertical)
    }
}
