
# react-native-point-sdk

## Getting started

`$ npm install react-native-point-sdk --save`

### Mostly automatic installation

`$ react-native link react-native-point-sdk`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-point-sdk` and add `RNPointSdk.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNPointSdk.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import au.com.bluedot.RNPointSdkPackage;` to the imports at the top of the file
  - Add `new RNPointSdkPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-point-sdk'
  	project(':react-native-point-sdk').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-point-sdk/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-point-sdk')
  	```


## Usage
```javascript
import RNPointSdk from 'react-native-point-sdk';

// TODO: What to do with the module?
RNPointSdk;
```
  