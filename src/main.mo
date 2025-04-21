import Principal "mo:base/Principal";
import Time "mo:base/Time";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Text "mo:base/Text";

shared (initMsg) actor class IcIdentityVerifier(admin : Principal) {
  type NanosecondsTimeStamp = Nat;
  let DEFAULT_EXPIRATION_NANOSECONDS : NanosecondsTimeStamp = 5 * 60 * 1_000_000_000;

  type Response = {
    #Ok;
    #Unauthorized;
    #Expired;
    #NotConfirmed;
    #InvalidSession;
  };

  // a Map of session IDs to their expiration time
  let adminAuthRequests = HashMap.HashMap<Text, NanosecondsTimeStamp>(5, Text.equal, Text.hash);

  // a Map of session IDs to their identity confirmation time and user principal
  let userIdentityConfirmations = HashMap.HashMap<Text, (NanosecondsTimeStamp, Principal)>(5, Text.equal, Text.hash);

  // method that admin can call to initiate an auth request for a user
  public shared ({ caller }) func initiateAuth(
    sessionId : Text,
    expirationNanoseconds : ?NanosecondsTimeStamp,
  ) : async (Response) {
    if (caller != admin) {
      return #Unauthorized;
    };

    let actualExpirationNanoseconds : Nat = switch (expirationNanoseconds) {
      case null {
        DEFAULT_EXPIRATION_NANOSECONDS;
      };
      case (?expiration) {
        expiration;
      };
    };

    let now = Time.now();
    let expiration : Nat = Int.abs(now) + actualExpirationNanoseconds;

    adminAuthRequests.put(sessionId, expiration);

    // cleanup if session has already been confirmed
    switch (userIdentityConfirmations.get(sessionId)) {
      case null {};
      case _ {
        userIdentityConfirmations.delete(sessionId);
      };
    };

    return #Ok;
  };

  // method that admin can call to verify a user's identity
  public shared ({ caller }) func verifyIdentity(sessionId : Text) : async (Response, ?Principal) {
    if (caller != admin) {
      return (#Unauthorized, null);
    };

    switch (userIdentityConfirmations.get(sessionId)) {
      case null {
        return (#NotConfirmed, null);
      };
      case (?(_, userPrincipal)) {
        // cleanup user identity confirmation
        userIdentityConfirmations.delete(sessionId);
        return (#Ok, ?userPrincipal);
      };
    };
  };

  // method that user can call to confirm their identity
  public shared ({ caller }) func confirmIdentity(sessionId : Text) : async (Response) {
    if (Principal.isAnonymous(caller)) {
      return #Unauthorized;
    };

    let time = Time.now();

    switch (adminAuthRequests.get(sessionId)) {
      case null {
        return #InvalidSession;
      };
      case (?adminAuthRequest) {
        if (adminAuthRequest < time) {
          return #Expired;
        };

        // cleanup admin auth request
        adminAuthRequests.delete(sessionId);
      };
    };

    userIdentityConfirmations.put(sessionId, (Int.abs(time), caller));

    return #Ok;
  };

  let documentationText = Text.join(
    "\n",
    [
      "IC Identity Verifier Canister",
      "",
      "This canister enables off-chain authentication of ICP principals in hybrid dApps,",
      "especially when wallets do not support message signing or public key retrieval.",
      "",
      "Flow:",
      "1. A user visits your frontend and connects their wallet (e.g., Plug, Internet Identity).",
      "2. The frontend sends a session ID to your off-chain backend.",
      "3. Your server (admin) authorizes this session by calling `initiateAuth` on the canister,",
      "   optionally providing an expiration time (defaults to 5 minutes).",
      "4. The user then calls `confirmIdentity(sessionId)` from the frontend to confirm their identity on-chain.",
      "5. The backend calls `verifyIdentity(sessionId)` to check if the confirmation occurred within the time window.",
      "",
      "This creates a bridge where the canister acts as a trusted identity attestation layer.",
      "Your backend can then issue session tokens (e.g., JWT) based on this verification.",
      "",
      "Security Notes:",
      "- Only the `admin` (your backend) can authorize a session via `initiateAuth`.",
      "- This prevents third-party dApps from abusing your canister as a free verification service.",
      "- You can deploy the canister with your server's principal like this:",
      "",
      "  dfx deploy --argument '(admin \"your-server-principal-id-here\")'",
      "",
      "Available Responses:",
      "- #Ok: Operation succeeded.",
      "- #Unauthorized: Caller is not permitted to perform the action.",
      "- #Expired: The confirmation window has elapsed.",
      "- #NotConfirmed: The user has not yet confirmed their identity.",
      "- #InvalidSession: The provided session ID is invalid or not found.",
    ].vals(),
  );

  // method that returns the documentation for the service
  public query func documentation() : async Text {
    return documentationText;
  };
};
