//
//  BillDetailView.swift
//  ios-final-coursework
//
//  Comprehensive Bill Inspection, Permanent Editing, and Deletion Screen
//

import SwiftUI
import SwiftData

public struct BillDetailView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Environment(\.modelContext) private var modelContext
    @Query private var allBills: [ElectricityBill]

    private var navModel: AppNavigationState { navState }
    
    public let billId: UUID?
    
    @State private var showDeleteConfirm = false
    @State private var showEditModal = false
    @State private var showImageZoom = false
    
    // Edit Form State
    @State private var editAccountNo = ""
    @State private var editCustomerName = ""
    @State private var editPrevReading = ""
    @State private var editCurrReading = ""
    @State private var editConsumption = ""
    @State private var editCurrentCharge = ""
    @State private var editTaxes = ""
    @State private var editOutstanding = ""
    @State private var editTotalPayable = ""
    @State private var editPeriodText = ""
    
    public init(billId: UUID? = nil) {
        self.billId = billId
    }
    
    private var bill: ElectricityBill? {
        if let id = billId {
            return allBills.first { $0.id == id }
        }
        return allBills.first
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Bar
            HStack {
                CustomBackButton(title: "Bill History") {
                    navState.navigate(to: .billHistory)
                }
                
                Spacer()
                
                if let bill = bill {
                    HStack(spacing: 8) {
                        Button(action: openEditModal) {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                Text("Edit")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(EnergyLensTheme.accentGreen)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(EnergyLensTheme.mintHighlight)
                            .cornerRadius(8)
                        }

                        Button(role: .destructive) {
                            try? SwiftDataBillService.shared.deleteBill(bill, in: modelContext)
                            navModel.navigateBack()
                        } label: {
                            Label("Delete Bill", systemImage: "trash")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.red)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.08))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 16)
            .padding(.horizontal, 24)
            
            if let activeBill = bill {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Main Hero Card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(activeBill.provider)
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.2))
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                    Text(activeBill.isVerified ? "Verified Bill" : "Imported")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(Color(red: 0.72, green: 0.95, blue: 0.82))
                            }
                            
                            Text(activeBill.billingPeriodText.isEmpty ? SwiftDataBillService.formatPeriod(start: activeBill.periodStart, end: activeBill.periodEnd) : activeBill.billingPeriodText)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                            
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(String(format: "%.0f", activeBill.consumptionKwh))
                                    .font(.system(size: 46, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("kWh")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("TOTAL DUE")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                                    Text(String(format: "Rs. %.2f", activeBill.totalAmountPayable))
                                        .font(.system(size: 20, weight: .black))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(20)
                        .background(EnergyLensTheme.cardGradient)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                        
                        // Scanned Screenshot Thumbnail if retained
                        if let data = activeBill.imageData, let img = UIImage(data: data) {
                            Button(action: { showImageZoom = true }) {
                                HStack(spacing: 12) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 54, height: 54)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(EnergyLensTheme.accentGreen, lineWidth: 1.5)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Original Bill Screenshot")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(EnergyLensTheme.textPrimary)
                                        
                                        Text("Stored locally in SwiftData · Tap to inspect")
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
                        
                        // Account & Customer Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Customer & Account Details")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            detailItem(label: "Account Number", value: activeBill.accountNumber.isEmpty ? "—" : activeBill.accountNumber, icon: "number")
                            if let name = activeBill.customerName, !name.isEmpty {
                                detailItem(label: "Customer Name", value: name, icon: "person")
                            }
                            if let tariff = activeBill.tariffCategory, !tariff.isEmpty {
                                detailItem(label: "Tariff Category", value: tariff, icon: "tag")
                            }
                            if let bDate = activeBill.billDate {
                                detailItem(label: "Reading / Issue Date", value: formatDate(bDate), icon: "calendar.badge.clock")
                            }
                            if let dDate = activeBill.dueDate {
                                detailItem(label: "Payment Due Date", value: formatDate(dDate), icon: "calendar.badge.exclamationmark")
                            }
                            detailItem(label: "Uploaded On", value: formatDate(activeBill.uploadedAt), icon: "arrow.up.doc")
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                        )
                        
                        // Meter Readings Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Meter Readings & Units")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Previous Reading")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(EnergyLensTheme.textSecondary)
                                    Text(activeBill.prevReading != nil ? "\(activeBill.prevReading!) kWh" : "—")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(EnergyLensTheme.textPrimary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                                .cornerRadius(10)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Current Reading")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(EnergyLensTheme.textSecondary)
                                    Text(activeBill.currReading != nil ? "\(activeBill.currReading!) kWh" : "—")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(EnergyLensTheme.textPrimary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                                .cornerRadius(10)
                            }
                            
                            if let p = activeBill.prevReading, let c = activeBill.currReading, c >= p {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(EnergyLensTheme.accentGreen)
                                        .font(.system(size: 12))
                                    Text("Difference: \(c) - \(p) = \(c - p) Units")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(EnergyLensTheme.accentGreen)
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                        )
                        
                        // Financial Breakdown Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Charges Breakdown")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            if let c = activeBill.currentCharges {
                                financialItem(title: "Electricity Charge", amount: String(format: "Rs. %.2f", c))
                            }
                            if let t = activeBill.taxesAndLevies {
                                financialItem(title: "SSC Levy & Taxes", amount: String(format: "Rs. %.2f", t))
                            }
                            if let bf = activeBill.previousBalance {
                                financialItem(title: "Brought Forward (B/F)", amount: String(format: "Rs. %.2f", bf))
                            }
                            if let p = activeBill.payments {
                                financialItem(title: "Payments Received", amount: String(format: "-Rs. %.2f", p), color: .green)
                            }
                            if let o = activeBill.outstandingBalance {
                                financialItem(title: "Outstanding Balance", amount: String(format: "Rs. %.2f", o))
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            HStack {
                                Text("Total Amount Payable")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(red: 0.08, green: 0.35, blue: 0.45))
                                Spacer()
                                Text(String(format: "Rs. %.2f", activeBill.totalAmountPayable))
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundColor(Color(red: 0.08, green: 0.35, blue: 0.45))
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                        )
                        
                        // Action Buttons: Edit and Delete
                        VStack(spacing: 12) {
                            GradientButton(title: "Edit Bill Information") {
                                openEditModal()
                            }
                            
                            Button(action: { showDeleteConfirm = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 15, weight: .medium))
                                    Text("Delete This Bill")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.08))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 28)
                    }
                    .padding(.horizontal, 24)
                }
            } else {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "doc.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                    Text("Bill record not found")
                        .font(.headline)
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    GradientButton(title: "Go to Bill History") {
                        navState.navigate(to: .billHistory)
                    }
                    Spacer()
                }
                .padding(24)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .sheet(isPresented: $showEditModal) {
            editBillModal
        }
        .sheet(isPresented: $showImageZoom) {
            if let data = bill?.imageData, let img = UIImage(data: data) {
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
        .alert("Delete Electricity Bill?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let b = bill {
                    try? SwiftDataBillService.shared.deleteBill(b, in: modelContext)
                    navModel.navigateBack()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the bill record and its screenshot from SwiftData.")
        }
    }

    // Helper Row Builders
    @ViewBuilder
    private func detailItem(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(EnergyLensTheme.accentGreen)
                .frame(width: 18)
            
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(EnergyLensTheme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(EnergyLensTheme.textPrimary)
        }
    }
    
    @ViewBuilder
    private func financialItem(title: String, amount: String, color: Color = EnergyLensTheme.textPrimary) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(EnergyLensTheme.textSecondary)
            Spacer()
            Text(amount)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: date)
    }
    
    private func openEditModal() {
        guard let b = bill else { return }
        editAccountNo = b.accountNumber
        editCustomerName = b.customerName ?? ""
        editPrevReading = b.prevReading != nil ? "\(b.prevReading!)" : ""
        editCurrReading = b.currReading != nil ? "\(b.currReading!)" : ""
        editConsumption = String(format: "%.0f", b.consumptionKwh)
        editCurrentCharge = b.currentCharges != nil ? String(format: "%.2f", b.currentCharges!) : ""
        editTaxes = b.taxesAndLevies != nil ? String(format: "%.2f", b.taxesAndLevies!) : ""
        editOutstanding = b.outstandingBalance != nil ? String(format: "%.2f", b.outstandingBalance!) : ""
        editTotalPayable = String(format: "%.2f", b.totalAmountPayable)
        editPeriodText = b.billingPeriodText
        showEditModal = true
    }
    
    private func savePermanentEdits() {
        guard let b = bill else { return }
        let prev = Int(editPrevReading)
        let curr = Int(editCurrReading)
        let cons = Double(editConsumption) ?? b.consumptionKwh
        let charge = Double(editCurrentCharge)
        let taxes = Double(editTaxes)
        let out = Double(editOutstanding)
        let tot = Double(editTotalPayable) ?? b.totalAmountPayable
        
        try? SwiftDataBillService.shared.updateBill(
            context: modelContext,
            bill: b,
            accountNumber: editAccountNo,
            customerName: editCustomerName.isEmpty ? nil : editCustomerName,
            prevReading: prev,
            currReading: curr,
            consumptionKwh: cons,
            currentCharges: charge,
            taxesAndLevies: taxes,
            outstandingBalance: out,
            totalAmountPayable: tot,
            billingPeriodText: editPeriodText,
            dueDate: b.dueDate
        )
        showEditModal = false
    }
    
    // Modal Form for Editing Bill
    private var editBillModal: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Edit Saved Bill Data")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    formField(label: "Account Number", text: $editAccountNo, icon: "number")
                    formField(label: "Customer Name", text: $editCustomerName, icon: "person")
                    formField(label: "Billing Period", text: $editPeriodText, icon: "calendar")
                    formField(label: "Previous Reading (kWh)", text: $editPrevReading, icon: "gauge")
                    formField(label: "Current Reading (kWh)", text: $editCurrReading, icon: "gauge.badge.plus")
                    formField(label: "Consumption (kWh)", text: $editConsumption, icon: "bolt.fill")
                    formField(label: "Current Electricity Charge", text: $editCurrentCharge, icon: "dollarsign.circle")
                    formField(label: "Taxes / Levies (SSC)", text: $editTaxes, icon: "percent")
                    formField(label: "Outstanding Balance", text: $editOutstanding, icon: "creditcard")
                    formField(label: "Total Amount Payable (LKR)", text: $editTotalPayable, icon: "banknote")
                    
                    GradientButton(title: "Save Changes Permanently") {
                        savePermanentEdits()
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
                .padding(20)
            }
            .navigationBarTitle("Edit Bill", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") { showEditModal = false },
                trailing: Button("Save") { savePermanentEdits() }.font(.headline)
            )
        }
    }
    
    private func formField(label: String, text: Binding<String>, icon: String) -> some View {
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
}
