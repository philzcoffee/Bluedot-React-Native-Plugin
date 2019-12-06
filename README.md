# bluedot-react-native

## Getting started

`$ npm install bluedot-react-native --save`

### Mostly automatic installation

`$ react-native link bluedot-react-native`

### For iOS
1. Install Pods

```
$ cd ios
$ pod install
```

2. Setup your .plist file as laid out on this [documentation page](https://docs.bluedot.io/ios-sdk/ios-integrating-the-sdk/).

### For Android
1) Include Jitpack in your Maven dependencies in `build.gradle`

```
allprojects {
    repositories {
        ...

         // ADD IT HERE
        maven { 
            url "https://jitpack.io" 
        }
    }
}
```

2) Make sure Jetify is available in your development environment

`$ npx jetify`

## Usage
```javascript
import BluedotPointSdk from 'bluedot-react-native';

componentDidMount = async () => {
    // Before starting the Bluedot Point SDK ask for Location Permissions
    
    // ...

    const channelId = 'Bluedot React Native'
    const channelName = 'Bluedot React Native'
    const title = 'Bluedot Foreground Service'
    const content = "This app is running a foreground service using location services"

    // Foreground Service for Android to improve trigger rate - iOS will ignore this.
    BluedotPointSdk.setForegroundNotification(channelId, channelName, title, content, true)

    // If you would like to add custom event meta data
    BluedotPointSdk.setCustomEventMetaData({ userId: 'user_id_goes_here' })

    // Start Bluedot SDK
    BluedotPointSdk.authenticate('your_application_api_key', '<Always|WhileInUse>', () => console.log("On success"), () => console.log("On fail"))

    BluedotPointSdk.on('zoneInfoUpdate', (event) => {
      // ...
    })

    BluedotPointSdk.on('checkedIntoFence', (event) => {
      // ...
    })

    BluedotPointSdk.on('checkedOutFromFence', (event) => {
      // ...
    })

    BluedotPointSdk.on('checkedIntoBeacon', (event) => {
      // ...
    })

    BluedotPointSdk.on('checkedOutFromBeacon', (event) => {
      // ...
    })

    BluedotPointSdk.on('startRequiringUserInterventionForBluetooth', (event) => {
      // ...
    })

    BluedotPointSdk.on('stopRequiringUserInterventionForBluetooth', (event) => {
      // ...
    })

    BluedotPointSdk.on('startRequiringUserInterventionForLocationServices', (event) => {
      // ...
    })

    BluedotPointSdk.on('stopRequiringUserInterventionForLocationServices', (event) => {
      // ...
    })
  }

```

## Events
#### zoneInfoUpdate
```javascript
{
    "zoneInfos": [
        {
            "ID": "zone-UUID-here",
            "name": "Your zone name here"
        }
        //...
    ]
}
```

#### checkedIntoFence
```javascript
{
    "zoneInfo": {
        "ID": "zone-UUID-here",
        "name": "Your zone name here"
    },
    "fenceInfo": {
        "ID": "fence-UUID-here",
        "name": "Your fence name here"
    },
    "locationInfo": {
        "unixDate": "Timestamp of triggering location update",
        "latitude": "Latitude of triggering location update",
        "longitude": "Longitude of triggering location update",
        "bearing": "Bearing of triggering location update (if available)",
        "speed": "speed of triggering location update (if available)",
    },
    "customData": {
        "custom-field-name": "Custom zone data field value"
    },
    "willCheckout": false // True if the zone has checkout enabled.
}
```

#### checkedOutFromFence
```javascript
{
    "zoneInfo": {
        "ID": "zone-UUID-here",
        "name": "Your zone name here"
    },
    "fenceInfo": {
        "ID": "fence-UUID-here",
        "name": "Your fence name here"
    },
    "customData": {
        "custom-field-name": "Custom zone data field value"
    },
    "dwellTime": 5 // Number of minutes the device dwelled in the zone
}
```

#### checkedIntoBeacon
```javascript
{
    "zoneInfo": {
        "ID": "zone-UUID-here",
        "name": "Your zone name here"
    },
    "beaconInfo": {
        "ID": "zone-UUID-here",
        "name": "Your zone name here",
        "macAddress": "AA:BB:CC:DD:EE:FF", // Mac address here
        "proximityUuid": "beacon-UUID-here",
        "major": 1, // As set on backend
        "minor": 2, // As set on backend
        "latitude": "Latitude of beacon",
        "longitude": "Longitude of beacon",
    },
    "locationInfo": {
        "unixDate": "Timestamp of triggering location update",
        "latitude": "Latitude of triggering location update",
        "longitude": "Longitude of triggering location update",
        "bearing": "Bearing of triggering location update (if available)",
        "speed": "speed of triggering location update (if available)",
    },
    "customData": {
        "custom-field-name": "Custom zone data field value"
    },
    "willCheckout": false // True if the zone has checkout enabled.
}
```
#### checkedOutFromBeacon
```javascript
{
    "zoneInfo": {
        "ID": "zone-UUID-here",
        "name": "Your zone name here"
    },
    "beaconInfo": {
        "ID": "zone-UUID-here",
        "name": "Your zone name here",
        "macAddress": "AA:BB:CC:DD:EE:FF", // Mac address here
        "proximityUuid": "beacon-UUID-here",
        "major": 1, // As set on backend
        "minor": 2, // As set on backend
        "latitude": "Latitude of beacon",
        "longitude": "Longitude of beacon",
    },
    "locationInfo": {
        "unixDate": "Timestamp of triggering location update",
        "latitude": "Latitude of triggering location update",
        "longitude": "Longitude of triggering location update",
        "bearing": "Bearing of triggering location update (if available)",
        "speed": "speed of triggering location update (if available)",
    },
    "customData": {
        "custom-field-name": "Custom zone data field value"
    },
    "dwellTime": 5 // Number of minutes the device dwelled in the zone
}
```

#### startRequiringUserInterventionForBluetooth
```javascript
{}
```
#### stopRequiringUserInterventionForBluetooth
```javascript
{}
```
#### startRequiringUserInterventionForLocationServices
```javascript
{
    "authorizationStatus": "denied" // Or: restricted, notDetermined, always, whenInUse, unknown
}
```
#### stopRequiringUserInterventionForLocationServices
```javascript
{
    "authorizationStatus": "denied" // Or: restricted, notDetermined, always, whenInUse, unknown
}
```