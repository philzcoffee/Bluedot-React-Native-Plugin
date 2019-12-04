import { NativeModules, NativeEventEmitter } from 'react-native';

const eventEmitter = new NativeEventEmitter(NativeModules.BluedotPointSDK)

const authenticate = (apiKey, authorizationLevel, onSucessCallback, onFailCallback) => {
    NativeModules.BluedotPointSDK.authenticate(apiKey, authorizationLevel, onSucessCallback, onFailCallback)
}

const logOut = (onSucessCallback, onFailCallback) => {
    NativeModules.BluedotPointSDK.logOut(onSucessCallback, onFailCallback)
}

const setCustomEventMetaData = (eventMetaData) => {
    NativeModules.BluedotPointSDK.setCustomEventMetaData(eventMetaData)
}

const setNotificationIdResourceId = (resourceId) => {
    NativeModules.BluedotPointSDK.setNotificationIDResourceID(resourceId)
}

const setForegroundNotification = (channelId, channelName, title, content, targetAllApis) => {
    NativeModules.BluedotPointSDK.setForegroundNotification(channelId, channelName, title, content, targetAllApis)
}

const notifyPushUpdateWithData = () => {
    NativeModules.BluedotPointSDK.notifyPushUpdateWithData()
}
 
const on = (eventName, callback) => {
    eventEmitter.addListener(eventName, callback)
}

const unsubscribe = (eventName, callback) => {
    eventEmitter.removeListener(eventName, callback)
}

const BluedotPointSDK = { 
    authenticate, 
    logOut, 
    on, 
    unsubscribe, 
    setForegroundNotification, 
    setCustomEventMetaData,
    setNotificationIdResourceId,
    notifyPushUpdateWithData
}

export default BluedotPointSDK