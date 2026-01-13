import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
        }
        .frame(width: 450, height: 200)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("pageSize") private var pageSize = 50

    var body: some View {
        Form {
            Section("Sessions") {
                Picker("Sessions per page", selection: $pageSize) {
                    Text("25").tag(25)
                    Text("50").tag(50)
                    Text("100").tag(100)
                }
            }
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}
