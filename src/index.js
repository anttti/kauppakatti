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

  // Get "my" lists
  db.collection("shoppinglists")
    .where("owners", "array-contains", uid)
    .get()
    .then(querySnapshot => {
      const lists = querySnapshot.docs.map(list => {
        console.log("list:", list.data());
        return {
          ...list.data(),
          id: list.id
        };
      });
      debugger;
      lists[0].get("items").then(
        querySnapshot => {
          console.log("got items");
          const items = querySnapshot.docs.map(item => {
            console.log("item", item.data());
          });
        },
        error => {
          console.log("errpr", error);
        }
      );

      // console.log("fetching", `shoppinglists/${lists[0].id}/items`);
      // db.collection(`shoppinglists/${lists[0].id}/items`)
      //   .get()
      //   .then(
      //     querySnapshot => {
      //       console.log("got items");
      //       const items = querySnapshot.docs.map(item => {
      //         console.log("item", item.data());
      //       });
      //     },
      //     error => {
      //       console.log(
      //         "error fetching",
      //         `shoppinglists/${lists[0].id}/items:`,
      //         error
      //       );
      //     }
      // );

      return;

      const initialModel = {
        items,
        newItemName: "",
        lists,
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
              owners: [uid]
            };
            console.log("creating new list:", newList);
            db.collection("shoppinglists").add(newList);
            break;
          case "create":
            // db.collection(itemsCollection).add({
            //   name: data.name,
            //   isDone: false
            // });
            break;
          case "update":
            // db.collection(itemsCollection)
            //   .doc(data.id)
            //   .set({
            //     name: data.name,
            //     isDone: data.isDone
            //   });
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

  // db.collection(itemsCollection).onSnapshot(querySnapshot => {
  //   const items = querySnapshot.docs.map(item => {
  //     return {
  //       ...item.data(),
  //       id: item.id
  //     };
  //   });
  //   elm.ports.itemsUpdated.send(items);
  // });
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
