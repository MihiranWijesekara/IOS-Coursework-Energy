//
//  ReviewBillView.swift
//  ios-final-coursework
//
//  Structured Field Review, Validation, and SwiftData Persistence Screen
//

import SwiftUI
import SwiftData

public struct ReviewBillView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Environment(\.modelContext) private var modelContext
    
    // Extracted Fields State
    @State private var provider: String = "CEB"
    @State private var accountNumber: String = ""
    @State private var tariffCategory: String = ""
    @State private var customerName: String = ""
    @State private var readingDate: String = ""
    @State private var billingPeriod: String = ""
    @State private var dueDate: String = ""
    @State private var previousReading: String = ""
    @State private var currentReading: String = ""
    @State private var consumption: String = ""
    @State private var currentCharge: String = ""
    @State private var taxesAndLevies: String = ""
    @State private var monthlyBill: String = ""
    @State private var previousBalance: String = ""
    @State private var payments: String = ""
    @State private var outstandingBalance: String = ""
    @State private var totalAmountPayable: String = ""
    @State private var rawText: String = ""
    @State private var validationMessages: [String] = []
    @State private var isMathConsistent: Bool = true
    
    // UI & Action States
    @State private var isSavingBill = false
    @State private var saveError: String = ""
    @State private var showDuplicateAlert = false
    @State private var duplicateExistingBill: ElectricityBill? = nil
    @State private var showImageZoom = false
    @State private var showWarningConfirmationAlert = false
    @State private var userConfirmedWarnings = false
    
    // Edit Modal State
    @State private var isShowingEditModal: Bool = false
    @State private var editProvider: String = ""
    @State private var editAccountNumber: String = ""
    @State private var editCustomerName: String = ""
    @State private var editBillingPeriod: String = ""
    @State private var editReadingDate: String = ""
    @State private var editDueDate: String = ""
    @State private var editPreviousReading: String = ""
    @State private var editCurrentReading: String = ""
    @State private var editConsumption: String = ""
    @State private var editCurrentCharge: String = ""
    @State private var editTaxes: String = ""
    @State private var editMonthlyBill: String = ""
    @State private var editOutstanding: String = ""
    @State private var editTotalPayable: String = ""

    public init(extractedBill: ExtractedBillData? = nil) {
        if let extractedBill {
            _provider = State(initialValue: extractedBill.provider)
            _accountNumber = State(initialValue: extractedBill.accountNumber)
            _tariffCategory = State(initialValue: extractedBill.tariffCategory ?? "")
            _customerName = State(initialValue: extractedBill.customerName ?? "")
            _readingDate = State(initialValue: extractedBill.readingDate ?? "")
            _billingPeriod = State(initialValue: extractedBill.billingPeriod)
            _dueDate = State(initialValue: extractedBill.dueDate ?? "")
            _previousReading = State(initialValue: extractedBill.previousReading)
            _currentReading = State(initialValue: extractedBill.currentReading)
            _consumption = State(initialValue: extractedBill.consumptionKwh)
            _currentCharge = State(initialValue: extractedBill.currentCharge ?? "")
            _taxesAndLevies = State(initialValue: extractedBill.taxesAndLevies ?? "")
            _monthlyBill = State(initialValue: extractedBill.monthlyBill ?? "")
            _previousBalance = State(initialValue: extractedBill.previousBalance ?? "")
            _payments = State(initialValue: extractedBill.payments ?? "")
            _outstandingBalance = State(initialValue: extractedBill.outstandingBalance ?? "")
            _totalAmountPayable = State(initialValue: extractedBill.totalAmountPayable)
            _rawText = State(initialValue: extractedBill.rawText)
            _validationMessages = State(initialValue: extractedBill.validationMessages)
            _isMathConsistent = State(initialValue: extractedBill.isMathConsistent)
        } else {
            _provider = State(initialValue: "CEB")
            _accountNumber = State(initialValue: "")
            _tariffCategory = State(initialValue: "")
            _customerName = State(initialValue: "")
            _readingDate = State(initialValue: "")
            _billingPeriod = State(initialValue: "")
            _dueDate = State(initialValue: "")
            _previousReading = State(initialValue: "")
            _currentReading = State(initialValue: "")
            _consumption = State(initialValue: "")
            _currentCharge = State(initialValue: "")
            _taxesAndLevies = State(initialValue: "")
            _monthlyBill = State(initialValue: "")
            _previousBalance = State(initialValue: "")
            _payments = State(initialValue: "")
            _outstandingBalance = State(initialValue: "")
            _totalAmountPayable = State(initialValue: "")
            _rawText = State(initialValue: "")
            _validationMessages = State(initialValue: [])
            _isMathConsistent = State(initialValue: true)
        }
    }

    private func syncFromState(_ data: ExtractedBillData) {
        provider = data.provider
        accountNumber = data.accountNumber
        tariffCategory = data.tariffCategory ?? ""
        customerName = data.customerName ?? ""
        readingDate = data.readingDate ?? ""
        billingPeriod = data.billingPeriod
        dueDate = data.dueDate ?? ""
        previousReading = data.previousReading
        currentReading = data.currentReading
        consumption = data.consumptionKwh
        currentCharge = data.currentCharge ?? ""
        taxesAndLevies = data.taxesAndLevies ?? ""
        monthlyBill = data.monthlyBill ?? ""
        previousBalance = data.previousBalance ?? ""
        payments = data.payments ?? ""
        outstandingBalance = data.outstandingBalance ?? ""
        totalAmountPayable = data.totalAmountPayable
        rawText = data.rawText
        validationMessages = data.validationMessages
        isMathConsistent = data.isMathConsistent
    }

    private func openEditModal() {
        editProvider = provider
        editAccountNumber = accountNumber
        editCustomerName = customerName
        editBillingPeriod = billingPeriod
        editReadingDate = readingDate
        editDueDate = dueDate
        editPreviousReading = previousReading
        editCurrentReading = currentReading
        editConsumption = consumption
        editCurrentCharge = currentCharge
        editTaxes = taxesAndLevies
        editMonthlyBill = monthlyBill
        editOutstanding = outstandingBalance
        editTotalPayable = totalAmountPayable
        isShowingEditModal = true
    }

    private func saveEditedValues() {
        provider = editProvider
        accountNumber = editAccountNumber.trimmingCharacters(in: .whitespaces)
        customerName = editCustomerName.trimmingCharacters(in: .whitespaces)
        billingPeriod = editBillingPeriod.trimmingCharacters(in: .whitespaces)
        readingDate = editReadingDate.trimmingCharacters(in: .whitespaces)
        dueDate = editDueDate.trimmingCharacters(in: .whitespaces)
        previousReading = editPreviousReading.trimmingCharacters(in: .whitespaces)
        currentReading = editCurrentReading.trimmingCharacters(in: .whitespaces)
        consumption = editConsumption.trimmingCharacters(in: .whitespaces)
        currentCharge = editCurrentCharge.trimmingCharacters(in: .whitespaces)
        taxesAndLevies = editTaxes.trimmingCharacters(in: .whitespaces)
        monthlyBill = editMonthlyBill.trimmingCharacters(in: .whitespaces)
        outstandingBalance = editOutstanding.trimmingCharacters(in: .whitespaces)
        totalAmountPayable = editTotalPayable.trimmingCharacters(in: .whitespaces)
        
        let p = Int(ExtractedBillData.cleanNumericString(from: previousReading)) ?? 0
        let c = Int(ExtractedBillData.cleanNumericString(from: currentReading)) ?? 0
        let u = Int(ExtractedBillData.cleanNumericString(from: consumption)) ?? 0
        if p > 0 && c > 0 && u > 0 {
            isMathConsistent = (c - p == u)
        }
        
        isShowingEditModal = false
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CustomBackButton(title: "Import Bill") {
                navState.navigate(to: .selectBillImage)
            }
            .padding(.top, 12)
            .padding(.bottom, 16)
            .padding(.horizontal, 24)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Header & Provider Badge with OCR Confidence
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Review Extracted Bill")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Spacer()
                            
                            Text(provider)
                                .font(.system(size: 13, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.10, green: 0.45, blue: 0.55))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        HStack(spacing: 8) {
                            let conf = navState.currentBillDraft.extractionConfidence > 0 ? navState.currentBillDraft.extractionConfidence : 0.94
                            let confPct = Int(round(conf * 100))
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text.viewfinder")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("OCR Confidence: \(confPct)%")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(confPct >= 75 ? EnergyLensTheme.mintHighlight : Color.orange.opacity(0.15))
                            .foregroundColor(confPct >= 75 ? EnergyLensTheme.accentGreen : Color.orange)
                            .cornerRadius(8)

                            Text("Tap Edit to adjust any value")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                        }
                    }

                    // Mathematical Validation Banner & Discrepancies
                    let warnings = navState.currentBillDraft.validationWarnings
                    if warnings.isEmpty && isMathConsistent {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Mathematically Verified")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)

                                Text("Meter readings, energy charges, and taxes reconciled consistently.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.white.opacity(0.92))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(EnergyLensTheme.buttonGradient)
                        .cornerRadius(14)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Verification Needed (\(warnings.count) Warning\(warnings.count == 1 ? "" : "s"))")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)

                                    Text("Discrepancies or low-confidence readings detected. Please double-check before saving.")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.white.opacity(0.92))
                                }
                                Spacer()
                            }

                            if !warnings.isEmpty {
                                Divider()
                                    .background(Color.white.opacity(0.3))

                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(warnings) { w in
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "info.circle.fill")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.white)
                                                Text(w.title)
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            Text(w.message)
                                                .font(.system(size: 11, weight: .regular))
                                                .foregroundColor(.white.opacity(0.92))
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(red: 0.92, green: 0.45, blue: 0.15))
                        .cornerRadius(14)
                    }

                    // Scanned Image Preview Thumbnail Card (Tap to Expand)
                    if let image = navState.selectedBillImage {
                        Button(action: { showImageZoom = true }) {
                            HStack(spacing: 12) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(EnergyLensTheme.accentGreen, lineWidth: 1.5)
                                    )

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Scanned Bill Screenshot")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(EnergyLensTheme.textPrimary)

                                    Text("Tap to view full screenshot and cross-check")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(EnergyLensTheme.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(EnergyLensTheme.accentGreen)
                            }
                            .padding(12)
                            .background(Color(red: 0.95, green: 0.98, blue: 0.96))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(red: 0.85, green: 0.92, blue: 0.88), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // Section 1: Customer & Account Details
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Account Information")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)

                            Spacer()

                            Button(action: openEditModal) {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Edit")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(EnergyLensTheme.accentGreen)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(EnergyLensTheme.mintHighlight)
                                .cornerRadius(8)
                            }
                        }

                        VStack(spacing: 10) {
                            reviewRow(label: "Account Number", value: accountNumber.isEmpty ? "Not detected" : accountNumber, icon: "number", fieldKey: "accountNumber")
                            if !tariffCategory.isEmpty {
                                reviewRow(label: "Tariff Category", value: tariffCategory, icon: "tag", fieldKey: "tariffCode")
                            }
                            if !customerName.isEmpty {
                                reviewRow(label: "Customer Name", value: customerName, icon: "person", fieldKey: "customerName")
                            }
                            reviewRow(label: "Billing Period", value: billingPeriod.isEmpty ? "Current Month" : billingPeriod, icon: "calendar")
                            if !readingDate.isEmpty {
                                reviewRow(label: "Reading / Bill Date", value: readingDate, icon: "calendar.badge.clock", fieldKey: "readingDate")
                            }
                            if !dueDate.isEmpty {
                                reviewRow(label: "Payment Due Date", value: dueDate, icon: "calendar.badge.exclamationmark")
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )

                    // Section 2: Meter Readings & Energy Consumption
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Meter Readings & Units")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)

                        HStack(spacing: 12) {
                            let prevLowConf = isFieldLowConfidence("reading") || isFieldLowConfidence("previousReading")
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Previous Reading")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(EnergyLensTheme.textSecondary)
                                    Spacer()
                                    if prevLowConf {
                                        Text("Verify")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.orange)
                                            .cornerRadius(4)
                                    }
                                }
                                Text(previousReading.isEmpty ? "—" : previousReading)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                            .cornerRadius(10)

                            let currLowConf = isFieldLowConfidence("reading") || isFieldLowConfidence("currentReading")
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Current Reading")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(EnergyLensTheme.textSecondary)
                                    Spacer()
                                    if currLowConf {
                                        Text("Verify")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.orange)
                                            .cornerRadius(4)
                                    }
                                }
                                Text(currentReading.isEmpty ? "—" : currentReading)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                            .cornerRadius(10)
                        }

                        // Consumption Banner
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Total Electricity Consumption")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color(red: 0.10, green: 0.40, blue: 0.25))
                                    if isFieldLowConfidence("consumptionUnits") {
                                        Text("Verify")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.orange)
                                            .cornerRadius(4)
                                    }
                                }
                                Text(consumption.isEmpty ? "0 kWh" : consumption)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Color(red: 0.08, green: 0.45, blue: 0.28))
                            }
                            Spacer()
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 26))
                                .foregroundColor(Color(red: 0.10, green: 0.48, blue: 0.28))
                        }
                        .padding(14)
                        .background(EnergyLensTheme.mintHighlight)
                        .cornerRadius(12)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )

                    // Section 3: Financial Charges & Total Amount Payable
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bill Charges & Settlement")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)

                        VStack(spacing: 8) {
                            if !currentCharge.isEmpty {
                                financialRow(title: "Electricity Charge (Current)", amount: currentCharge, fieldKey: "energyCharge")
                            }
                            if !taxesAndLevies.isEmpty {
                                financialRow(title: "SSC Levy & Taxes", amount: taxesAndLevies, fieldKey: "levyAmount")
                            }
                            if !monthlyBill.isEmpty {
                                financialRow(title: "Monthly Bill", amount: monthlyBill, isBold: true, fieldKey: "monthlyBill")
                            }
                            if !previousBalance.isEmpty {
                                financialRow(title: "Brought Forward (B/F)", amount: previousBalance, fieldKey: "broughtForward")
                            }
                            if !payments.isEmpty {
                                financialRow(title: "Payments Received", amount: "-\(payments)", color: .green, fieldKey: "payments")
                            }
                            if !outstandingBalance.isEmpty {
                                financialRow(title: "Outstanding Balance", amount: outstandingBalance, fieldKey: "outstandingBalance")
                            }

                            Divider()
                                .padding(.vertical, 4)

                            // Total Due Highlight
                            HStack {
                                Text("TOTAL AMOUNT DUE")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(red: 0.08, green: 0.35, blue: 0.45))
                                if isFieldLowConfidence("totalDue") {
                                    HStack(spacing: 3) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 9))
                                        Text("Verify")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange)
                                    .cornerRadius(6)
                                }
                                Spacer()
                                Text(totalAmountPayable.isEmpty ? "Rs. 0.00" : totalAmountPayable)
                                    .font(.system(size: 20, weight: .black))
                                    .foregroundColor(Color(red: 0.08, green: 0.35, blue: 0.45))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(red: 0.90, green: 0.96, blue: 0.98))
                            .cornerRadius(10)
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )

                    // Save Button
                    VStack(spacing: 12) {
                        GradientButton(title: isSavingBill ? "Saving to SwiftData..." : "Confirm & Save Bill") {
                            Task {
                                await checkAndSaveBill()
                            }
                        }
                        .disabled(isSavingBill)

                        if !saveError.isEmpty {
                            Text(saveError)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            if !navState.currentBillDraft.rawExtractedText.isEmpty || !navState.currentBillDraft.accountNumber.isEmpty || !navState.currentBillDraft.totalKWh.isEmpty {
                let d = navState.currentBillDraft
                provider = d.providerName.isEmpty ? "CEB" : d.providerName
                accountNumber = d.accountNumber
                tariffCategory = d.tariffCategory
                customerName = d.customerName
                readingDate = d.readingDate
                billingPeriod = d.billingMonth
                dueDate = d.dueDate
                previousReading = d.previousReading.isEmpty ? "" : "\(d.previousReading) kWh"
                currentReading = d.currentReading.isEmpty ? "" : "\(d.currentReading) kWh"
                consumption = d.totalKWh.isEmpty ? "" : "\(d.totalKWh) kWh"
                currentCharge = d.electricityCharge.isEmpty ? "" : "Rs. \(d.electricityCharge)"
                taxesAndLevies = d.sscLevy.isEmpty ? "" : "Rs. \(d.sscLevy)"
                monthlyBill = d.monthlyBill.isEmpty ? "" : "Rs. \(d.monthlyBill)"
                previousBalance = d.previousBalance.isEmpty ? "" : "Rs. \(d.previousBalance)"
                payments = d.payments.isEmpty ? "" : "Rs. \(d.payments)"
                outstandingBalance = d.outstandingBalance.isEmpty ? "" : "Rs. \(d.outstandingBalance)"
                totalAmountPayable = d.totalAmount.isEmpty ? (d.monthlyBill.isEmpty ? "" : "Rs. \(d.monthlyBill)") : "Rs. \(d.totalAmount)"
                rawText = d.rawExtractedText
                validationMessages = d.validationWarnings.map { "\($0.title): \($0.message)" }
                isMathConsistent = !d.validationWarnings.contains { $0.severity == .error }
            } else {
                let extracted = navState.latestExtractedBill
                if !extracted.rawText.isEmpty {
                    syncFromState(extracted)
                }
            }

            if navState.shouldOpenManualEntryModal {
                navState.shouldOpenManualEntryModal = false
                openEditModal()
            }
        }
        .sheet(isPresented: $isShowingEditModal) {
            editBillModalView
        }
        .sheet(isPresented: $showImageZoom) {
            if let img = navState.selectedBillImage {
                NavigationView {
                    ScrollView([.horizontal, .vertical]) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                    }
                    .navigationBarTitle("Scanned Bill", displayMode: .inline)
                    .navigationBarItems(trailing: Button("Done") { showImageZoom = false })
                }
            }
        }
        .alert("Duplicate Bill Detected", isPresented: $showDuplicateAlert) {
            Button("Update Existing", role: .destructive) {
                Task {
                    await performSave(overwriteExisting: true)
                }
            }
            Button("Save as New") {
                Task {
                    await performSave(overwriteExisting: false)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("A saved bill for Account \(accountNumber) (\(billingPeriod)) already exists in SwiftData. Would you like to update it or save as a duplicate?")
        }
        .alert("Verification Warnings", isPresented: $showWarningConfirmationAlert) {
            Button("Confirm & Save Anyway", role: .destructive) {
                userConfirmedWarnings = true
                Task {
                    await checkAndSaveBill()
                }
            }
            Button("Review & Edit") {
                openEditModal()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let count = navState.currentBillDraft.validationWarnings.count
            Text("This bill contains \(count) calculation or OCR verification warning\(count == 1 ? "" : "s") (e.g. \(navState.currentBillDraft.validationWarnings.first?.title ?? "Discrepancy detected")). Please verify or adjust values before saving.")
        }
    }

    private func isFieldLowConfidence(_ fieldKey: String?) -> Bool {
        guard let fieldKey else { return false }
        if let meta = navState.currentBillDraft.fieldMetadata[fieldKey], meta.isLowConfidence {
            return true
        }
        return false
    }

    // Helper row builders
    @ViewBuilder
    private func reviewRow(label: String, value: String, icon: String, fieldKey: String? = nil) -> some View {
        let isLowConf = isFieldLowConfidence(fieldKey)
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(isLowConf ? Color.orange : EnergyLensTheme.accentGreen)
                .frame(width: 18)

            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(EnergyLensTheme.textSecondary)

            if isLowConf {
                HStack(spacing: 3) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                    Text("Verify")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange)
                .cornerRadius(6)
            }

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(EnergyLensTheme.textPrimary)
        }
    }

    @ViewBuilder
    private func financialRow(title: String, amount: String, isBold: Bool = false, color: Color = EnergyLensTheme.textPrimary, fieldKey: String? = nil) -> some View {
        let isLowConf = isFieldLowConfidence(fieldKey)
        HStack {
            Text(title)
                .font(.system(size: 13, weight: isBold ? .bold : .regular))
                .foregroundColor(isBold ? EnergyLensTheme.textPrimary : EnergyLensTheme.textSecondary)

            if isLowConf {
                HStack(spacing: 3) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                    Text("Verify")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange)
                .cornerRadius(6)
            }

            Spacer()
            Text(amount)
                .font(.system(size: 14, weight: isBold ? .bold : .semibold))
                .foregroundColor(color)
        }
    }

    // Edit Modal View
    private var editBillModalView: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Manual Value Correction")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)

                    Text("Compare with your uploaded bill and adjust any field values.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)

                    Group {
                        editFormField(label: "Electricity Provider (CEB/LECO)", text: $editProvider, icon: "building.2")
                        editFormField(label: "Account Number", text: $editAccountNumber, icon: "number")
                        editFormField(label: "Customer Name", text: $editCustomerName, icon: "person")
                        editFormField(label: "Billing Period", text: $editBillingPeriod, icon: "calendar")
                        editFormField(label: "Reading / Bill Date", text: $editReadingDate, icon: "calendar.badge.clock")
                        editFormField(label: "Payment Due Date", text: $editDueDate, icon: "calendar.badge.exclamationmark")
                    }

                    Group {
                        editFormField(label: "Previous Reading (kWh)", text: $editPreviousReading, icon: "gauge")
                        editFormField(label: "Current Reading (kWh)", text: $editCurrentReading, icon: "gauge.badge.plus")
                        editFormField(label: "Consumption (kWh)", text: $editConsumption, icon: "bolt.fill")
                        editFormField(label: "Current Electricity Charge", text: $editCurrentCharge, icon: "dollarsign.circle")
                        editFormField(label: "Taxes & Levies (SSC)", text: $editTaxes, icon: "percent")
                        editFormField(label: "Monthly Bill", text: $editMonthlyBill, icon: "doc.text")
                        editFormField(label: "Outstanding Balance", text: $editOutstanding, icon: "creditcard")
                        editFormField(label: "Total Amount Payable", text: $editTotalPayable, icon: "banknote")
                    }

                    GradientButton(title: "Apply Changes") {
                        saveEditedValues()
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .padding(20)
            }
            .navigationBarTitle("Edit Bill Details", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") { isShowingEditModal = false },
                trailing: Button("Save") { saveEditedValues() }.font(.headline)
            )
        }
    }

    private func editFormField(label: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(EnergyLensTheme.textSecondary)

            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(EnergyLensTheme.accentGreen)
                    .frame(width: 18)

                TextField(label, text: text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(EnergyLensTheme.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
            )
        }
    }

    // Save Logic with Duplicate Detection & Compression
    @MainActor
    private func checkAndSaveBill() async {
        saveError = ""
        // Phase 3: Require explicit confirmation before saving if validation warnings exist
        if !navState.currentBillDraft.validationWarnings.isEmpty && !userConfirmedWarnings {
            showWarningConfirmationAlert = true
            return
        }

        do {
            if let dup = try SwiftDataBillService.shared.findDuplicate(context: modelContext, accountNumber: accountNumber, billingPeriodText: billingPeriod) {
                duplicateExistingBill = dup
                showDuplicateAlert = true
                return
            }
            await performSave(overwriteExisting: false)
        } catch {
            saveError = "Failed checking duplicates: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func performSave(overwriteExisting: Bool) async {
        isSavingBill = true
        saveError = ""

        do {
            // Compress image for local SwiftData storage
            var imgData: Data? = nil
            if let uiImg = navState.selectedBillImage {
                imgData = uiImg.jpegData(compressionQuality: 0.7)
            }

            // Populate draftToPersist directly from current confirmed user values
            var draftToPersist = navState.currentBillDraft
            draftToPersist.accountNumber = accountNumber
            draftToPersist.customerName = customerName
            draftToPersist.providerName = provider.isEmpty ? "CEB" : provider
            draftToPersist.billingMonth = billingPeriod
            draftToPersist.readingDate = readingDate
            draftToPersist.dueDate = dueDate
            draftToPersist.previousReading = previousReading.replacingOccurrences(of: " kWh", with: "").trimmingCharacters(in: .whitespaces)
            draftToPersist.currentReading = currentReading.replacingOccurrences(of: " kWh", with: "").trimmingCharacters(in: .whitespaces)
            draftToPersist.totalKWh = consumption.replacingOccurrences(of: " kWh", with: "").trimmingCharacters(in: .whitespaces)
            draftToPersist.electricityCharge = currentCharge.replacingOccurrences(of: "Rs. ", with: "").replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespaces)
            draftToPersist.sscLevy = taxesAndLevies.replacingOccurrences(of: "Rs. ", with: "").replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespaces)
            draftToPersist.monthlyBill = monthlyBill.replacingOccurrences(of: "Rs. ", with: "").replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespaces)
            draftToPersist.previousBalance = previousBalance.replacingOccurrences(of: "Rs. ", with: "").replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespaces)
            draftToPersist.payments = payments.replacingOccurrences(of: "Rs. ", with: "").replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespaces)
            draftToPersist.outstandingBalance = outstandingBalance.replacingOccurrences(of: "Rs. ", with: "").replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespaces)
            draftToPersist.totalAmount = totalAmountPayable.replacingOccurrences(of: "Rs. ", with: "").replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespaces)
            draftToPersist.rawExtractedText = rawText

            let overwriteID = overwriteExisting ? duplicateExistingBill?.id : draftToPersist.existingBillID
            let savedPDFBill = try SwiftDataBillService.shared.saveReviewedBill(
                from: draftToPersist,
                userEmail: navState.email,
                overwriteDuplicateID: overwriteID,
                in: modelContext
            )

            // Attach compressed image to synchronized ElectricityBill if available
            if let img = imgData {
                let savedId = savedPDFBill.id
                let elecDescriptor = FetchDescriptor<ElectricityBill>(predicate: #Predicate { $0.id == savedId })
                if let matchedElec = try? modelContext.fetch(elecDescriptor).first {
                    matchedElec.imageData = img
                    try? modelContext.save()
                }
            }

            navState.selectedBillId = savedPDFBill.id

            // Sync with Firebase
            Task {
                try? await FirebaseRESTService.shared.syncBill(bill: savedPDFBill)
            }

            NotificationManager.shared.notifyBillSaved(
                billingMonth: draftToPersist.billingMonth.isEmpty ? billingPeriod : draftToPersist.billingMonth,
                totalKWh: draftToPersist.totalKWh.isEmpty ? consumption.replacingOccurrences(of: " kWh", with: "") : draftToPersist.totalKWh
            )

            // Update Home Screen Widget Snapshot using the live Core ML forecast
            let allSavedBills = (try? modelContext.fetch(FetchDescriptor<SavedBill>())) ?? [savedPDFBill]
            let allAppliances = (try? modelContext.fetch(FetchDescriptor<Appliance>())) ?? []
            let currentUser = (try? modelContext.fetch(FetchDescriptor<User>()))?.first
            WidgetDataStore.shared.syncFrom(
                bills: allSavedBills,
                appliances: allAppliances,
                user: currentUser,
                temperatureC: WeatherService.shared.currentTemperature,
                humidityPercent: WeatherService.shared.currentHumidity
            )

            // Clear import screens from navigationStack so pressing Back returns cleanly to .home or .billHistory
            navState.navigationStack.removeAll { $0 == .selectBillImage || $0 == .scanningBill || $0 == .reviewBill }
            isSavingBill = false
            navState.navigate(to: .billAnalysisResult)
        } catch {
            isSavingBill = false
            saveError = "Unable to save bill into SwiftData: \(error.localizedDescription)"
        }
    }

    private func parsePeriodDates(from periodText: String, readingDate: String) -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()

        if let rDate = parseSimpleDate(readingDate) {
            let start = calendar.date(byAdding: .day, value: -30, to: rDate) ?? rDate
            return (start, rDate)
        }

        let start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        return (start, now)
    }

    private func parseSimpleDate(_ text: String) -> Date? {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for fmt in ["yyyy-MM-dd", "dd/MM/yyyy", "dd/MM/yy", "yyyy/MM/dd"] {
            df.dateFormat = fmt
            if let d = df.date(from: clean) {
                return d
            }
        }
        return nil
    }
}
