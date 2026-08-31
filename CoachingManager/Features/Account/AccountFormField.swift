//
//  AccountFormField.swift
//  CoachingManager
//

import SwiftUI
import AuthenticationServices

/// The text field used across the account sheets.
///
/// Written once here because `SignInView`, `SignUpView` and the re-authentication prompt all
/// need the same treatment, and the app has no `Form` styling that fits a full-bleed sheet.
struct AccountFormField: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    /// Shown inside the field while it is empty.
    ///
    /// **Secure fields must not leave this blank.** When AutoFill offers to generate a strong
    /// password it lays a cover view over the field, and that view draws the field's own
    /// placeholder. Given an empty one it falls back to rendering its internal debug string,
    /// "Automatic Strong Password cover view text", while still swallowing every touch and
    /// keystroke -- so the field looks garbled and refuses to accept typing.
    var placeholder: String = ""
    var isSecure: Bool = false
    var textContentType: UITextContentType?
    var keyboardType: UIKeyboardType = .default
    var submitLabel: SubmitLabel = .next
    var onSubmit: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.mutedText(colorScheme))

            HStack(spacing: 11) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isFocused ? AppTheme.brandAccent : AppTheme.mutedText(colorScheme))
                    .frame(width: 20)

                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.primaryText(colorScheme))
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(isSecure || keyboardType == .emailAddress ? .never : .words)
                .autocorrectionDisabled()
                .submitLabel(submitLabel)
                .focused($isFocused)
                .onSubmit { onSubmit?() }
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(AppTheme.insetFill(colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(
                                isFocused ? AppTheme.brandAccent.opacity(0.55) : AppTheme.strokeColor(colorScheme),
                                lineWidth: 1
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
    }
}

/// The filled primary button shared by the account sheets, with an inline spinner so the
/// button itself communicates progress rather than a separate overlay.
struct AccountPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.brandAccent.opacity(isEnabled && !isLoading ? 1 : 0.45))
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
    }
}

/// The Sign in with Apple button, styled once for every account surface.
///
/// The nonce handling lives in `AuthService.prepareAppleRequest(_:)`, so callers only supply the
/// completion. Height and corner radius match `AccountPrimaryButton` so the two stack cleanly.
struct AppleSignInButton: View {
    var label: SignInWithAppleButton.Label = .signIn
    var isDisabled: Bool = false
    let onCompletion: (Result<ASAuthorization, Error>) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        SignInWithAppleButton(label) { request in
            AuthService.shared.prepareAppleRequest(request)
        } onCompletion: { result in
            onCompletion(result)
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .disabled(isDisabled)
    }
}

/// An "or" rule separating the Apple button from the email form beneath it.
struct AccountOrDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            line
            Text("or")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.mutedText(colorScheme))
            line
        }
    }

    private var line: some View {
        Rectangle()
            .fill(AppTheme.strokeColor(colorScheme))
            .frame(height: 1)
    }
}
