## 0.3.0

- **BREAKING**: Removed `connectAwaitable` and merged it with `connect`.
- **BREAKING**: Removed `allowPlainAuth` from `ConnectionSettings`. If you don't want to use SASL PLAIN, don't register the negotiator. If you want to only conditionally use SASL PLAIN, extend the `SaslPlainNegotiator` and override its `matchesFeature` method to only call the super method when SASL PLAIN should be used.
- **BREAKING**: The user avatar's `subscribe` and `unsubscribe` no longer subscribe to the `:data` PubSub nodes
- Renamed `ResourceBindingSuccessEvent` to `ResourceBoundEvent`
- **BREAKING**: Removed `isFeatureSupported` from the manager attributes. The managers now all have a method `isFeatureSupported` that works the same
- The `PresenceManager` is now optional

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
