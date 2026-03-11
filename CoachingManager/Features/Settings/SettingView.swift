//
//  SettingView.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("minPlayersOnPitch") private var minPlayersOnPitch = 11
    @AppStorage("enableSkillFilter") private var enableSkillFilter = false
    @AppStorage("requiredSkills") private var requiredSkills: String = ""
    @AppStorage("gameSettingsData") private var gameSettingsData: String = ""
    @AppStorage("defaultTeamId") private var defaultTeamId: String = ""
    
    @Query(sort: \Team.name) private var teams: [Team]
    @StateObject private var customOptionsManager = CustomOptionsManager.shared

    // All skills including custom ones
    private var allSkills: [String] {
        customOptionsManager.allSkills
    }
    
    // All positions including custom ones
    private var allPositions: [String] {
        customOptionsManager.allPositions
    }

    @State private var selectedSkills: Set<String> = []
    @State private var gameSettings = GameSettings()
    @State private var circleResultSettings = CircleResultSettings()
    
    // Custom options input states
    @State private var newCustomSkill = ""
    @State private var newCustomPosition = ""
    @State private var showAddSkillAlert = false
    @State private var showAddPositionAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - General Settings
                Section {
                    Picker("Default Team", selection: $defaultTeamId) {
                        Text("None").tag("")
                        ForEach(teams) { team in
                            Text(team.name).tag(team.id.uuidString)
                        }
                    }
                    
                    Stepper("Minimum Players: \(minPlayersOnPitch)", value: $minPlayersOnPitch, in: 1...22)
                } header: {
                    Label("General", systemImage: "gearshape")
                } footer: {
                    Text("Set your default team and minimum players required on the pitch.")
                }
                
                // MARK: - Skills & Positions Management
                Section {
                    NavigationLink {
                        SkillsManagementView(customOptionsManager: customOptionsManager)
                    } label: {
                        HStack {
                            Label("Manage Skills", systemImage: "star.fill")
                            Spacer()
                            Text("\(customOptionsManager.allSkills.count) active")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }
                    
                    NavigationLink {
                        PositionsManagementView(customOptionsManager: customOptionsManager)
                    } label: {
                        HStack {
                            Label("Manage Positions", systemImage: "figure.run")
                            Spacer()
                            Text("\(customOptionsManager.allPositions.count) active")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Label("Skills & Positions", systemImage: "list.bullet")
                } footer: {
                    Text("Add custom skills and positions, or hide default ones you don't need.")
                }
                
                // MARK: - Skill Filter Section
                Section {
                    Toggle("Filter by Required Skills", isOn: $enableSkillFilter)

                    if enableSkillFilter {
                        VStack(alignment: .leading, spacing: 12) {
                            if !selectedSkills.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Array(selectedSkills), id: \.self) { skill in
                                            HStack(spacing: 4) {
                                                Text(skill)
                                                    .font(.caption)
                                                Button {
                                                    selectedSkills.remove(skill)
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Capsule().fill(Color.blue.opacity(0.1)))
                                        }
                                    }
                                }
                                .frame(height: 40)
                            }

                            NavigationLink {
                                SkillSelectionView(
                                    allSkills: allSkills,
                                    selectedSkills: $selectedSkills
                                )
                            } label: {
                                HStack {
                                    Text("Select Required Skills")
                                    Spacer()
                                    Text("\(selectedSkills.count) selected")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Label("Pitch Skill Filter", systemImage: "line.3.horizontal.decrease.circle")
                } footer: {
                    Text(enableSkillFilter ? "Only players with selected skills will be available for the pitch." : "All players will be available regardless of skills.")
                }
                
                // MARK: - Event Recording Settings
                Section {
                    Toggle("Require Player for Infractions", isOn: $gameSettings.requirePlayerForInfractions)
                    Toggle("Require Player for Circle Entry", isOn: $gameSettings.requirePlayerForCircleEntry)
                    Toggle("Require Player for Turnover", isOn: $gameSettings.requirePlayerForTurnover)
                } header: {
                    Label("Event Recording", systemImage: "square.and.pencil")
                } footer: {
                    Text("When enabled, you'll select a specific player when recording events for your team.")
                }
                
                // MARK: - Event Marker Appearance
                Section {
                    Toggle("Show Symbols on Pitch", isOn: $circleResultSettings.showSymbolsOnPitch)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Marker Size")
                            Spacer()
                            Text(markerSizeLabel)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Slider(value: $circleResultSettings.eventMarkerSize, in: 0.5...1.5, step: 0.25)
                            Image(systemName: "circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        CircleResultAppearanceView(settings: $circleResultSettings)
                    } label: {
                        HStack {
                            Text("Customize Colors")
                            Spacer()
                            HStack(spacing: 4) {
                                ForEach([CircleResult.goal, .penaltyCorner, .shotSaved, .turnover], id: \.self) { result in
                                    Circle()
                                        .fill(circleResultSettings.appearance(for: result).color)
                                        .frame(width: 14, height: 14)
                                }
                            }
                        }
                    }
                } header: {
                    Label("Event Markers", systemImage: "paintpalette")
                } footer: {
                    Text("Customize how event markers appear on the pitch.")
                }

                // MARK: - Save & Reset
                Section {
                    Button {
                        saveSettings()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Save Settings", systemImage: "checkmark.circle.fill")
                            Spacer()
                        }
                    }
                    .disabled(!settingsChanged())
                    
                    Button(role: .destructive) {
                        resetToDefaults()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Reset All to Defaults", systemImage: "arrow.counterclockwise")
                            Spacer()
                        }
                    }
                }
            }
            .contentMargins(.bottom, 100, for: .scrollContent)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadSettings()
                loadSelectedSkills()
                circleResultSettings = CircleResultSettings.loadFromDefaults()
            }
            .onDisappear {
                saveSelectedSkills()
                circleResultSettings.saveToDefaults()
            }
            .onChange(of: selectedSkills) {
                saveSelectedSkills()
            }
            .onChange(of: circleResultSettings) {
                circleResultSettings.saveToDefaults()
            }
        }
    }

    // MARK: - Helper Methods
    
    private var markerSizeLabel: String {
        switch circleResultSettings.eventMarkerSize {
        case 0.5: return "Small"
        case 0.75: return "Medium Small"
        case 1.0: return "Normal"
        case 1.25: return "Medium Large"
        case 1.5: return "Large"
        default: return String(format: "%.0f%%", circleResultSettings.eventMarkerSize * 100)
        }
    }

    private func loadSelectedSkills() {
        if let data = requiredSkills.data(using: String.Encoding.utf8),
           let skills = try? JSONDecoder().decode([String].self, from: data) {
            selectedSkills = Set(skills)
        }
    }

    private func saveSelectedSkills() {
        if let data = try? JSONEncoder().encode(Array(selectedSkills)) {
            requiredSkills = String(data: data, encoding: String.Encoding.utf8) ?? ""
        }
    }

    private func resetToDefaults() {
        minPlayersOnPitch = 11
        enableSkillFilter = false
        selectedSkills = []
        requiredSkills = ""
        defaultTeamId = ""
        gameSettings = GameSettings() // Reset to default game settings
        circleResultSettings = CircleResultSettings() // Reset circle result settings
        circleResultSettings.saveToDefaults()
        customOptionsManager.resetSkillsToDefaults()
        customOptionsManager.resetPositionsToDefaults()
        saveSettings() // Save the reset state
    }

    private func saveSettings() {
        do {
            let data = try JSONEncoder().encode(gameSettings)
            gameSettingsData = String(data: data, encoding: String.Encoding.utf8) ?? ""
        } catch {
            print("Failed to save settings: \(error)")
        }
    }

    private func loadSettings() {
        guard let data = gameSettingsData.data(using: String.Encoding.utf8) else { return }
        do {
            gameSettings = try JSONDecoder().decode(GameSettings.self, from: data)
        } catch {
            print("Failed to load settings: \(error)")
        }
    }

    private func settingsChanged() -> Bool {
        // Check if current settings differ from saved ones
        guard let data = gameSettingsData.data(using: String.Encoding.utf8),
              let savedSettings = try? JSONDecoder().decode(GameSettings.self, from: data) else {
            return true
        }
        return gameSettings.quarters != savedSettings.quarters ||
               gameSettings.quarterDuration != savedSettings.quarterDuration ||
               gameSettings.halfTimeDuration != savedSettings.halfTimeDuration ||
               gameSettings.requirePlayerForInfractions != savedSettings.requirePlayerForInfractions ||
               gameSettings.requirePlayerForCircleEntry != savedSettings.requirePlayerForCircleEntry ||
               gameSettings.requirePlayerForTurnover != savedSettings.requirePlayerForTurnover
    }
}

// MARK: - Skills Management View
struct SkillsManagementView: View {
    @ObservedObject var customOptionsManager: CustomOptionsManager
    @State private var newSkillName = ""
    @State private var showResetAlert = false
    @FocusState private var isAddFieldFocused: Bool
    
    var body: some View {
        List {
            // MARK: - Active Skills
            Section {
                // Default skills (can be hidden)
                ForEach(PlayerOptions.defaultSkills, id: \.self) { skill in
                    SkillRowView(
                        name: skill,
                        isDefault: true,
                        isHidden: customOptionsManager.isDefaultSkillHidden(skill),
                        onToggle: {
                            withAnimation {
                                if customOptionsManager.isDefaultSkillHidden(skill) {
                                    customOptionsManager.showDefaultSkill(skill)
                                } else {
                                    customOptionsManager.hideDefaultSkill(skill)
                                }
                            }
                        }
                    )
                }
                
                // Custom skills
                ForEach(customOptionsManager.customSkills, id: \.self) { skill in
                    SkillRowView(
                        name: skill,
                        isDefault: false,
                        isHidden: false,
                        onDelete: {
                            withAnimation {
                                customOptionsManager.removeCustomSkill(skill)
                            }
                        }
                    )
                }
            } header: {
                HStack {
                    Text("Skills")
                    Spacer()
                    Text("\(customOptionsManager.allSkills.count) active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } footer: {
                Text("Toggle default skills on/off, or delete custom skills. Hidden skills won't appear in player forms or filters.")
            }
            
            // MARK: - Add New Skill
            Section {
                HStack {
                    TextField("New skill name", text: $newSkillName)
                        .textInputAutocapitalization(.words)
                        .focused($isAddFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            addSkill()
                        }
                    
                    Button {
                        addSkill()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(newSkillName.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .blue)
                    }
                    .disabled(newSkillName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                Text("Add Custom Skill")
            }
            
            // MARK: - Hidden Skills
            if !customOptionsManager.hiddenDefaultSkills.isEmpty {
                Section {
                    ForEach(Array(customOptionsManager.hiddenDefaultSkills).sorted(), id: \.self) { skill in
                        HStack {
                            Image(systemName: "eye.slash")
                                .foregroundColor(.secondary)
                            Text(skill)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Restore") {
                                withAnimation {
                                    customOptionsManager.showDefaultSkill(skill)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("Hidden Default Skills")
                }
            }
            
            // MARK: - Reset
            Section {
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Reset Skills to Defaults", systemImage: "arrow.counterclockwise")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Manage Skills")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset Skills?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                withAnimation {
                    customOptionsManager.resetSkillsToDefaults()
                }
            }
        } message: {
            Text("This will remove all custom skills and restore all default skills.")
        }
    }
    
    private func addSkill() {
        let trimmed = newSkillName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        withAnimation {
            customOptionsManager.addCustomSkill(trimmed)
            newSkillName = ""
        }
        isAddFieldFocused = false
    }
}

// MARK: - Positions Management View
struct PositionsManagementView: View {
    @ObservedObject var customOptionsManager: CustomOptionsManager
    @State private var newPositionName = ""
    @State private var showResetAlert = false
    @FocusState private var isAddFieldFocused: Bool
    
    private func iconForPosition(_ position: String) -> String {
        switch position {
        case "Goalkeeper": return "hand.raised.fill"
        case "Defender": return "shield.fill"
        case "Midfielder": return "arrow.left.arrow.right"
        case "Forward": return "scope"
        default: return "person.fill"
        }
    }
    
    var body: some View {
        List {
            // MARK: - Active Positions
            Section {
                // Default positions (can be hidden)
                ForEach(PlayerOptions.defaultPositions, id: \.self) { position in
                    PositionRowView(
                        name: position,
                        icon: iconForPosition(position),
                        isDefault: true,
                        isHidden: customOptionsManager.isDefaultPositionHidden(position),
                        onToggle: {
                            withAnimation {
                                if customOptionsManager.isDefaultPositionHidden(position) {
                                    customOptionsManager.showDefaultPosition(position)
                                } else {
                                    customOptionsManager.hideDefaultPosition(position)
                                }
                            }
                        }
                    )
                }
                
                // Custom positions
                ForEach(customOptionsManager.customPositions, id: \.self) { position in
                    PositionRowView(
                        name: position,
                        icon: "person.fill",
                        isDefault: false,
                        isHidden: false,
                        onDelete: {
                            withAnimation {
                                customOptionsManager.removeCustomPosition(position)
                            }
                        }
                    )
                }
            } header: {
                HStack {
                    Text("Positions")
                    Spacer()
                    Text("\(customOptionsManager.allPositions.count) active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } footer: {
                Text("Toggle default positions on/off, or delete custom positions. Hidden positions won't appear in player forms or filters.")
            }
            
            // MARK: - Add New Position
            Section {
                HStack {
                    TextField("New position name", text: $newPositionName)
                        .textInputAutocapitalization(.words)
                        .focused($isAddFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            addPosition()
                        }
                    
                    Button {
                        addPosition()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(newPositionName.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .blue)
                    }
                    .disabled(newPositionName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                Text("Add Custom Position")
            }
            
            // MARK: - Hidden Positions
            if !customOptionsManager.hiddenDefaultPositions.isEmpty {
                Section {
                    ForEach(Array(customOptionsManager.hiddenDefaultPositions).sorted(), id: \.self) { position in
                        HStack {
                            Image(systemName: "eye.slash")
                                .foregroundColor(.secondary)
                            Text(position)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Restore") {
                                withAnimation {
                                    customOptionsManager.showDefaultPosition(position)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("Hidden Default Positions")
                }
            }
            
            // MARK: - Reset
            Section {
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Reset Positions to Defaults", systemImage: "arrow.counterclockwise")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Manage Positions")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset Positions?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                withAnimation {
                    customOptionsManager.resetPositionsToDefaults()
                }
            }
        } message: {
            Text("This will remove all custom positions and restore all default positions.")
        }
    }
    
    private func addPosition() {
        let trimmed = newPositionName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        withAnimation {
            customOptionsManager.addCustomPosition(trimmed)
            newPositionName = ""
        }
        isAddFieldFocused = false
    }
}

// MARK: - Skill Row View
struct SkillRowView: View {
    let name: String
    let isDefault: Bool
    let isHidden: Bool
    var onToggle: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .foregroundColor(isHidden ? .gray : (isDefault ? .blue : .orange))
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .foregroundColor(isHidden ? .secondary : .primary)
                if isDefault {
                    Text("Default")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Custom")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            if isDefault {
                // Toggle button for default skills
                Button {
                    onToggle?()
                } label: {
                    Image(systemName: isHidden ? "eye.slash.circle" : "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(isHidden ? .gray : .green)
                }
            } else {
                // Delete button for custom skills
                Button {
                    onDelete?()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                }
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Position Row View
struct PositionRowView: View {
    let name: String
    let icon: String
    let isDefault: Bool
    let isHidden: Bool
    var onToggle: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isHidden ? .gray : (isDefault ? .blue : .orange))
                .font(.caption)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .foregroundColor(isHidden ? .secondary : .primary)
                if isDefault {
                    Text("Default")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Custom")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            if isDefault {
                Button {
                    onToggle?()
                } label: {
                    Image(systemName: isHidden ? "eye.slash.circle" : "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(isHidden ? .gray : .green)
                }
            } else {
                Button {
                    onDelete?()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                }
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Skill Chip View

struct SkillChip: View {
    let skill: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(skill)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Circle Result Appearance View
struct CircleResultAppearanceView: View {
    @Binding var settings: CircleResultSettings
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showResetConfirmation = false
    @State private var resetFlash = false
    
    // Available symbols for accessibility
    private let availableSymbols = [
        "soccerball", "flag.fill", "hand.raised.fill", "arrow.up.right",
        "arrow.triangle.2.circlepath", "flag.2.crossed.fill", "circle.dashed",
        "xmark.circle.fill", "checkmark.circle.fill", "star.fill",
        "bolt.fill", "target", "scope", "exclamationmark.triangle.fill"
    ]
    
    // Predefined color palette
    private let colorPalette: [(name: String, hex: String)] = [
        ("Green", "#34C759"),
        ("Orange", "#FF9500"),
        ("Blue", "#007AFF"),
        ("Purple", "#AF52DE"),
        ("Red", "#FF3B30"),
        ("Indigo", "#5856D6"),
        ("Gray", "#8E8E93"),
        ("Teal", "#5AC8FA"),
        ("Pink", "#FF2D55"),
        ("Yellow", "#FFCC00"),
        ("Mint", "#00C7BE"),
        ("Cyan", "#32ADE6")
    ]
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                // Accessibility info section
//            Section {
//                HStack(spacing: 12) {
//                    Image(systemName: "accessibility")
//                        .font(.title2)
//                        .foregroundStyle(.blue)
//                    
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("Accessibility")
//                            .font(.headline)
//                        Text("Each outcome has both a unique color AND symbol to help distinguish them regardless of color vision.")
//                            .font(.caption)
//                            .foregroundStyle(.secondary)
//                    }
//                }
//                .padding(.vertical, 8)
//            }
            
                // Preview section
                Section {
                    VStack(spacing: 20) {
                        HStack {
                            Label("Preview", systemImage: "eye.fill")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            
                            // Reset success indicator
                            if resetFlash {
                                Label("Reset!", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        
                        // Pitch-style preview card
                        ZStack {
                            // Pitch background
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.3), Color.green.opacity(0.15)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(resetFlash ? Color.green : Color.green.opacity(0.3), lineWidth: resetFlash ? 2 : 1)
                                )
                            
                            // Event markers
                            HStack(spacing: 20) {
                                ForEach(CircleResult.allCases, id: \.self) { result in
                                    VStack(spacing: 8) {
                                        CircleResultPreview(
                                            appearance: settings.appearance(for: result),
                                            showSymbol: settings.showSymbolsOnPitch,
                                            size: 40
                                        )
                                        
                                        Text(shortName(for: result))
                                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.primary.opacity(0.8))
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .scaleEffect(resetFlash ? 1.02 : 1.0)
                        
                        // Legend
                        Text("Markers will appear on the pitch during gameplay")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical, 12)
                }
                .id("previewSection")
            
                // Individual outcome settings
                ForEach(CircleResult.allCases, id: \.self) { result in
                    Section {
                        OutcomeSettingRow(
                            result: result,
                            appearance: bindingForResult(result),
                            colorPalette: colorPalette,
                            availableSymbols: availableSymbols
                        )
                } header: {
                    Text(result.rawValue)
                }
            }
            
                // Reset to defaults
                Section {
                    Button(role: .destructive) {
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        // Reset settings
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            settings = CircleResultSettings()
                        }
                        
                        // Scroll to top
                        withAnimation(.easeInOut(duration: 0.4)) {
                            proxy.scrollTo("previewSection", anchor: .top)
                        }
                        
                        // Show success flash
                        withAnimation(.spring(response: 0.3)) {
                            resetFlash = true
                        }
                        
                        // Success haptic
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            let notificationFeedback = UINotificationFeedbackGenerator()
                            notificationFeedback.notificationOccurred(.success)
                        }
                        
                        // Hide flash after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                resetFlash = false
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Reset to Default Colors")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Outcome Colors")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func shortName(for result: CircleResult) -> String {
        switch result {
        case .goal: return "Goal"
        case .penaltyCorner: return "PC"
        case .shotSaved: return "Saved"
        case .shotWide: return "Wide"
        case .turnover: return "Turn"
        case .longCorner: return "LC"
        case .nothing: return "None"
        }
    }
    
    private func bindingForResult(_ result: CircleResult) -> Binding<CircleResultAppearance> {
        switch result {
        case .goal:
            return $settings.goalAppearance
        case .penaltyCorner:
            return $settings.penaltyCornerAppearance
        case .shotSaved:
            return $settings.shotSavedAppearance
        case .shotWide:
            return $settings.shotWideAppearance
        case .turnover:
            return $settings.turnoverAppearance
        case .longCorner:
            return $settings.longCornerAppearance
        case .nothing:
            return $settings.nothingAppearance
        }
    }
}

// MARK: - Circle Result Preview
struct CircleResultPreview: View {
    let appearance: CircleResultAppearance
    let showSymbol: Bool
    var size: CGFloat = 36
    
    var body: some View {
        ZStack {
            Circle()
                .fill(appearance.color.opacity(0.2))
                .frame(width: size, height: size)
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [appearance.color, appearance.color.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.78, height: size * 0.78)
                .shadow(color: appearance.color.opacity(0.4), radius: 4, x: 0, y: 2)
                .overlay(
                    Image(systemName: showSymbol ? appearance.symbol : "circle.fill")
                        .font(.system(size: size * 0.33, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }
}

// MARK: - Outcome Setting Row
struct OutcomeSettingRow: View {
    let result: CircleResult
    @Binding var appearance: CircleResultAppearance
    let colorPalette: [(name: String, hex: String)]
    let availableSymbols: [String]
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // Live Preview Card
            HStack(spacing: 16) {
                CircleResultPreview(appearance: appearance, showSymbol: true, size: 56)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Live Preview")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(appearance.color)
                                .frame(width: 12, height: 12)
                            Text(colorName(for: appearance.colorHex))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: appearance.symbol)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Text(symbolName(for: appearance.symbol))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.5))
            )
            
            // Color Selection
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Color", systemImage: "paintpalette.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                    ForEach(colorPalette, id: \.hex) { color in
                        ColorSelectionButton(
                            color: Color(hex: color.hex) ?? .gray,
                            isSelected: appearance.colorHex == color.hex,
                            colorName: color.name
                        ) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                appearance.colorHex = color.hex
                            }
                        }
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Symbol Selection
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Symbol", systemImage: "star.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text("For accessibility")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray5))
                        )
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                    ForEach(availableSymbols, id: \.self) { symbol in
                        SymbolSelectionButton(
                            symbol: symbol,
                            isSelected: appearance.symbol == symbol,
                            accentColor: appearance.color
                        ) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                appearance.symbol = symbol
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 12)
    }
    
    private func colorName(for hex: String) -> String {
        colorPalette.first(where: { $0.hex == hex })?.name ?? "Custom"
    }
    
    private func symbolName(for symbol: String) -> String {
        symbol.replacingOccurrences(of: ".fill", with: "")
            .replacingOccurrences(of: ".", with: " ")
            .capitalized
    }
}

// MARK: - Color Selection Button
struct ColorSelectionButton: View {
    let color: Color
    let isSelected: Bool
    let colorName: String
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background ring for selection
                Circle()
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2.5)
                    .frame(width: 42, height: 42)
                
                // Color circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 34, height: 34)
                    .shadow(color: isSelected ? color.opacity(0.5) : .clear, radius: 4, x: 0, y: 2)
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(colorName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Symbol Selection Button
struct SymbolSelectionButton: View {
    let symbol: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected 
                        ? LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                        : LinearGradient(
                            colors: [Color(.systemGray5), Color(.systemGray5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
                    .frame(width: 40, height: 40)
                    .shadow(color: isSelected ? accentColor.opacity(0.4) : .clear, radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSelected ? accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                
                // Symbol
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white.opacity(0.8) : .primary.opacity(0.7)))
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol.replacingOccurrences(of: ".", with: " "))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    SettingsView()
}
