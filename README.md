# DeskBoard
An open-source desktop dashboard built for touch-screen Raspberry Pi setups, with HomeAssistant and Spotify integrations.

## Features
- Clock, date, and weather display
- To-do list
- Spotify controller (Requires Spotify Developer API)
    - Playlists
    - Queue
    - Shuffle & Loop
    - Playback controls
    - Media device selector
- Home Assistant controller
    - Scene changer (Requires webhook and automation set-up)
    - Home Assistant Webview (Requires Chromium)
- Brightness changer
- Stand-by mode
- Lyrics display with LRCLIB


## Installation Guide

### Requirements
- Flutter (latest stable)
- Raspberry Pi OS (Desktop version recommended)
- Home Assistant server (running locally or remotely)
- Spotify account + Developer API access
- Internet connection
- Chromium and Onboard



## Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/USERNAME/DeskBoard.git
cd DeskBoard
```

---

### 2. Install Dependencies
```bash
flutter pub get
```

---

### 3. Configure the App
Create these files in the lib folder:
#### config.dart
```dart
// Your city name is used for weather data.
const city = "Malacca";

// Home Assistant URL for home control.
const homeAssistantUrl = "http://192.168.1.129:8123/";
```

#### secrets.dart
```dart
const String clientIdS = "YOUR_CLIENT_ID";
const String clientSecretS = "YOUR_CLIENT_SECRET";
```

- Get these values from your Spotify Developer Dashboard: https://developer.spotify.com/dashboard 
- Create an app, set the Redirect URI to "http://127.0.0.1:8580/callback", and replace the placeholders above.

> [!CAUTION]
> These credentials are used for the Spotify integration. Never upload your secrets.dart anywhere and remember to include it in your .gitignore!

---

### 4. Home Assistant Setup
> [!NOTE]
> If you don't have Home Assistant yet, you can get it here: https://www.home-assistant.io/installation/

Create this automation in your Home Assistant:

```yaml
alias: Scene Webhook Controller
description: DeskBoard Integration
triggers:
  - trigger: webhook
    webhook_id: good_night_webhook
    id: night
    local_only: true
  - trigger: webhook
    webhook_id: casual_lighting_webhook
    id: casual
    local_only: true
  - trigger: webhook
    webhook_id: study_mode_webhook
    id: study
    local_only: true
    allowed_methods:
      - POST
      - PUT
  - trigger: webhook
    webhook_id: all_off_webhook
    id: "off"
    local_only: true
    allowed_methods:
      - POST
      - PUT

actions:
  - choose:
      - conditions:
          - condition: trigger
            id: night
        sequence:
          - action: scene.turn_on
            target:
              entity_id: scene.good_night

      - conditions:
          - condition: trigger
            id: casual
        sequence:
          - action: scene.turn_on
            target:
              entity_id: scene.casual_lighting

      - conditions:
          - condition: trigger
            id: study
        sequence:
          - action: scene.turn_on
            target:
              entity_id: scene.study_mode

      - conditions:
          - condition: trigger
            id:
              - "off"
        sequence:
          - action: light.turn_off
            target:
              area_id: bedroom
            data: {}

mode: single
```
DeskBoard sends requests to:
http://<home_assistant_ip>:8123/api/webhook/<webhook_id>
which triggers the corresponding scene/action

> [!TIP]
> You may edit this automation based on your own scenes, or create them based on these.
> More info here: 
> - Scenes: https://www.home-assistant.io/docs/scene/editor/
> - Automations: https://www.home-assistant.io/docs/automation/editor/
---

### 5. Install Chromium (for Home Assistant WebView) and Onboard (on-screen keyboard)
Install Chromium:
```bash
sudo apt install chromium
```

Install Onboard:
```bash
sudo apt install onboard
```

---

### 6. Build Release
Enable building for Linux projects:
```
flutter config --enable-linux-desktop
```
Build the app:
```bash
flutter build linux
```
Run the app:
```bash
./build/linux/x64/release/bundle/deskboard
```

---

### 7. Auto Start DeskBoard
```bash
nano ~/.config/lxsession/LXDE-pi/autostart
```

Add:
```bash
@/home/$USER/DeskBoard/build/linux/x64/release/bundle/deskboard
```



---

## Notes
- Spotify requires an active playback device
- Weather depends on correct city naming
- Home Assistant scenes must exist
- Designed for touchscreen usage

---

