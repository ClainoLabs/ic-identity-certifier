import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface IcIdentityVerifier {
  'confirmIdentity' : ActorMethod<[], Response>,
  'documentation' : ActorMethod<[], string>,
  'initiateAuth' : ActorMethod<
    [Principal, [] | [NanosecondsTimeStamp]],
    Response
  >,
  'verifyIdentity' : ActorMethod<[Principal], Response>,
}
export type NanosecondsTimeStamp = bigint;
export type Response = { 'Ok' : null } |
  { 'NotConfirmed' : null } |
  { 'Unauthorized' : null } |
  { 'Expired' : null };
export interface _SERVICE extends IcIdentityVerifier {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
