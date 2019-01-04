import "./main.css";
import { Elm } from "./Main.elm";
import registerServiceWorker from "./registerServiceWorker";

import firebase from "firebase/app";
require("firebase/firestore");

firebase.initializeApp({
  apiKey: "AIzaSyCQ2JG0br6V-IuKFGsZ04L3433cBgSh4sc",
  authDomain: "kauppakatti.firebaseapp.com",
  databaseURL: "https://kauppakatti.firebaseio.com",
  projectId: "kauppakatti",
  storageBucket: "kauppakatti.appspot.com",
  messagingSenderId: "414167894818"
});

const db = firebase.firestore();

db.settings({
  timestampsInSnapshots: true
});

const start = () => {
  db.collection("shoppinglist")
    .get()
    .then(querySnapshot => {
      const items = [];
      querySnapshot.forEach(item => {
        items.push(item.data());
      });

      const initialModel = {
        items,
        newItemName: ""
      };
      const app = Elm.Main.init({
        node: document.getElementById("root"),
        flags: initialModel
      });
      app.ports.outputValue.subscribe(data => {
        console.log("got from elm:", data);
      });
    });
};

start();
