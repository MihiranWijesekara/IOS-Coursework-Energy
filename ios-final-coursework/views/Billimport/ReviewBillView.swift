//
//  ReviewBillView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

public struct ReviewBillView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Environment(\.modelContext) private var modelContext
    @State private var billingPeriod: String
    @State private var previousReading: String
    @State private var currentReading: String
    @State private var consumption: String
    @State private var billAmount: String
    @State private var rawText: String
    @State private var isSavingBill = false
    @State private var saveError: String = ""

    public init(extractedBill: ExtractedBillData = .sample) {
        _billingPeriod = State(initialValue: extractedBill.billingPeriod)
        _previousReading = State(initialValue: extractedBill.previousReading)
        _currentReading = State(initialValue: extractedBill.currentReading)
        _consumption = State(initialValue: extractedBill.consumptionKwh)
        _billAmount = State(initialValue: extractedBill.billAmount)
        _rawText = State(initialValue: extractedBill.rawText)

        _isShowingEditModal = State(initialValue: false)
        _editBillingPeriod = State(initialValue: "")
        _editPreviousReading = State(initialValue: "")
        _editCurrentReading = State(initialValue: "")
        _editConsumption = State(initialValue: "")
        _editBillAmount = State(initialValue: "")
    }

    @State private var isShowingEditModal: Bool = false
    @State private var editBillingPeriod: String = ""
    @State private var editPreviousReading: String = ""
    @State private var editCurrentReading: String = ""
    @State private var editConsumption: String = ""
    @State private var editBillAmount: String = ""

    private func openEditModal() {
        editBillingPeriod = billingPeriod
        editPreviousReading = previousReading
        editCurrentReading = currentReading
        editConsumption = consumption
        editBillAmount = billAmount
        isShowingEditModal = true
    }

    private func saveEditedValues() {
        billingPeriod = editBillingPeriod
        previousReading = editPreviousReading
        currentReading = editCurrentReading
        editConsumption = editConsumption.trimmingCharacters(in: .whitespaces)
        consumption = editConsumption.isEmpty ? consumption : editConsumption
        billAmount = editBillAmount
        isShowingEditModal = false
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CustomBackButton(title: "Import Bill") {
                navState.navigate(to: .scanningBill)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .padding(.horizontal, 24)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Review your bill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)

                        Text("Automatically extracted. Tap a field to edit.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.white)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Extraction successful")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)

                            Text("Please check the values against your bill.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.92))
                        }

                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(EnergyLensTheme.buttonGradient)
                    .cornerRadius(14)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Bill information")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)

                            Spacer()

                            Button(action: {
                                openEditModal()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Edit")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(EnergyLensTheme.accentGreen)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(EnergyLensTheme.mintHighlight.opacity(0.6))
                                .cornerRadius(8)
                            }
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Button(action: { openEditModal() }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Billing period")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(EnergyLensTheme.textSecondary)

                                    HStack {
                                        Text(billingPeriod)
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(EnergyLensTheme.textPrimary)
                                        Spacer()
                                        Image(systemName: "pencil")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(EnergyLensTheme.accentGreen)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            Divider()
                                .background(EnergyLensTheme.fieldBorder)

                            Button(action: { openEditModal() }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Previous reading")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(EnergyLensTheme.textSecondary)

                                    HStack {
                                        Text(previousReading)
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(EnergyLensTheme.textPrimary)
                                        Spacer()
                                        Image(systemName: "pencil")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(EnergyLensTheme.accentGreen)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            Divider()
                                .background(EnergyLensTheme.fieldBorder)

                            Button(action: { openEditModal() }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Current reading")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(EnergyLensTheme.textSecondary)

                                    HStack {
                                        Text(currentReading)
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(EnergyLensTheme.textPrimary)
                                        Spacer()
                                        Image(systemName: "pencil")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(EnergyLensTheme.accentGreen)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: { openEditModal() }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Consumption")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Color(red: 0.12, green: 0.45, blue: 0.28))
                                        Spacer()
                                        Image(systemName: "pencil")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(red: 0.12, green: 0.45, blue: 0.28))
                                    }

                                    Text(consumption)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Color(red: 0.10, green: 0.42, blue: 0.26))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(EnergyLensTheme.mintHighlight)
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: { openEditModal() }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Bill amount")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Color(red: 0.10, green: 0.40, blue: 0.50))
                                        Spacer()
                                        Image(systemName: "pencil")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(red: 0.10, green: 0.40, blue: 0.50))
                                    }

                                    Text(billAmount)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Color(red: 0.08, green: 0.38, blue: 0.48))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(Color(red: 0.90, green: 0.96, blue: 0.98))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(18)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                        )
                    }

                    Text("The difference between your readings is \(consumption).\nContinue when all information is correct.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)

                    Spacer(minLength: 30)

                    VStack(spacing: 12) {
                        GradientButton(title: "Save confirmed bill") {
                            Task {
                                await saveConfirmedBill()
                            }
                        }

                        if !saveError.isEmpty {
                            Text(saveError)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .sheet(isPresented: $isShowingEditModal) {
            editBillModalView
        }
        .onAppear {
            let data = navState.extractedBillData
            billingPeriod = data.billingPeriod
            previousReading = data.previousReading
            currentReading = data.currentReading
            consumption = data.consumptionKwh
            billAmount = data.billAmount
            rawText = data.rawText
        }
    }

    private var editBillModalView: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Edit Extracted Data")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)

                        Text("Compare with your scanned bill below and fix any incorrect values.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(EnergyLensTheme.accentGreen)

                            Text("SCANNED BILL REFERENCE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                                .tracking(0.6)

                            Spacer()
                        }

                        SampleBillDocumentView()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        editFormField(label: "Billing Period", text: $editBillingPeriod, icon: "calendar")
                        editFormField(label: "Previous Reading", text: $editPreviousReading, icon: "gauge")
                        editFormField(label: "Current Reading", text: $editCurrentReading, icon: "gauge.badge.plus")
                        editFormField(label: "Consumption", text: $editConsumption, icon: "bolt.fill")
                        editFormField(label: "Bill Amount", text: $editBillAmount, icon: "dollarsign.circle.fill")
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )

                    GradientButton(title: "Save Changes") {
                        saveEditedValues()
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitle("Edit Details", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    isShowingEditModal = false
                }
                .foregroundColor(EnergyLensTheme.textSecondary),
                trailing: Button("Save") {
                    saveEditedValues()
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(EnergyLensTheme.accentGreen)
            )
        }
    }

    private func editFormField(label: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(EnergyLensTheme.textSecondary)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(EnergyLensTheme.accentGreen)
                    .frame(width: 20)

                TextField(label, text: text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(EnergyLensTheme.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
            )
        }
    }

    @MainActor
    private func saveConfirmedBill() async {
        isSavingBill = true
        saveError = ""

        do {
            let parsedPeriod = parsePeriod(billingPeriod)
            let cleanPrev = previousReading.replacingOccurrences(of: ",", with: "").filter { $0.isNumber }
            let cleanCurr = currentReading.replacingOccurrences(of: ",", with: "").filter { $0.isNumber }
            let cleanConsumption = consumption.replacingOccurrences(of: ",", with: "").filter { $0.isNumber || $0 == "." }
            let cleanAmount = billAmount.replacingOccurrences(of: ",", with: "").filter { $0.isNumber || $0 == "." }

            let prevReadingValue = Int(cleanPrev) ?? 0
            let currentReadingValue = Int(cleanCurr) ?? 0
            let consumptionValue = Double(cleanConsumption) ?? 0
            let amountValue = Double(cleanAmount) ?? 0

            let bill = ElectricityBill(
                periodStart: parsedPeriod.0,
                periodEnd: parsedPeriod.1,
                prevReading: prevReadingValue == 0 ? nil : prevReadingValue,
                currReading: currentReadingValue == 0 ? nil : currentReadingValue,
                consumptionKwh: max(consumptionValue, 0),
                billAmount: max(amountValue, 0),
                currency: "LKR",
                user: nil
            )

            modelContext.insert(bill)
            try modelContext.save()

            isSavingBill = false
            navState.navigate(to: .billAnalysisResult)
        } catch {
            isSavingBill = false
            saveError = "Unable to save this bill: \(error.localizedDescription)"
        }
    }

    private func parsePeriod(_ value: String) -> (Date, Date) {
        let now = Date()
        let calendar = Calendar.current

        if let dateRange = parseDateRange(from: value) {
            return dateRange
        }

        let start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let end = now
        return (start, end)
    }

    private func parseDateRange(from text: String) -> (Date, Date)? {
        let pattern = #"(\d{1,2}\s+[A-Za-z]{3,9})\s*(?:-|–|to)\s*(\d{1,2}\s+[A-Za-z]{3,9})\s+(\d{4})"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges == 4,
              let startDayMonthRange = Range(match.range(at: 1), in: text),
              let endDayMonthRange = Range(match.range(at: 2), in: text),
              let yearRange = Range(match.range(at: 3), in: text) else {
            return nil
        }

        let year = String(text[yearRange])
        let startString = "\(text[startDayMonthRange]) \(year)"
        let endString = "\(text[endDayMonthRange]) \(year)"

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        for format in ["dd MMM yyyy", "d MMM yyyy", "dd MMMM yyyy", "d MMMM yyyy"] {
            formatter.dateFormat = format
            if let startDate = formatter.date(from: startString),
               let endDate = formatter.date(from: endString) {
                return (startDate, endDate)
            }
        }

        return nil
    }
}

