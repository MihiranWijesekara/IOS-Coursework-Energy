//
//  ContentView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct ContentView: View {
    @StateObject private var navState = AppNavigationState()
    @State private var showScreenPicker = false
    
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
                case .consumptionBreakdown:
                    ConsumptionBreakdownView()
                case .appliances:
                    AppliancesView()
                case .addAppliance:
                    AddApplianceView()
                case .applianceDetail:
                    ApplianceDetailView()
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
                    
                default:
                        // Fallback placeholder for all other screens until they are implemented
                        Text("Screen not implemented yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                }
            }
            .environmentObject(navState)
            
            // Floating Quick Screen Switcher (For testing all 33 PDF pages directly)
            VStack(spacing: 0) {
                if showScreenPicker {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("EnergyLens 33-Screen PDF Navigator")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { withAnimation { showScreenPicker = false } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.bottom, 4)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(AppScreen.allCases) { screen in
                                    Button(action: {
                                        navState.navigate(to: screen)
                                        withAnimation { showScreenPicker = false }
                                    }) {
                                        Text(screen.rawValue)
                                            .font(.system(size: 12, weight: navState.currentScreen == screen ? .bold : .medium))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(navState.currentScreen == screen ? EnergyLensTheme.accentGreen : Color.white.opacity(0.2))
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(red: 0.08, green: 0.12, blue: 0.18).opacity(0.96))
                    .cornerRadius(16)
                    .shadow(radius: 12)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                
                // Switcher Pill Toggle
                HStack {
                    Spacer()
                    Button(action: { withAnimation { showScreenPicker.toggle() } }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Page \(navState.currentScreen.screenNumber)/33")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.78))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(radius: 4)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 12)
                }
            }
        }
    }
}
