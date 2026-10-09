package com.stillmoment.presentation.ui.settings

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.widget.Toast
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.unit.dp
import com.stillmoment.BuildConfig
import com.stillmoment.R
import com.stillmoment.domain.models.FeedbackLinks
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/*
 * "Rate the App" and "Write to Us" in the settings' info section (shared-134).
 *
 * Both rows only react to a tap — the app never asks for a review on its own.
 * TalkBack reads the visible text (merged by `clickable`) and announces the action label
 * ("Double-tap to open Google Play"), which says that the app is left.
 */

/** Opens the Google Play page of Still Moment; falls back to the browser without Play Store. */
@Composable
internal fun RateAppRow(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val actionLabel = stringResource(R.string.accessibility_app_settings_rate_app_action)

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClickLabel = actionLabel) { context.openStoreListing() }
            .padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Text(
            text = stringResource(R.string.app_settings_rate_app),
            style = TextStyle.body.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.weight(1f)
        )
        RowChevron()
    }
}

/** Opens a prepared mail to Still Moment; calls [onNoMailApp] when no mail app is installed. */
@Composable
internal fun WriteToUsRow(onNoMailApp: () -> Unit, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val actionLabel = stringResource(R.string.accessibility_app_settings_write_to_us_action)

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClickLabel = actionLabel) {
                if (!context.composeFeedbackMail()) {
                    onNoMailApp()
                }
            }
            .padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = stringResource(R.string.app_settings_write_to_us),
                style = TextStyle.body.toComposeTextStyle(),
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = stringResource(R.string.app_settings_write_to_us_subtitle),
                style = TextStyle.caption.toComposeTextStyle(),
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        RowChevron()
    }
}

/** Shows the address when no mail app can take the mail, so tapping never stays unanswered. */
@Composable
internal fun NoMailAppDialog(onDismiss: () -> Unit) {
    val context = LocalContext.current
    val clipboardManager = LocalClipboardManager.current
    val copiedMessage = stringResource(R.string.app_settings_address_copied)

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.app_settings_no_mail_app_title)) },
        text = { Text(stringResource(R.string.app_settings_no_mail_app_message, FeedbackLinks.MAIL_ADDRESS)) },
        confirmButton = {
            TextButton(
                onClick = {
                    clipboardManager.setText(AnnotatedString(FeedbackLinks.MAIL_ADDRESS))
                    // Android 13+ confirms copying itself; below that Google recommends own feedback.
                    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.S_V2) {
                        Toast.makeText(context, copiedMessage, Toast.LENGTH_SHORT).show()
                    }
                    onDismiss()
                }
            ) {
                Text(stringResource(R.string.app_settings_copy_address))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(stringResource(R.string.common_ok)) }
        }
    )
}

@Composable
private fun RowChevron() {
    Icon(
        imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
        contentDescription = null,
        tint = MaterialTheme.colorScheme.onSurfaceVariant
    )
}

private fun Context.openStoreListing() {
    val openedPlayStore = startIfPossible(Intent(Intent.ACTION_VIEW, Uri.parse(FeedbackLinks.STORE_URI)))
    if (!openedPlayStore) {
        // No browser either: there is nothing else that could show the page.
        startIfPossible(Intent(Intent.ACTION_VIEW, Uri.parse(FeedbackLinks.STORE_WEB_URL)))
    }
}

/**
 * Subject and text go both into the `mailto` URI (RFC 6068) and into the extras,
 * because mail apps differ in which of the two they read.
 *
 * @return false when no mail app is installed
 */
private fun Context.composeFeedbackMail(): Boolean {
    val appVersion = BuildConfig.VERSION_NAME
    val buildNumber = BuildConfig.VERSION_CODE.toString()
    val osVersion = Build.VERSION.RELEASE
    val uri = Uri.parse(FeedbackLinks.mailtoUri(appVersion, buildNumber, osVersion))
    val intent = Intent(Intent.ACTION_SENDTO, uri).apply {
        putExtra(Intent.EXTRA_EMAIL, arrayOf(FeedbackLinks.MAIL_ADDRESS))
        putExtra(Intent.EXTRA_SUBJECT, FeedbackLinks.MAIL_SUBJECT)
        putExtra(Intent.EXTRA_TEXT, FeedbackLinks.mailBody(appVersion, buildNumber, osVersion))
    }
    return startIfPossible(intent)
}

/**
 * Starts [intent] and reports whether an app took it. Invoking and catching is the approach
 * recommended for package visibility (no `<queries>`, no `resolveActivity`).
 */
private fun Context.startIfPossible(intent: Intent): Boolean = try {
    startActivity(intent)
    true
} catch (ignored: ActivityNotFoundException) {
    false
}
