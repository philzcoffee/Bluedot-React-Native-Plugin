package com.reactlibrary;

import android.Manifest;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.os.Build;
import android.support.v4.app.NotificationCompat;
import au.com.bluedot.application.model.Proximity;
import au.com.bluedot.point.ApplicationNotificationListener;
import au.com.bluedot.point.net.engine.BeaconInfo;
import au.com.bluedot.point.net.engine.FenceInfo;
import au.com.bluedot.point.net.engine.LocationInfo;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import au.com.bluedot.point.ServiceStatusListener;
import au.com.bluedot.point.net.engine.BDError;
import au.com.bluedot.point.net.engine.ServiceManager;
import au.com.bluedot.point.net.engine.ZoneInfo;
import java.util.List;
import java.util.Map;

import static android.app.Notification.PRIORITY_MAX;

public class BluedotPointSdkModule extends ReactContextBaseJavaModule
        implements ServiceStatusListener, ApplicationNotificationListener {

    private final ReactApplicationContext reactContext;
    ServiceManager serviceManager;
    private Callback appNotifyFenceCallback;
    private Callback zoneInfoCallback;

    public BluedotPointSdkModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        serviceManager = ServiceManager.getInstance(reactContext);
    }

    @Override
    public String getName() {
        return "BluedotPointSdk";
    }

    @ReactMethod
    public void sampleMethod(String stringArgument, int numberArgument, Callback callback) {
        // TODO: Implement some actually useful functionality
        callback.invoke("Received numberArgument: " + numberArgument + " stringArgument: " + stringArgument);
    }

    @ReactMethod
    public void authenticate(String apiKey, String permLevel, Callback success,Callback fail){
        if(apiKey.equals(" "))
            apiKey="0811c6a0-0251-11e9-aebf-02e673959816";

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if(reactContext.checkSelfPermission(
                    Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ) {
                //serviceManager.setForegroundServiceNotification(createNotification(), false);
                serviceManager.sendAuthenticationRequest(apiKey, this);
                success.invoke("Success");
            } else
            {
                fail.invoke("No permission");
            }
        }
    }

    @ReactMethod
    public void setForeground(String channelId, String channelName, String title, String content){
        serviceManager.setForegroundServiceNotification(createNotification(channelId,channelName,title,content), false);
    }

    private Notification createNotification(String channelId,String channelName,String title, String content) {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            //channelId = "Bluedot React Demo";
            //channelName = "Bluedot Service";
            NotificationChannel notificationChannel = new NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_DEFAULT);
            notificationChannel.enableLights(false);
            notificationChannel.setLightColor(Color.RED);
            notificationChannel.enableVibration(false);
            NotificationManager notificationManager = (NotificationManager) reactContext.getSystemService(
                    Context.NOTIFICATION_SERVICE);
            notificationManager.createNotificationChannel(notificationChannel);

            Notification.Builder notification = new Notification.Builder(reactContext, channelId)
                    .setContentTitle(title)
                    .setContentText(content)
                    .setStyle(new Notification.BigTextStyle().bigText("Bluedot FG"))
                    .setOngoing(true)
                    .setCategory(Notification.CATEGORY_SERVICE);

            return notification.build();
        } else {

            NotificationCompat.Builder notification = new NotificationCompat.Builder(reactContext)
                    .setContentTitle(title)
                    .setContentText(content)
                    .setStyle(new NotificationCompat.BigTextStyle().bigText("FG Service"))
                    .setOngoing(true)
                    .setCategory(Notification.CATEGORY_SERVICE)
                    .setPriority(PRIORITY_MAX);

            return notification.build();
        }
    }

    @Override public void onBlueDotPointServiceStartedSuccess() {
        serviceManager.subscribeForApplicationNotification(this);
    }

    @Override public void onBlueDotPointServiceStop() {

    }

    @Override public void onBlueDotPointServiceError(BDError bdError) {

    }

    @Override public void onRuleUpdate(List<ZoneInfo> list) {
        if(zoneInfoCallback != null && list.size() > 0)
            zoneInfoCallback.invoke(" Zones updated:"+list.size());
    }

    @ReactMethod public void ruleUpdateCallback(Callback callback){
        zoneInfoCallback = callback;
    }

    @ReactMethod
    public void checkedIntoFenceCallback(Callback callback){
        appNotifyFenceCallback = callback;
    }

    @Override
    public void onCheckIntoFence(FenceInfo fenceInfo, ZoneInfo zoneInfo, LocationInfo locationInfo,
            Map<String, String> map, boolean b) {

    }

    @Override public void onCheckedOutFromFence(FenceInfo fenceInfo, ZoneInfo zoneInfo, int i,
            Map<String, String> map) {

    }

    @Override public void onCheckIntoBeacon(BeaconInfo beaconInfo, ZoneInfo zoneInfo,
            LocationInfo locationInfo, Proximity proximity, Map<String, String> map, boolean b) {

    }

    @Override public void onCheckedOutFromBeacon(BeaconInfo beaconInfo, ZoneInfo zoneInfo, int i,
            Map<String, String> map) {

    }
}
