//
//  NavigationModel.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import Combine

public enum AppScreen: String, CaseIterable, Identifiable {
    case splash = "1. Splash"
    case createAccount = "2. Create Account"
    case signIn = "3. Sign In"
    case secureData = "4. Secure Data"
    
    case home = "6. Home"
    case analysis = "7. Analysis"
    case billAnalysis = "8. Bill Analysis"
    case selectBillImage = "9. Select Bill"
    case scanningBill = "10. Scanning Bill"
    case reviewBill = "11. Review Bill"
    case billAnalysisResult = "12. Analysis Result"
    case billHistory = "13. Bill History"
    case consumptionBreakdown = "14. Breakdown"
    case appliances = "15. Appliances"
    case addAppliance = "16. Add Appliance"
    case applianceDetail = "17. Appliance Detail"
    case weatherDetails = "18. Weather Details"
    case nextMonthPrediction = "19. Prediction"
    case whyThisPrediction = "20. Why Prediction"
    case savingsSimulator = "21. Savings Simulator"
    case simulationResult = "22. Simulation Result"
    case addScenarioModal = "23. Add Scenario"
    case solarAnalysis = "24. Solar Analysis"
    case profile = "25. Profile"
    case notifications = "26. Notifications"
    case billHistoryEmpty = "27. Bill History (Empty)"
    case appliancesEmpty = "28. Appliances (Empty)"
    case notificationsEmpty = "29. Notifications (Empty)"
    case predictionEmpty = "30. Prediction (Empty)"
    case weatherError = "31. Weather (Offline)"
    case billScanError = "32. Bill (Unreadable)"
    case homeSkeleton = "33. Home (Loading)"
    
    public var id: String { rawValue }
    
    public var screenNumber: Int {
        switch self {
        case .splash: return 1
        case .createAccount: return 2
        case .signIn: return 3
        case .secureData: return 4
        case .home: return 6
        case .analysis: return 7
        case .billAnalysis: return 8
        case .selectBillImage: return 9
        case .scanningBill: return 10
        case .reviewBill: return 11
        case .billAnalysisResult: return 12
        case .billHistory: return 13
        case .consumptionBreakdown: return 14
        case .appliances: return 15
        case .addAppliance: return 16
        case .applianceDetail: return 17
        case .weatherDetails: return 18
        case .nextMonthPrediction: return 19
        case .whyThisPrediction: return 20
        case .savingsSimulator: return 21
        case .simulationResult: return 22
        case .addScenarioModal: return 23
        case .solarAnalysis: return 24
        case .profile: return 25
        case .notifications: return 26
        case .billHistoryEmpty: return 27
        case .appliancesEmpty: return 28
        case .notificationsEmpty: return 29
        case .predictionEmpty: return 30
        case .weatherError: return 31
        case .billScanError: return 32
        case .homeSkeleton: return 33
        }
    }
}

public enum MainTab: String, CaseIterable {
    case home = "Home"
    case analysis = "Analysis"
    case savings = "Savings"
    case profile = "Profile"
}

public final class AppNavigationState: ObservableObject {
    @Published public var currentScreen: AppScreen = .splash
    @Published public var selectedTab: MainTab = .home
    
    // Auth and User State
    @Published public var firstName: String = "Achintha"
    @Published public var lastName: String = "Mihiran"
    @Published public var email: String = "achintha@example.com"
    @Published public var phone: String = "+94 77 123 4567"
    @Published public var province: String = "Western"
    @Published public var district: String = "Colombo"
    @Published public var town: String = "Colombo"
    
    @Published public var enteredPasscode: String = ""
    @Published public var isAuthenticated: Bool = false
//    
    // Bill Data and Simulator State
    @Published public var selectedAppliance: String = "Air Conditioner"
    @Published public var selectedApplianceId: UUID? = nil
    @Published public var simulationHours: Double = 4.0
    @Published public var currentAcHours: Double = 6.0

    public init() {}
    
    public func navigate(to screen: AppScreen) {
        currentScreen = screen
        if screen == .home || screen == .homeSkeleton {
            selectedTab = .home
        } else if screen == .analysis || screen == .consumptionBreakdown || screen == .appliances || screen == .nextMonthPrediction || screen == .solarAnalysis {
            selectedTab = .analysis
        } else if screen == .savingsSimulator || screen == .simulationResult {
            selectedTab = .savings
        } else if screen == .profile {
            selectedTab = .profile
        }
    }
}
