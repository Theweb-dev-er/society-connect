// Import the Firebase scripts (compat mode is required for service workers)
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

// Initialize Firebase app in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyBQmwUNts7Jhv-pZ31PTp0v2JMuWPtDtjw",
  authDomain: "societyconnect-171d7.firebaseapp.com",
  projectId: "societyconnect-171d7",
  storageBucket: "societyconnect-171d7.firebasestorage.app",
  messagingSenderId: "373614264581",
  appId: "1:373614264581:web:c19ad0998a1f41aec7776c"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message received: ', payload);

  const notificationTitle = payload.notification.title || "Society Connect";
  const notificationOptions = {
    body: payload.notification.body || "",
    icon: '/favicon.png'
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
