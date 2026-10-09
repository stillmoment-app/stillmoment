//
//  AppSettingsView+Previews.swift
//  Still Moment
//
//  SwiftUI previews for AppSettingsView (DEBUG only; built on preview doubles / AppDependencies.live()).
//

#if DEBUG
import SwiftUI

@available(iOS 17.0, *)
#Preview {
    NavigationStack {
        AppSettingsView(settingsRepository: AppDependencies.live().guidedSettingsRepository)
    }
}
#endif
