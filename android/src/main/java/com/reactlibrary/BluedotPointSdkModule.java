package com.reactlibrary;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import au.com.bluedot.point.ServiceStatusListener;
import au.com.bluedot.point.net.engine.BDError;
import au.com.bluedot.point.net.engine.ServiceManager;
import au.com.bluedot.point.net.engine.ZoneInfo;

public class BluedotPointSdkModule extends ReactContextBaseJavaModule implements ServiceStatusListener {

    private final ReactApplicationContext reactContext;
    ServiceManager serviceManager;

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

    @Override public void onBlueDotPointServiceStartedSuccess() {

    }

    @Override public void onBlueDotPointServiceStop() {

    }

    @Override public void onBlueDotPointServiceError(BDError bdError) {

    }

    @Override public void onRuleUpdate(List<ZoneInfo> list) {

    }
}
