//
//  AnimatedGradientBGView.swift
//  NFCMate
//
//  Created by NAVEEN MADHAN on 1/15/22.
//

import Foundation
import SwiftUI


struct GradientBG: View {
    // MARK: - PROPERTY

    @State var randomization: [PointRandomization]
    @State var size: CGSize = CGSize()

    private let colorElements: [Color]
    private let animated: Bool
    private let animation: Animation
    private let blurRadius: CGFloat

    private let timer = Timer
        .publish(every: 5, on: .main, in: .common)
        .autoconnect()

    // MARK: - INIT

    public init(
        animated: Bool = defaultAnimated,
        animation: Animation = defaultAnimation,
        blurRadius: CGFloat = defaultBlurRadius,
        colors: [Color] = defaultColorList,
        colorCount: Int = defaultColorCount
    ) {
        assert(colors.count > 0)
        assert(colorCount > 0)
        assert(blurRadius > 0)

        self.animated = animated
        self.animation = animation
        self.blurRadius = blurRadius

        var colorCompiler = [Color]()
        while colorCompiler.count < colorCount {
            colorCompiler.append(contentsOf: colors.shuffled())
        }
        if colorCompiler.count > colorCount {
            colorCompiler.removeLast(colorCompiler.count - colorCount)
        }
        assert(colorCompiler.count == colorCount)
        colorElements = colorCompiler

        _randomization = State(initialValue: [PointRandomization](repeating: .init(), count: colorCount))
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        public init(
            animated: Bool = defaultAnimated,
            animation: Animation = defaultAnimation,
            blurRadius: CGFloat = defaultBlurRadius,
            nsColors: [NSColor],
            colorCount: Int = defaultColorCount
        ) {
            self.init(
                animated: animated,
                animation: animation,
                blurRadius: blurRadius,
                colors: nsColors.map { Color($0) },
                colorCount: colorCount
            )
        }
    #endif

    #if canImport(UIKit)
        public init(
            animated: Bool = defaultAnimated,
            animation: Animation = defaultAnimation,
            blurRadius: CGFloat = defaultBlurRadius,
            uiColors: [UIColor],
            colorCount: Int = defaultColorCount
        ) {
            self.init(
                animated: animated,
                animation: animation,
                blurRadius: blurRadius,
                colors: uiColors.map { Color($0) },
                colorCount: colorCount
            )
        }
    #endif

    // MARK: - VIEW

    public var body: some View {
        GeometryReader { reader in
            ZStack {
                ForEach(obtainRangeAndUpdate(size: reader.size), id: \.self) { idx in
                    Circle()
                        .foregroundColor(colorElements[idx])
                        .opacity(0.5)
                        .frame(width: randomization[idx].diameter,
                               height: randomization[idx].diameter)
                        .offset(x: randomization[idx].offsetX,
                                y: randomization[idx].offsetY)
                }
            }
            .frame(width: reader.size.width,
                   height: reader.size.height)
        }
        .clipped()
        .blur(radius: blurRadius)
        .onReceive(timer) { _ in
            dispatchUpdate()
        }
    }

    // MARK: - FUNCTION

    private func dispatchUpdate() {
        if !animated { return }
        withAnimation(animation) {
            randomizationStart()
        }
    }

    private func randomizationStart() {
        var randomizationBuilder = [PointRandomization]()
        while randomizationBuilder.count < randomization.count {
            let randomizationElement: PointRandomization = {
                var randomization = PointRandomization()
                randomization.randomizeIn(size: size)
                return randomization
            }()
            randomizationBuilder.append(randomizationElement)
        }
        randomization = randomizationBuilder
    }

    private func obtainRangeAndUpdate(size: CGSize) -> Range<Int> {
        issueSizeUpdate(withValue: size)
        return 0 ..< colorElements.count
    }

    private func issueSizeUpdate(withValue size: CGSize) {
        if self.size == size { return }
        DispatchQueue.main.async {
            self.size = size
            self.dispatchUpdate()
        }
    }
}


fileprivate let kDefaultSourceColorList = [#colorLiteral(red: 0.9586862922, green: 0.660125792, blue: 0.8447988033, alpha: 1), #colorLiteral(red: 0.8714533448, green: 0.723166883, blue: 0.9342088699, alpha: 1), #colorLiteral(red: 0.7458761334, green: 0.7851135731, blue: 0.9899476171, alpha: 1), #colorLiteral(red: 0.4398113191, green: 0.8953480721, blue: 0.9796616435, alpha: 1), #colorLiteral(red: 0.3484552801, green: 0.933657825, blue: 0.9058339596, alpha: 1), #colorLiteral(red: 0.5567936897, green: 0.9780793786, blue: 0.6893508434, alpha: 1)]

extension GradientBG {
    static let defaultAnimated: Bool = true
    static let defaultBlurRadius: CGFloat = 64
    static let defaultColorCount: Int = 32

    static let defaultAnimation: Animation = Animation
        .interpolatingSpring(stiffness: 50, damping: 1)
        .speed(0.05)

    static let defaultColorList: [Color] = kDefaultSourceColorList
        .map { Color($0) }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        static let defaultColorListNSColor: [NSColor] = kDefaultSourceColorList
    #endif

    #if canImport(UIKit)
        static let defaultColorListUIColor: [UIColor] = kDefaultSourceColorList
    #endif

    
    struct PointRandomization: Equatable, Hashable {
        var diameter: CGFloat = 0
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0

        mutating func randomizeIn(size: CGSize) {
            let decision = (size.width + size.height) / 4
            diameter = CGFloat.random(in: (decision * 0.25) ... (decision * 0.75))
            offsetX = CGFloat.random(in: -(size.width / 2) ... +(size.width / 2))
            offsetY = CGFloat.random(in: -(size.height / 2) ... +(size.height / 2))
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(diameter)
            hasher.combine(offsetX)
            hasher.combine(offsetY)
        }

        static func == (lhs: PointRandomization, rhs: PointRandomization) -> Bool {
            lhs.diameter == rhs.diameter &&
                lhs.offsetX == rhs.offsetX &&
                lhs.offsetY == rhs.offsetY
        }
    }
    
}
