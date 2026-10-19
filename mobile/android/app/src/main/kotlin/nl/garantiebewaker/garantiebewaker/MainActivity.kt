package nl.garantiebewaker.garantiebewaker

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import com.fluttercavalry.open_file_handler.OpenFileHandlerPlugin
import io.flutter.embedding.android.FlutterActivity

/**
 * Ontvangt bestanden die met GarantieBewaker worden geopend of gedeeld
 * (PDF, JPEG, PNG, HEIC) en geeft ze door aan Flutter via open_file_handler.
 * Het bestand wordt naar de cache van de app gekopieerd; Flutter controleert
 * het daarna en ruimt de kopie op.
 */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.action != Intent.ACTION_VIEW && intent.action != Intent.ACTION_SEND) return
        @Suppress("DEPRECATION")
        val uri: Uri? = intent.data ?: intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
        if (uri != null) {
            OpenFileHandlerPlugin.handleOpenURI(uri, alwaysCopy = true)
        }
    }
}
