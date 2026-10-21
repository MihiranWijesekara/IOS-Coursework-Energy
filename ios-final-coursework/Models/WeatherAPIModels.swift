//
//  WeatherAPIModels.swift
//  ios-final-coursework
//
//  Created for Open-Meteo Weather API integration
//

import Foundation

// MARK: - Geocoding Response (Town/City name to Coordinates)
public struct GeocodingResponse: Codable {
    public let results: [GeocodingLocation]?
}

public struct GeocodingLocation: Codable {
    public let id: Int?
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let country: String?
    public let admin1: String? // State/Province
    public let timezone: String?
}

// MARK: - Weather Forecast Response from Open-Meteo
public struct OpenMeteoResponse: Codable {
    public let latitude: Double?
    public let longitude: Double?
    public let timezone: String?
    public let current: CurrentWeather?
    public let daily: DailyWeather?
}

public struct CurrentWeather: Codable {
    public let time: String
    public let temperature2m: Double
    public let relativeHumidity2m: Double?
    public let windSpeed10m: Double?
    public let weatherCode: Int
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case relativeHumidity2m = "relative_humidity_2m"
        case windSpeed10m = "wind_speed_10m"
        case weatherCode = "weather_code"
    }
}

public struct DailyWeather: Codable {
    public let time: [String]
    public let temperature2mMax: [Double]
    public let temperature2mMin: [Double]
    public let precipitationProbabilityMax: [Int]?
    public let weatherCode: [Int]
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case precipitationProbabilityMax = "precipitation_probability_max"
        case weatherCode = "weather_code"
    }
}
