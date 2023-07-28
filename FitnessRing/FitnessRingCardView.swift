import SwiftUI

struct FitnessRingCardView: View {
    @EnvironmentObject var ringViewModel: RingViewModel
    @Binding var isFlip: Bool

    var body: some View {
        if !ringViewModel.isDataLoaded {
            ProgressView("Loading...")
        } else {
            VStack(spacing: 15){
                HStack{
                    Text("Nutrition Intake")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity,alignment: .leading)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            self.isFlip = true
                        }
                    }) {
                        Image(systemName: "rotate.right")
                            .foregroundColor(.gray)
                    }
                }
                HStack(spacing: 20){
                    ZStack{
                        ForEach(ringViewModel.rings.indices, id: \.self){ index in
                            AnimatedRingView(ring: ringViewModel.rings[index], index: index)
                        }
                    }
                    .frame(width: 130, height: 130)
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(ringViewModel.rings.indices, id: \.self){ index in
                            Label {
                                Spacer()
                                HStack(alignment: .bottom, spacing: 6) {
                                    Text("\(Int(ringViewModel.rings[index].userInput)) / \(Int(ringViewModel.rings[index].minValue))")
                                        .font(.title3.bold())
                                }
                            } icon: {
                                Group {
                                    switch ringViewModel.rings[index].keyIcon {
                                    case .system(let name):
                                        Image(systemName: name)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 25, height: 25)
                                            .foregroundColor(ringViewModel.rings[index].iconColor)
                                    case .local(let name):
                                        Image(name)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 25, height: 25)
                                            .foregroundColor(ringViewModel.rings[index].iconColor)
                                    }
                                }
                                .frame(width: 30)
                                let ring = ringViewModel.rings[index]
                                Text(ring.value)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.leading,10)
                }
                .padding(.top,20)
            }
            .padding(.horizontal,20)
            .padding(.vertical,25)
            .background{
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            }
            .onAppear {
                ringViewModel.loadData()
            }
            .onChange(of: ringViewModel.needsRefresh) { needsRefresh in
                if needsRefresh {
                    ringViewModel.loadData()
                    ringViewModel.needsRefresh = false
                }
            }
        }
    }
}

struct DetailView: View {
    @EnvironmentObject var ringViewModel: RingViewModel
    @Binding var isFlip: Bool
    @State private var newUserInput = [String: String]()

    var body: some View {
        VStack(spacing: 15){
            HStack {
                Text("Input")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        self.isFlip = false
                    }
                }) {
                    Image(systemName: "rotate.left")
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 20){
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(ringViewModel.rings.indices, id: \.self){ index in
                        HStack {
                            let ring = ringViewModel.rings[index]
                            Label {
                                HStack(alignment: .bottom, spacing: 6) {
                                    Text("\(Int(ring.userInput)) / \(Int(ring.minValue))")
                                        .font(.title3.bold())
                                    
                                    Text(unit(for: ringViewModel.rings[index].value))  // Display unit information only
                                        .font(.caption)
                                    Spacer()
                                }
                            } icon: {
                                Group {
                                    switch ring.keyIcon {
                                    case .system(let name):
                                        Image(systemName: name)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 25, height: 25)
                                            .foregroundColor(ring.iconColor)
                                    case .local(let name):
                                        Image(name)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 25, height: 25)
                                            .foregroundColor(ring.iconColor)
                                    }
                                }
                                .frame(width: 30)
                            }
                            
                            if ring.value != "Completion" {
                                HStack {
                                    TextField("Input", text: Binding(
                                        get: { self.newUserInput[ring.id, default: ""] },
                                        set: { self.newUserInput[ring.id] = $0 }
                                    ))
                                    .keyboardType(.numberPad)
                                    .frame(width: 50)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        if let newValue = NumberFormatter().number(from: newUserInput[ring.id] ?? "")?.floatValue {
                                            var existingValue = Float(ring.userInput)
                                            
                                            if existingValue == 0 {
                                              return
                                            }
                                            if existingValue - newValue < 0 {
                                                        existingValue = 0
                                                    } else {
                                                        existingValue -= newValue
                                                    }
                                            
                                            ringViewModel.updateUserInputForRing(ring, userInput: existingValue)
                                            newUserInput[ring.id] = ""
                                        }
                                        ringViewModel.storeUserInputInFirestore(ring: ring)
                                    }) {
                                        Image(systemName: "minus")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 25, height: 25)
                                            .padding(.top)
                                    }
                                    
                                    Button(action: {
                                        if let newValue = NumberFormatter().number(from: newUserInput[ring.id] ?? "")?.floatValue {
                                            ringViewModel.updateUserInputForRing(ring, userInput: Float(ring.userInput) + newValue)
                                            newUserInput[ring.id] = ""
                                        }
                                        ringViewModel.storeUserInputInFirestore(ring: ring)
                                    }) {
                                        Image(systemName: "plus")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 25, height: 25)
                                            .padding(.top)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.leading,10)
            }
            .padding(.top,20)
        }
        .onAppear(perform: {
            ringViewModel.loadData()
        })
        .padding(.horizontal,20)
        .padding(.vertical,25)
        .background{
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        }
    }
    private func unit(for value: String) -> String {
        switch value {
        case "Carbohydrates":
            return "g"
        case "Calories +/-":
            return "kcal"
        case "Protein":
            return "g"
        case "Hydration":
            return "ml"
        default:
            return ""
        }
    }
}

struct FlipEffect: AnimatableModifier {
    var animatableData: Double
    
    @Binding var isFlipped: Bool
    
    init(isFlipped: Binding<Bool>, angle: Angle) {
        self._isFlipped = isFlipped
        self.animatableData = angle.degrees
    }
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(animatableData), axis: (x: 0, y: 1, z: 0))
    }
}

extension View {
    func flipEffect(isFlipped: Binding<Bool>, angle: Angle) -> some View {
        self.modifier(FlipEffect(isFlipped: isFlipped, angle: angle))
    }
}

struct AnimatedRingView: View {
    @EnvironmentObject var ringViewModel: RingViewModel
    var ring: Ring
    var index: Int
    @State var showRing: Bool = false
    
    var body: some View{
        Group {
            if ringViewModel.isLoading{
                ProgressView("Loading...")
            } else {
                ZStack{
                    Circle()
                        .stroke(Color.gray.opacity(0.3),lineWidth: 10)
                    
                    Circle()
                        .trim(from: 0, to: showRing ? ring.progress / 100 : 0)
                        .stroke(ring.keyColor, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                        .rotationEffect(.init(degrees: -90))
                }
                .padding(CGFloat(index) * 16)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.interactiveSpring(response: 1, dampingFraction: 1, blendDuration: 1).delay(Double(index) * 0.1)){
                            showRing = true
                        }
                    }
                }
            }
        }
    }
}
