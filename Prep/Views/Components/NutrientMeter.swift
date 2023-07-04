import SwiftUI

struct NutrientMeter: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Binding var model: NutrientMeter.Model
    
    @State private var hasAppeared = false
    
    init(model: Binding<NutrientMeter.Model>) {
        _model = model
    }
}

extension NutrientMeter {
    var body: some View {
        GeometryReader { proxy -> AnyView in
            return AnyView(
                capsulesPrototype(proxy)
                    .animation(.bouncy, value: model.planned)
            )
        }
        .clipShape(
            shape
        )
        .task {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                hasAppeared = true
            }
        }
    }

    var shape: some Shape {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
//            Capsule()
    }
    

    func capsulesPrototype(_ proxy: GeometryProxy) -> some View {
        
        var placeholderCapsule: some View {
            shape
                .fill(placeholderColor)
                .animation(.none, value: model.planned)
        }
        
        var preppedCapsule: some View {
            
            var fill: some ShapeStyle {
                model.increment == nil
                ? model.eatenColor.gradient
                : model.preppedColor.gradient
            }
            
            return shape
//                .fill(model.preppedColor.gradient)
                .fill(fill)
                .frame(width: preppedWidth(for: proxy))
                .if(hasAppeared, transform: { view in
                    /// Use this to make sure the animation only gets applied after the view has appeared, so that it doesn't animate it during it being transitioned into view
                    view
                        .animation(animation, value: model.eaten)
                        .animation(animation, value: model.increment)
                })
        }
        
        var eatenCapsule: some View {
            shape
                .fill(model.eatenColor.gradient)
//                .frame(width: preppedWidth(for: proxy))
                .frame(width: eatenWidth(proxy: proxy))
                .if(hasAppeared, transform: { view in
                    /// Use this to make sure the animation only gets applied after the view has appeared, so that it doesn't animate it during it being transitioned into view
                    view
                        .animation(animation, value: model.eaten)
                        .animation(animation, value: model.increment)
                })
        }

        var incrementCapsule: some View {
            shape
                .fill(model.incrementColor.gradient)
                .frame(width: incrementWidth(proxy: proxy))
                .if(hasAppeared, transform: { view in
                    /// Use this to make sure the animation only gets applied after the view has appeared, so that it doesn't animate it during it being transitioned into view
                    view
                        .animation(animation, value: model.eaten)
                        .animation(animation, value: model.increment)
                })
        }
        
        @ViewBuilder
        var lowerGoalMark: some View {
            if model.shouldShowLowerGoalMark {
                DottedLine()
                    .stroke(style: StrokeStyle(
                        lineWidth: model.lowerGoalMarkLineWidth,
                        dash: [model.lowerGoalMarkDash])
                    )
                    .frame(width: 1)
                    .foregroundColor(model.lowerGoalMarkColor)
                    .opacity(model.lowerGoalMarkOpacity)
                    .offset(x: lowerGoalMarkOffset(for: proxy))
            }
        }

        @ViewBuilder
        var upperGoalMark: some View {
            if model.shouldShowUpperGoalMark {
                DottedLine()
                    .stroke(style: StrokeStyle(
                        lineWidth: model.upperGoalMarkLineWidth,
                        dash: [model.upperGoalMarkDash])
                    )
                    .frame(width: 1)
                    .foregroundColor(model.upperGoalMarkColor)
                    .opacity(model.upperGoalMarkOpacity)
                    .offset(x: upperGoalMarkOffset(for: proxy))
            }
        }

        return ZStack(alignment: .leading) {
            placeholderCapsule
            incrementCapsule
            preppedCapsule
//            eatenCapsule
            lowerGoalMark
            upperGoalMark
        }
    }
    
    //MARK: - Accessors
    var food: Double {
        model.planned
    }
    
    //MARK: - 📐 Widths
    /// If it's not at 0, return a minimum to account for the corner width
    func correctedWidth(_ width: Double) -> Double {
        guard width != 0 else { return width }
        return max(width, 5)
    }
    func preppedWidth(for proxy: GeometryProxy) -> Double {
        correctedWidth(proxy.size.width * model.preppedPercentageForMeter)
    }
    
    func eatenWidth(proxy: GeometryProxy) -> Double {
        correctedWidth(proxy.size.width * model.eatenPercentage)
    }
    
    func incrementWidth(proxy: GeometryProxy) -> Double {
        correctedWidth(proxy.size.width * model.incrementPercentageForMeter)
    }
    
    func lowerGoalMarkOffset(for proxy: GeometryProxy) -> Double {
        (proxy.size.width * model.lowerGoalPercentage) - 1.0
    }

    func upperGoalMarkOffset(for proxy: GeometryProxy) -> Double {
        (proxy.size.width * model.upperGoalPercentage) - 1.0
    }

    //MARK: - 🎨 Colors
    var placeholderColor: Color {
        Colors.placeholder
    }

    //MARK: - 🎞 Animations
    var animation: Animation {

        .interactiveSpring()
//        .default
        
//        let shouldBounce = !model.isCloseToEdges || !model.haveGoal
//        if shouldBounce {
//            return .interactiveSpring(response: 0.35, dampingFraction: 0.66, blendDuration: 0.35)
//        } else {
//            /// don't bounce the bar if we're going to 0 or going close to 1
//            return .interactiveSpring()
//        }
    }
    
    //MARK: - Enums
    struct Colors {
        static let placeholder = Color("StatsEmptyFill")
    }
}

extension NutrientMeter.Model {
    
    var isCloseToEdges: Bool {
        if showingIncrement {
            return incrementPercentage <= 0.05 || incrementPercentage >= 0.95
        } else {
            return eatenPercentage <= 0.05 || eatenPercentage >= 0.95
        }
    }
    
    var shouldShowLowerGoalMark: Bool {
        switch goalBoundsType {
            
        case .lowerAndUpper:
            /// Show as long as its not at 100%
            return lowerGoalPercentage < 1.0
//            /// Always shows
//            return true
            
        case .lowerOnly:
            /// Shows if the endPoint exceeds the lower mark
            guard let goalLower else { return false }
            return endPoint > goalLower
            
        default:
            return false
        }
    }
    
    var shouldShowUpperGoalMark: Bool {
        switch goalBoundsType {
            
        case .lowerAndUpper, .upperOnly:
            /// Shows if the endPoint exceeds the upper mark
            guard let goalUpper else { return false }
            return endPoint > goalUpper
            
        default:
            return false
        }
    }
    var preppedPercentageType: PercentageType {
        let defaultType = PercentageType(preppedPercentage)
        switch goalBoundsType {
        case .none, .lowerOnly:
            return preppedPercentage < 1 ? defaultType : .complete
        case .upperOnly:
            return preppedPercentage < 1 ? .complete : .excess
        case .lowerAndUpper:
            guard let goalLower, let goalUpper else { return defaultType }
            if planned < goalLower {
                return defaultType
            } else if planned < goalUpper {
                return .complete
            } else {
                return .excess
            }
        }
    }
    
    var incrementPercentageType: PercentageType {
        guard let increment else { return .regular }
        let defaultType = PercentageType(incrementPercentage)
        switch goalBoundsType {
        case .none, .lowerOnly:
            return incrementPercentage < 1 ? defaultType : .complete
        case .upperOnly:
            return incrementPercentage < 1 ? .complete : .excess
        case .lowerAndUpper:
            guard let goalLower, let goalUpper else { return defaultType }
            if planned + increment < goalLower {
                return defaultType
            } else if planned + increment < goalUpper {
                return .complete
            } else {
                return .excess
            }
        }
    }

    var incrementPercentage: Double {
        guard let increment = increment else { return 0 }
        guard totalGoal != 0 else {
            return 1
        }
        return (increment + planned) / totalGoal
    }
    
    var incrementPercentageForMeter: Double {
        guard let increment = increment, increment > 0 else { return 0 }
        //        guard let increment = increment?.wrappedValue, totalGoal != 0 else { return 0 }
        
        guard totalGoal != 0 else {
            return 1
        }
        
        /// Choose greater of goal or "prepped + increment"
        let total: Double
        if planned + increment > totalGoal {
            total = planned + increment
        } else {
            total = totalGoal
        }
        
        return ((increment / total) + preppedPercentage)
    }
    
    
    var endPoint: Double {
        if let increment {
            return planned + increment
        } else {
            return planned
        }
    }
    
    //MARK: Lower Goal
    var lowerGoalPercentage: CGFloat {
        guard let goalLower else { return 0 }
        //TODO: Possibly remove this redundant conditional by always using endPoint instead
        if let goalUpper, goalUpper > 0 {
            return goalLower / max(goalUpper, endPoint)
        } else {
            guard endPoint > 0 else { return 0}
            return goalLower / endPoint
        }
    }
    var lowerGoalMarkColor: Color {
        Color(.systemGroupedBackground)
//        Color.white
//        Color(.label)
//        let percentageType = showingIncrement ? incrementPercentageType : preppedPercentageType
//        switch percentageType {
//        case .excess:
//            return Colors.Excess.text
//        default:
//            return Colors.Complete.text
//        }
    }
    
    var lowerGoalMarkOpacity: CGFloat {
//        lowerGoalMarkOverBar ? 0.5 : 1.0
        1.0
    }
    
    var lowerGoalMarkLineWidth: CGFloat {
//        lowerGoalMarkOverBar ? 1 : 1.5
        lowerGoalMarkOverBar ? 2 : 1.5
    }
    
    var lowerGoalMarkOverBar: Bool {
        guard let goalLower else { return false }
        return goalLower < endPoint
    }
    
    var lowerGoalMarkDash: CGFloat {
        lowerGoalMarkOverBar ? 2 : 100
    }
    
    //MARK: Upper Goal
    
    var upperGoalPercentage: CGFloat {
        guard let goalUpper, endPoint > 0 else { return 0 }
        return goalUpper / endPoint
    }
    var upperGoalMarkColor: Color {
        Color(.systemGroupedBackground)
//        Color.white
//        Color(.label)
//        let percentageType = showingIncrement ? incrementPercentageType : preppedPercentageType
//        switch percentageType {
//        case .excess:
//            return Colors.Excess.text
//        default:
//            return Colors.Complete.text
//        }
    }
    
    var upperGoalMarkOpacity: CGFloat {
//        upperGoalMarkOverBar ? 0.5 : 1.0
        1.0
    }
    
    var upperGoalMarkLineWidth: CGFloat {
//        upperGoalMarkOverBar ? 1 : 1.5
        upperGoalMarkOverBar ? 2 : 1.5
    }
    
    var upperGoalMarkOverBar: Bool {
        guard let goalUpper else { return false }
        return goalUpper < endPoint
    }
    
    var upperGoalMarkDash: CGFloat {
        upperGoalMarkOverBar ? 2 : 100
    }
}

