# CupLink for iOS

Requires an Apple Developer account for the App Groups and Network Extension entitlements.

You will need to provision an app group and update bundle IDs throughout the Xcode project as appropriate.

To build, install Go 1.21 or later, and then install `gomobile`:

```
go get golang.org/x/mobile/cmd/gomobile
gomobile init
```

Download the `Mesh.xcframework` from the RiV-chain artifacts:

```
# Download from GitHub Maven repo
curl -L -o Mesh.xcframework.zip https://github.com/RiV-chain/artifact/raw/main/org/rivchain/v6space/0.4.7.24/v6space-0.4.7.24.zip
unzip Mesh.xcframework.zip
```

Then copy `Mesh.xcframework` into the top-level folder of this repository and then build using Xcode.
