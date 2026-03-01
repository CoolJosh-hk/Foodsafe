import SwiftUI

struct ContentView: View {
    
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    
    var body: some View {
        TabView {
            
            SafetyCheckerView()
                .tabItem {
                    Image(systemName: "checkmark.shield.fill")
                    Text("Safety Checker")
                }
            
            GameView()
                .tabItem {
                    Image(systemName: "gamecontroller.fill")
                    Text("Game")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }
}
