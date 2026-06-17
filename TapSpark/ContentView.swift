import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

private enum Storage {
    static let bestScoreKey = "TapSpark.bestScore"
}

struct ContentView: View {
    @AppStorage(Storage.bestScoreKey) private var bestScore = 0
    @State private var sparks: [Spark] = []
    @State private var score = 0
    @State private var combo = 1
    @State private var lastTap = Date.distantPast

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AnimatedBackground(score: score)
                    .ignoresSafeArea()

                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onEnded { value in
                                addSpark(at: value.location, in: proxy.size)
                            }
                    )

                ForEach(sparks) { spark in
                    SparkBurstView(spark: spark)
                }

                Button {
                    addSpark(at: centerPoint(in: proxy.size), in: proxy.size)
                } label: {
                    Image(systemName: "sparkles")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 104, height: 104)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.22), radius: 20, x: 0, y: 14)
                }
                .buttonStyle(.plain)

                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    bottomBar
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
        }
    }

    private var topBar: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                Text("TapSpark")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)

                HStack(spacing: 8) {
                    StatPill(title: "Score", value: "\(score)")
                    StatPill(title: "Best", value: "\(bestScore)")
                }
            }

            Spacer()

            Button {
                reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.white.opacity(0.22), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reset")
        }
    }

    private var bottomBar: some View {
        HStack {
            StatPill(title: "Combo", value: "x\(combo)")
            Spacer()
            StatPill(title: "Sparks", value: "\(sparks.count)")
        }
    }

    private func addSpark(at rawPoint: CGPoint, in size: CGSize) {
        let now = Date()
        combo = now.timeIntervalSince(lastTap) < 0.72 ? min(combo + 1, 9) : 1
        lastTap = now

        score += combo
        bestScore = max(bestScore, score)

        let point = CGPoint(
            x: clamp(rawPoint.x, 28, max(28, size.width - 28)),
            y: clamp(rawPoint.y, 28, max(28, size.height - 28))
        )
        let spark = Spark.random(at: point, score: score)

        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
            sparks.append(spark)
            if sparks.count > 70 {
                sparks.removeFirst(sparks.count - 70)
            }
        }

        haptic(for: combo)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                sparks.removeAll { $0.id == spark.id }
            }
        }
    }

    private func reset() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            score = 0
            combo = 1
            lastTap = .distantPast
            sparks.removeAll()
        }
    }

    private func centerPoint(in size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width / 2 + CGFloat.random(in: -34...34),
            y: size.height / 2 + CGFloat.random(in: -46...46)
        )
    }

    private func clamp(_ value: CGFloat, _ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
        min(max(value, lower), upper)
    }

    private func haptic(for combo: Int) {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: combo >= 6 ? .medium : .light)
        generator.impactOccurred(intensity: min(CGFloat(combo) / 9, 1))
        #endif
    }
}

private struct AnimatedBackground: View {
    let score: Int

    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate / 18
            let firstHue = (Double(score % 23) / 23 + phase).truncatingRemainder(dividingBy: 1)
            let secondHue = (firstHue + 0.33).truncatingRemainder(dividingBy: 1)
            let thirdHue = (firstHue + 0.66).truncatingRemainder(dividingBy: 1)

            LinearGradient(
                colors: [
                    Color(hue: firstHue, saturation: 0.64, brightness: 0.92),
                    Color(hue: secondHue, saturation: 0.54, brightness: 0.74),
                    Color(hue: thirdHue, saturation: 0.58, brightness: 0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct StatPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .minimumScaleFactor(0.72)
                .lineLimit(1)
                .foregroundStyle(.white)
        }
        .frame(minWidth: 70, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct SparkBurstView: View {
    let spark: Spark
    @State private var expanded = false

    var body: some View {
        ZStack {
            ForEach(spark.particles) { particle in
                Circle()
                    .fill(spark.color.opacity(expanded ? 0 : 0.95))
                    .frame(width: particle.size, height: particle.size)
                    .offset(
                        x: expanded ? CGFloat(cos(particle.angle.radians)) * particle.distance : 0,
                        y: expanded ? CGFloat(sin(particle.angle.radians)) * particle.distance : 0
                    )
                    .scaleEffect(expanded ? 0.2 : 1)
            }

            Image(systemName: spark.symbol)
                .font(.system(size: spark.size, weight: .heavy))
                .foregroundStyle(spark.color)
                .shadow(color: spark.color.opacity(0.45), radius: 12)
                .scaleEffect(expanded ? 1.7 : 0.25)
                .rotationEffect(.degrees(expanded ? spark.rotation : 0))
                .opacity(expanded ? 0 : 1)
        }
        .position(spark.point)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.86)) {
                expanded = true
            }
        }
    }
}

private struct Spark: Identifiable {
    let id = UUID()
    let point: CGPoint
    let color: Color
    let size: CGFloat
    let symbol: String
    let rotation: Double
    let particles: [SparkParticle]

    static func random(at point: CGPoint, score: Int) -> Spark {
        let symbols = ["sparkle", "star.fill", "heart.fill", "bolt.fill", "flame.fill", "seal.fill"]
        let hue = (Double(score % 29) / 29 + Double.random(in: 0...0.16)).truncatingRemainder(dividingBy: 1)
        let particles = (0..<12).map { index in
            SparkParticle(
                angle: .degrees(Double(index) * 30 + Double.random(in: -9...9)),
                distance: CGFloat.random(in: 34...92),
                size: CGFloat.random(in: 5...12)
            )
        }

        return Spark(
            point: point,
            color: Color(hue: hue, saturation: 0.72, brightness: 1),
            size: CGFloat.random(in: 32...48),
            symbol: symbols.randomElement() ?? "sparkle",
            rotation: Double.random(in: -180...180),
            particles: particles
        )
    }
}

private struct SparkParticle: Identifiable {
    let id = UUID()
    let angle: Angle
    let distance: CGFloat
    let size: CGFloat
}

#Preview {
    ContentView()
}
