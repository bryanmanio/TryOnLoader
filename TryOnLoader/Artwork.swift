import SwiftUI

/// Names the stage looks for in `Assets.xcassets`. Drop in image sets with these
/// names and the drawn placeholders below are replaced automatically.
enum Artwork {
    static let subject = "model"
    static let top = "top"
    static let bottom = "bottom"
}

/// An asset-catalog image when one exists, otherwise a drawn stand-in so the
/// stage runs before any photography is wired up.
struct ArtworkImage<Placeholder: View>: View {
    let name: String
    @ViewBuilder var placeholder: () -> Placeholder

    var body: some View {
        if let image = UIImage(named: name) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            placeholder()
        }
    }
}

// MARK: - Drawn stand-ins

struct TeeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        func point(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        path.move(to: point(0.30, 0.13))
        path.addQuadCurve(to: point(0.70, 0.13), control: point(0.50, 0.27))
        path.addLine(to: point(0.98, 0.32))
        path.addLine(to: point(0.86, 0.52))
        path.addLine(to: point(0.79, 0.45))
        path.addLine(to: point(0.79, 0.93))
        path.addLine(to: point(0.21, 0.93))
        path.addLine(to: point(0.21, 0.45))
        path.addLine(to: point(0.14, 0.52))
        path.addLine(to: point(0.02, 0.32))
        path.closeSubpath()
        return path
    }
}

struct LeggingsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        func point(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        path.move(to: point(0.22, 0.05))
        path.addLine(to: point(0.78, 0.05))
        path.addLine(to: point(0.70, 0.96))
        path.addLine(to: point(0.55, 0.96))
        path.addLine(to: point(0.50, 0.48))
        path.addLine(to: point(0.45, 0.96))
        path.addLine(to: point(0.30, 0.96))
        path.closeSubpath()
        return path
    }
}

struct SubjectPlaceholder: View {
    var body: some View {
        figure.aspectRatio(0.29, contentMode: .fit)
    }

    private var figure: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                Circle()
                    .fill(Color(white: 0.78))
                    .frame(width: side * 0.24, height: side * 0.24)
                    .offset(y: -side * 0.20)
                Capsule()
                    .fill(Color(white: 0.82))
                    .frame(width: side * 0.52, height: side * 0.56)
                    .offset(y: side * 0.24)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
