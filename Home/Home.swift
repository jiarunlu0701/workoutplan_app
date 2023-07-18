import SwiftUI

struct Home: View {
    @EnvironmentObject var userAuth: UserAuth
    @State private var isFlipped = false
    @State private var isShowingLoginView = false
    @StateObject private var ringViewModel = RingViewModel()
    @StateObject private var appState = AppState()
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedSegment = "Workouts"
    
    var body: some View {
        ZStack {
            BackgroundView()
            ScrollView(.vertical, showsIndicators: false){
                VStack(spacing: 40) {
                    Text("")
                    Text("Welcome \(userAuth.username)")
                        .font(.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ZStack {
                        if isFlipped {
                            DetailView(isFlip: $isFlipped)
                                .environmentObject(ringViewModel)
                                .scaleEffect(x: -1)
                        } else {
                            FitnessRingCardView(isFlip: $isFlipped)
                                .environmentObject(ringViewModel)
                        }
                    }
                    .flipEffect(isFlipped: $isFlipped, angle: Angle(degrees: isFlipped ? 180 : 0))

                                        
                    DateScrollBar(selectedDate: $selectedDate, workoutManager: appState.workoutManager)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    Picker("", selection: $selectedSegment) {
                        Text("Workouts").tag("Workouts")
                        Text("Diet Plan").tag("Diet Plan")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    if selectedSegment == "Workouts" {
                        ExerciseContent(date: selectedDate, workoutManager: appState.workoutManager)
                    } else if selectedSegment == "Diet Plan" {
                        DietPlanContent(date: selectedDate)
                    }
                    
                }
                .onAppear {
                    if let userId = UserAuth.getCurrentUserId() {
                        appState.workoutManager.fetchWorkoutPhasesForUser(userId: userId)
                    }
                }
                .padding(.horizontal)
                }
            }
        }
    }

struct DateScrollBar: View {
    @Binding var selectedDate: Date
    @ObservedObject var workoutManager: WorkoutManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                let range = (Calendar.current.dateComponents([.day], from: workoutManager.earliestPhaseStartDate, to: workoutManager.latestPhaseEndDate).day ?? 0) + 1
                ForEach(Array(0..<range), id: \.self) { i in
                    let date = Calendar.current.date(byAdding: .day, value: i, to: workoutManager.earliestPhaseStartDate)!
                    VStack(alignment: .center) {
                        Text("\(getWeekdayString(date: date))")
                            .font(.subheadline)
                        Text("\(getDateString(date: date, format: "MMM d"))")
                            .fontWeight(date == selectedDate ? .bold : .none)
                    }
                        .fontWeight(date == selectedDate ? .bold : .none)
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .background(date == selectedDate ? Color.gray.opacity(0.1) : Color.clear)
                        .cornerRadius(25)
                        .onTapGesture {
                            withAnimation {
                                selectedDate = date
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
        .padding(.top)
    }

    
    func getDateString(date: Date, format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        
        if Calendar.current.isDateInToday(date) {
            return "Today, " + dateFormatter.string(from: date)
        } else {
            return dateFormatter.string(from: date)
        }
    }
    
    func getWeekdayString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EE"
        return dateFormatter.string(from: date)
    }
}

struct ExerciseContent: View {
    let date: Date
    let workoutManager: WorkoutManager
    @EnvironmentObject var userAuth: UserAuth

    var body: some View {
        ScrollView {
            if userAuth.isLoggedin {
                let exercises = workoutManager.exercisesForDay(date: date)
                if !exercises.isEmpty {
                    VStack(alignment: .leading, spacing: 30) {
                        ForEach(exercises) { exercise in
                            ExerciseView(exercise: exercise)
                        }
                    }
                    .padding()
                } else {
                    Text("🎉🎉 Rest Day !!! 🎉🎉")
                        .font(.headline)
                }
            }
        }
    }
}

struct ExerciseView: View {
    let exercise: Exercise
    @State private var isChecked: Bool = false

    var body: some View {
        HStack {
            Button(action: {
                isChecked.toggle()
            }) {
                if isChecked {
                    CustomCheckmark()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.green)
                } else {
                    Circle()
                        .stroke(Color.gray, lineWidth: 1)
                        .frame(width: 20, height: 20)
                }
            }
            
            VStack(alignment: .leading) {
                Text(exercise.name)
                    .font(.system(size: 20))
                if let sets = exercise.sets, let reps = exercise.reps {
                    Text("Sets: \(sets) Reps: \(reps)")
                        .font(.system(size: 15))
                }
                if let weight = exercise.suggested_weight {
                    Text("Suggested weight: \(weight)")
                        .font(.system(size: 15))
                }
                if let notes = exercise.notes {
                    Text(notes)
                        .font(.system(size: 15))
                }
            }
            Spacer()
            Image(systemName: "play.rectangle")
                .resizable()
                .frame(width: 70, height: 50)
        }
    }
}

struct DietPlanContent: View {
    let date: Date
    var body: some View {
        // Add your content for diet plan here
        Text("Diet Plan for \(date)")
    }
}

struct CustomCheckmark: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green)
            Path { path in
                path.move(to: CGPoint(x: 5, y: 10))
                path.addLine(to: CGPoint(x: 8, y: 15))
                path.addLine(to: CGPoint(x: 15, y: 5))
            }
            .stroke(Color.white, lineWidth: 2)
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
            .environmentObject(UserAuth())
            .environmentObject(RingViewModel())

    }
}
