//
//  WeatherService.swift
//  ios-final-coursework
//
//  Created for fetching live weather data and caching in SwiftData
//

import Foundation
import SwiftData

public final class WeatherService {
    public static let shared = WeatherService()
    
    private init() {}
    
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
    
    /// 2. Fetch current and 7-day weather forecast from Open-Meteo
    public func fetchWeather(latitude: Double, longitude: Double) async throws -> OpenMeteoResponse {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&timezone=auto"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
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
