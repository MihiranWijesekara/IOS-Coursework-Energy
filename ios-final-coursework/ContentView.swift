//
//  ContentView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct ContentView: View {
    @StateObject private var navState = AppNavigationState()
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Main Active Screen (all 33 screens from PDF specification)
            Group {
                switch navState.currentScreen {
                case .splash:
                    SplashScreenView()
                case .createAccount:
                    CreateAccountView()
                case .signIn:
                    SignInView()
                case .secureData:
                    SecureDataView()
                case .home:
                    HomeDashboardView()
                case .analysis:
                    AnalysisView()
                case .billAnalysis:
                    BillAnalysisView()
                case .selectBillImage:
                    SelectBillImageView()
                case .scanningBill:
                    ScanningBillView()
                case .reviewBill:
                    ReviewBillView()
                case .billAnalysisResult:
                    BillAnalysisResultView()
                case .billHistory:
                    BillHistoryView()
                case .billDetail:
                    BillDetailView(billId: navState.selectedBillId)
                case .consumptionBreakdown:
                    ConsumptionBreakdownView()
                case .appliances:
                    AppliancesView()
                case .addAppliance:
                    AddApplianceView()
                case .applianceDetail:
                    ApplianceDetailView(applianceId: navState.selectedApplianceId)
                case .weatherDetails:
                    WeatherDetailsView()
                case .nextMonthPrediction:
                    NextMonthPredictionView()
                case .whyThisPrediction:
                    WhyThisPredictionView()
                case .savingsSimulator:
                    SavingsSimulatorView()
                case .simulationResult:
                    SimulationResultView()
                case .addScenarioModal:
                    AddScenarioModalView()
                case .solarAnalysis:
                    SolarAnalysisView()
                case .profile:
                    ProfileView()
                case .notifications:
                    NotificationsView()
                case .billHistoryEmpty:
                    BillHistoryEmptyView()
                case .appliancesEmpty:
                    AppliancesEmptyView()
                case .notificationsEmpty:
                    NotificationsEmptyView()
                case .predictionEmpty:
                    PredictionEmptyView()
                case .weatherError:
                    WeatherErrorView()
                case .billScanError:
                    BillScanErrorView()
                case .homeSkeleton:
                    HomeSkeletonView()
                }
            }
            .environmentObject(navState)
            .environment(navState)
            
        }
    }
}
