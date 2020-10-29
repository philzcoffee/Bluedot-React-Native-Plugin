package com.reactlibrary;

import android.Manifest;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.os.Build;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;
import au.com.bluedot.application.model.Proximity;
import au.com.bluedot.point.ApplicationNotificationListener;
import au.com.bluedot.point.BluetoothNotEnabledError;
import au.com.bluedot.point.LocationServiceNotEnabledError;
import au.com.bluedot.point.ServiceStatusListener;
import au.com.bluedot.point.net.engine.BDError;
import au.com.bluedot.point.net.engine.BeaconInfo;
import au.com.bluedot.point.net.engine.FenceInfo;
import au.com.bluedot.point.net.engine.LocationInfo;
import au.com.bluedot.point.net.engine.ServiceManager;
import au.com.bluedot.point.net.engine.TempoStatusListener;
import au.com.bluedot.point.net.engine.ZoneInfo;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static android.app.Notification.PRIORITY_MAX;

public class BluedotPointSdkModule extends ReactContextBaseJavaModule
        implements ServiceStatusListener, ApplicationNotificationListener {

    private final ReactApplicationContext reactContext;
    ServiceManager serviceManager;
    private Callback logOutCallback;

    public BluedotPointSdkModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        serviceManager = ServiceManager.getInstance(reactContext);
    }

    @Override
    public String getName() {
        return "BluedotPointSDK";
    }

    private void sendEvent(ReactContext reactContext,
            String eventName,
            @Nullable WritableMap params) {
        reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
    }

    @ReactMethod
    public void authenticate(String projectId, String permLevel, Callback success, Callback fail){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if(reactContext.checkSelfPermission(
                    Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ) {
                serviceManager.sendAuthenticationRequest(projectId, this);
                success.invoke("Success");
            }
        }
    }

    @ReactMethod
    public void logOut(Callback callback, Callback fail){
        logOutCallback = callback;
        serviceManager.stopPointService();
    }

    @ReactMethod
    public void setForegroundNotification(String channelId, String channelName, String title, String content, boolean targetAllAPis){
        serviceManager.setForegroundServiceNotification(createNotification(channelId,channelName,title,content), targetAllAPis);
    }

    private Notification createNotification(String channelId,String channelName,String title, String content) {

        Intent activityIntent = new Intent(this.getCurrentActivity().getIntent());
        activityIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
        PendingIntent pendingIntent = PendingIntent.getActivity(reactContext, 0,
                activityIntent, PendingIntent.FLAG_UPDATE_CURRENT);

        NotificationManager notificationManager =
                (NotificationManager) reactContext.getSystemService(Context.NOTIFICATION_SERVICE);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (notificationManager.getNotificationChannel(channelId) == null) {
                NotificationChannel notificationChannel =
                        new NotificationChannel(channelId, channelName,
                                NotificationManager.IMPORTANCE_HIGH);
                notificationChannel.enableLights(false);
                notificationChannel.setLightColor(Color.RED);
                notificationChannel.enableVibration(false);
                notificationManager.createNotificationChannel(notificationChannel);
            }
            Notification.Builder notification = new Notification.Builder(reactContext, channelId)
                    .setContentTitle(title)
                    .setContentText(content)
                    .setStyle(new Notification.BigTextStyle().bigText(content))
                    .setOngoing(true)
                    .setCategory(Notification.CATEGORY_SERVICE)
                    .setContentIntent(pendingIntent)
                    .setSmallIcon(R.mipmap.ic_launcher);
            return notification.build();
        } else {
            NotificationCompat.Builder notification = new NotificationCompat.Builder(reactContext)
                    .setContentTitle(title)
                    .setContentText(content)
                    .setStyle(new NotificationCompat.BigTextStyle().bigText(content))
                    .setOngoing(true)
                    .setCategory(Notification.CATEGORY_SERVICE)
                    .setPriority(PRIORITY_MAX)
                    .setContentIntent(pendingIntent)
                    .setSmallIcon(R.mipmap.ic_launcher);
            return notification.build();
        }
    }
    @Override public void onBlueDotPointServiceStartedSuccess() {
        serviceManager.subscribeForApplicationNotification(this);
    }

    @Override public void onBlueDotPointServiceStop() {
        if (logOutCallback != null) {
            logOutCallback.invoke("Success");

            // Reset callbacks.
            // React Native Callbacks can be invoked only once. More info: https://reactnative.dev/docs/native-modules-android.html#callbacks
            logOutCallback = null;
        }
        serviceManager.unsubscribeForApplicationNotification(this);
    }

    @Override public void onBlueDotPointServiceError(BDError bdError) {
        WritableMap error = new WritableNativeMap();
        error.putString("error",bdError.getReason());
        if (bdError instanceof LocationServiceNotEnabledError) {
            sendEvent(reactContext,"startRequiringUserInterventionForLocationServices",error);
            serviceManager.stopPointService();
        } else if (bdError instanceof BluetoothNotEnabledError) {
            sendEvent(reactContext,"startRequiringUserInterventionForBluetooth",error);
            serviceManager.stopPointService();
        }

    }

    @Override public void onRuleUpdate(List<ZoneInfo> list) {
        WritableArray zoneList = new WritableNativeArray();
        if(list != null) {
            for (int i = 0; i < list.size(); i++) {
                WritableMap zone = new WritableNativeMap();
                zone.putString("name",list.get(i).getZoneName());
                zone.putString("ID",list.get(i).getZoneId());
                zoneList.pushMap(zone);
            }
        }
        WritableMap map = new WritableNativeMap();
        map.putArray("zoneInfos",zoneList);
        sendEvent(reactContext, "zoneInfoUpdate",map);
    }

    @Override
    public void onCheckIntoFence(FenceInfo fenceInfo, ZoneInfo zoneInfo, LocationInfo locationInfo,
            Map<String, String> map, boolean isCheckout) {

        WritableMap fenceDetails = new WritableNativeMap();
        fenceDetails.putString("ID",fenceInfo.getId());
        fenceDetails.putString("name",fenceInfo.getName());

        WritableMap zoneDetails = new WritableNativeMap();
        zoneDetails.putString("ID",zoneInfo.getZoneId());
        zoneDetails.putString("name",zoneInfo.getZoneName());

        WritableMap locationDetails = new WritableNativeMap();
        locationDetails.putDouble("unixDate", locationInfo.getTimeStamp());
        locationDetails.putDouble("latitude", locationInfo.getLatitude());
        locationDetails.putDouble("longitude", locationInfo.getLongitude());
        locationDetails.putDouble("bearing", locationInfo.getBearing());
        locationDetails.putDouble("speed", locationInfo.getSpeed());
        WritableMap customData = new WritableNativeMap();
        if(map != null) {
            for (String entry : map.keySet()) {
                customData.putString(entry, map.get(entry));
            }
        }

        WritableMap writableMap = new WritableNativeMap();
        writableMap.putMap("fenceInfo",fenceDetails);
        writableMap.putMap("zoneInfo",zoneDetails);
        writableMap.putMap("locationInfo", locationDetails);
        writableMap.putMap("customData",customData);
        writableMap.putBoolean("willCheckout",isCheckout);

        sendEvent(reactContext, "checkedIntoFence",writableMap);
    }

    @Override public void onCheckedOutFromFence(FenceInfo fenceInfo, ZoneInfo zoneInfo, int dwellTime,
            Map<String, String> map) {
        WritableMap fenceDetails = new WritableNativeMap();
        fenceDetails.putString("ID",fenceInfo.getId());
        fenceDetails.putString("name",fenceInfo.getName());

        WritableMap zoneDetails = new WritableNativeMap();
        zoneDetails.putString("ID",zoneInfo.getZoneId());
        zoneDetails.putString("name",zoneInfo.getZoneName());

        WritableMap customData = new WritableNativeMap();
        if(map != null) {
            for (String entry : map.keySet()) {
                customData.putString(entry, map.get(entry));
            }
        }
        WritableMap writableMap = new WritableNativeMap();
        writableMap.putMap("fenceInfo",fenceDetails);
        writableMap.putMap("zoneInfo",zoneDetails);
        writableMap.putMap("customData",customData);
        writableMap.putInt("dwellTime",dwellTime);
        sendEvent(reactContext, "checkedOutFromFence",writableMap);
    }

    @Override public void onCheckIntoBeacon(BeaconInfo beaconInfo, ZoneInfo zoneInfo,
            LocationInfo locationInfo, Proximity proximity, Map<String, String> map, boolean isCheckout) {
        WritableMap beaconDetails = new WritableNativeMap();
        beaconDetails.putString("ID",beaconInfo.getId());
        beaconDetails.putString("name",beaconInfo.getName());
        beaconDetails.putString("macAddress",beaconInfo.getMacAddress());
        beaconDetails.putDouble("latitude",beaconInfo.getLocation().getLatitude());
        beaconDetails.putDouble("longitude",beaconInfo.getLocation().getLongitude());

        WritableMap zoneDetails = new WritableNativeMap();
        zoneDetails.putString("ID",zoneInfo.getZoneId());
        zoneDetails.putString("name",zoneInfo.getZoneName());

        WritableMap locationDetails = new WritableNativeMap();
        locationDetails.putDouble("unixDate", locationInfo.getTimeStamp());
        locationDetails.putDouble("latitude", locationInfo.getLatitude());
        locationDetails.putDouble("longitude", locationInfo.getLongitude());
        locationDetails.putDouble("bearing", locationInfo.getBearing());
        locationDetails.putDouble("speed", locationInfo.getSpeed());

        WritableMap customData = new WritableNativeMap();
        if(map != null) {
            for (String entry : map.keySet()) {
                customData.putString(entry, map.get(entry));
            }
        }

        WritableMap writableMap = new WritableNativeMap();
        writableMap.putMap("beaconInfo",beaconDetails);
        writableMap.putMap("zoneInfo",zoneDetails);
        writableMap.putMap("locationInfo", locationDetails);
        writableMap.putMap("customData",customData);
        writableMap.putInt("proximity",getIntForProximity(proximity));
        writableMap.putBoolean("willCheckout",isCheckout);

        sendEvent(reactContext, "checkedIntoBeacon",writableMap);
    }

    @Override public void onCheckedOutFromBeacon(BeaconInfo beaconInfo, ZoneInfo zoneInfo, int dwellTime,
            Map<String, String> map) {

        WritableMap beaconDetails = new WritableNativeMap();
        beaconDetails.putString("ID",beaconInfo.getId());
        beaconDetails.putString("name",beaconInfo.getName());
        beaconDetails.putString("macAddress",beaconInfo.getMacAddress());
        beaconDetails.putDouble("latitude",beaconInfo.getLocation().getLatitude());
        beaconDetails.putDouble("longitude",beaconInfo.getLocation().getLongitude());

        WritableMap zoneDetails = new WritableNativeMap();
        zoneDetails.putString("ID",zoneInfo.getZoneId());
        zoneDetails.putString("name",zoneInfo.getZoneName());

        WritableMap customData = new WritableNativeMap();
        if(map != null) {
            for (String entry : map.keySet()) {
                customData.putString(entry, map.get(entry));
            }
        }

        WritableMap writableMap = new WritableNativeMap();
        writableMap.putMap("beaconInfo",beaconDetails);
        writableMap.putMap("zoneInfo",zoneDetails);
        writableMap.putMap("customData",customData);
        writableMap.putInt("dwellTime",dwellTime);
        sendEvent(reactContext, "checkedOutFromBeacon",writableMap);
    }

    @ReactMethod
    public void setCustomEventMetaData(ReadableMap metaData){
       if(metaData != null) {
           ReadableMapKeySetIterator mapKeySetIterator = metaData.keySetIterator();
           HashMap<String, String> metaDataMap = new HashMap<>();
           while (mapKeySetIterator.hasNextKey()) {
               String key = mapKeySetIterator.nextKey();
               metaDataMap.put(key, metaData.getString(key));
           }
           serviceManager.setCustomEventMetaData(metaDataMap);
       }
    }

    @ReactMethod
    public void setNotificationIDResourceID(String resourceID){
        // the setNotificationIDResourceID method is added to keep consistency with the iOS implementation
    }

    @ReactMethod
    public void startTempoTracking(String destinationId, final Callback failedCallback){
        TempoStatusListener listener = new TempoStatusListener() {
            @Override public void tempoStarted() {
                sendEvent(reactContext, "tempoStarted", null);
            }
            
            @Override public void tempoStopped() {
                sendEvent(reactContext, "tempoStopped", null);
            }

            @Override public void tempoStartError(BDError bdError) {
                String exceptionAsString = bdError.getReason();
                failedCallback.invoke(exceptionAsString);

                WritableMap errorMap = new WritableNativeMap();
                errorMap.putString("error", exceptionAsString);

                sendEvent(reactContext, "tempoStartError", errorMap);
            }
        };

        serviceManager.startTempoTracking(destinationId, listener);
    }

    @ReactMethod
    public void stopTempoTracking(){
        serviceManager.stopTempoTracking();
    }

    @ReactMethod
    public void getInstallRef(Promise promise){
        try {
            String installRef = serviceManager.getInstallRef();
            promise.resolve(installRef);
        } catch (Exception e) {
            promise.reject("Error getting the Installation Reference");
        }
    }

    private int getIntForProximity(Proximity value) {
        int result = 0;
        switch (value) {
            case Unknown:
                result = 0;
                break;
            case Immediate:
                result = 1;
                break;
            case Near:
                result = 2;
                break;
            case Far:
                result = 3;
                break;
        }
        return result;
    }
}
