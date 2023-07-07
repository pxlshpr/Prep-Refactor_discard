import SwiftUI

func heroButtonLabel(_ systemImage: String) -> some View {
    ZStack {
        Circle()
            .foregroundStyle(Color.accentColor.gradient)
            .shadow(color: Color(.black).opacity(0.1), radius: 5, x: 0, y: 3)
        Image(systemName: systemImage)
            .font(.system(size: 25))
            .fontWeight(.medium)
            .foregroundStyle(Color(.systemBackground))
    }
    .frame(width: HeroButton.size, height: HeroButton.size)
    .hoverEffect(.lift)
}
