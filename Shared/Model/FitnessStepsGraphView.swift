import SwiftUI

extension Color {
    static var systemUltraThinMaterial: Color {
        if #available(iOS 13.0, *) {
            return Color(UIColor { traits -> UIColor in
                if traits.userInterfaceStyle == .dark {
                    return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
                } else {
                    return UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
                }
            })
        } else {
            return Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.3)
        }
    }
}

struct FitnessStepsGraphView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Today's Exercise")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

            ForEach(workoutManager.exercisesForDay(date: Date())) { exercise in
                HStack {
                    VStack(alignment: .leading) {
                        Text(exercise.name)
                            .fontWeight(.semibold)
                        if let sets = exercise.sets, let reps = exercise.reps {
                            Text("Sets: \(sets) Reps: \(reps)")
                        }
                        if let weight = exercise.suggested_weight {
                            Text("Suggested weight: \(weight)")
                        }
                    }
                    .padding()
                    .frame(minWidth: 350, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color.systemUltraThinMaterial)
                            .opacity(0.2)
                    )

                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 25)
        .background(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color.clear)
        )
        .cornerRadius(25)
        .foregroundColor(Color.clear)
    }
}
