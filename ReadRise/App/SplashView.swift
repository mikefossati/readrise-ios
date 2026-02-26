import SwiftUI

struct SplashView: View {
    @State private var appeared = false
    @State private var pulsing = false

    var body: some View {
        ZStack {
            Color.rrBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.rrAmber)
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)

                VStack(spacing: 6) {
                    Text("ReadRise")
                        .font(.custom("Georgia", size: 38).bold())
                        .foregroundStyle(Color.rrLabel)
                    Text("Track every page.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.rrSecondaryLabel)
                }
                .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 24)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.rrAmber)
                    .frame(width: 40, height: 3)
                    .opacity(appeared ? (pulsing ? 0.3 : 1.0) : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(0.6)) {
                pulsing = true
            }
        }
    }
}
