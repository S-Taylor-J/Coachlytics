//
//  SettingView.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("minPlayersOnPitch") private var minPlayersOnPitch = 11
    @AppStorage("enableSkillFilter") private var enableSkillFilter = false
    @AppStorage("requiredSkills") private var requiredSkills: String = ""
    @AppStorage("defaultTeamId") private var defaultTeamId: String = ""
    @AppStorage(TeamColorSettings.ourTeamColorKey) private var ourTeamColorHex = TeamColorSettings.defaultOurTeamHex
    @AppStorage(TeamColorSettings.opponentTeamColorKey) private var opponentTeamColorHex = TeamColorSettings.defaultOpponentHex
    @AppStorage("showPlayerTimers") private var showPlayerTimers = false
    
    @Query(sort: \Team.name) private var teams: [Team]
    @StateObject private var customOptionsManager = CustomOptionsManager.shared
    @ObservedObject private var settingsStore = AppSettingsStore.shared
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var entitlements = EntitlementStore.shared

    // All skills including custom ones
    private var allSkills: [String] {
        customOptionsManager.allSkills
    }
    
    // All positions including custom ones
    private var allPositions: [String] {
        customOptionsManager.allPositions
    }

    @State private var selectedSkills: Set<String> = []

    // Live settings — edits publish straight through the store to every screen.
    private var circleResultSettings: CircleResultSettings { settingsStore.circleResultSettings }

    // Custom options input states
    @State private var newCustomSkill = ""
    @State private var newCustomPosition = ""
    @State private var showAddSkillAlert = false
    @State private var showAddPositionAlert = false
    @State private var showResetConfirmation = false
    @State private var showSkillsManagement = false
    @State private var showPositionsManagement = false
    @State private var showSignIn = false
    @State private var showSignUp = false
    @State private var showPaywall = false
    @State private var showAccount = false
    
    private var ourTeamColorBinding: Binding<Color> {
        Binding(
            get: { TeamColorSettings.color(from: ourTeamColorHex, fallback: .red) },
            set: { ourTeamColorHex = $0.toHex() }
        )
    }
    
    private var opponentTeamColorBinding: Binding<Color> {
        Binding(
            get: { TeamColorSettings.color(from: opponentTeamColorHex, fallback: .blue) },
            set: { opponentTeamColorHex = $0.toHex() }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                generalSection
                skillsPositionsSection
                skillFilterSection
                pitchDisplaySection
                eventRecordingSection
                eventMarkersSection
                teamColorsSection
                resetSection
            }
            .contentMargins(.bottom, 100, for: .scrollContent)
            .scrollContentBackground(.hidden)
            .appBackground()
            .tint(AppTheme.brandAccent)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSignIn) { SignInView() }
            .sheet(isPresented: $showSignUp) { SignUpView() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Reset All Settings?", isPresented: $showResetConfirmation) {
                Button("Reset", role: .destructive) {
                    resetToDefaults()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will restore all settings and custom options to their defaults.")
            }
            .onAppear {
                loadSelectedSkills()
            }
            .onDisappear {
                saveSelectedSkills()
            }
            .onChange(of: selectedSkills) {
                saveSelectedSkills()
            }
            .navigationDestination(isPresented: $showSkillsManagement) {
                SkillsManagementView(customOptionsManager: customOptionsManager)
            }
            .navigationDestination(isPresented: $showPositionsManagement) {
                PositionsManagementView(customOptionsManager: customOptionsManager)
            }
            .navigationDestination(isPresented: $showAccount) {
                AccountView()
            }
        }
    }

    // MARK: - Account

    /// Sits first in Settings because it is the entry point to everything cloud-related.
    /// Signed out it sells the idea and offers a way in; signed in it shows who you are, the
    /// current plan, and a route to the full account screen (including deletion).
    private var accountSection: some View {
        Section {
            if let profile = authService.state.profile {
                // A `Button` + `navigationDestination` rather than a `NavigationLink`: wrapping a
                // link around the whole card makes the List draw its own disclosure indicator
                // outside the card and shrink the card to fit it, which is what made this row
                // narrower than every other card on the screen. The sibling rows (Coachlytics Pro,
                // Manage Skills, Manage Positions) all navigate this way and own their chevron.
                Button {
                    showAccount = true
                } label: {
                    SettingsSectionCard(accent: AppTheme.brandAccent) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.brandAccent, AppTheme.brandDeepBlue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 42, height: 42)

                                Text(profile.initials)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.resolvedDisplayName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AppTheme.primaryText(colorScheme))

                                if !profile.email.isEmpty {
                                    Text(profile.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer(minLength: 0)

                            Text(entitlements.isPro ? "Pro" : "Free")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(entitlements.isPro ? AppTheme.goldAccent : AppTheme.mutedText(colorScheme))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(
                                        (entitlements.isPro ? AppTheme.goldAccent : AppTheme.mutedText(colorScheme))
                                            .opacity(0.15)
                                    )
                                )

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } else {
                SettingsSectionCard(accent: AppTheme.brandAccent) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "icloud.and.arrow.up.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(AppTheme.brandAccent)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sign in to back up your data")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AppTheme.primaryText(colorScheme))

                                Text("Keep your season safe and share it with your club.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)
                        }

                        HStack(spacing: 10) {
                            Button {
                                showSignUp = true
                            } label: {
                                Text("Create Account")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(AppTheme.brandAccent)
                                    )
                            }
                            .buttonStyle(.plain)

                            Button {
                                showSignIn = true
                            } label: {
                                Text("Sign In")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppTheme.brandAccent)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(AppTheme.brandAccent.opacity(0.45), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            if !entitlements.isPro {
                Button {
                    showPaywall = true
                } label: {
                    SettingsSectionCard(accent: AppTheme.goldAccent) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.goldAccent)

                            Text("Coachlytics Pro")
                                .foregroundStyle(AppTheme.primaryText(colorScheme))

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        } header: {
            Label("Account", systemImage: "person.crop.circle")
        } footer: {
            Text("Cloud backup and clubs are coming soon. Everything else works without an account.")
        }
    }

    private var generalSection: some View {
        Section {
            SettingsSectionCard(accent: AppTheme.brandAccent) {
                Picker("Default Team", selection: $defaultTeamId) {
                    Text("None").tag("")
                    ForEach(teams) { team in
                        Text(team.name).tag(team.id.uuidString)
                    }
                }

                Divider()

                Stepper("Minimum Players: \(minPlayersOnPitch)", value: $minPlayersOnPitch, in: 1...22)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        } header: {
            Label("General", systemImage: "gearshape")
        } footer: {
            Text("Set your default team and minimum players required on the pitch.")
        }
    }

    private var skillsPositionsSection: some View {
        Section {
            Button {
                showSkillsManagement = true
            } label: {
                SettingsSectionCard(accent: AppTheme.brandAccent) {
                    HStack {
                        Text("Manage Skills")
                        Spacer()
                        Text("\(customOptionsManager.allSkills.count) active")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            Button {
                showPositionsManagement = true
            } label: {
                SettingsSectionCard(accent: AppTheme.brandAccent) {
                    HStack {
                        Text("Manage Positions")
                        Spacer()
                        Text("\(customOptionsManager.allPositions.count) active")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        } header: {
            Label("Skills & Positions", systemImage: "list.bullet")
        } footer: {
            Text("Add custom skills and positions, or hide default ones you don't need.")
        }
    }

    private var skillFilterSection: some View {
        Section {
            SettingsSectionCard(accent: AppTheme.brandAccent) {
                Toggle("Filter by Required Skills", isOn: $enableSkillFilter)

                if enableSkillFilter {
                    Divider()

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
                                        .background(Capsule().fill(AppTheme.brandAccent.opacity(0.12)))
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
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        } header: {
            Label("Pitch Skill Filter", systemImage: "line.3.horizontal.decrease.circle")
        } footer: {
            Text(enableSkillFilter ? "Only players with selected skills will be available for the pitch." : "All players will be available regardless of skills.")
        }
    }

    private var pitchDisplaySection: some View {
        Section {
            SettingsSectionCard(accent: AppTheme.brandAccent) {
                Toggle("Show Player Timers", isOn: $showPlayerTimers)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        } header: {
            Label("Pitch Display", systemImage: "clock")
        } footer: {
            Text("Toggle timer badges under players on the pitch and bench.")
        }
    }

    private var eventRecordingSection: some View {
        Section {
            SettingsSectionCard(accent: AppTheme.brandAccent) {
                Toggle("Require Player for Infractions", isOn: $settingsStore.gameSettings.requirePlayerForInfractions)
                Divider()
                Toggle("Require Player for Circle Entry", isOn: $settingsStore.gameSettings.requirePlayerForCircleEntry)
                Divider()
                Toggle("Require Player for Turnover", isOn: $settingsStore.gameSettings.requirePlayerForTurnover)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        } header: {
            Label("Event Recording", systemImage: "square.and.pencil")
        } footer: {
            Text("When enabled, you'll select a specific player when recording events for your team.")
        }
    }

    private var eventMarkersSection: some View {
        Section {
            SettingsSectionCard(accent: AppTheme.brandAccent) {
                Toggle("Show Symbols on Pitch", isOn: $settingsStore.circleResultSettings.showSymbolsOnPitch)

                Divider()

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
                        Slider(value: $settingsStore.circleResultSettings.eventMarkerSize, in: 0.5...1.5, step: 0.25)
                        Image(systemName: "circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                NavigationLink {
                    CircleResultAppearanceView(settings: $settingsStore.circleResultSettings)
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
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        } header: {
            Label("Event Markers", systemImage: "paintpalette")
        } footer: {
            Text("Customize how event markers appear on the pitch.")
        }
    }

    private var teamColorsSection: some View {
        Section {
            SettingsSectionCard(accent: AppTheme.brandAccent) {
                ColorPicker("Our Team", selection: ourTeamColorBinding, supportsOpacity: false)
                Divider()
                ColorPicker("Opponent", selection: opponentTeamColorBinding, supportsOpacity: false)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        } header: {
            Label("Team Colors", systemImage: "paintpalette.fill")
        } footer: {
            Text("Customize the colors used for team highlights in game view.")
        }
    }

    private var resetSection: some View {
        Section {
            SettingsSectionCard(accent: AppTheme.brandAccent) {
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Reset All to Defaults", systemImage: "arrow.counterclockwise")
                            .foregroundStyle(.red)
                        Spacer()
                    }
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
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
        ourTeamColorHex = TeamColorSettings.defaultOurTeamHex
        opponentTeamColorHex = TeamColorSettings.defaultOpponentHex
        settingsStore.resetToDefaults() // Resets game + circle result settings and persists them
        customOptionsManager.resetSkillsToDefaults()
        customOptionsManager.resetPositionsToDefaults()
    }

}

private struct SettingsSectionCard<Content: View>: View {
    let accent: Color
    let content: Content

    @Environment(\.colorScheme) private var colorScheme

    init(accent: Color, @ViewBuilder content: () -> Content) {
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(14)
        .cardSurface(cornerRadius: 18, strokeAccent: accent, showShadow: false)
    }
}


// MARK: - Skills Management View
struct SkillsManagementView: View {
    @ObservedObject var customOptionsManager: CustomOptionsManager
    @State private var newSkillName = ""
    @State private var showResetAlert = false
    @FocusState private var isAddFieldFocused: Bool

    @Environment(\.colorScheme) private var colorScheme
    
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
                            .foregroundColor(AppTheme.brandAccent)
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
        .scrollContentBackground(.hidden)
        .appBackground()
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
    @Environment(\.colorScheme) private var colorScheme
    
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
                            .foregroundColor(AppTheme.brandAccent)
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
        .scrollContentBackground(.hidden)
        .appBackground()
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
                .foregroundColor(isHidden ? .gray : (isDefault ? AppTheme.brandAccent : AppTheme.warning))
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
                        .foregroundColor(AppTheme.warning)
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
                        .foregroundColor(isHidden ? .gray : AppTheme.success)
                }
            } else {
                // Delete button for custom skills
                Button {
                    onDelete?()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.danger)
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
                .foregroundColor(isHidden ? .gray : (isDefault ? AppTheme.brandAccent : AppTheme.warning))
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
                        .foregroundColor(AppTheme.warning)
                }
            }
            
            Spacer()
            
            if isDefault {
                Button {
                    onToggle?()
                } label: {
                    Image(systemName: isHidden ? "eye.slash.circle" : "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(isHidden ? .gray : AppTheme.success)
                }
            } else {
                Button {
                    onDelete?()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.danger)
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
                        .fill(isSelected ? AppTheme.brandAccent : Color.gray.opacity(0.2))
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
    @State private var editingResult: CircleResult? = nil
    
    // Available symbols for accessibility
    private let availableSymbols = [
        "soccerball", "flag.fill", "hand.raised.fill", "arrow.up.right",
        "arrow.triangle.2.circlepath", "flag.2.crossed.fill", "circle.dashed",
        "xmark.circle.fill", "checkmark.circle.fill", "star.fill",
        "bolt.fill", "target", "scope", "exclamationmark.triangle.fill"
    ]
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                // Preview section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Preview", systemImage: "eye.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            if resetFlash {
                                Label("Reset!", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(CircleResult.allCases, id: \.self) { result in
                                    VStack(spacing: 6) {
                                        CircleResultPreview(
                                            appearance: settings.appearance(for: result),
                                            showSymbol: settings.showSymbolsOnPitch,
                                            size: 36
                                        )
                                        Text(shortName(for: result))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(width: 52)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        Text("Changes update the game pitch markers and event lists.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .id("previewSection")
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
                // Section {
                //     VStack(spacing: 20) {
                //         HStack {
                //             Label("Preview", systemImage: "eye.fill")
                //                 .font(.headline)
                //                 .foregroundStyle(.primary)
                //             Spacer()
                            
                //             // Reset success indicator
                //             if resetFlash {
                //                 Label("Reset!", systemImage: "checkmark.circle.fill")
                //                     .font(.caption)
                //                     .fontWeight(.semibold)
                //                     .foregroundStyle(.green)
                //                     .transition(.scale.combined(with: .opacity))
                //             }
                //         }
                        
                //         // Pitch-style preview card
                //         ZStack {
                //             // Pitch background
                //             RoundedRectangle(cornerRadius: 16, style: .continuous)
                //                 .fill(
                //                     LinearGradient(
                //                         colors: [Color.green.opacity(0.3), Color.green.opacity(0.15)],
                //                         startPoint: .top,
                //                         endPoint: .bottom
                //                     )
                //                 )
                //                 .frame(height: 120)
                //                 .overlay(
                //                     RoundedRectangle(cornerRadius: 16, style: .continuous)
                //                         .stroke(resetFlash ? Color.green : Color.green.opacity(0.3), lineWidth: resetFlash ? 2 : 1)
                //                 )
                            
                //             GeometryReader { proxy in
                //                 let count = CGFloat(CircleResult.allCases.count)
                //                 let spacing: CGFloat = 16
                //                 let horizontalPadding: CGFloat = 16
                //                 let available = proxy.size.width - (horizontalPadding * 2) - (spacing * (count - 1))
                //                 let computedSize = available / count
                //                 let markerSize = min(40, max(26, computedSize))
                //                 let needsScroll = computedSize < 30

                //                 ScrollView(.horizontal, showsIndicators: false) {
                //                     HStack(spacing: spacing) {
                //                         ForEach(CircleResult.allCases, id: \.self) { result in
                //                             VStack(spacing: 6) {
                //                                 CircleResultPreview(
                //                                     appearance: settings.appearance(for: result),
                //                                     showSymbol: settings.showSymbolsOnPitch,
                //                                     size: markerSize
                //                                 )
                                                
                //                                 Text(shortName(for: result))
                //                                     .font(.system(size: 10, weight: .semibold, design: .rounded))
                //                                     .foregroundStyle(.primary.opacity(0.8))
                //                                     .lineLimit(1)
                //                                     .minimumScaleFactor(0.7)
                //                             }
                //                             .frame(width: markerSize + 6)
                //                         }
                //                     }
                //                     .padding(.horizontal, horizontalPadding)
                //                     .frame(maxWidth: needsScroll ? .infinity : nil, alignment: .center)
                //                 }
                //             }
                //             .padding(.vertical, 8)
                //         }
                //         .scaleEffect(resetFlash ? 1.02 : 1.0)
                        
                //         // Legend
                //         Text("Markers will appear on the pitch during gameplay")
                //             .font(.caption)
                //             .foregroundStyle(.secondary)
                //             .frame(maxWidth: .infinity, alignment: .center)
                //     }
                //     .padding(.vertical, 12)
                // }
                // .id("previewSection")
            
                // Individual outcome settings
                ForEach(CircleResult.allCases, id: \.self) { result in
                    Section {
                        OutcomePreviewRow(
                            result: result,
                            appearance: settings.appearance(for: result)
                        ) {
                            editingResult = result
                        }
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
            .scrollContentBackground(.hidden)
            .appBackground()
        }
        .navigationTitle("Outcome Colors")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingResult) { result in
            OutcomeEditSheet(
                result: result,
                appearance: bindingForResult(result),
                availableSymbols: availableSymbols
            )
        }
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

extension CircleResult: Identifiable {
    var id: String { rawValue }
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
                .overlay(
                    Image(systemName: showSymbol ? appearance.symbol : "circle.fill")
                        .font(.system(size: size * 0.33, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }
}

// MARK: - Outcome Setting Row
struct OutcomePreviewRow: View {
    let result: CircleResult
    let appearance: CircleResultAppearance
    let onEdit: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            CircleResultPreview(appearance: appearance, showSymbol: true, size: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text("Preview")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(appearance.color)
                            .frame(width: 10, height: 10)
                        Text(appearance.colorHex.uppercased())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: appearance.symbol)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text(symbolName(for: appearance.symbol))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Button("Edit") {
                onEdit()
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.secondarySurfaceFill(colorScheme))
        )
    }
    
    private func symbolName(for symbol: String) -> String {
        symbol.replacingOccurrences(of: ".fill", with: "")
            .replacingOccurrences(of: ".", with: " ")
            .capitalized
    }
}

// MARK: - Outcome Edit Sheet
struct OutcomeEditSheet: View {
    let result: CircleResult
    @Binding var appearance: CircleResultAppearance
    let availableSymbols: [String]
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: appearance.colorHex) ?? .gray },
            set: { appearance.colorHex = $0.toHex() }
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        CircleResultPreview(appearance: appearance, showSymbol: true, size: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.rawValue)
                                .font(.headline)
                            HStack(spacing: 10) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(appearance.color)
                                        .frame(width: 10, height: 10)
                                    Text(appearance.colorHex.uppercased())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                HStack(spacing: 6) {
                                    Image(systemName: appearance.symbol)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                    Text(symbolName(for: appearance.symbol))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.secondarySurfaceFill(colorScheme))
                    )
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Color", systemImage: "paintpalette.fill")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            ColorPicker("", selection: colorBinding, supportsOpacity: false)
                                .labelsHidden()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Icon", systemImage: "star.circle.fill")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("For accessibility")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(AppTheme.secondarySurfaceFill(colorScheme)))
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
                .padding(16)
            }
            .appBackground()
            .navigationTitle("Edit Outcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
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
                            colors: [AppTheme.secondarySurfaceFill(colorScheme), AppTheme.secondarySurfaceFill(colorScheme)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
                    .frame(width: 40, height: 40)
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
