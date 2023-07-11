import SwiftUI
import Foundation

struct Home: View {
    @EnvironmentObject var userAuth: UserAuth
    @State private var isShowingLoginView = false
    @StateObject private var appState = AppState()
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var isShowingCoachChatView = false
    
    var body: some View {
        VStack(spacing: 40) {
            HStack {
                Button(action: {
                    userAuth.signOut()
                }) {
                    Text("Sign Out")
                        .fontWeight(.bold)
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .background(Color.gray.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                .padding(.horizontal)
            }
            Text("")
            Text("Workout Plan")
                .font(.title)
                .fontWeight(.bold)
            
            Button(action: {
                isShowingCoachChatView.toggle()
            }) {
                Text("Chat with AI coach")
                    .fontWeight(.bold)
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
            .padding(.horizontal)
            
            DateScrollBar(selectedDate: $selectedDate, workoutManager: appState.workoutManager)
                .padding(.horizontal)
                .padding(.top, 10)
            
            ExerciseContent(date: selectedDate, workoutManager: appState.workoutManager)
                .frame(minHeight: 700)
        }
        .onAppear {
            if let userId = UserAuth.getCurrentUserId() {
                appState.workoutManager.fetchWorkoutPhasesForUser(userId: userId)
            }
        }
        .padding(.horizontal)
        .background(Color.clear)
        .sheet(isPresented: $isShowingCoachChatView) {
            CoachChatView(appState: appState)
        }
        .sheet(isPresented: $isShowingLoginView) {
            LoginView()
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
                    Text("\(getDateString(date: date, format: "MMM d")), \(getWeekdayString(date: date))")
                        .fontWeight(date == selectedDate ? .bold : .none)
                        .foregroundColor(date == selectedDate ? .primary : .secondary)
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .background(date == selectedDate ? Color.gray.opacity(0.6) : Color.clear)
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
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: date)
    }

}

struct ExerciseContent: View {
    let date: Date
    let workoutManager: WorkoutManager
    
    var body: some View {
        ScrollView {
            if let exercises = workoutManager.exercisesForDay(date: date), !exercises.isEmpty {
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

struct ExerciseView: View {
    let exercise: Exercise
    
    var body: some View {
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
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
