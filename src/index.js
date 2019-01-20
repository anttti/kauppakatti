import "./main.css";
import { Elm } from "./Main.elm";

import firebase from "firebase/app";
require("firebase/auth");
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

const start = uid => {
  let elm;

  db.collection("shoppinglists")
    .get()
    .then(
      querySnapshot => {
        const items = querySnapshot.docs.map(item => {
          console.log("item", item);
        });
      },
      error => {
        console.log("1 error:", error);
      }
    );
  return;

  const itemsCollection = `shoppinglist/${uid}/items`;
  console.log("accessing", itemsCollection);
  db.collection(itemsCollection)
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
        newItemName: "",
        lists: [
          { name: "Ruokakauppa", id: "12345" },
          { name: "Rautakauppa", id: "23456" }
        ],
        currentlySelectedListId: "12345",
        newListName: ""
      };
      console.log("initial items", items);

      elm = Elm.Main.init({
        node: document.getElementById("root"),
        flags: initialModel
      });

      elm.ports.updateDataStore.subscribe(data => {
        if (!isValidPayload(data)) {
          return;
        }
        console.log("action:", data);
        switch (data.action) {
          case "new-list":
            const newList = {
              name: data.name,
              roles: {
                [uid]: "owner"
              }
            };
            console.log("creating new list:", newList);
            db.collection("shoppinglists").add(newList);
            break;
          case "create":
            db.collection(itemsCollection).add({
              name: data.name,
              isDone: false
            });
            break;
          case "update":
            db.collection(itemsCollection)
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

  // db.collection("shoppinglists").onSnapshot(
  //   querySnapshot => {
  //     console.log("updated:");
  //     const items = querySnapshot.docs.map(item => {
  //       console.log(item);
  //       // return {
  //       //   ...item.data(),
  //       //   id: item.id
  //       // };
  //     });
  //   },
  //   error => {
  //     console.log("error in onSnapshot:", error);
  //   }
  // );

  db.collection(itemsCollection).onSnapshot(querySnapshot => {
    const items = querySnapshot.docs.map(item => {
      return {
        ...item.data(),
        id: item.id
      };
    });
    elm.ports.itemsUpdated.send(items);
  });
};

const authProvider = new firebase.auth.GoogleAuthProvider();
firebase.auth().onAuthStateChanged(user => {
  if (user) {
    // Logged in
    console.log("logged in with uid", user.uid);
    start(user.uid);
  } else {
    // Logged out
    console.log("logged out");
    firebase.auth().signInWithPopup(authProvider);
  }
});
