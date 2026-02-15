// Firebase options from GoogleService-Info.plist / google-services.json
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isIOS) return ios;
    return android;
  }

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: 'AIzaSyDXAkAIGgKGPdFZqdPf5xv9tMemiOc6YxM',
        appId: '1:181753653554:android:3ee0ea4ea38fd5f9c0cf2b',
        messagingSenderId: '181753653554',
        projectId: 'fantastar-1a5bc',
        storageBucket: 'fantastar-1a5bc.firebasestorage.app',
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: 'AIzaSyCMW147-qzKkz11lqo6Kj5pn89FBMEEO2I',
        appId: '1:181753653554:ios:df926848b3019000c0cf2b',
        messagingSenderId: '181753653554',
        projectId: 'fantastar-1a5bc',
        storageBucket: 'fantastar-1a5bc.firebasestorage.app',
        iosBundleId: 'com.fantastar.frontendMobile',
      );
}
