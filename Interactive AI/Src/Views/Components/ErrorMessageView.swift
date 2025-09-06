//
//  ErrorMessageView.swift
//  Interactive AI
//
//  Created by Irham Sahbana on 06/09/25.
//

import SwiftUI

struct ErrorMessageView: View {
    let message: String

    var body: some View {
        Text(message)
            .foregroundColor(.red)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
    }
}
