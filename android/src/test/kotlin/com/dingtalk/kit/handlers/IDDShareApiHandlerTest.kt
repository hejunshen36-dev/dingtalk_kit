package com.dingtalk.kit.handlers

import com.android.dingtalk.share.ddsharemodule.IDDShareApi
import com.android.dingtalk.share.ddsharemodule.DDShareConfiguration
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.After
import org.junit.Assert.*
import org.junit.Test
import java.lang.reflect.Proxy

class IDDShareApiHandlerTest {
    private class Reply : MethodChannel.Result {
        val values = mutableListOf<Any?>()
        val errors = mutableListOf<String>()
        override fun success(result: Any?) { values.add(result) }
        override fun error(code: String, message: String?, details: Any?) { errors.add(code) }
        override fun notImplemented() { fail("Unexpected unimplemented method") }
        fun assertOnce() { assertEquals(1, values.size + errors.size) }
    }

    private val sends = mutableListOf<String>()
    private fun sdk(accepted: Boolean = true, throws: Boolean = false) {
        IDDShareApiHandler.iddShareApi = Proxy.newProxyInstance(
            IDDShareApi::class.java.classLoader, arrayOf(IDDShareApi::class.java)
        ) { _, method, _ ->
            if (method.name == "sendReq" || method.name == "sendReqToDing") {
                sends.add(method.name)
                if (throws) throw IllegalStateException("SDK failure")
                accepted
            } else if (method.returnType == Boolean::class.javaPrimitiveType) true else 0
        } as IDDShareApi
    }

    @After fun reset() { IDDShareApiHandler.iddShareApi = null }

    @Test fun registrationTargetsTheStandardDingTalkClient() {
        IDDShareApiHandler.iddShareApi = null
        val reply = Reply()
        IDDShareApiHandler.registerApp(MethodCall("registerApp", mapOf("appId" to "test-client")), reply)
        reply.assertOnce()
        assertEquals("com.alibaba.android.rimet", DDShareConfiguration.get().targetPackageName)
        assertTrue(DDShareConfiguration.get().isForceTarget)
    }

    @Test fun allShareTypesReturnSdkAcceptanceExactlyOnce() {
        for (accepted in listOf(true, false)) {
            for (ding in listOf(true, false)) {
                sdk(accepted)
                val args = mapOf<String?, Any?>(
                    "text" to "hello", "url" to "https://example.com",
                    "title" to "title", "content" to "content", "thumbUrl" to "",
                    "picUrl" to "https://example.com/image.png", "isSendDing" to ding
                )
                val text = Reply(); IDDShareApiHandler.sendTextMessage(args, text)
                val web = Reply(); IDDShareApiHandler.sendWebPageMessage(args, web)
                val image = Reply(); IDDShareApiHandler.sendImageMessage(args, image)
                for (reply in listOf(text, web, image)) {
                    reply.assertOnce()
                    assertEquals(listOf(accepted), reply.values)
                }
                assertEquals(if (ding) "sendReqToDing" else "sendReq", sends.last())
            }
        }
    }

    @Test fun invalidImageDoesNotSendOrCompleteTwice() {
        sdk()
        for (args in listOf(
            mapOf<String?, Any?>("picPath" to "/missing-dingtalk-test.png", "isSendDing" to false),
            mapOf<String?, Any?>("isSendDing" to false)
        )) {
            val reply = Reply()
            IDDShareApiHandler.sendImageMessage(args, reply)
            reply.assertOnce()
            assertEquals(1, reply.errors.size)
            assertTrue(sends.isEmpty())
        }
    }

    @Test fun missingRegistrationAndSdkExceptionCompleteWithError() {
        val args = mapOf<String?, Any?>("text" to "hello", "isSendDing" to false)
        val missing = Reply()
        IDDShareApiHandler.iddShareApi = null
        IDDShareApiHandler.sendTextMessage(args, missing)
        missing.assertOnce()
        assertEquals(1, missing.errors.size)
        sdk(throws = true)
        val thrown = Reply()
        IDDShareApiHandler.sendTextMessage(args, thrown)
        thrown.assertOnce()
        assertEquals(listOf("ShareError"), thrown.errors)
    }
}
