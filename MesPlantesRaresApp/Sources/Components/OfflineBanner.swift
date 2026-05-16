import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        Text("📡 Mode hors-ligne")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color.orange)
    }
}
