import SwiftUI

struct PlantCardView: View {
    let plant: Plant
    var showStatusBadge = true

    var body: some View {
        HStack(spacing: 10) {
            // Photo
            AsyncImage(url: plant.photoURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure, .empty:
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundColor(.green600)
                @unknown default:
                    Color.green100
                }
            }
            .frame(width: 64, height: 64)
            .background(Color.green100)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(plant.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray700)
                    .lineLimit(1)

                if !plant.subtitle.isEmpty {
                    Text(plant.subtitle)
                        .font(.caption)
                        .foregroundColor(.gray400)
                        .lineLimit(1)
                }

                if let location = plant.location, !location.isEmpty {
                    Text("📍 \(location)")
                        .font(.caption2)
                        .foregroundColor(.gray500)
                        .lineLimit(1)
                }

                if let lastCare = plant.lastCare {
                    Text("Dernier soin: \(lastCare, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.gray500)
                }

                if showStatusBadge, let (label, type) = plant.statusBadge {
                    Text(label)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(type == "badge-danger" ? Color.red100 : Color.yellow100)
                        .foregroundColor(type == "badge-danger" ? Color.red700 : Color.yellow700)
                        .clipShape(Capsule())
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
