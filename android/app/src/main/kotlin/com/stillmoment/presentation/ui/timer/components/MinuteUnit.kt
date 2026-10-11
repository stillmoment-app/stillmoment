package com.stillmoment.presentation.ui.timer.components

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.pluralStringResource
import com.stillmoment.R

/**
 * Lokalisierte Minuten-Einheit fuer eine Minutenzahl, ohne die Zahl selbst
 * ("Minute" bei 1, sonst "Minutes"/"Minuten") — shared-140.
 *
 * Steht unter der grossen Zahl, wo Zahl und Einheit getrennte Zeilen sind
 * (Atemkreis, spaeter die Dauer-Anzeige aus shared-125). Gross-/Kleinschreibung
 * kommt aus dem Text-Stil der Aufrufstelle, nicht aus dem String.
 */
@Composable
fun minuteUnit(minutes: Int): String = pluralStringResource(R.plurals.timer_dial_unit, minutes)
