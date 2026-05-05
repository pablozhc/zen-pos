import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyACRpEzVcjX4GLPLRk_TDCiGCuUv7HNAAQ',
    appId: '1:590487505113:web:2d34fd6554f8e50c3096c8',
    messagingSenderId: '590487505113',
    projectId: 'zen-pos',
    authDomain: 'zen-pos.firebaseapp.com',
    storageBucket: 'zen-pos.firebasestorage.app',
    measurementId: 'G-TGQHP0R9EM',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBr5dn7bJ0jSgoORLiikuRxlHai1u1lh_s',
    appId: '1:590487505113:android:a1140ae81f24bbef3096c8',
    messagingSenderId: '590487505113',
    projectId: 'zen-pos',
    storageBucket: 'zen-pos.firebasestorage.app',
  );
}
