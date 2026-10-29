package com.kosmos3d.kosmos3d

import android.content.Context
import android.view.View
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.UdpDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.ui.PlayerView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

@UnstableApi
class GoProPreviewFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        GoProPreview(context, viewId, messenger)
}

@UnstableApi
private class GoProPreview(context: Context, id: Int, messenger: BinaryMessenger) : PlatformView {
    private val channel = MethodChannel(messenger, "kosmos/preview/$id")
    private var firstFrame = false
    private var failure: String? = null
    private val player = ExoPlayer.Builder(context)
        .setLoadControl(DefaultLoadControl.Builder()
            .setBufferDurationsMs(250, 1500, 100, 200).build())
        .build()
    private val playerView = PlayerView(context).apply {
        useController = false
        keepScreenOn = true
        player = this@GoProPreview.player
    }
    init {
        player.volume = 0f
        player.addListener(object : Player.Listener {
            override fun onRenderedFirstFrame() { firstFrame = true }
            override fun onPlayerError(error: PlaybackException) {
                failure = error.errorCodeName + ": " + (error.cause?.message ?: error.message)
            }
        })
        channel.setMethodCallHandler { call, result ->
            if (call.method == "status") {
                result.success(mapOf("firstFrame" to firstFrame, "error" to failure,
                    "playing" to player.isPlaying, "buffering" to (player.playbackState == Player.STATE_BUFFERING)))
            } else { result.notImplemented() }
        }
        val item = MediaItem.Builder().setUri("udp://0.0.0.0:8554").setMimeType(MimeTypes.VIDEO_MP2T).build()
        val source = ProgressiveMediaSource.Factory(DataSource.Factory { UdpDataSource(65536, 15000) })
            .createMediaSource(item)
        player.setMediaSource(source)
        player.prepare()
        player.playWhenReady = true
    }
    override fun getView(): View = playerView
    override fun dispose() {
        channel.setMethodCallHandler(null)
        playerView.player = null
        player.release()
    }
}
