package com.kosmos3d.kosmos3d

import android.app.Activity
import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiNetworkSpecifier
import android.os.Build
import io.flutter.plugin.common.MethodChannel

class CameraWifi(private val activity: Activity) {
    private val manager = activity.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private var callback: ConnectivityManager.NetworkCallback? = null
    private var pending: MethodChannel.Result? = null

    fun release() {
        manager.bindProcessToNetwork(null)
        callback?.let { try { manager.unregisterNetworkCallback(it) } catch (_: Exception) {} }
        callback = null
        pending?.error("CANCELLED", "Wi-Fi request cancelled", null)
        pending = null
    }

    fun join(ssid: String, password: String, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error("UNSUPPORTED", "Join the camera in Wi-Fi settings on Android 9 and earlier", null)
            return
        }
        release()
        pending = result
        try {
            val specifier = WifiNetworkSpecifier.Builder().setSsid(ssid).setWpa2Passphrase(password).build()
            val request = NetworkRequest.Builder()
                .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                .setNetworkSpecifier(specifier).build()
            val cb = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    activity.runOnUiThread {
                        if (callback !== this) return@runOnUiThread
                        if (manager.bindProcessToNetwork(network)) pending?.success(true)
                        else pending?.error("BIND_FAILED", "Could not route camera traffic over Wi-Fi", null)
                        pending = null
                    }
                }
                override fun onUnavailable() {
                    activity.runOnUiThread {
                        if (callback !== this) return@runOnUiThread
                        pending?.error("WIFI_UNAVAILABLE", "Wi-Fi connection declined or timed out", null)
                        pending = null
                        release()
                    }
                }
                override fun onLost(network: Network) {
                    activity.runOnUiThread { if (callback === this) release() }
                }
            }
            callback = cb
            manager.requestNetwork(request, cb, 45000)
        } catch (e: Exception) {
            pending = null
            release()
            result.error("WIFI_FAILED", e.message, null)
        }
    }
}
