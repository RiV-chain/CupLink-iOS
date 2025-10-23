# CupLink for iOS

Requires an Apple Developer account for the App Groups and Network Extension entitlements.

You will need to provision an app group and update bundle IDs throughout the Xcode project as appropriate.

To build, install Go 1.13 or later, and then install `gomobile`:

```
go get golang.org/x/mobile/cmd/gomobile
gomobile init
```

Clone the main CupLink repository and build the `CupLink.framework`:

```
git clone https://github.com/cuplink-network/cuplink-go
cd cuplink-go
./build -i
```

Then copy `CupLink.framework` into the top-level folder of this repository and then build using Xcode.
