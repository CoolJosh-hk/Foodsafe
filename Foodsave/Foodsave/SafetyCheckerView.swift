import SwiftUI

struct SafetyCheckerView: View {
    
    enum PageState {
        case home
        case form
        case analyzing
        case result
    }
    
    @State private var page: PageState = .home
    @State private var riskScore: Int = 0
    @State private var resultText: String = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch page {
            case .home:
                HomePage(page: $page)
                
            case .form:
                FormPage(page: $page,
                         riskScore: $riskScore,
                         resultText: $resultText)
                
            case .analyzing:
                AnalyzingPage(page: $page)
                
            case .result:
                ResultPage(page: $page,
                           score: riskScore,
                           explanation: resultText)
            }
        }
    }
}

struct HomePage: View {
    @Binding var page: SafetyCheckerView.PageState
    
    let tips = [
        "Tip: Bananas with brown spots are ripe, not rotten!",
        "Tip: Slimy meat is often unsafe to consume.",
        "Tip: Best before dates are about quality, not safety."
    ]
    
    var randomTip: String {
        tips.randomElement() ?? tips[0]
    }
    
    var body: some View {
        VStack(spacing: 40) {
            
            Text("Food Safety Checker")
                .font(.title)
                .foregroundColor(.white)
            
            Button(action: {
                page = .form
            }) {
                Text("Start Checking")
                    .padding()
                    .frame(width: 200)
                    .background(Color.green)
                    .foregroundColor(.black)
                    .cornerRadius(10)
            }
            
            Text(randomTip)
                .foregroundColor(.gray)
                .padding()
        }
    }
}

struct FormPage: View {
    
    @Binding var page: SafetyCheckerView.PageState
    @Binding var riskScore: Int
    @Binding var resultText: String
    
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
    
    @State private var useByPastDays = 0
    @State private var bestBeforePastMonths = 0
    
    @State private var storageDays = 0
    @State private var storageTemp = 5
    
    var isPerishable: Bool {
        return !(category == "Snacks" || category == "Beverages") &&
        !(type == "Packaged" || type == "Canned")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                Text("Food")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Picker("Category", selection: $category) {
                    Text("Carbohydrates").tag("Carbohydrates")
                    Text("Vegetables/Fruits").tag("Vegetables/Fruits")
                    Text("Meat").tag("Meat")
                    Text("Dairy").tag("Dairy")
                    Text("Snacks").tag("Snacks")
                    Text("Beverages").tag("Beverages")
                }
                .pickerStyle(MenuPickerStyle())
                
                Toggle("Moldy", isOn: $moldy)
                Toggle("Discoloration", isOn: $discoloration)
                Toggle("Cloudy Liquid", isOn: $cloudy)
                
                Toggle("Sour Smell", isOn: $sour)
                Toggle("Rotten Egg Smell", isOn: $rottenEgg)
                Toggle("Alcoholic Smell", isOn: $alcoholic)
                Toggle("Fishy Smell", isOn: $fishy)
                
                Toggle("Slimy", isOn: $slimy)
                Toggle("Sticky", isOn: $sticky)
                Toggle("Mushy", isOn: $mushy)
                Toggle("Dry/Cracked", isOn: $dry)
                
                Toggle("Leaked/Damaged", isOn: $leaked)
                
                Stepper("Days Stored: \(storageDays)", value: $storageDays, in: 0...30)
                
                Stepper("Storage Temp: \(storageTemp)°C", value: $storageTemp, in: -30...40)
                
                Button("Start Analysis") {
                    analyze()
                    page = .analyzing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        page = .result
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.black)
                .cornerRadius(10)
            }
            .foregroundColor(.white)
            .padding()
        }
    }
    
    func analyze() {
        
        // HARD OVERRIDES
        if (moldy && isPerishable) ||
            rottenEgg ||
            (fishy && category == "Fish") ||
            leaked ||
            (isPerishable && storageTemp > 20 && storageDays > 0) {
            
            riskScore = 100
            resultText = "Severe contamination risk detected."
            return
        }
        
        var score = 0
        
        // APPEARANCE
        if moldy { score += 30 }
        if discoloration { score += 10 }
        if cloudy { score += 10 }
        
        // SMELL
        if sour { score += 15 }
        if alcoholic { score += 10 }
        if fishy { score += 15 }
        
        // TEXTURE
        if slimy { score += 25 }
        if sticky { score += 15 }
        if mushy { score += 10 }
        if dry { score += 5 }
        
        // CATEGORY
        if category == "Dairy" { score += 5 }
        if category == "Meat" { score += 8 }
        
        // STORAGE
        if isPerishable && storageDays > 3 { score += 20 }
        if isPerishable && storageDays > 5 { score += 40 }
        
        if storageTemp >= 5 && storageTemp <= 15 { score += 10 }
        if storageTemp > 15 && storageTemp <= 25 { score += 25 }
        if storageTemp > 25 { score += 40 }
        
        riskScore = min(score, 100)
        
        switch riskScore {
        case 0...25:
            resultText = "Food appears likely safe."
        case 26...55:
            resultText = "Caution advised."
        case 56...80:
            resultText = "High risk of spoilage."
        default:
            resultText = "Discard immediately."
        }
    }
}

struct AnalyzingPage: View {
    @Binding var page: SafetyCheckerView.PageState
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
            Text("Analyzing...")
                .foregroundColor(.white)
        }
    }
}

struct ResultPage: View {
    
    @Binding var page: SafetyCheckerView.PageState
    var score: Int
    var explanation: String
    
    var body: some View {
        VStack(spacing: 30) {
            
            Text("Analysis Results")
                .font(.title)
                .foregroundColor(.white)
            
            Gauge(value: Double(score), in: 0...100) {
                Text("")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(gradient)
            
            Text(explanation)
                .foregroundColor(.white)
            
            Text("This tool provides general guidance only and may not always be accurate. When in doubt, consult a food safety professional or discard the food.")
                .foregroundColor(.gray)
                .font(.footnote)
            
            Button("Back to Safety Checker") {
                page = .home
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.black)
            .cornerRadius(10)
        }
    }
    
    var gradient: Gradient {
        Gradient(colors: [.green, .yellow, .orange, .red])
    }
}
