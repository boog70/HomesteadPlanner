import SwiftUI

struct WizardStep1View: View {
    @Environment(\.appState) var appState
    @Environment(\.navigationPath) var path

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Step 1: Who's in your family?")
                    .font(.title2.bold())
                Text("Add each family member so we can calculate your nutritional needs.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let state = appState {
                    FamilyFormView(state: state)
                }

                HStack {
                    Spacer()
                    Button("Next: Enter location") {
                        path?.wrappedValue.append(Route.step2)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(appState?.family.isEmpty ?? true)
                }
                .padding(.top)
            }
            .padding(24)
        }
        .navigationTitle("Family")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FamilyFormView: View {
    let state: AppState
    @State private var heightFt: [String: String] = [:]
    @State private var heightIn: [String: String] = [:]
    @State private var weightLb: [String: String] = [:]

    private let cmPerIn = 2.54
    private let kgPerLb = 0.45359237

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Family Composition")
                .font(.headline)
            ForEach(state.family) { member in
                FamilyMemberCard(member: member, state: state, heightFt: $heightFt, heightIn: $heightIn, weightLb: $weightLb)
            }
            Button("Add family member") {
                state.addFamilyMember()
            }
            .buttonStyle(.bordered)
            .tint(.green)
        }
    }
}

struct FamilyMemberCard: View {
    let member: FamilyMember
    let state: AppState
    @Binding var heightFt: [String: String]
    @Binding var heightIn: [String: String]
    @Binding var weightLb: [String: String]

    private let kgPerLb = 0.45359237
    private let cmPerIn = 2.54

    private var ageBinding: Binding<Int> {
        Binding(get: { member.age }, set: { v in state.updateFamilyMember(id: member.id) { $0.age = max(1, min(100, v)) } })
    }
    private var sexBinding: Binding<Sex> {
        Binding(get: { member.sex }, set: { v in state.updateFamilyMember(id: member.id) { $0.sex = v } })
    }
    private var activityBinding: Binding<ActivityLevel> {
        Binding(get: { member.activityLevel }, set: { v in state.updateFamilyMember(id: member.id) { $0.activityLevel = v } })
    }
    private var unitBinding: Binding<UnitSystem> {
        Binding(get: { member.unitSystem }, set: { v in state.updateFamilyMember(id: member.id) { $0.unitSystem = v } })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("Age", selection: ageBinding) {
                    ForEach(1..<101, id: \.self) { Text("\($0)").tag($0) }
                }
                .frame(width: 80)
                Picker("Sex", selection: sexBinding) {
                    Text("Female").tag(Sex.female)
                    Text("Male").tag(Sex.male)
                }
                .pickerStyle(.menu)
                Picker("Activity", selection: activityBinding) {
                    ForEach(ActivityLevel.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                .pickerStyle(.menu)
                Spacer()
                Button(role: .destructive) { state.removeFamilyMember(id: member.id) } label: {
                    Image(systemName: "trash")
                }
            }
            HeightWeightRow(member: member, state: state, heightFt: $heightFt, heightIn: $heightIn, weightLb: $weightLb, unitSystem: unitBinding, kgPerLb: kgPerLb, cmPerIn: cmPerIn)
            if member.sex == .female && member.age >= 19 {
                Toggle("Pregnant", isOn: Binding(get: { member.isPregnant ?? false }, set: { v in state.updateFamilyMember(id: member.id) { $0.isPregnant = v } }))
                Toggle("Lactating", isOn: Binding(get: { member.isLactating ?? false }, set: { v in state.updateFamilyMember(id: member.id) { $0.isLactating = v } }))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct HeightWeightRow: View {
    let member: FamilyMember
    let state: AppState
    @Binding var heightFt: [String: String]
    @Binding var heightIn: [String: String]
    @Binding var weightLb: [String: String]
    @Binding var unitSystem: UnitSystem
    let kgPerLb: Double
    let cmPerIn: Double

    var body: some View {
        HStack(spacing: 12) {
            if member.unitSystem == .imperial {
                TextField("Ft", text: Binding(
                    get: { heightFt[member.id] ?? "5" },
                    set: { heightFt[member.id] = $0; updateHeightFromImperial() }
                ))
                .keyboardType(.numberPad)
                .frame(width: 40)
                TextField("In", text: Binding(
                    get: { heightIn[member.id] ?? "0" },
                    set: { heightIn[member.id] = $0; updateHeightFromImperial() }
                ))
                .keyboardType(.numberPad)
                .frame(width: 40)
            } else {
                TextField("Height (cm)", value: Binding(
                    get: { member.heightCm },
                    set: { v in state.updateFamilyMember(id: member.id) { $0.heightCm = v } }
                ), format: .number)
                .keyboardType(.decimalPad)
                .frame(width: 80)
            }
            TextField("Weight", text: weightBinding)
                .keyboardType(.decimalPad)
                .frame(width: 60)
            Picker("Units", selection: $unitSystem) {
                Text("Imperial").tag(UnitSystem.imperial)
                Text("Metric").tag(UnitSystem.metric)
            }
            .pickerStyle(.segmented)
        }
    }

    private var weightBinding: Binding<String> {
        Binding(
            get: { member.unitSystem == .imperial ? (weightLb[member.id] ?? "150") : String(format: "%.1f", member.weightKg) },
            set: { weightLb[member.id] = $0; if let v = Double($0) { state.updateFamilyMember(id: member.id) { $0.weightKg = member.unitSystem == .imperial ? v * kgPerLb : v } } }
        )
    }

    private func updateHeightFromImperial() {
        let ft = Int(heightFt[member.id] ?? "5") ?? 5
        let inch = Int(heightIn[member.id] ?? "0") ?? 0
        state.updateFamilyMember(id: member.id) { $0.heightCm = Double(ft * 12 + inch) * cmPerIn }
    }
}
