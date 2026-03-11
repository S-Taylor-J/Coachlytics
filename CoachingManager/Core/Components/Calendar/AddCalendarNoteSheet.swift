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
                                .foregroundColor(.blue)
                            
                            Text(date.dayOfWeek)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                            
                            Spacer()
                        }
                        
                        Text(date.fullDate)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                    
                    // Note input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        TextField("Enter your note...", text: $noteText, axis: .vertical)
                            .font(.system(size: 15))
                            .lineLimit(5...10)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    
                    // Quick suggestions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Add")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(["Training 6pm", "Game Day", "Team Meeting", "Practice Match", "Rest Day"], id: \.self) { suggestion in
                                    Button {
                                        noteText = suggestion
                                    } label: {
                                        Text(suggestion)
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(Color.blue.opacity(0.1))
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
                                    .fill(Color.red)
                            )
                        }
                    }
                }
                .padding(20)
            }
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
