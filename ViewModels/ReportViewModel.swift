//
//  ReportViewModel.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import Foundation
import SwiftUI
import CoreData

@MainActor
final class ReportViewModel: ObservableObject {
    private let excelService = ExcelExportService()
    private let lessonViewModel = LessonViewModel()
    
    @Published var selectedYear: Int
    @Published var selectedMonth: Int
    @Published var generatingReport = false
    
    init() {
        let currentDate = Date()
        let calendar = Calendar.current
        selectedYear = calendar.component(.year, from: currentDate)
        selectedMonth = calendar.component(.month, from: currentDate)
    }
    
    func generateReport() async {
        generatingReport = true
        defer { generatingReport = false }
        
        let lessons = await lessonViewModel.fetchLessonsByMonth(year: selectedYear, month: selectedMonth)
        
        if let reportPath = excelService.generateMonthlyReport(lessons: lessons, year: selectedYear, month: selectedMonth) {
            excelService.openFile(at: reportPath)
        }
    }
    
    func getAvailableYears() -> [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear-5)...currentYear)
    }
    
    func getAvailableMonths() -> [(id: Int, name: String)] {
        return (1...12).map { month in
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "pl_PL")
            
            guard let date = Calendar.current.date(from: DateComponents(year: 2021, month: month)) else {
                return (month, "Nieznany")
            }
            
            dateFormatter.dateFormat = "LLLL"
            return (month, dateFormatter.string(from: date).capitalized)
        }
    }
}
