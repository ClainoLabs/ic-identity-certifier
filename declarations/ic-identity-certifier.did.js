export const idlFactory = ({ IDL }) => {
  const Response = IDL.Variant({
    'Ok' : IDL.Null,
    'NotConfirmed' : IDL.Null,
    'Unauthorized' : IDL.Null,
    'Expired' : IDL.Null,
  });
  const NanosecondsTimeStamp = IDL.Nat;
  const IcIdentityVerifier = IDL.Service({
    'confirmIdentity' : IDL.Func([], [Response], []),
    'documentation' : IDL.Func([], [IDL.Text], ['query']),
    'initiateAuth' : IDL.Func(
        [IDL.Principal, IDL.Opt(NanosecondsTimeStamp)],
        [Response],
        [],
      ),
    'verifyIdentity' : IDL.Func([IDL.Principal], [Response], []),
  });
  return IcIdentityVerifier;
};
export const init = ({ IDL }) => { return [IDL.Principal]; };
