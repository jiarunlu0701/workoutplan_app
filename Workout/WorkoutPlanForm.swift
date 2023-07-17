import SwiftUI
import FirebaseFirestore
import Firebase

struct WorkoutPlanForm: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var age = ""
    @State private var gender = ""
    @State private var weight = ""
    @State private var height = ""
    @State private var bodyFitnessPercentage = ""
    @State private var currentFitnessLevel = ""
    @State private var fitnessGoal = ""
    @State private var trainingFor = ""
    @State private var exercisesPerDay = ""
    @State private var muscleGroupsPerWorkout = ""
    @State private var restDay = ""
    @State private var workoutLocation = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var benchPressWeight = ""
    @State private var shoulderPressWeight = ""
    @State private var pullUps = ""
    @State private var squatWeight = ""
    @State private var dynamicExercises = false
    @State private var additionalNotes = ""
    let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    TextField("Gender", text: $gender)
                    TextField("Weight (lbs)", text: $weight)
                        .keyboardType(.numberPad)
                    TextField("Height (inches)", text: $height)
                        .keyboardType(.numberPad)
                    TextField("Body Fitness Percentage (%)", text: $bodyFitnessPercentage)
                        .keyboardType(.decimalPad)
                    TextField("Current Fitness Level", text: $currentFitnessLevel)
                }
                
                Section(header: Text("Workout Goals")) {
                    TextField("Fitness Goal", text: $fitnessGoal)
                    TextField("Training For", text: $trainingFor)
                }
                
                Section(header: Text("Workout Schedule")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    TextField("Exercises per Day", text: $exercisesPerDay)
                        .keyboardType(.numberPad)
                    TextField("Muscle Groups per Workout", text: $muscleGroupsPerWorkout)
                        .keyboardType(.numberPad)
                    TextField("Rest Day (1-7)", text: $restDay)
                        .keyboardType(.numberPad)
                    TextField("Workout Location", text: $workoutLocation)
                }

                Section(header: Text("Workout Details")) {
                    TextField("Bench Press Weight (lbs)", text: $benchPressWeight)
                        .keyboardType(.numberPad)
                    TextField("Shoulder Press Weight (lbs)", text: $shoulderPressWeight)
                        .keyboardType(.numberPad)
                    TextField("Number of Pull-ups", text: $pullUps)
                        .keyboardType(.numberPad)
                    TextField("Squat Weight (lbs)", text: $squatWeight)
                        .keyboardType(.numberPad)
                    Toggle("Dynamic Exercises", isOn: $dynamicExercises)
                }

                Section(header: Text("Additional Notes")) {
                    TextField("Any other notes or comments", text: $additionalNotes)
                }

                Button(action: generatePlan) {
                    Text("Generate")
                }
            }
            .navigationTitle("Workout Plan Form")
        }
    }
    func generatePlan() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let formattedStartDate = dateFormatter.string(from: startDate)
        let formattedEndDate = dateFormatter.string(from: endDate)
        let planDetails = """
        Workout Plan Information:
        Age: \(age)
        Gender: \(gender)
        Weight: \(weight)
        Height: \(height)
        Body Fitness Percentage: \(bodyFitnessPercentage)
        Current Fitness Level: \(currentFitnessLevel)
        
        Workout Goals:
        Fitness Goal: \(fitnessGoal)
        Training For: \(trainingFor)
        
        Workout Schedule:
        Start Date: \(formattedStartDate)
        End Date: \(formattedEndDate)
        Exercises per Day: \(exercisesPerDay)
        Muscle Groups per Workout: \(muscleGroupsPerWorkout)
        Rest Day: \(restDay)
        Workout Location: \(workoutLocation)
        
        Workout Details:
        Bench Press Weight: \(benchPressWeight)
        Shoulder Press Weight: \(shoulderPressWeight)
        Number of Pull-ups: \(pullUps)
        Squat Weight: \(squatWeight)
        Dynamic Exercises: \(dynamicExercises ? "Yes" : "No")
        
        Additional Notes: \(additionalNotes)
        """
        print(planDetails)
        if let userId = UserAuth.getCurrentUserId() {
            saveGeneratePlan(userId: userId, planDetails: planDetails)
        } else {
            print("Error: Could not get the current user ID.")
        }
        appState.generateWorkoutPlan(userMessage: planDetails)
        self.presentationMode.wrappedValue.dismiss()
    }
    
    func saveGeneratePlan(userId: String, planDetails: String) {
        let docData: [String: Any] = [
            "planDetails": planDetails,
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("WorkoutForm").document(userId).setData(docData) { error in
            if let error = error {
                print("Error writing document: \(error)")
            } else {
                print("Document successfully written!")
            }
        }
    }
}


struct WorkoutPlanForm_Previews: PreviewProvider {
    @State static var selectedTab = 0
    static var previews: some View {
        WorkoutPlanForm().environmentObject(AppState())
    }
}
