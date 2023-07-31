import SwiftUI

struct Home: View {
    @EnvironmentObject var userAuth: UserAuth
    @StateObject private var dietManager = DietManager()
    @StateObject private var workoutManager = WorkoutManager()
    @State private var isFlipped = false
    @State private var isShowingLoginView = false
    @StateObject private var ringViewModel = RingViewModel()
    @StateObject private var appState = AppState()
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedSegment = "Workouts"
    @State private var workoutProgress: Float = 0.0

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
                    
                    ZStack(alignment: .leading) {
                        GeometryReader { geometryReader in
                            Rectangle()
                                .frame(width: geometryReader.size.width * CGFloat(workoutProgress))
                                .foregroundColor(.green)
                                .animation(.linear, value: workoutProgress)
                            Text("\(Int(workoutProgress * 100))% In Progress")
                                .frame(width: geometryReader.size.width, height: geometryReader.size.height, alignment: .center)
                        }
                    }
                    .frame(height: 20)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(10)
                    .padding()

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
                            .environmentObject(dietManager)
                    }
                }
                .onAppear {
                    if let userId = UserAuth.getCurrentUserId() {
                        appState.workoutManager.fetchWorkoutPhasesForUser(userId: userId)
                        dietManager.fetchDietPlansForUser(userId: userId) // fetch diet plans
                    }
                }
                .onChange(of: appState.workoutManager.earliestPhaseStartDate, perform: { value in
                    workoutProgress = appState.workoutManager.calculateWorkoutProgress(startDate: appState.workoutManager.earliestPhaseStartDate, endDate: appState.workoutManager.latestPhaseEndDate, currentDate: Date())
                })
                .onChange(of: appState.workoutManager.latestPhaseEndDate, perform: { value in
                    workoutProgress = appState.workoutManager.calculateWorkoutProgress(startDate: appState.workoutManager.earliestPhaseStartDate, endDate: appState.workoutManager.latestPhaseEndDate, currentDate: Date())
                })
                 .padding(.horizontal)
            }
        }
    }
}

struct DateScrollBar: View {
    @Binding var selectedDate: Date
    @ObservedObject var workoutManager: WorkoutManager
    @State private var scrollToIndex: Int?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { scrollViewProxy in
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
                            .id(i) // Give each date an id
                    }
                }
                .padding(.horizontal)
                .onAppear {
                    if let scrollTo = scrollToIndex {
                        withAnimation {
                            scrollViewProxy.scrollTo(scrollTo, anchor: .center)
                        }
                    }
                }
                .onChange(of: workoutManager.earliestPhaseStartDate) { _ in
                    calculateScrollToIndex()
                    if let scrollTo = scrollToIndex {
                        withAnimation {
                            scrollViewProxy.scrollTo(scrollTo, anchor: .center)
                        }
                    }
                }
            }
        }
        .padding(.top)
        .onAppear {
            calculateScrollToIndex()
        }
    }

    func calculateScrollToIndex() {
        let range = (Calendar.current.dateComponents([.day], from: workoutManager.earliestPhaseStartDate, to: Date()).day ?? 0) + 1
        scrollToIndex = range - 1
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
    @EnvironmentObject var dietManager: DietManager
    let date: Date
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var body: some View {
        VStack {
            if let dietPlan = dietManager.dietPlans.first(where: { formatter.date(from: $0.date) == date }) {
                
                Text("Date: \(dietPlan.date)")
                    .font(.headline)
                    .padding()
                
                Text("Total Calories: Min: \(dietPlan.total_calories["min"] ?? 0) kcal, Max: \(dietPlan.total_calories["max"] ?? 0) kcal")
                    .font(.subheadline)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Protein:")
                        .font(.subheadline)
                    Text("Min: \(dietPlan.protein["min"] ?? 0) g, Max: \(dietPlan.protein["max"] ?? 0) g")
                        .font(.subheadline)
                    Text("Carbohydrates:")
                        .font(.subheadline)
                    Text("Min: \(dietPlan.carbohydrates["min"] ?? 0) g, Max: \(dietPlan.carbohydrates["max"] ?? 0) g")
                        .font(.subheadline)
                    Text("Hydration:")
                        .font(.subheadline)
                    Text("Min: \(dietPlan.hydration["min"] ?? 0) L, Max: \(dietPlan.hydration["max"] ?? 0) L")
                        .font(.subheadline)
                    Text("Fats:")
                        .font(.subheadline)
                    Text("Min: \(dietPlan.fats["min"] ?? 0) g, Max: \(dietPlan.fats["max"] ?? 0) g")
                        .font(.subheadline)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Food Sources")
                        .font(.title)
                        .bold()
                        .padding(.top)
                    
                    ForEach(dietPlan.food_sources.keys.sorted(), id: \.self) { category in
                        VStack(alignment: .leading) {
                            Text(category.capitalized)
                                .font(.subheadline)
                                .bold()
                                .padding(.top)
                            
                            ForEach(dietPlan.food_sources[category] ?? [], id: \.self) { food in
                                Text(food)
                                    .font(.subheadline)
                                    .padding(.leading)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Text("Plan Explanation: \(dietPlan.plan_explanation)")
                    .font(.subheadline)
                    .padding(.horizontal)
                
            } else {
                Text("No diet plan available for this date")
                    .font(.headline)
            }
        }
        .padding()
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
            .environmentObject(DietManager())
    }
}
