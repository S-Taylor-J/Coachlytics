//
//  SkillSelectionView.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

struct SkillSelectionView: View {
    let allSkills: [String]
    @Binding var selectedSkills: Set<String>
    @Environment(\.dismiss) private var dismiss
    @StateObject private var customOptionsManager = CustomOptionsManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        List {
            Section {
                ForEach(allSkills, id: \.self) { skill in
                    HStack {
                        Text(skill)
                        if customOptionsManager.isCustomSkill(skill) {
                            Image(systemName: "star.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        Spacer()
                        if selectedSkills.contains(skill) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedSkills.contains(skill) {
                            selectedSkills.remove(skill)
                        } else {
                            selectedSkills.insert(skill)
                        }
                    }
                }
            } footer: {
                HStack {
                    Text("Selected: \(selectedSkills.count)/\(allSkills.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if !selectedSkills.isEmpty {
                        Button("Clear All") {
                            selectedSkills.removeAll()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .scrollContentBackground(.hidden)
        .background(backgroundColor)
        .navigationTitle("Select Skills")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.05, green: 0.06, blue: 0.09) : Color(red: 0.97, green: 0.98, blue: 1.0)
    }
}
