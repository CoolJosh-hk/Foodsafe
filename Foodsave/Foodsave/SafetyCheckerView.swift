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
    var foodName: String

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

private func isPerishable(type: String) -> Bool {
    if type == "Frozen" {
        return false
    }
    if type == "Packaged/Canned (unopened)" {
        return false
    }
    // Raw, Cooked, Opened → perishable
    return true
}

private func assess(_ obs: FoodObservation) -> Assessment {
    var reasons: [String] = []
    let daysStored = obs.storageMinutesTotal / (24 * 60)
    let perishable = isPerishable(type: obs.type)
    let seafood = ["Fish", "Shrimp", "Crab", "Lobster", "Mussels", "Clams", "Squid/Octopus"]
    let shellfish = ["Shrimp", "Crab", "Lobster", "Mussels", "Clams"]
    let poultry = ["Chicken", "Turkey", "Duck"]

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

    //Danger Zone = 15-60C (above room temp) and > 2h
    if perishable &&
       obs.storageTempC > 15 &&
       obs.storageTempC <= 60 &&
       obs.storageMinutesTotal > 120 {
        return Assessment(score: 100,
                          headline: "Discard immediately.",
                          reasons: ["Perishable food stayed in room temperature for over 2 hours"])
    }


    if obs.type == "Cooked/Baked" && perishable && daysStored > 4 {
        return Assessment(
            score: 100,
            headline: "Discard immediately.",
            reasons: ["Cooked food stored over 4 days."]
        )
    }

    if perishable && daysStored >= 7 {
    return Assessment(
        score: 100,
        headline: "Discard immediately.",
        reasons: ["Perishable food stored over 7 days."]
    )
}
    
    if seafood.contains(obs.foodName) && obs.fishy && perishable {
        return Assessment(
        score: 100,
        headline: "Discard immediately.",
        reasons: ["Strong fishy smell is a clear spoilage sign for fish."]
    )
}

    if shellfish.contains(obs.foodName) && (obs.fishy || obs.sour || obs.rottenEgg || obs.alcoholic) && perishable {
        return Assessment(
        score: 100,
        headline: "Discard immediately.",
        reasons: ["Shellfish with abnormal odor is unsafe."]
    )
}

    if poultry.contains(obs.foodName) &&
   (obs.slimy || obs.sour) {

    return Assessment(
        score: 100,
        headline: "Discard immediately.",
        reasons: ["Raw poultry with slime or sour smell indicates high spoilage risk."]
    )
}

    if obs.foodName == "Rice" &&
   obs.type == "Cooked/Baked" &&
   obs.storageTempC >= 15 &&
   obs.storageMinutesTotal > 120 {

    return Assessment(
        score: 100,
        headline: "Discard immediately.",
        reasons: ["Cooked rice left at room temperature over 2 hours can be unsafe."]
    )
}

    
    if obs.foodName == "Milk" &&
   obs.sour {

    return Assessment(
        score: 100,
        headline: "Discard immediately.",
        reasons: ["Sour smell indicates milk spoilage."]
    )
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
    add(15, "Strong fishy smell.", if: obs.fishy)

    add(25, "Slimy texture.", if: obs.slimy)
    add(15, "Sticky texture.", if: obs.sticky)
    add(10, "Mushy texture.", if: obs.mushy)
    add(5,  "Dry/cracked texture.", if: obs.dry)

    add(8, "Higher-risk category: Meat.", if: obs.category == "Meat")
    add(5, "Higher-risk category: Dairy.", if: obs.category == "Dairy")
    add(5, "Higher-risk state: Raw/Fresh.", if: obs.type == "Raw/Fresh")
    add(8, "Higher-risk state: Cooked/Baked.", if: obs.type == "Cooked/Baked")

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

    private let categories = ["Carbohydrates", "Vegetables", "Fruit", "Meat", "Dairy", "Snacks", "Beverages"]
    private let types = ["Raw/Fresh", "Cooked/Baked", "Packaged/Canned (unopened)", "Frozen", "Opened"]
    private let foodOptions: [String: [String]] = [
    "Carbohydrates": ["Bread","Buns", "Rice", "Pasta", "Noodles", "Oatmeal", "Corn", "Potato", "Barley", "Cereal", "Others"],
    "Vegetables": ["Lettuce", "Spinach", "Kale", "Cabbage", "Broccoli", "Choy Sum", "Carrot", "Tomato", "Cucumber", "Zucchini", "Eggplant", "Pepper", "Onion", "Garlic", "Pumpkin", "Radish", "Green Beans", "Peas", "Corn", "Mushroom", "Bok choy", "Others"],
    "Fruit": ["Apple", "Banana", "Orange", "Lemon", "Lime", "Mango", "Pineapple", "Watermelon", "Grapes", "Strawberry", "Berries", "Cherry", "Peach", "Plum", "Pear", "Kiwi", "Dragon fruit", "Coconut", "Avocado", "Fig", "Others"],
    "Meat": ["Chicken", "Beef", "Pork", "Turkey", "Duck", "Goose", "Venison", "Rabbit", "Quail", "Fish", "Shrimp", "Crab", "Lobster", "Mussels", "Clams", "Squid/Octopus", "Others"],
    "Dairy": ["Cheese", "Yogurt", "Butter", "Cream", "Others"],
    "Snacks": ["Potato chips", "Chocolate", "Cake", "Lollipop", "Ice-cream", "Popsicle", "Popcorn", "Pretzels", "Crackers", "Bars (Protein, chocolate etc.)", "Candy", "Gummy bears", "Marshmallows", "Cookies", "Biscuits", "Brownies", "Cupcakes", "Muffins", "Donuts", "Pudding", "Jelly", "Nuts", "Seaweed snacks", "Beef jerky", "Dried fruit", "Others"],
    "Beverages": ["Coca-cola", "Juice", "Tea", "Coffee", "Energy drink", "Smoothie", "Milk", "Chocolate milk", "Soy milk", "Coconut water", "Wine", "Cocktail", "Others"]
    ]
    
    @State private var category = ""
    @State private var type = ""
    @State private var selectedFood = ""
    @State private var isFoodExpanded = false
    
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
            

                GroupBox("Category") {
    VStack(alignment: .leading, spacing: 12) {

        // Category Picker
        Picker("Category", selection: $category) {
            ForEach(categories, id: \.self) { Text($0).tag($0) }
        }
        .pickerStyle(MenuPickerStyle())

        // Food Dropdown
        DisclosureGroup(
            selectedFood.isEmpty ? "Select Food" : selectedFood,
            isExpanded: $isFoodExpanded
        ) {

            if let foods = foodOptions[category] {
                ForEach(foods, id: \.self) { food in
                    Button(food) {
                        selectedFood = food
                        isFoodExpanded = false   // auto collapse
                    }
                    .padding(.vertical, 4)
                }
            }
        }
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
                in: -30...80,
                step: 5)

        Text("Tip: Time at room temperature matters most for perishables.")
            .font(.footnote)
            .foregroundColor(.secondary)
    }
}
                        
        GroupBox("Packaging") {
                    Toggle("Leaking / damaged", isOn: $leaked)
                }

                
                Button("Start Analysis") {
                    if selectedFood.isEmpty {
        resultText = "Please select a specific food before analysis."
        page = .result
        return
    }
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
}
    .onChange(of: category) { newValue in
                selectedFood = ""
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
            foodName: selectedFood,
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
            storageMinutesTotal: totalMinutes,
            storageTempC: storageTemp,
            leaked: leaked
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
