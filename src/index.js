import { Elm } from "./Main.elm";
const firebase = require("firebase/app");
require("firebase/auth");

const config = {
  apiKey: process.env.ELM_APP_FIREBASE_API_KEY,
  authDomain: process.env.ELM_APP_FIREBASE_AUTH_DOMAIN,
  databaseURL: process.env.ELM_APP_FIREBASE_DATABASE_URL,
  projectId: process.env.ELM_APP_FIREBASE_PROJECT_ID,
  storageBucket: process.env.ELM_APP_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.ELM_APP_FIREBASE_MESSAGING_SENDER_ID
};
firebase.initializeApp(config);

const app = Elm.Main.init({
  node: document.getElementById("root"),
  flags: config
});

function dataForElm(data) {
  switch (data.msg) {
    case "OnAuthStateChanged":
      app.ports.dataForElm.send(data);
      break;
    case "UrlReceived":
      app.ports.dataForElm.send(data);
      break;
    default:
      console.error("Bad message for elm", data.msg);
      break;
  }
}

// app.ports.dataForFirebase.subscribe(data => {
//   switch (data.msg) {
//     case "LogError":
//       console.error("LogError", data.payload);
//       break;
//     case "DeleteUser":
//       deleteUser(data.payload);
//       break;
//     case "GetToken":
//       getToken(data.payload);
//       break;
//     case "SignOut":
//       signOut();
//       break;
//     default:
//       console.error("Bad message for JS", data.msg);
//       break;
//   }
// });

function deleteUser(/*uid*/) {
  firebase
    .auth()
    .currentUser.delete()
    .then(() => console.log("Account deleted"))
    .catch(error => {
      if (error.code === "auth/requires-recent-login") {
        /* Change this to an on-screen error */
        window.alert(
          "You need to have recently signed-in to delete your account. Please sign-in and try again."
        );
        firebase.auth().signOut();
      }
    });
}

function execJsonp(url, callbackFunction) {
  const callbackName = url.match(/callback=([^&]+)/)[1];

  // Assign the callback to the window so it can execute
  window[callbackName] = function(data) {
    callbackFunction(data);

    // Delete the assignment after execution
    delete window[callbackName];
  };

  // Execute the URL by creating the script DOM element
  const script = document.createElement("script");
  script.type = "text/javascript";
  script.async = true;
  script.src = url;

  // Insert the element, which executes the script
  document.head.appendChild(script);

  // Remove the temp element from the DOM, to avoid DOM bloat
  script.parentNode.removeChild(script);
}

function getToken(url) {
  const callback = function(data) {
    if (data.token) {
      firebase
        .auth()
        .signInWithCustomToken(data.token)
        .then(() => loadUrl())
        .catch();
    } else {
      console.error(data);
    }
  };
  execJsonp(url, callback);
}

function loadUrl(url) {
  const base = window.location.origin;
  let url_;
  if (url === undefined) {
    url_ = base;
  } else {
    url_ = base + url;
  }
  dataForElm({ msg: "UrlReceived", payload: url_ });
}

function signOut() {
  firebase.auth().signOut();
}

firebase.auth().onAuthStateChanged(user => {
  dataForElm({ msg: "OnAuthStateChanged", payload: user });
});
