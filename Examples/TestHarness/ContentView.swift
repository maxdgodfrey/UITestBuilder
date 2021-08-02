//
//  ContentView.swift
//  TestHarness
//
//  Created by Max Godfrey on 3/06/21.
//

import SwiftUI

struct ContentView: View {
    
    let user: User
    
    var body: some View {
        List {
            NavigationLink(destination: UselessForm()) { Text("Show a form") }
        }
        .padding()
        .navigationTitle("Hello \(user.username)")
    }

}

struct Selection: Identifiable {
    let id: UUID
}

struct UselessForm: View {
    
    @State var numberInput: String = ""
    @State var textInput: String = ""
    @Environment(\.presentationMode) var presentationMode
    @State var sheetItem: Selection?
    
    var body: some View {
        Form {
            TextField("Number input", text: $numberInput)
                .keyboardType(.numberPad)
            TextField("Text input", text: $textInput)
            Button("Submit") {
                sheetItem = .init(id: UUID())
            }
        }
        .actionSheet(item: $sheetItem) { _ in
            ActionSheet(
                title: Text("Sheet sheetington"),
                message: Text("A message"),
                buttons: [
                    .default(Text("Confirm")) {
                        presentationMode.wrappedValue.dismiss()
                    },
                    .cancel()
                ]
            )
        }
    }
}
