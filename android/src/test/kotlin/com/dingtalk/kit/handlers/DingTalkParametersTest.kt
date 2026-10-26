package com.dingtalk.kit.handlers

import android.app.Activity
import android.os.Bundle
import com.android.dingtalk.share.ddsharemodule.IDDShareApi
import com.android.dingtalk.share.ddsharemodule.message.*
import io.flutter.plugin.common.MethodChannel
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.lang.reflect.Proxy

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], manifest = Config.NONE)
class DingTalkParametersTest {
    private lateinit var activity: Activity
    private lateinit var actual: SendMessageToDD.Req
    private var method = ""
    private val reply = object : MethodChannel.Result {
        override fun success(result: Any?) { assertEquals(true, result) }
        override fun error(code: String, message: String?, details: Any?) { fail(code) }
        override fun notImplemented() { fail("unimplemented") }
    }

    @Before fun prepare() {
        activity = Robolectric.buildActivity(Activity::class.java).create().get()
        IDDShareApiHandler.setRegister(activity)
        IDDShareApiHandler.iddShareApi = Proxy.newProxyInstance(
            IDDShareApi::class.java.classLoader, arrayOf(IDDShareApi::class.java)
        ) { _, call, args ->
            when (call.name) {
                "sendReq", "sendReqToDing" -> {
                    method = call.name
                    actual = args!![0] as SendMessageToDD.Req
                    true
                }
                "getDDSupportAPI" -> 20160101
                else -> true
            }
        } as IDDShareApi
    }

    @After fun reset() {
        IDDShareApiHandler.setRegister(null)
        IDDShareApiHandler.iddShareApi = null
    }

    private fun assertDemoBundle(media: DDMediaMessage, ding: Boolean) {
        // Golden construction follows MainActivity.java in the supplied official Demo.
        val expected = SendMessageToDD.Req().apply { mMediaMessage = media }
        val demo = Bundle().also { expected.toBundle(it) }
        val plugin = Bundle().also { actual.toBundle(it) }
        assertEquals(demo.keySet(), plugin.keySet())
        for (key in demo.keySet()) assertEquals("wire parameter $key", demo.get(key), plugin.get(key))
        assertEquals(if (ding) "sendReqToDing" else "sendReq", method)
        assertNull(actual.mTransaction) // Demo also leaves transaction unset.
        assertTrue(media.checkArgs())
    }

    @Test fun webpageWireParametersAndBothSendRoutesMatchDemo() {
        for (ding in listOf(false, true)) {
            val url = "http://www.baidu.com"
            val thumb = "http://static.dingtalk.com/media/lAHPBY0V4shLSVDMlszw_240_150.gif"
            IDDShareApiHandler.sendWebPageMessage(mapOf(
                "url" to url, "title" to "title", "content" to null,
                "thumbUrl" to thumb, "isSendDing" to ding
            ), reply)
            assertDemoBundle(DDMediaMessage().apply {
                mMediaObject = DDWebpageMessage().apply { mUrl = url }
                mTitle = "title"
                mContent = null
                mThumbUrl = thumb
            }, ding)
        }
    }

    @Test fun textAndOnlineImageWireParametersMatchDemo() {
        for (ding in listOf(false, true)) {
            IDDShareApiHandler.sendTextMessage(mapOf("text" to "demo text", "isSendDing" to ding), reply)
            assertDemoBundle(DDMediaMessage().apply {
                mMediaObject = DDTextMessage().apply { mText = "demo text" }
            }, ding)
            val image = "https://example.com/demo.png"
            IDDShareApiHandler.sendImageMessage(mapOf("picUrl" to image, "isSendDing" to ding), reply)
            assertDemoBundle(DDMediaMessage().apply {
                mMediaObject = DDImageMessage().apply { mImageUrl = image }
            }, ding)
        }
    }

}
