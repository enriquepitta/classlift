package com.pitta.classlift

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Flutter paints this same artwork before running its own exit animation.
            splashScreen.setOnExitAnimationListener { it.remove() }
        }
    }
}
