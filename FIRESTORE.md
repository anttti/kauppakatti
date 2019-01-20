# Data model in Firestore

```
/shoppinglists/{shoppinglistId}

{
  title: "Ruokakauppa",
  roles: {
    "user_1_firestore_auth_id": "owner",
    "user_2_firestore_auth_id": "owner"
  }
}

/shoppinglists/{shoppinglistId}/items/{itemId}

{
  name: "Maito",
  isDone: false
}
```

## Security rules in Firestore

```
service cloud.firestore {
  match /databases/{database}/documents {
    match /shoppinglists/{shoppinglistId} {
      function isSignedIn() {
        return request.auth != null;
      }

      function getRole(res) {
        // Read from the "roles" map in the resource (res).
        return res.data.roles[request.auth.uid];
      }

      function isOneOfRoles(res, array) {
        // Determine if the user is one of an array of roles
        return isSignedIn() && (getRole(res) in array);
      }

      function isValidNewStory() {
        // Valid if shoppinglist does not exist and the new shoppinglist has the correct owner.
        return resource == null
          && request.resource.data.roles[request.auth.uid] == 'owner';
      }

      // Owners can read, write, and delete shoppinglists
      allow write: if isValidNewStory() || isOneOfRoles(resource, ['owner']);
    }
  }
}
```
