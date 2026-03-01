import SwiftUI

struct SettingsView: View {
    
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    // Title
                    Text("Settings")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top)
                    
                    // About
                    VStack(alignment: .leading, spacing: 10) {
                        Text("About")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("""
FoodSafe helps you reduce unnecessary food waste while staying safe.

The Safety Checker analyzes common signs of spoilage and storage conditions to guide you in deciding whether food is safe to consume. It helps prevent throwing away good food due to common misconceptions, such as assuming browned apples or spotted bananas are rotten.

The Game section reinforces food safety knowledge in an interactive way. Players learn how to interpret labels like “Use By” and “Best Before,” recognize common spoilage signs, and understand widespread myths about food freshness.

FoodSafe empowers you to make informed decisions, reduce waste, and contribute to a more sustainable environment.
""")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    // Sound
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sound")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Toggle("On/Off", isOn: $soundEnabled)
                            .tint(.green)
                    }
                    
                    // Mode
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mode")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Toggle("Light/Dark", isOn: $darkModeEnabled)
                            .tint(.green)
                    }
                    
                    // Disclaimer
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Disclaimer")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("The FoodSafe Safety Checker provides general guidance based on common food safety principles. Results are not guaranteed to be accurate in all situations and should not replace professional judgment. If you are uncertain about the safety of any food, please consult a qualified food safety expert or discard the item.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Version
                    Text("Version 1.0")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }
}
