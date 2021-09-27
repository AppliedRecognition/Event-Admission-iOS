//
//  IdentifiedUserSelector.swift
//  EventAdmission
//
//  Created by Jakub Dolejs on 27/09/2021.
//

import Foundation

public class IdentifiedUserSelector {
    
    public var minScoreDistance: Float = 0.2
    
    public func selectBestMatch(candidates: [(String,Float)]) -> String? {
        if candidates.isEmpty {
            return nil
        }
        if candidates.count == 1 {
            return candidates.first!.0
        }
        let sortedCandidates = candidates.sorted(by: {
            $0.1 > $1.1
        })
        if sortedCandidates[0].1 - sortedCandidates[1].1 > self.minScoreDistance {
            return sortedCandidates[0].0
        }
        return nil
    }
}
