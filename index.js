import { NativeModules, NativeEventEmitter } from 'react-native';

const eventEmitter = new NativeEventEmitter(NativeModules.BluedotPointSDK)

const authenticate = (projectId, authorizationLevel, onSucessCallback, onFailCallback) => {
    NativeModules.BluedotPointSDK.authenticate(projectId, authorizationLevel, onSucessCallback, onFailCallback)
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

const on = (eventName, callback) => {
    eventEmitter.addListener(eventName, callback)
}

const unsubscribe = (eventName, callback) => {
    eventEmitter.removeListener(eventName, callback)
}

const startTempoTracking = (destinationId, callback) => {
    NativeModules.BluedotPointSDK.startTempoTracking(destinationId, callback)
}

const stopTempoTracking = () => {
    NativeModules.BluedotPointSDK.stopTempoTracking()
}

const getInstallRef = () => {
    return NativeModules.BluedotPointSDK.getInstallRef()
}

const isBlueDotPointServiceRunning = () => {
    return NativeModules.BluedotPointSDK.isBlueDotPointServiceRunning()
}

const BluedotPointSDK = { 
    authenticate, 
    logOut, 
    on, 
    unsubscribe, 
    setForegroundNotification, 
    setCustomEventMetaData,
    setNotificationIdResourceId,
    startTempoTracking,
    stopTempoTracking,
    getInstallRef,
    isBlueDotPointServiceRunning
}

export default BluedotPointSDK