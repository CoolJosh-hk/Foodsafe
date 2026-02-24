import SwiftUI

struct ContentView: View {
    
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
    }
}
