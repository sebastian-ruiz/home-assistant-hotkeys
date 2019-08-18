# Home Assistant Hotkeys

This is a menu bar application for Mac OS that allows you to toggle on/off lights via Home Assistant. It uses the [Home Assistant Rest API](https://developers.home-assistant.io/docs/en/external_api_rest.html)

## Installation

1. Run:

```
bundle install
pod install
```

2. When running pod install it will ask for a `host` key and a `secret` key.
Set the `host` key to your the URL where your home assistant is running, for example `https://example.com`. Set the `secret` key to your `Long-Lived Access Token` as described in [the Rest API](https://developers.home-assistant.io/docs/en/external_api_rest.html).

3. Open `home-assistant-hotkeys.xcworkspace` and compile.

