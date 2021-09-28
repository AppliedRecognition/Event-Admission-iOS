//
//  IdentifiedUserSelector.swift
//  EventAdmission
//
//  Created by Jakub Dolejs on 27/09/2021.
//

import Foundation

/// Helps to select a best match from users identified by Ver-ID
public class IdentifiedUserSelector {
    
    /// Minimum distance between the first and second score
    /// If the second score deducted from the first score exceeds this distance the user with the first score is selected as best match
    public var minScoreDistance: Float = 0.2
    
    /// Initializer
    public init() {
    }
    
    /// Select the best match for a face from users identified by Ver-ID
    /// - Parameter candidates: Dictionary with users and their scores
    /// - Returns: The user with the best score that's at least `minScoreDistance` from the second best score or `nil` if no such user exists
    public func selectBestMatch(candidates: [String:Float]) -> String? {
        if candidates.isEmpty {
            return nil
        }
        if candidates.count == 1 {
            return candidates.first!.0
        }
        let sortedCandidates = candidates.map({ ($0,$1) }).sorted(by: {
            $0.1 > $1.1
        })
        if sortedCandidates[0].1 - sortedCandidates[1].1 > self.minScoreDistance {
            return sortedCandidates[0].0
        }
        return nil
    }
}
