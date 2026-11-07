# मोबाइल से APK बनाने के अगले चरण

1. Firebase Console में नया प्रोजेक्ट बनाएं।
2. Authentication > Sign-in method > Email/Password सक्षम करें।
3. Firestore Database बनाएं और firestore.rules में दिए नियम प्रकाशित करें।
4. Firebase में Android App register करें, package name: in.lawyerdiary.lawyer_diary_ai_8
5. FlutterFire CLI से बने lib/firebase_options.dart को base64 में encode करके GitHub Actions secret FIREBASE_OPTIONS_B64 में रखें। यह Firebase client configuration है, admin service account key नहीं।
6. GitHub > Actions > Build Android APK > Run workflow चलाएं।
7. Build सफल होने पर Artifacts से debug APK डाउनलोड करें।

यह केवल परीक्षण संस्करण है। अभी स्थानीय पेशी नोटिफिकेशन, eCourts auto-sync, cloud backup restore verification, और production security testing बाकी हैं। किसी वास्तविक मुवक्किल का डेटा परीक्षण से पहले न डालें।
