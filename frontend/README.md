# Society Connect 🏢

A comprehensive Society Management Application built with Flutter, Riverpod, and GoRouter. 
This application provides dedicated interfaces for Residents, Secretaries/Admins, and Security Guards to streamline apartment living, gate operations, and financial management.

## 🚀 Tech Stack
* **Framework:** Flutter
* **State Management:** Riverpod
* **Routing:** GoRouter
* **UI Structure:** Responsive Design (Mobile-first, constrained on Web/Desktop)

---

## 🛠️ Getting Started & Run Procedure

Follow these instructions to get the project up and running on your local machine.

### 1. Prerequisites
Ensure you have the following installed:
* [Flutter SDK](https://docs.flutter.dev/get-started/install)
* [Dart SDK](https://dart.dev/get-dart)
* Android Studio / VS Code (with Flutter extensions)

### 2. Clean and Install Dependencies
Whenever you clone the repository or pull major updates, it is best practice to clean the old build files and fetch the latest packages:

```bash
# Clean existing build files
flutter clean

# Fetch all dependencies
flutter pub get
```

### 3. Running the App

**For Web (Chrome):**
Recommended for quick UI testing and debugging:
```bash
flutter run -d chrome
```

**For Android Emulator / Physical Device:**
Ensure your emulator is running or device is connected, then:
```bash
flutter run
```

### 4. Running Code Analysis & Fixes
To ensure your code meets standard formatting and there are no hidden errors:
```bash
# Check for linting issues
flutter analyze

# Automatically fix simple formatting issues
dart fix --apply
```

---

## 📱 Features

* **Resident Dashboard:** View maintenance bills, raise complaints, and pre-approve expected visitors with auto-generated QR Passes.
* **Security Dashboard:** Digital visitor logging, QR code scanning, and inside-premises tracking.
* **Secretary Dashboard:** Generate maintenance bills, broadcast notices, and view society directory.
