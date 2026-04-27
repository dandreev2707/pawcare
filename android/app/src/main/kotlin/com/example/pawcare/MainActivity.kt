package com.example.pawcare

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.yandex.mapkit.MapKitFactory

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        MapKitFactory.setApiKey("1ca7aeee-1cc2-43ca-96f7-81a6efa139d3")
        super.configureFlutterEngine(flutterEngine)
    }
}