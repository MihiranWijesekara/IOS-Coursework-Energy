import XCTest
import SwiftData
@testable import ios_final_coursework

@MainActor
final class EnergyLensBillOCRTests: XCTestCase {

    private var parser: ElectricityBillParser!
    private var validator: ElectricityBillValidator!
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!

    override func setUpWithError() throws {
        parser = ElectricityBillParser()
        validator = ElectricityBillValidator()

        let schema = Schema([SavedUser.self, SavedBill.self, SavedAppliance.self, SavedScenario.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
    }

    func testReferenceCEBScreenshot() {
        let text = """
        Forwarded
        CEB e-Bill
        Open this link to view your electricity bill.
        ebill.edl.lk
        A/C No: 5410264908 (D1)
        R RANJITH
        B/F: Rs. 2,987.07
        Payments: Rs. 2,200.00
        Outstanding: Rs. 787.07 by 2026-09-17
        Reading Date: 2026-09-30 (457)
        Reading: 10756 - 10678 = 78 Units
        Charge: Rs. 1,588.00
        SSC Levy: Rs. 40.72
        Monthly Bill: Rs. 1,628.72
        Total Due: Rs. 2,415.79
        View e-Bill here:
        https://ebill.edl.lk/v1/NTQxMDI2NDkwOCo0NTcqNTg2
        """

        let extracted = parser.parse(rawText: text)

        XCTAssertEqual(extracted.formatType, .cebEBill)
        XCTAssertEqual(extracted.accountNumber, "5410264908")
        XCTAssertEqual(extracted.tariffCode, "D1")
        XCTAssertEqual(extracted.customerName, "R RANJITH")
        XCTAssertEqual(extracted.broughtForward, Decimal(string: "2987.07"))
        XCTAssertEqual(extracted.payments, Decimal(string: "2200.00"))
        XCTAssertEqual(extracted.outstandingBalance, Decimal(string: "787.07"))
        XCTAssertEqual(extracted.outstandingDueDateRaw, "2026-09-17")
        XCTAssertEqual(extracted.readingDateRaw, "2026-09-30")
        XCTAssertEqual(extracted.readingDateSuffix, "457")
        XCTAssertEqual(extracted.currentReading, 10756)
        XCTAssertEqual(extracted.previousReading, 10678)
        XCTAssertEqual(extracted.consumptionUnits, 78)
        XCTAssertEqual(extracted.energyCharge, Decimal(string: "1588.00"))
        XCTAssertEqual(extracted.levyAmount, Decimal(string: "40.72"))
        XCTAssertEqual(extracted.monthlyBill, Decimal(string: "1628.72"))
        XCTAssertEqual(extracted.totalDue, Decimal(string: "2415.79"))
        XCTAssertTrue(extracted.validationWarnings.isEmpty)
    }

    func testDynamicAccountNumber() {
        let text = """
        CEB e-Bill
        A/C No: 7788990011 (GP1)
        Reading Date: 2026-10-15 (312)
        Reading: 4500 - 4300 = 200 Units
        Total Due: Rs. 5,400.00
        """
        let extracted = parser.parse(rawText: text)
        XCTAssertEqual(extracted.accountNumber, "7788990011")
        XCTAssertNotEqual(extracted.accountNumber, "5410264908")
    }

    func testMeterReadings() {
        let text = """
        CEB e-Bill
        A/C No: 1122334455 (D1)
        Reading Date: 2026-10-20 (101)
        Reading: 15890 - 15720 = 170 Units
        Total Due: Rs. 4,120.50
        """
        let extracted = parser.parse(rawText: text)
        XCTAssertEqual(extracted.currentReading, 15890)
        XCTAssertEqual(extracted.previousReading, 15720)
        XCTAssertEqual(extracted.consumptionUnits, 170)
    }

    func testSwiftDataPersistence() throws {
        let draft = BillTextRecognitionService.shared.parseRecognizedText("""
        CEB e-Bill
        A/C No: 5410264908 (D1)
        Reading Date: 2026-09-30 (457)
        Reading: 10756 - 10678 = 78 Units
        Total Due: Rs. 2,415.79
        """)

        let saved = try SwiftDataBillService.shared.saveReviewedBill(
            from: draft,
            userEmail: "test@energylens.app",
            in: modelContext
        )

        let freshContext = ModelContext(modelContainer)
        let fetched = SwiftDataBillService.shared.fetchBills(for: "test@energylens.app", in: freshContext)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, saved.id)
        XCTAssertEqual(fetched.first?.accountNumber, "5410264908")
        XCTAssertEqual(fetched.first?.totalKWh, 78.0)
    }
}
