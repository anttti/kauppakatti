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

const getMyLists = async uid => {
  try {
    const querySnapshot = await db
      .collection("shoppinglists")
      .where("owners", "array-contains", uid)
      .get();
    return querySnapshot.docs.map(list => {
      return {
        ...list.data(),
        id: list.id
      };
    });
  } catch (error) {
    console.error("Error reading fetching my lists:", error);
    return [];
  }
};

const getListItems = async listId => {
  try {
    const querySnapshot = await db
      .collection(`shoppinglists/${listId}/items`)
      .get();
    return querySnapshot.docs.map(item => {
      return {
        ...item.data(),
        id: item.id
      };
    });
  } catch (error) {
    console.error("Error reading shopping list items:", error);
    return [];
  }
};

const start = async uid => {
  let snapshotUnsubscribe;

  const updateItems = querySnapshot => {
    const items = querySnapshot.docs.map(item => {
      return {
        ...item.data(),
        id: item.id
      };
    });
    elm.ports.itemsUpdated.send(items);
  };

  const lists = await getMyLists(uid);

  const currentlySelectedListId = lists[0].id;
  const currentListItems = await getListItems(currentlySelectedListId);

  const initialModel = {
    items: currentListItems,
    newItemName: "",
    lists,
    currentlySelectedListId: lists[0].id,
    newListName: ""
  };

  console.log("initial model", initialModel);
  const elm = Elm.Main.init({
    node: document.getElementById("root"),
    flags: initialModel
  });

  snapshotUnsubscribe = db
    .collection(`shoppinglists/${currentlySelectedListId}/items`)
    .onSnapshot(updateItems);

  elm.ports.updateDataStore.subscribe(data => {
    if (!isValidPayload(data)) {
      return;
    }
    console.log("action:", data);

    switch (data.action) {
      case "new-list":
        db.collection("shoppinglists").add({
          name: data.name,
          owners: [uid]
        });
        break;

      case "change-list":
        getListItems(data.listId).then(items => {
          elm.ports.itemsUpdated.send(items);
        });
        // Set up a snapshot listener & remove the old one
        if (snapshotUnsubscribe) {
          snapshotUnsubscribe();
        }
        snapshotUnsubscribe = db
          .collection(`shoppinglists/${data.listId}/items`)
          .onSnapshot(updateItems);
        break;

      case "create":
        db.collection(`shoppinglists/${data.listId}/items`).add({
          name: data.name,
          isDone: false
        });
        break;

      case "update":
        db.collection(`shoppinglists/${data.listId}/items`)
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

  snapshotUnsubscribe = db
    .collection(`shoppinglists`)
    .where("owners", "array-contains", uid)
    .onSnapshot(querySnapshot => {
      console.log("Liists updated");
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
