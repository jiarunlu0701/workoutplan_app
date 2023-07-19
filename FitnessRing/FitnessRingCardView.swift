import SwiftUI

struct FitnessRingCardView: View {
    @EnvironmentObject var ringViewModel: RingViewModel
    @Binding var isFlip: Bool

    var body: some View {
        VStack(spacing: 15){
            HStack{
                Text("Progress")
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
                            HStack(alignment: .bottom, spacing: 6) {
                                Text("\(Int(ringViewModel.rings[index].progress))%")
                                    .font(.title3.bold())
                                
                                Text(ringViewModel.rings[index].value)
                                    .font(.caption)
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
    }
}

struct DetailView: View {
    @EnvironmentObject var ringViewModel: RingViewModel
    @Binding var isFlip: Bool
    var body: some View {
        VStack(spacing: 15){
            HStack {
                            Text("Input")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity,alignment: .leading)
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
                            Label {
                                HStack(alignment: .bottom, spacing: 6) {
                                    TextField("%", value: $ringViewModel.rings[index].progress, formatter: NumberFormatter())
                                        .font(.title3.bold())
                                    
                                    Text(ringViewModel.rings[index].value)
                                        .font(.caption)
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
                            }
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
    var ring: Ring
    var index: Int
    @State var showRing: Bool = false
    
    var body: some View{
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

