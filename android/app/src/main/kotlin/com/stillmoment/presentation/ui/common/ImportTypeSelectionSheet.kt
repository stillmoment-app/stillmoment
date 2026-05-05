package com.stillmoment.presentation.ui.common

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.ImportAudioType
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle

/**
 * Bottom sheet for selecting the import type when sharing an audio file with the app.
 * Presents two options: Guided Meditation and Soundscape.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ImportTypeSelectionSheet(onTypeSelect: (ImportAudioType) -> Unit, onDismiss: () -> Unit) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = MaterialTheme.colorScheme.surface
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 32.dp)
        ) {
            Text(
                text = stringResource(R.string.import_type_title),
                style = TypographyRole.ScreenTitle.textStyle(),
                color = TypographyRole.ScreenTitle.textColor(),
                modifier = Modifier.semantics { heading() }
            )

            Spacer(modifier = Modifier.height(16.dp))

            ImportTypeRow(
                icon = Icons.Filled.PlayCircle,
                title = stringResource(R.string.import_type_guided),
                description = stringResource(R.string.import_type_guided_description),
                onClick = { onTypeSelect(ImportAudioType.GUIDED_MEDITATION) }
            )

            ImportTypeRow(
                icon = Icons.Filled.GraphicEq,
                title = stringResource(R.string.import_type_soundscape),
                description = stringResource(R.string.import_type_soundscape_description),
                onClick = { onTypeSelect(ImportAudioType.SOUNDSCAPE) }
            )
        }
    }
}

@Composable
private fun ImportTypeRow(icon: ImageVector, title: String, description: String, onClick: () -> Unit) {
    val rowDescription = "$title — $description"

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .semantics { contentDescription = rowDescription }
            .clickable(onClick = onClick)
            .padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(32.dp),
            tint = MaterialTheme.colorScheme.primary
        )

        Spacer(modifier = Modifier.width(16.dp))

        Column {
            Text(
                text = title,
                style = TypographyRole.SettingsLabel.textStyle(),
                color = TypographyRole.SettingsLabel.textColor()
            )
            Text(
                text = description,
                style = TypographyRole.SettingsDescription.textStyle(),
                color = TypographyRole.SettingsDescription.textColor()
            )
        }
    }
}
