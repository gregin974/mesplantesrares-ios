import SwiftUI

struct CareButtonView: View {
    let action: CareActionType
    let onTap: (CareActionType) -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                pressed = false
                onTap(action)
            }
        } label: {
            VStack(spacing: 6) {
                Text(action.emoji)
                    .font(.system(size: 28))
                Text(action.label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray700)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray200, lineWidth: 2)
        )
        .scaleEffect(pressed ? 0.95 : 1.0)
    }
}
