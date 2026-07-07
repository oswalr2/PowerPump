import SwiftUI

/// Grid catalog of trackable sport activities, organised by category.
struct SportsCatalogView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: SportCategory = .outdoor

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sbBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        header
                        categoryPicker
                        sportsGrid
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(verbatim: PT("Sports"))
                        .font(SBFont.heading(16))
                        .foregroundColor(.sbTextPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.sbTextSecondary)
                            .font(.system(size: 20))
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: PT("Track any sport"))
                .font(SBFont.heading(20))
                .foregroundColor(.sbTextPrimary)
            Text(verbatim: PT("Pick a sport to start a tracked session. Outdoor sports use GPS; results sync to Apple Health."))
                .font(SBFont.caption())
                .foregroundColor(.sbTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Category picker

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SportCategory.allCases) { cat in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { selectedCategory = cat }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(verbatim: PT(cat.rawValue))
                                .font(SBFont.label(12))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(selectedCategory == cat ? .white : .sbTextPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(selectedCategory == cat ? Color.sbAccent : Color.sbSurfaceRaised)
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Sports grid

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var sportsGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(SportLibrary.byCategory(selectedCategory)) { sport in
                NavigationLink(destination: SportDetailView(sport: sport)) {
                    SportCard(sport: sport)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Card

private struct SportCard: View {
    let sport: SportActivity

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.sbAccent.opacity(0.32),
                                     Color.sbAccent.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                Image(systemName: sport.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.sbAccent)
            }

            Text(verbatim: PT(sport.nameKey))
                .font(SBFont.body())
                .fontWeight(.semibold)
                .foregroundColor(.sbTextPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            if sport.usesGPS {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 9))
                    Text(verbatim: PT("GPS"))
                        .font(SBFont.label(9))
                }
                .foregroundColor(.sbAccent)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.sbAccent.opacity(0.15))
                .cornerRadius(6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(Color.sbSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sbBorder, lineWidth: 1))
    }
}
