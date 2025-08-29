# MultiSpace - App Cloner & Parallel Apps

একটি শক্তিশালী Android অ্যাপ যা আপনাকে একই ডিভাইসে একাধিক অ্যাপের কপি চালানোর সুবিধা দেয়। এর মাধ্যমে আপনি একই ফোনে দুইটি WhatsApp, Facebook, Instagram বা অন্য যেকোনো অ্যাপ আলাদা ডেটা সহ ব্যবহার করতে পারবেন।

## ✨ মূল ফিচারসমূহ

- **Multi App Clone**: যেকোনো ইনস্টল করা অ্যাপকে আলাদা স্পেসে ক্লোন করুন
- **Real Device Apps**: আপনার ডিভাইসের সব ইনস্টল করা অ্যাপ দেখুন
- **Data Separation**: প্রতিটি ক্লোনের আলাদা ডেটা ও কনফিগারেশন
- **Custom Names**: ক্লোন করা অ্যাপের নাম পরিবর্তন করুন
- **Easy Management**: সহজ UI দিয়ে অ্যাপ ম্যানেজ করুন
- **Lightweight**: কম স্টোরেজ ও RAM ব্যবহার

## 🛠️ প্রয়োজনীয় সফটওয়্যার

### Flutter Development Environment

1. **Flutter SDK** (3.0.0 বা তার পরের ভার্সন)
   ```bash
   # Flutter ডাউনলোড করুন
   git clone https://github.com/flutter/flutter.git -b stable
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

2. **Android Studio** অথবা **VS Code** with Flutter extension

3. **Android SDK** (API level 21 বা তার পরের)
   - Android SDK Build-Tools
   - Android SDK Platform-Tools
   - Android SDK Tools

4. **Java Development Kit (JDK)** 8 বা তার পরের ভার্সন

## 📱 Build Instructions

### 1. প্রজেক্ট সেটআপ

```bash
# প্রজেক্ট ডিরেক্টরিতে যান
cd multispace_cloner

# Dependencies ইনস্টল করুন
flutter pub get

# Flutter doctor চালান সব কিছু ঠিক আছে কিনা দেখতে
flutter doctor
```

### 2. Android Configuration

**android/app/build.gradle** ফাইলে নিশ্চিত করুন:
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### 3. Permissions

অ্যাপটি নিম্নলিখিত permissions ব্যবহার করে:
- `QUERY_ALL_PACKAGES` - সব ইনস্টল করা অ্যাপ দেখার জন্য
- `WRITE_EXTERNAL_STORAGE` - ডেটা সেভ করার জন্য
- `SYSTEM_ALERT_WINDOW` - ওভারলে ফিচারের জন্য

### 4. APK Build করুন

#### Debug APK (টেস্টিং এর জন্য):
```bash
flutter build apk --debug
```

#### Release APK (প্রোডাকশনের জন্য):
```bash
flutter build apk --release
```

#### Split APKs (ছোট সাইজের জন্য):
```bash
flutter build apk --split-per-abi
```

### 5. APK ফাইলের অবস্থান

Build সম্পন্ন হওয়ার পর APK ফাইল পাবেন:
```
build/app/outputs/flutter-apk/
├── app-release.apk          # Release APK
├── app-debug.apk            # Debug APK
├── app-arm64-v8a-release.apk    # ARM64 devices
├── app-armeabi-v7a-release.apk  # ARM32 devices
└── app-x86_64-release.apk       # x86 devices
```

## 🔧 Development Setup

### VS Code এ Development:

1. Flutter extension ইনস্টল করুন
2. প্রজেক্ট ওপেন করুন
3. `Ctrl+Shift+P` চেপে "Flutter: Select Device" সিলেক্ট করুন
4. `F5` চেপে অ্যাপ রান করুন

### Android Studio তে Development:

1. "Open an existing Android Studio project" সিলেক্ট করুন
2. প্রজেক্ট ফোল্ডার সিলেক্ট করুন
3. Device/Emulator সিলেক্ট করুন
4. Run বাটন চাপুন

## 📋 Testing

### Device এ টেস্ট করুন:

1. Android device এ USB Debugging enable করুন
2. Device কম্পিউটারে connect করুন
3. ```bash
   flutter devices  # Device detect হয়েছে কিনা চেক করুন
   flutter run      # অ্যাপ রান করুন
   ```

### Emulator এ টেস্ট করুন:

1. Android Studio থেকে AVD Manager ওপেন করুন
2. Virtual device তৈরি করুন (API 21+)
3. Emulator start করুন
4. `flutter run` কমান্ড চালান

## 🚀 Installation

### APK Install করুন:

1. Android device এ "Unknown Sources" enable করুন
2. APK ফাইল device এ transfer করুন
3. File manager দিয়ে APK ওপেন করুন
4. Install করুন

### Permissions Grant করুন:

প্রথমবার অ্যাপ ওপেন করার সময়:
1. "Query All Packages" permission দিন
2. Storage permission দিন
3. অন্যান্য প্রয়োজনীয় permissions দিন

## 🔍 Troubleshooting

### Common Issues:

1. **"Harmful App" Warning**:
   - Settings > Security > Unknown Sources enable করুন
   - অথবা Settings > Apps > Special Access > Install Unknown Apps

2. **Apps Not Loading**:
   - QUERY_ALL_PACKAGES permission check করুন
   - Android 11+ এ targetSdkVersion 30+ হলে queries section প্রয়োজন

3. **Build Errors**:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk
   ```

4. **Permission Denied**:
   - App Settings এ গিয়ে manually permissions দিন

## 📁 Project Structure

```
multispace_cloner/
├── lib/
│   ├── main.dart                 # Main app entry point
│   ├── models/
│   │   └── app_info.dart        # App data model
│   ├── screens/
│   │   ├── home_screen.dart     # Main screen with + button
│   │   ├── app_list_screen.dart # App selection screen
│   │   └── cloned_apps_screen.dart # Cloned apps display
│   └── services/
│       └── app_service.dart     # App management service
├── android/
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml
│   │   │   └── kotlin/.../MainActivity.kt
│   │   └── build.gradle
│   └── build.gradle
├── assets/
│   └── images/
└── pubspec.yaml
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

যদি কোনো সমস্যা হয় বা সাহায্য প্রয়োজন হয়:

1. GitHub Issues এ report করুন
2. Documentation আবার পড়ুন
3. Flutter community forum এ জিজ্ঞাসা করুন

## 🔮 Future Features

- [ ] App themes customization
- [ ] Backup/Restore cloned apps
- [ ] Batch operations
- [ ] Advanced security features
- [ ] Cloud sync support

---

**Note**: এই অ্যাপটি educational এবং demonstration purposes এর জন্য তৈরি। Real app cloning একটি complex process যার জন্য advanced Android development knowledge প্রয়োজন।
