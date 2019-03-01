import { Elm } from "./Main.elm";
var firebase = require("firebase/app");
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
  flags: { config: config }
});

const dataForElm = function(data) {
  switch (data.msg) {
    case "OnAuthStateChanged":
      app.ports.dataForElm.send(data);
      break;
    case "GoToUrl":
      app.ports.dataForElm.send(data);
      break;
    default:
      console.error("Bad message for elm", data.msg);
      break;
  }
};

app.ports.dataForJs.subscribe(data => {
  switch (data.msg) {
    case "DeleteUser":
      deleteUser(data.payload);
      break;
    case "ExecJsonp":
      execJsonp(data.payload);
      break;
    case "SignOut":
      signOut();
      break;
    case "LogError":
      console.error("LogError", data.payload);
      break;
    default:
      console.error("Bad message for JS", data.msg);
      break;
  }
});

firebase.auth().onAuthStateChanged(user => {
  dataForElm({ msg: "OnAuthStateChanged", payload: user });
});

const deleteUser = function(uid) {
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
};

const loadUrl = function(url) {
  const base = window.location.origin;
  let url_;
  if (url === undefined) {
    url_ = base;
  } else {
    url_ = base + url;
  }
  dataForElm({ msg: "GoToUrl", payload: url_ });
};

const signOut = function() {
  firebase.auth().signOut();
};

// Attach the JSONP callback function to the window.
// For some reason it isn't called unless it's attached.
window.signIn = function(data) {
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

const execJsonp = function(url) {
  // Execute the URL by creating the script DOM element
  var script = document.createElement("script");
  script.type = "text/javascript";
  script.async = true;
  script.src = url;

  // Insert the element, which executes the script
  document.head.appendChild(script);

  // Remove the temp element from the DOM, to avoid DOM bloat
  // You should be able to do this right away, without affecting JSONP execution
  script.parentNode.removeChild(script);
};
