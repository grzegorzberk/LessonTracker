//
//  ReportGeneratorView.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import SwiftUI

struct ReportGeneratorView: View {
    @StateObject private var viewModel = ReportViewModel()
    @State private var reportGenerated = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Generator raportów miesięcznych")
                .font(.title)
                .padding(.top)
            
            Form {
                Picker("Rok", selection: $viewModel.selectedYear) {
                    ForEach(viewModel.getAvailableYears(), id: \.self) { year in
                        Text("\(year)").tag(year)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Picker("Miesiąc", selection: $viewModel.selectedMonth) {
                    ForEach(viewModel.getAvailableMonths(), id: \.id) { month in
                        Text(month.name).tag(month.id)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .frame(maxWidth: 400)
            
            HStack {
                Spacer()
                
                if viewModel.generatingReport {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.trailing, 10)
                }
                
                Button(action: {
                    Task {
                        await viewModel.generateReport()
                        reportGenerated = true
                        
                        // Ukryj komunikat po 3 sekundach
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            reportGenerated = false
                        }
                    }
                }) {
                    Text("Generuj raport Excel")
                        .padding(.horizontal)
                }
                .keyboardShortcut(.return)
                .disabled(viewModel.generatingReport)
                
                Spacer()
            }
            
            if reportGenerated {
                Text("Raport został wygenerowany i otwarty w programie Excel (lub domyślnym programie do plików CSV).")
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Text("Raport zostanie wygenerowany w formacie CSV (można otworzyć w Excel) i będzie zawierać:")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("• Listę wszystkich lekcji z wybranego miesiąca")
                Text("• Podział na uczniów")
                Text("• Informacje o datach, czasie trwania i stawkach")
                Text("• Informację o statusie płatności")
                Text("• Podsumowanie miesięczne")
            }
            .font(.subheadline)
            .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
    }
}
