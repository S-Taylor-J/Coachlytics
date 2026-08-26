//
//  AddCalendarNoteSheet.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

/// Sheet for adding/editing calendar notes
struct AddCalendarNoteSheet: View {
    let date: Date
    let existingNote: String
    let onSave: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var noteText: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date display
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.brandAccent)

                            Text(date.dayOfWeek)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.primaryText(colorScheme))

                            Spacer()
                        }

                        Text(date.fullDate)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText(colorScheme))
                    }
                    .padding(16)
                    .cardSurface(cornerRadius: 12, strokeAccent: AppTheme.brandAccent)

                    // Note input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText(colorScheme))

                        TextField("Enter your note...", text: $noteText, axis: .vertical)
                            .font(.system(size: 15))
                            .lineLimit(5...10)
                            .padding(12)
                            .cardSurface(cornerRadius: 12, showShadow: false)
                    }

                    // Quick suggestions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Add")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText(colorScheme))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(["Training 6pm", "Game Day", "Team Meeting", "Practice Match", "Rest Day"], id: \.self) { suggestion in
                                    Button {
                                        noteText = suggestion
                                    } label: {
                                        Text(suggestion)
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(AppTheme.brandAccent)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(AppTheme.brandAccent.opacity(0.12))
                                            )
                                    }
                                }
                            }
                        }
                    }

                    // Delete button - only show if there's an existing note
                    if !existingNote.isEmpty {
                        Button(role: .destructive) {
                            onSave("")
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Delete Note")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppTheme.danger)
                            )
                        }
                    }
                }
                .padding(20)
            }
            .appBackground()
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(noteText.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                noteText = existingNote
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    AddCalendarNoteSheet(
        date: Date(),
        existingNote: "",
        onSave: { _ in }
    )
}
