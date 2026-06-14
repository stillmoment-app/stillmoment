package com.stillmoment.presentation.ui.timer.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors

/**
 * Gemeinsame Karten-Flaeche fuer den Gong-Auswahl-Screen (shared-115).
 *
 * Pendant zu iOS' `GongCardBackground`: abgerundete Flaeche mit `cardBackground`-
 * Fuellung, 0,5dp `cardBorder`-Rand und Radius 22dp. Im Light-Mode hebt die
 * dezente Elevation die Karte, im Dark-Mode traegt der Rand den Lift.
 */
@Composable
fun GongCard(modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    val colors = LocalStillMomentColors.current
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = colors.cardBackground),
        shape = RoundedCornerShape(22.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        border = BorderStroke(0.5.dp, colors.cardBorder),
        content = content
    )
}
