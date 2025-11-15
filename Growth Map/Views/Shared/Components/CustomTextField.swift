//
//  CustomTextField.swift
//  Growth Map
//
//  Created on 2025-11-15.
//

import SwiftUI

/// Styled text field with support for secure entry, validation, and error states
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var errorMessage: String?
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: UITextAutocapitalizationType = .none
    
    @State private var isSecureVisible: Bool = false
    @FocusState private var isFocused: Bool
    
    private var hasError: Bool {
        if let message = errorMessage {
            return !message.isEmpty
        }
        return false
    }
    
    private var borderColor: Color {
        if hasError {
            return AppColors.error
        } else if isFocused {
            return AppColors.accent
        } else {
            return Color.clear
        }
    }
    
    @ViewBuilder
    private var textInputField: some View {
        if isSecure && !isSecureVisible {
            SecureField(placeholder, text: $text)
                .font(AppTypography.textField)
                .textContentType(textContentType)
                .autocorrectionDisabled()
                .focused($isFocused)
        } else {
            TextField(placeholder, text: $text)
                .font(AppTypography.textField)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .autocorrectionDisabled()
                .focused($isFocused)
        }
    }
    
    private var toggleVisibilityButton: some View {
        Button(action: { isSecureVisible.toggle() }) {
            Image(systemName: isSecureVisible ? "eye.slash.fill" : "eye.fill")
                .foregroundColor(AppColors.textSecondary)
                .frame(width: Layout.minTouchTarget, height: Layout.minTouchTarget)
        }
        .accessibilityLabel(isSecureVisible ? "Hide password" : "Show password")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacingXS) {
            Text(title)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textPrimary)
            
            HStack {
                textInputField
                
                if isSecure {
                    toggleVisibilityButton
                }
            }
            .padding(.horizontal, Layout.spacingM)
            .frame(height: Layout.textFieldHeight)
            .background(AppColors.backgroundElevated)
            .cornerRadius(Layout.cornerRadiusM)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadiusM)
                    .stroke(borderColor, lineWidth: Layout.borderWidth)
            )
            
            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                HStack(spacing: Layout.spacingXS) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(errorMessage)
                }
                .errorText()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(text.isEmpty ? placeholder : text)
        .accessibilityHint(hasError ? (errorMessage ?? "") : "Text field for \(title.lowercased())")
    }
}

#Preview {
    VStack(spacing: Layout.spacingL) {
        CustomTextField(
            title: "Email",
            text: .constant(""),
            placeholder: "Enter your email",
            keyboardType: .emailAddress,
            textContentType: .emailAddress
        )
        
        CustomTextField(
            title: "Password",
            text: .constant(""),
            placeholder: "Enter your password",
            isSecure: true,
            textContentType: .password
        )
        
        CustomTextField(
            title: "Name",
            text: .constant("Invalid"),
            placeholder: "Enter your name",
            errorMessage: "This field is required"
        )
    }
    .padding()
}
