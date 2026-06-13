importScripts(
  "https://www.gstatic.com/firebasejs/11.0.0/firebase-app-compat.js",
  "https://www.gstatic.com/firebasejs/11.0.0/firebase-messaging-compat.js"
);

// Populated at build time by Dockerfile.web via envsubst.
// For local dev, replace these with your Firebase project values.
const firebaseConfig = {
  apiKey: "${FIREBASE_WEB_API_KEY}",
  authDomain: "${FIREBASE_WEB_AUTH_DOMAIN}",
  projectId: "${FIREBASE_WEB_PROJECT_ID}",
  storageBucket: "${FIREBASE_WEB_STORAGE_BUCKET}",
  messagingSenderId: "${FIREBASE_WEB_MESSAGING_SENDER_ID}",
  appId: "${FIREBASE_WEB_APP_ID}",
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

messaging.onBackgroundMessage((message) => {
  const notification = message.notification;
  if (!notification) return;

  return self.registration.showNotification(notification.title, {
    body: notification.body,
    icon: "/icons/Icon-192.png",
  });
});
