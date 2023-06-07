## 0.4.0

- **BREAKING**: Remove `lastResource` from `XmppConnection`'s `connect` method. Instead, set the `StreamManagementNegotiator`'s `resource` attribute instead. Since the resource can only really be restored by stream management, this is no issue.
- **BREAKING**: Changed order of parameters of `CryptographicHashManager.hashFromData`
- **BREAKING**: Removed support for XEP-0414, as the (supported) hash computations are already implemented by `CryptographicHashManager.hashFromData`.
- The `DiscoManager` now only handled entity capabilities if a `EntityCapabilityManager` is registered.
- The `EntityCapabilityManager` now verifies and validates its data before caching.
- **BREAKING**: Added the `resumed` parameter to `StreamNegotiationsDoneEvent`. Use this to check if the current stream is new or resumed instead of using the `ConnectionStateChangedEvent`.
- **BREAKING**: Remove `DiscoManager.discoInfoCapHashQuery`.
- **BREAKING**: The entity argument of `DiscoManager.discoInfoQuery` and `DiscoManager.discoItemsQuery` are now `JID` instead of `String`.
- **BREAKING**: `PubSubManager` and `UserAvatarManager` now use `JID` instead of `String`.
- **BREAKING**: `XmppConnection.sendStanza` not only takes a `StanzaDetails` argument.
- Sent stanzas are now kept in a queue until sent.
- **BREAKING**: `MessageManager.sendMessage` does not use `MessageDetails` anymore. Instead, use `TypedMap`.
- `MessageManager` now allows registering callbacks for adding data whenever a message is sent.
- **BREAKING**: `MessageEvent` now makes use of `TypedMap`.
- **BREAKING**: Removed `PresenceReceivedEvent`. Use a manager registering handlers with priority greater than `[PresenceManager.presenceHandlerPriority]` instead.

## 0.3.1

- Fix some issues with running moxxmpp as a component

## 0.3.0

- **BREAKING**: Removed `connectAwaitable` and merged it with `connect`.
- **BREAKING**: Removed `allowPlainAuth` from `ConnectionSettings`. If you don't want to use SASL PLAIN, don't register the negotiator. If you want to only conditionally use SASL PLAIN, extend the `SaslPlainNegotiator` and override its `matchesFeature` method to only call the super method when SASL PLAIN should be used.
- **BREAKING**: The user avatar's `subscribe` and `unsubscribe` no longer subscribe to the `:data` PubSub nodes
- Renamed `ResourceBindingSuccessEvent` to `ResourceBoundEvent`
- **BREAKING**: Removed `isFeatureSupported` from the manager attributes. The managers now all have a method `isFeatureSupported` that works the same
- The `PresenceManager` is now optional
- **BREAKING**: Removed `setConnectionSettings` and `getConnectionSettings`. Just directly acces the `connectionSettings` field.
- Implement XEP-0114 for implementing components
- **BREAKING**: Remove `useDirectTLS` from `ConnectionSettings`

## 0.1.6+1

 - **FIX**: Fix LMC not working.

## 0.1.6

 - **FEAT**: Implement XEP-0308.

## 0.1.5

 - **FEAT**: Message events now contain the stanza error, if available.

## 0.1.4

 - **FIX**: Only stanza-id required 'sid:0' support.
 - **FEAT**: Implement parsing and sending of retractions.

## 0.1.3+1

 - **FIX**: Expose the error classes.

## 0.1.3

 - **REFACTOR**: Replace MayFail by Result.
 - **FIX**: Remove the old Results API.
 - **FEAT**: Rework how the negotiator system works.

## 0.1.2+3

 - **FIX**: SASL SCRAM-SHA-{256,512} should now work.

## 0.1.2+2

 - **FIX**: Fix reconnections when the connection is awaited.

## 0.1.2+1

 - **FIX**: A certificate rejection does not crash the connection.

## 0.1.2

 - **FEAT**: Remove Moxxy specific strings.

## 0.1.1

 - **REFACTOR**: Move packages into packages/.
 - **FEAT**: Fix moxxmpp_socket_tcp's pubspec.

## 0.1.0

- Initial version copied over from Moxxyv2
