import "./main.css";
import { Elm } from "./Main.elm";

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

const isValidPayload = payload => {
  if (payload.action === undefined) {
    return false;
  }
  return true;
};

const start = () => {
  db.collection("shoppinglist")
    .get()
    .then(querySnapshot => {
      const items = querySnapshot.docs.map(item => {
        return {
          ...item.data(),
          id: item.id
        };
      });

      const initialModel = {
        items,
        newItemName: ""
      };
      console.log("initial items", items);

      const app = Elm.Main.init({
        node: document.getElementById("root"),
        flags: initialModel
      });

      app.ports.outputValue.subscribe(data => {
        if (!isValidPayload(data)) {
          return;
        }
        console.log("action:", data);
        switch (data.action) {
          case "create":
            db.collection("shoppinglist").add({
              name: data.name,
              isDone: false
            });
            break;
          case "update":
            db.collection("shoppinglist")
              .doc(data.id)
              .set({
                name: data.name,
                isDone: data.isDone
              });
            break;
          default:
            break;
        }
      });
    });
};

start();
