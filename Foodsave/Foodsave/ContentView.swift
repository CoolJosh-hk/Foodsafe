import SwiftUI
import Combine

// MARK: - Enums & Models

enum GameState {
    case startScreen
    case playing
    case feedback
    case gameOver
}

enum ExpiryType: String {
    case useBy = "Use By"
    case bestBefore = "Best Before"
    case sellBy = "Sell By"
    case expiresOn = "Expires On"
}

enum ActionType {
    case keep
    case dispose
}

struct FoodItem: Identifiable {
    let id = UUID()
    let name: String
    let sfSymbolName: String
    let symbolColor: Color
    let expiryType: ExpiryType
    let daysOffset: Int
    let correctAction: ActionType
    let explanation: String
    
    var formattedDateString: String {
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: daysOffset, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: targetDate)
    }
}

struct LeaderboardEntry: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let score: Int
    let isCurrentUser: Bool
}

// MARK: - Game Manager

class GameManager: ObservableObject {
    @Published var state: GameState = .startScreen
    @Published var score: Int = 0
    @Published var timeRemaining: Int = 60
    @Published var currentItem: FoodItem?
    @Published var isCorrectLastAnswer: Bool = false
    @Published var leaderboard: [LeaderboardEntry] = []
    
    // Hardcoded mock database
    private let allItems: [FoodItem] = [
        FoodItem(name: "Milk", sfSymbolName: "drop.fill", symbolColor: .blue, expiryType: .useBy, daysOffset: -2, correctAction: .dispose, explanation: "Never consume dairy past its 'Use By' date due to bacterial growth risks."),
        FoodItem(name: "Canned Beans", sfSymbolName: "cylinder.split.1x2", symbolColor: .gray, expiryType: .bestBefore, daysOffset: -30, correctAction: .keep, explanation: "'Best Before' indicates peak quality. Canned goods are safe long after this date."),
        FoodItem(name: "Fresh Chicken", sfSymbolName: "bird.fill", symbolColor: .orange, expiryType: .useBy, daysOffset: 1, correctAction: .keep, explanation: "It is before the 'Use By' date, so it is safe to cook and eat if stored properly."),
        FoodItem(name: "Eggs", sfSymbolName: "oval.fill", symbolColor: .yellow, expiryType: .bestBefore, daysOffset: -5, correctAction: .keep, explanation: "Eggs are often safe for weeks past their 'Best Before' date if refrigerated."),
        FoodItem(name: "Yogurt", sfSymbolName: "cup.and.saucer.fill", symbolColor: .purple, expiryType: .sellBy, daysOffset: -2, correctAction: .keep, explanation: "'Sell By' is for stores. Yogurt is usually safe 1-2 weeks past this date."),
        FoodItem(name: "Ground Beef", sfSymbolName: "circle.hexagongrid.fill", symbolColor: .red, expiryType: .useBy, daysOffset: -1, correctAction: .dispose, explanation: "Minced meats spoil quickly and are dangerous past their 'Use By' date."),
        FoodItem(name: "Dry Pasta", sfSymbolName: "lines.measurement.horizontal", symbolColor: .yellow, expiryType: .bestBefore, daysOffset: -180, correctAction: .keep, explanation: "Dry pasta lasts indefinitely. 'Best Before' is just for optimal texture."),
        FoodItem(name: "Spinach", sfSymbolName: "leaf.fill", symbolColor: .green, expiryType: .useBy, daysOffset: 0, correctAction: .keep, explanation: "Today is the 'Use By' date, so it is still safe to consume today."),
        FoodItem(name: "Bread", sfSymbolName: "square.grid.2x2.fill", symbolColor: .brown, expiryType: .bestBefore, daysOffset: -4, correctAction: .keep, explanation: "Unless you see mold, bread is safe past its 'Best Before' date (it just goes stale)."),
        FoodItem(name: "Raw Fish", sfSymbolName: "fish.fill", symbolColor: .cyan, expiryType: .useBy, daysOffset: -1, correctAction: .dispose, explanation: "Seafood is highly perishable. Dispose immediately if past 'Use By'."),
        FoodItem(name: "Hard Cheese", sfSymbolName: "rectangle.roundedbottom", symbolColor: .orange, expiryType: .bestBefore, daysOffset: -14, correctAction: .keep, explanation: "Hard cheeses are safe well past 'Best Before'. You can even cut off surface mold safely."),
        FoodItem(name: "Deli Meat", sfSymbolName: "rectangle.roundedtop", symbolColor: .pink, expiryType: .useBy, daysOffset: -3, correctAction: .dispose, explanation: "Deli meats carry high Listeria risk past their 'Use By' date."),
        FoodItem(name: "Canned Soup", sfSymbolName: "cup.and.saucer", symbolColor: .red, expiryType: .bestBefore, daysOffset: -365, correctAction: .keep, explanation: "Properly stored canned goods are practically immortal and safe to eat."),
        FoodItem(name: "Pre-cut Apples", sfSymbolName: "apple.logo", symbolColor: .green, expiryType: .useBy, daysOffset: -2, correctAction: .dispose, explanation: "Pre-cut produce has a high surface area for bacteria. Respect the 'Use By' date."),
        FoodItem(name: "Honey", sfSymbolName: "drop.triangle", symbolColor: .yellow, expiryType: .bestBefore, daysOffset: -1000, correctAction: .keep, explanation: "Honey is naturally antimicrobial and essentially never expires.")
    ]
    
    func startGame() {
        score = 0
        timeRemaining = 60
        nextItem()
        state = .playing
    }
    
    func nextItem() {
        currentItem = allItems.randomElement()
    }
    
    func submitAnswer(action: ActionType) {
        guard let item = currentItem else { return }
        
        if action == item.correctAction {
            score += 10
            isCorrectLastAnswer = true
        } else {
            isCorrectLastAnswer = false
        }
        
        state = .feedback
    }
    
    func continuePlaying() {
        if timeRemaining <= 0 {
            endGame()
        } else {
            nextItem()
            state = .playing
        }
    }
    
    func tick() {
        if state == .playing && timeRemaining > 0 {
            timeRemaining -= 1
            if timeRemaining == 0 {
                endGame()
            }
        }
    }
    
    func endGame() {
        state = .gameOver
        let currentHighScore = UserDefaults.standard.integer(forKey: "FoodsaveHighScore")
        if score > currentHighScore {
            UserDefaults.standard.set(score, forKey: "FoodsaveHighScore")
        }
        generateLeaderboard()
    }
    
    private func generateLeaderboard() {
        let savedHighScore = UserDefaults.standard.integer(forKey: "FoodsaveHighScore")
        
        var mockEntries = [
            LeaderboardEntry(name: "ChefGordon", score: 250, isCurrentUser: false),
            LeaderboardEntry(name: "SafeEats", score: 210, isCurrentUser: false),
            LeaderboardEntry(name: "Foodie99", score: 180, isCurrentUser: false),
            LeaderboardEntry(name: "FridgeMaster", score: 160, isCurrentUser: false),
            LeaderboardEntry(name: "SnackKing", score: 140, isCurrentUser: false),
            LeaderboardEntry(name: "AppleLover", score: 120, isCurrentUser: false),
            LeaderboardEntry(name: "Healthy101", score: 100, isCurrentUser: false),
            LeaderboardEntry(name: "KitchenPro", score: 80, isCurrentUser: false),
            LeaderboardEntry(name: "LeftoverHero", score: 60, isCurrentUser: false),
            LeaderboardEntry(name: "Newbie", score: 30, isCurrentUser: false)
        ]
        
        mockEntries.append(LeaderboardEntry(name: "You (High Score)", score: savedHighScore, isCurrentUser: true))
        mockEntries.sort { $0.score > $1.score }
        
        leaderboard = Array(mockEntries.prefix(10))
    }
}

// MARK: - Main Content View

public struct ContentView: View {
    @StateObject private var gameManager = GameManager()
    @AppStorage("FoodsaveHighScore") private var highScore: Int = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            switch gameManager.state {
            case .startScreen:
                StartView(gameManager: gameManager)
            case .playing:
                PlayingView(gameManager: gameManager)
            case .feedback:
                FeedbackView(gameManager: gameManager)
            case .gameOver:
                GameOverView(gameManager: gameManager, highScore: highScore)
            }
        }
        .onReceive(timer) { _ in
            gameManager.tick()
        }
        .animation(.easeInOut, value: gameManager.state)
    }
}

// MARK: - Subviews

struct StartView: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "trash.slash.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .shadow(radius: 5)
            
            Text("Foodsave")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundColor(.primary)
            
            VStack(spacing: 15) {
                Text("60 Seconds.")
                    .font(.headline)
                Text("Save the good food, dump the bad.")
                Text("Know the difference between 'Use By', 'Best Before', and 'Sell By' to maximize your score!")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                gameManager.startGame()
            }) {
                Text("Start Game")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
                    .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
    }
}

struct PlayingView: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        VStack {
            // Top UI
            HStack {
                VStack(alignment: .leading) {
                    Text("Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("00:\(String(format: "%02d", gameManager.timeRemaining))")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundColor(gameManager.timeRemaining <= 10 ? .red : .primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(gameManager.score)")
                        .font(.title2.bold())
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(15)
            .padding(.horizontal)
            .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
            
            Spacer()
            
            // Center UI
            if let item = gameManager.currentItem {
                VStack(spacing: 20) {
                    Image(systemName: item.sfSymbolName)
                        .font(.system(size: 100))
                        .foregroundColor(item.symbolColor)
                        .shadow(radius: 5)
                    
                    Text(item.name)
                        .font(.largeTitle.bold())
                    
                    VStack(spacing: 5) {
                        Text(item.expiryType.rawValue.uppercased())
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .tracking(2)
                        
                        Text(item.formattedDateString)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(item.daysOffset < 0 ? .red : .primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(10)
                }
                .padding(30)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(25)
                .padding(.horizontal)
                .shadow(color: .black.opacity(0.1), radius: 15, y: 10)
            }
            
            Spacer()
            
            // Bottom UI
            HStack(spacing: 20) {
                Button(action: {
                    gameManager.submitAnswer(action: .keep)
                }) {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 30))
                        Text("Keep")
                            .font(.title3.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.green)
                    .cornerRadius(20)
                    .shadow(color: .green.opacity(0.3), radius: 10, y: 5)
                }
                
                Button(action: {
                    gameManager.submitAnswer(action: .dispose)
                }) {
                    VStack {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 30))
                        Text("Dispose")
                            .font(.title3.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.red)
                    .cornerRadius(20)
                    .shadow(color: .red.opacity(0.3), radius: 10, y: 5)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

struct FeedbackView: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: gameManager.isCorrectLastAnswer ? "checkmark.seal.fill" : "xmark.octagon.fill")
                .font(.system(size: 100))
                .foregroundColor(gameManager.isCorrectLastAnswer ? .green : .red)
                .shadow(radius: 5)
            
            Text(gameManager.isCorrectLastAnswer ? "Correct!" : "Incorrect!")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(gameManager.isCorrectLastAnswer ? .green : .red)
            
            if let item = gameManager.currentItem {
                Text(item.explanation)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(15)
                    .padding(.horizontal, 20)
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
            }
            
            Button(action: {
                gameManager.continuePlaying()
            }) {
                Text("Next Item")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
                    .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
    }
}

struct GameOverView: View {
    @ObservedObject var gameManager: GameManager
    let highScore: Int
    
    var body: some View {
        VStack {
            Text("Game Over")
                .font(.largeTitle.bold())
                .padding(.top, 40)
            
            HStack(spacing: 40) {
                VStack {
                    Text("Score")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("\(gameManager.score)")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(.blue)
                }
                
                VStack {
                    Text("Best")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("\(max(gameManager.score, highScore))")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(.orange)
                }
            }
            .padding()
            
            Text("Global Leaderboard")
                .font(.headline)
                .padding(.top)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(gameManager.leaderboard.enumerated()), id: \.element.id) { index, entry in
                        HStack {
                            Text("#\(index + 1)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .frame(width: 35, alignment: .leading)
                            
                            Text(entry.name)
                                .fontWeight(entry.isCurrentUser ? .bold : .regular)
                                .foregroundColor(entry.isCurrentUser ? .blue : .primary)
                            
                            Spacer()
                            
                            Text("\(entry.score)")
                                .fontWeight(entry.isCurrentUser ? .bold : .regular)
                                .foregroundColor(entry.isCurrentUser ? .blue : .primary)
                        }
                        .padding()
                        .background(entry.isCurrentUser ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
                    }
                }
                .padding(.horizontal)
            }
            
            Button(action: {
                gameManager.startGame()
            }) {
                Text("Play Again")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(15)
                    .shadow(color: .green.opacity(0.3), radius: 10, y: 5)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
    }
}
