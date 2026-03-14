//
//  DateNavigatorView.swift
//  ScrollDown
//
//  Forward/back date navigation bar.
//

import SwiftUI

struct DateNavigatorView: View {
    let date: Date
    let onBack: () -> Void
    let onForward: () -> Void
    let onPickDate: (Date) -> Void

    @State private var showDatePicker = false

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.medium))
            }

            Spacer()

            Button {
                showDatePicker.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(dateFormatter.string(from: date))
                        .font(.subheadline.weight(.medium))
                }
            }
            .foregroundStyle(.primary)

            Spacer()

            Button(action: onForward) {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
            }
            .disabled(isToday)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                DatePicker("Select Date", selection: Binding(
                    get: { date },
                    set: { newDate in
                        onPickDate(newDate)
                        showDatePicker = false
                    }
                ), in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Pick Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showDatePicker = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}
