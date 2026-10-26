//
//  WeatherService.swift
//  ios-final-coursework
//
//  Created for fetching live weather data and caching in SwiftData
//

import Foundation
import Combine
import SwiftData

@MainActor
public final class WeatherService: ObservableObject {
    public static let shared = WeatherService()
    
    // Published live weather properties
    @Published public var currentTemperature: Double = 31.0
    @Published public var currentHumidity: Double = 78.0
    @Published public var conditionDescription: String = "Sunny & Clear"
    @Published public var weatherIconName: String = "sun.max.fill"
    @Published public var hourlyForecast: [(time: String, temp: Int, icon: String)] = [
        ("2 PM", 33, "sun.max.fill"),
        ("5 PM", 31, "cloud.sun.fill"),
        ("8 PM", 28, "moon.stars.fill")
    ]
    @Published public var acLoadImpactPercent: Int = 18
    /// Tomorrow's forecast max temperature (nil until a forecast has been fetched)
    @Published public var tomorrowMaxTemperature: Double? = nil
    @Published public var isLoading: Bool = false
    @Published public var lastError: String? = nil
    
    // Default coordinates: Sri Lanka (Colombo / Malabe)
    public let defaultLatitude: Double = 6.9271
    public let defaultLongitude: Double = 79.8612
    
    private init() {
        calculateAcImpact()
    }
    
    /// Calculate dynamic AC load impact percentage based on temperature and relative humidity
    public func calculateAcImpact() {
        let tempExcess = max(0.0, currentTemperature - 24.0)
        let humidityExcess = max(0.0, currentHumidity - 60.0)
        let impact = Int(round((tempExcess * 3.5) + (humidityExcess * 0.2)))
        self.acLoadImpactPercent = max(5, min(40, impact))
    }
    
    /// 1. Convert Town/City name to Coordinates (Latitude, Longitude)
    public func fetchCoordinates(for town: String) async throws -> (lat: Double, lon: Double, displayName: String) {
        let cleanedTown = town.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let encodedTown = cleanedTown.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(encodedTown)&count=1&language=en&format=json") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let geocoding = try JSONDecoder().decode(GeocodingResponse.self, from: data)
        guard let location = geocoding.results?.first else {
            throw NSError(domain: "WeatherService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Location '\(town)' not found"])
        }
        
        return (location.latitude, location.longitude, location.name)
    }
    
    /// 2. Fetch current and hourly weather forecast from Open-Meteo
    @discardableResult
    public func fetchWeather(
        latitude: Double = 6.9271,
        longitude: Double = 79.8612
    ) async throws -> OpenMeteoResponse {
        isLoading = true
        lastError = nil
        
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&hourly=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code&forecast_days=2&timezone=auto"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            throw URLError(.badURL)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                isLoading = false
                throw URLError(.badServerResponse)
            }
            
            let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            
            // Update current conditions
            if let current = decoded.current {
                self.currentTemperature = current.temperature2m
                if let rh = current.relativeHumidity2m {
                    self.currentHumidity = rh
                }
                let mapped = Self.mapWeatherCode(current.weatherCode, temperature: current.temperature2m)
                self.conditionDescription = mapped.condition
                self.weatherIconName = mapped.icon
                calculateAcImpact()
            }
            
            if let maxes = decoded.daily?.temperature2mMax, maxes.count > 1 {
                self.tomorrowMaxTemperature = maxes[1]
            }
            
            // Update hourly forecast
            if let hourly = decoded.hourly {
                var items: [(time: String, temp: Int, icon: String)] = []
                for (idx, timeStr) in hourly.time.enumerated() {
                    guard idx < hourly.temperature2m.count, idx < hourly.weatherCode.count else { continue }
                    
                    let hourPart: Int = {
                        if let t = timeStr.firstIndex(of: "T") {
                            let sub = timeStr[timeStr.index(after: t)...].prefix(2)
                            return Int(sub) ?? idx
                        }
                        return idx
                    }()
                    
                    // Select key hourly milestones (2 PM, 5 PM, 8 PM or spaced upcoming hours)
                    if [14, 17, 20].contains(hourPart) || (items.count < 3 && hourPart >= 11 && hourPart % 3 == 2) {
                        let h12 = hourPart == 0 ? 12 : (hourPart > 12 ? hourPart - 12 : hourPart)
                        let ampm = hourPart >= 12 ? "PM" : "AM"
                        let label = "\(h12) \(ampm)"
                        let temp = Int(round(hourly.temperature2m[idx]))
                        let icon = Self.mapWeatherCode(hourly.weatherCode[idx], temperature: hourly.temperature2m[idx]).icon
                        
                        if !items.contains(where: { $0.time == label }) {
                            items.append((time: label, temp: temp, icon: icon))
                        }
                    }
                }
                
                if !items.isEmpty {
                    self.hourlyForecast = items
                }
            }
            
            isLoading = false
            return decoded
        } catch {
            isLoading = false
            lastError = error.localizedDescription
            throw error
        }
    }
    
    /// Convenience fetch with Sri Lanka coordinates
    @discardableResult
    public func fetchWeather() async throws -> OpenMeteoResponse {
        return try await fetchWeather(latitude: defaultLatitude, longitude: defaultLongitude)
    }
    
    /// Geocodes the user's town and updates the shared live weather values.
    /// Falls back to Colombo (6.9271, 79.8612) when the town is empty or geocoding/offline fails.
    public func fetchWeather(forTown town: String) async {
        var lat = defaultLatitude
        var lon = defaultLongitude
        let cleaned = town.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleaned.isEmpty, let coords = try? await fetchCoordinates(for: cleaned) {
            lat = coords.lat
            lon = coords.lon
        }
        _ = try? await fetchWeather(latitude: lat, longitude: lon)
    }
    
    /// 3. Helper to translate WMO weather codes into conditions, SF Symbols, and cooling demand advice
    public static func mapWeatherCode(_ code: Int, temperature: Double? = nil) -> (condition: String, icon: String, advice: String) {
        let temp = temperature ?? 30.0
        let coolingAdvice = temp >= 30.0 ? "High cooling demand · Keep AC at 24–26°C" : "Moderate cooling demand"
        
        switch code {
        case 0:
            return ("Sunny & Clear", "sun.max.fill", coolingAdvice)
        case 1, 2:
            return ("Partly Cloudy", "cloud.sun.fill", coolingAdvice)
        case 3:
            return ("Overcast", "cloud.fill", "Lower cooling demand today")
        case 45, 48:
            return ("Foggy", "cloud.fog.fill", "Moderate humidity · Fan recommended")
        case 51, 53, 55:
            return ("Light Drizzle", "cloud.drizzle.fill", "Natural cooling outside")
        case 61, 63, 65:
            return ("Rain", "cloud.rain.fill", "Cooler outside · Reduce AC usage")
        case 80, 81, 82:
            return ("Showers", "cloud.heavyrain.fill", "Cool weather · Natural ventilation recommended")
        case 95, 96, 99:
            return ("Thunderstorm", "cloud.bolt.rain.fill", "Unplug sensitive appliances")
        default:
            return ("Partly Cloudy", "cloud.sun.fill", coolingAdvice)
        }
    }
}
