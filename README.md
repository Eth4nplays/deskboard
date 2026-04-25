# DeskBoard
An open-source desktop dashboard built for touch-screen Raspberry Pi setups, with HomeAssistant and Spotify integrations.

<img width="752.5" height="351.5" alt="image" src="https://github.com/user-attachments/assets/5218d654-17a9-4e73-89b1-dfabe0e2531c" />

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
<div align="center" style="display: flex; flex-wrap: wrap; gap: 10px; justify-content: center;">
<img src="https://github.com/user-attachments/assets/8d575843-c0aa-4ff9-ab32-fb58156212fc" width="350"/>
<img src="https://github.com/user-attachments/assets/001a0b10-fcb4-47b8-9245-72d351bc9125" width="350"/>
<img src="https://github.com/user-attachments/assets/b8290b78-fc73-4baa-9d46-11d009e8b805" width="350"/>
<img src="https://github.com/user-attachments/assets/c64b580f-210d-4dfd-9b6b-b04c835aa497" width="350"/>
</div>

## My Set-Up
Links are from Cytron Malaysia:
- Raspberry Pi 4 Model B (8GB RAM) - Sufficient for running DeskBoard and Home Assistant: https://my.cytron.io/p-raspberry-pi-4-model-b-1-gb-and-kits
- SmartiPi Touch 2 for Raspberry Pi Display - Casing for the overall presentation of the device, easy assembly with manuals: https://my.cytron.io/p-raspberry-pi-7in-touch-screen-with-smartipi-case
- Raspberry Pi 7 Inch DSI Touch Screen Display - 7-Inch Touch screen display, recommended display size for app: https://my.cytron.io/p-raspberry-pi-7-inch-touch-screen-display

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
`http://<home_assistant_ip>:8123/api/webhook/<webhook_id>`
which triggers the corresponding scene/action

> [!TIP]
> You may edit this automation based on your own scenes, or create them based on these.
> More info here: 
> - Scenes: https://www.home-assistant.io/docs/scene/editor/
> - Automations: https://www.home-assistant.io/docs/automation/editor/
---

### 5. Install Chromium (for Home Assistant WebView), Onboard (on-screen keyboard), and Fonts-Noto (correct text output)
Install Chromium:
```bash
sudo apt install chromium
```

Install Onboard:
```bash
sudo apt install onboard
```

Install Fonts-Noto:
```bash
sudo apt install fonts-noto-cjk fonts-noto-core fonts-noto-color-emoji
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
