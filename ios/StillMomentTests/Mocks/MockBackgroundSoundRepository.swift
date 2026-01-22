//
//  MockBackgroundSoundRepository.swift
//  Still Moment
//

import Foundation
@testable import StillMoment

final class MockBackgroundSoundRepository: BackgroundSoundRepositoryProtocol {
    var soundsToReturn: [BackgroundSound] = []
    var loadShouldThrow = false

    var availableSounds: [BackgroundSound] {
        self.soundsToReturn
    }

    func loadSounds() throws -> [BackgroundSound] {
        if self.loadShouldThrow {
            throw BackgroundSoundRepositoryError.configFileNotFound
        }
        return self.soundsToReturn
    }

    func getSound(byId id: String) -> BackgroundSound? {
        self.soundsToReturn.first { $0.id == id }
    }
}
