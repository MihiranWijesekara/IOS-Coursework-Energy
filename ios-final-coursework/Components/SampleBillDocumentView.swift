//
//  SampleBillDocumentView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct SampleBillDocumentView: View {
    public init() {}

    public var body: some View {
        Group {
            #if canImport(UIKit)
            if let uiImage = UIImage(named: "SampleBill") {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            } else {
                vectorBillView
            }
            #else
            vectorBillView
            #endif
        }
    }

    private var vectorBillView: some View {
        VStack(spacing: 0) {
            billDocumentCard
        }
        .padding(.horizontal, 4)
    }

    private var billDocumentCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            headerRow
            Divider().background(Color.gray.opacity(0.3))
            billingInfoRow
            billTableSection
            footerRow
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
        )
    }

    private var headerRow: some View {
        HStack(alignment: .top) {
            accountHeader
            Spacer()
            barcodeBlock
        }
        .padding(.bottom, 4)
    }

    private var accountHeader: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color(red: 0.15, green: 0.20, blue: 0.25), lineWidth: 1.5)
                    .frame(width: 22, height: 22)
                Text("CEB")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(Color(red: 0.15, green: 0.20, blue: 0.25))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("CEYLON ELECTRICITY BOARD")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color(red: 0.15, green: 0.20, blue: 0.25))
                Text("Electricity Statement / Invoice")
                    .font(.system(size: 6, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
    }

    private var barcodeBlock: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 1.5) {
                ForEach(0..<14, id: \.self) { i in
                    Rectangle()
                        .fill(Color.black.opacity(i % 3 == 0 ? 0.9 : 0.6))
                        .frame(width: i % 2 == 0 ? 2 : 1, height: 12)
                }
            }
            Text("A/C: 084 729 1845")
                .font(.system(size: 6, design: .monospaced))
                .foregroundColor(.gray)
        }
    }

    private var billingInfoRow: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                billTextRow(label: "Account Name", value: "Achintha Mihiran")
                billTextRow(label: "Tariff Category", value: "Domestic - D1")
                billTextRow(label: "Premises ID", value: "COL-003-8924")
                billTextRow(label: "Bill Month", value: "August 2025")
            }

            Spacer()

            VStack(alignment: .leading, spacing: 3) {
                billTextRow(label: "Billing Date", value: "31/08/2025")
                billTextRow(label: "Due Date", value: "21/09/2025")
                billTextRow(label: "Prev. Reading", value: "12,450 kWh")
                billTextRow(label: "Curr. Reading", value: "12,630 kWh")
            }
        }
        .padding(.vertical, 4)
    }

    private var billTableSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Description")
                    .font(.system(size: 7, weight: .bold))
                Spacer()
                Text("Units (kWh)")
                    .font(.system(size: 7, weight: .bold))
                Spacer()
                Text("Amount (LKR)")
                    .font(.system(size: 7, weight: .bold))
            }
            .foregroundColor(Color.black.opacity(0.75))
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color(red: 0.93, green: 0.95, blue: 0.97))

            Rectangle()
                .fill(Color.gray.opacity(0.25))
                .frame(height: 0.8)

            tableRow(title: "Energy Consumption", units: "180", amount: "6,840.00")
            tableRow(title: "Fixed Charge", units: "-", amount: "540.00")
            tableRow(title: "Fuel Adjustment Charge", units: "-", amount: "470.00")

            Rectangle()
                .fill(Color.black.opacity(0.4))
                .frame(height: 1)

            HStack {
                Text("TOTAL CHARGES DUE")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.4, blue: 0.2))
                Spacer()
                Text("180 kWh")
                    .font(.system(size: 8, weight: .bold))
                Spacer()
                Text("LKR 7,850.00")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Color(red: 0.1, green: 0.4, blue: 0.2))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color(red: 0.91, green: 0.96, blue: 0.92))
        }
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.8)
        )
    }

    private var footerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("* Official CEB Computer Generated Invoice *")
                    .font(.system(size: 6, weight: .regular))
                    .foregroundColor(.gray)
                Text("Payment Ref: 0847291845-202508")
                    .font(.system(size: 6, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.8))
            }
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                    .frame(width: 48, height: 18)
                Text("PAID / VERIFIED")
                    .font(.system(size: 5, weight: .bold))
                    .foregroundColor(Color.blue.opacity(0.6))
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func billTextRow(label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 7, weight: .semibold))
                .foregroundColor(Color.black.opacity(0.85))
        }
    }

    @ViewBuilder
    private func tableRow(title: String, units: String, amount: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 7, weight: .regular))
                .foregroundColor(Color.black.opacity(0.8))
            Spacer()
            Text(units)
                .font(.system(size: 7, weight: .regular))
                .foregroundColor(Color.black.opacity(0.8))
            Spacer()
            Text(amount)
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(Color.black.opacity(0.8))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
    }
}

