//
//  DateFormatters.swift
//  Growth Map
//
//  Created on November 15, 2025.
//

import Foundation

/// Custom date formatters for Supabase timestamp handling
enum DateFormatters {
    /// ISO8601 formatter for timestamptz fields (with milliseconds)
    static let iso8601WithMilliseconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    /// ISO8601 formatter for date-only fields
    static let iso8601DateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// JSON decoder configured for Supabase timestamps
    static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 with milliseconds first (timestamptz)
            if let date = iso8601WithMilliseconds.date(from: dateString) {
                return date
            }
            
            // Try date-only format (date)
            if let date = iso8601DateOnly.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }
        return decoder
    }()
    
    /// JSON encoder configured for Supabase timestamps
    static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let dateString = iso8601WithMilliseconds.string(from: date)
            try container.encode(dateString)
        }
        return encoder
    }()
}
