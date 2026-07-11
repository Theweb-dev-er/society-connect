# Production Deployment Activities Guide - FCM Integration

This document outlines the step-by-step activities required to deploy the Firebase Cloud Messaging (FCM) push notification system to your production environment.

---

## 1. Backend Deployment Activities

### A. Environment Configuration (`.env`)
Ensure the following variables are defined in the production server's `.env` file:
```bash
# Path to the production Firebase Admin private key JSON
FIREBASE_CREDENTIALS_PATH=/etc/secrets/firebase-service-account.json

# Redis connection settings for Celery queue
CELERY_BROKER_URL=redis://your-production-redis-host:6379/1
CELERY_RESULT_BACKEND=redis://your-production-redis-host:6379/2
```

> [!IMPORTANT]
> Ensure `CELERY_TASK_ALWAYS_EAGER` is **not** set to `True` in production. It is disabled by default in `base.py` and `prod.py` to ensure tasks run asynchronously on worker processes.

### B. Secrets Provisioning
* Upload the Firebase Service Account private key JSON securely to your production server (e.g., `/etc/secrets/firebase-service-account.json`).
* Ensure read permissions are restricted only to the system user executing the Django/Gunicorn process (e.g., `chmod 400 /etc/secrets/firebase-service-account.json`).

### C. Database Migrations
* Apply database migrations to create the new `device_tokens` table:
```bash
python manage.py migrate
```

### D. Celery Worker Daemon Setup
* Setup and supervise the Celery worker process on the server using `systemd` or `supervisor`.
* Command to run the worker:
```bash
celery -A config worker --loglevel=info
```
* Example systemd service configuration (`/etc/systemd/system/celery.service`):
```ini
[Unit]
Description=Celery Worker for Society Connect
After=network.target

[Service]
Type=simple
User=django-user
Group=django-group
WorkingDirectory=/home/django/society_app/backend
ExecStart=/home/django/society_app/backend/venv/bin/celery -A config worker --loglevel=info
Restart=always

[Install]
WantedBy=multi-user.target
```

---

## 2. Frontend (Android) Deployment Activities

1. **Google Services Config**: Verify that your production `google-services.json` (downloaded from the production Firebase Project) is located at `frontend/android/app/google-services.json`.
2. **Signing Fingerprints**:
   - Retrieve the SHA-1 and SHA-256 fingerprints of your **production release keystore**.
   - Add these fingerprints to your Android App settings in the **Firebase Console** (this is critical for OTP authentication and push notifications validation).
3. **Build Command**:
   - Build the release App Bundle (AAB) or APK:
     ```bash
     flutter build appbundle --release
     ```

---

## 3. Frontend (iOS) Deployment Activities

1. **Xcode Capabilities**:
   - Open `frontend/ios/Runner.xcworkspace` in Xcode.
   - Go to the **Runner** project settings > **Signing & Capabilities** tab.
   - Click **+ Capability** and add:
     * **Push Notifications**
     * **Background Modes** (check the **Remote notifications** checkbox).
2. **Apple Developer Portal Setup**:
   - Under *Certificates, Identifiers & Profiles > Keys*, create a new **APNs Auth Key** (`.p8` format).
3. **Firebase Console APNs Registration**:
   - Navigate to *Firebase Console > Project Settings > Cloud Messaging > Apple app sharing settings*.
   - Upload the generated `.p8` key, and enter your **Key ID** and **Team ID**.
4. **Provisioning Profile**:
   - Ensure the App Store / Ad-Hoc provisioning profile includes the Push Notification entitlement.
5. **Build Command**:
   - Build the iOS Archive:
     ```bash
     flutter build ipa --release
     ```

---

## 4. Frontend (Web) Deployment Activities

1. **Firebase Config Update**:
   - Edit the production configuration in `frontend/web/firebase-messaging-sw.js` and `frontend/web/index.html`.
   - Update the configuration block with your production Firebase keys:
     ```javascript
     const firebaseConfig = {
       apiKey: "YOUR_PROD_API_KEY",
       authDomain: "YOUR_PROD_AUTH_DOMAIN",
       projectId: "YOUR_PROD_PROJECT_ID",
       storageBucket: "YOUR_PROD_STORAGE_BUCKET",
       messagingSenderId: "YOUR_PROD_MESSAGING_SENDER_ID",
       appId: "YOUR_PROD_APP_ID",
       measurementId: "YOUR_PROD_MEASUREMENT_ID"
     };
     ```
2. **VAPID Key Generation**:
   - In the **Firebase Console**, go to *Project Settings > Cloud Messaging*.
   - Under *Web configuration*, click **Generate key pair** in the *Web Push certificates* section. This is your public VAPID key.
3. **Build Command with VAPID Key**:
   - Run the production build command, passing the VAPID key using `--dart-define`:
     ```bash
     flutter build web --release --dart-define=FCM_VAPID_KEY="YOUR_PUBLIC_VAPID_KEY"
     ```
   - Alternatively, replace `"YOUR_PUBLIC_VAPID_KEY_HERE"` directly inside `frontend/lib/services/notification_service.dart`.

