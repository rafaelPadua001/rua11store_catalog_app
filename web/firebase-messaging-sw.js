importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

firebase.initializeApp({
    apiKey: "AIzaSyCeXmQoeC_3VMCsY90hAEDh7_STO1dpCW4",
    authDomain: "rua11store-notifications-24f29.firebaseapp.com",
    projectId: "rua11store-notifications-24f29",
    storageBucket: "rua11store-notifications-24f29.firebasestorage.app",
    messagingSenderId: "358519725314",
    appId: "1:358519725314:web:e5675404647642936ef61bD",
    measurementId: "G-TQCM38XQCF"
});

const messaging = firebase.messaging();
