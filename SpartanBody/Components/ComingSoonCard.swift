import SwiftUI

struct ComingSoonCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        SBCard {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.sbAccentDim)
                        .frame(width: 72, height: 72)
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.sbAccent)
                }
                VStack(spacing: 6) {
                    Text(title)
                        .font(SBFont.heading())
                        .foregroundColor(.sbTextPrimary)
                        .multilineTextAlignment(.center)
                    Text(subtitle)
                        .font(SBFont.body())
                        .foregroundColor(.sbTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 20)
    }
}
