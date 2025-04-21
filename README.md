# `ic-identity-certifier`

This canister enables **off-chain authentication of ICP principals** in hybrid dApps, particularly when using wallets (like Plug or Internet Identity) that do **not support message signing** or public key retrieval.

It serves as a minimal bridge between your Internet Computer frontend and traditional backend infrastructure, allowing your backend to confirm that a user has control over a given `Principal` through a secure session-based authentication flow.

---

## ✨ Use Case

This is ideal for hybrid applications, such as:

- Sports betting exchanges  
- Game backends  
- Analytics dashboards  
- Any ICP dApp using off-chain APIs and requiring secure user identification

---

## 🔐 How It Works

1. **Frontend**: A user visits your app and connects with their wallet.  
2. **Backend**: Your server generates a unique session ID and sends it to the frontend.  
3. **Authorization**: Your backend calls `initiateAuth(sessionId)` on the canister, authorizing this session for a short time (default is 5 minutes).  
4. **User Action**: The frontend tells the user to call `confirmIdentity(sessionId)` from their wallet-connected session.  
5. **Verification**: Your backend calls `verifyIdentity(sessionId)` to check if the user successfully confirmed their identity in time.  
6. **Outcome**: If successful, your backend receives the user's principal and can issue a session (e.g., a JWT) or grant access.

---

## 🔧 Deployment

Make sure to deploy this canister with your server's principal as the **admin**, so only your backend can authorize authentication requests.

```bash
dfx deploy --argument '(admin "your-server-principal-id-here")'
```

This protects your canister from being abused as a free authentication service by other dApps.

---

## 🧪 Interface

### `initiateAuth(sessionId: Text, expirationNanoseconds: ?Nat) : async Response`

Called by the **admin** to authorize a session. The second parameter is optional; if omitted, defaults to 5 minutes.

---

### `confirmIdentity(sessionId: Text) : async Response`

Called by the **user** (from the frontend). Confirms their identity on-chain using the provided session ID.

---

### `verifyIdentity(sessionId: Text) : async (Response, ?Principal)`

Called by the **admin**. Returns whether the user successfully confirmed their identity and their principal if successful.

---

### `documentation() : query Text`

Returns a human-readable explanation of the canister's purpose and usage.

---

## 📦 Response Types

```motoko
type Response = {
  #Ok;            // Success
  #Unauthorized;  // Caller is not allowed to perform this action
  #Expired;       // User failed to confirm identity within time window
  #NotConfirmed;  // User has not confirmed yet
  #InvalidSession; // The provided session ID is invalid or not found
};
```

---

## 🛡️ Security Notes

- Only the `admin` can initiate authentication requests.  
- The canister tracks expiration times to prevent replay attacks.  
- User confirmations are cleared after verification to avoid repeated confirmations.
- Session IDs should be randomly generated and sufficiently long to prevent guessing.
- Each session can only be used once for authentication.

---

## 🧩 Example Flow Diagram

```
Frontend ↔ Backend ↔ IC Canister

[1] User connects wallet  
[2] Backend generates session ID → Frontend  
[3] Backend calls initiateAuth(sessionId)  
[4] User calls confirmIdentity(sessionId) on IC  
[5] Backend calls verifyIdentity(sessionId)  
[6] Backend receives user's principal and issues JWT  
```

---

## 📄 License

MIT – Feel free to use, extend, or contribute improvements.

---

## 🙌 Credits

Built to simplify identity workflows in modern ICP dApps without relying on wallet-specific features.