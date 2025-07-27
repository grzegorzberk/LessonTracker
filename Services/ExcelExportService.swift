//
//  ExcelExportService.swift
//  LessonTracker
//
//  Created by Grzegorz Berk on 27/07/2025.
//

import Foundation
import CoreData
import AppKit

class ExcelExportService {
    func generateMonthlyReport(lessons: [Lesson], year: Int, month: Int) -> URL? {
        // Grupowanie lekcji według studentów
        var studentLessons: [Student: [Lesson]] = [:]
        
        for lesson in lessons {
            if let student = lesson.student {
                if studentLessons[student] == nil {
                    studentLessons[student] = []
                }
                studentLessons[student]?.append(lesson)
            }
        }
        
        // Tworzymy plik CSV (Excel może otworzyć)
        let fileName = "Raport_\(year)_\(month).csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        var csvContent = "Raport korepetycji za \(monthName(month)) \(year)\n\n"
        
        var totalHours = 0.0
        var totalIncome = 0.0
        
        // Dodajemy informacje o każdym studencie
        for (student, lessons) in studentLessons {
            let studentIdentifier = student.billingId ?? student.name ?? "Nieznany uczeń"
            csvContent += "Uczeń: \(studentIdentifier)\n"
            csvContent += "Data;Czas trwania (h);Stawka (PLN/h);Kwota (PLN);Status\n"
            
            var studentHours = 0.0
            var studentIncome = 0.0
            
            // Dodajemy informacje o lekcjach danego studenta
            for lesson in lessons.sorted(by: { $0.date! < $1.date! }) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                
                let date = dateFormatter.string(from: lesson.date!)
                let duration = lesson.duration
                let rate = lesson.hourlyRate
                let amount = duration * rate
                let status = lesson.isPaid ? "Opłacone" : "Nieopłacone"
                
                csvContent += "\(date);\(duration);\(rate);\(amount);\(status)\n"
                
                studentHours += duration
                studentIncome += amount
            }
            
            csvContent += "Suma godzin: \(studentHours), Należność: \(studentIncome) PLN\n\n"
            
            totalHours += studentHours
            totalIncome += studentIncome
        }
        
        // Podsumowanie całego miesiąca
        csvContent += "PODSUMOWANIE MIESIĄCA\n"
        csvContent += "Łączna liczba godzin: \(totalHours)\n"
        csvContent += "Łączna należność: \(totalIncome) PLN\n"
        
        // Zapisujemy do pliku
        do {
            try csvContent.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            print("Błąd zapisu pliku CSV: \(error)")
            return nil
        }
    }
    
    private func monthName(_ month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "pl_PL")
        
        guard let date = Calendar.current.date(from: DateComponents(year: 2021, month: month)) else {
            return "Nieznany miesiąc"
        }
        
        dateFormatter.dateFormat = "LLLL"
        return dateFormatter.string(from: date).capitalized
    }
    
    func openFile(at url: URL) {
        NSWorkspace.shared.open(url)
    }
}
