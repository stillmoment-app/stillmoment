package com.stillmoment.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.stillmoment.domain.services.FontLicenseProviderProtocol
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * ViewModel for the "Font Attributions" screen (shared-136).
 * Loads the license text of the bundled fonts; null while loading or if it cannot be read.
 */
@HiltViewModel
class FontAttributionsViewModel
@Inject
constructor(
    private val fontLicenseProvider: FontLicenseProviderProtocol
) : ViewModel() {

    private val _licenseText = MutableStateFlow<String?>(null)
    val licenseText: StateFlow<String?> = _licenseText.asStateFlow()

    init {
        viewModelScope.launch {
            _licenseText.value = fontLicenseProvider.loadLicenseText()
        }
    }
}
