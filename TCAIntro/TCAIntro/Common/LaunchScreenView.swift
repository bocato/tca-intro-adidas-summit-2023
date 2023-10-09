import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        VStack {
            Image(systemName: "apple.logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            Text("TCA Intro")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .background(Color.blue)
        .ignoresSafeArea()
    }
}

