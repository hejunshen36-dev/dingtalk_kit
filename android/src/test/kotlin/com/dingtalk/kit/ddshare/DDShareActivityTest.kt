package com.dingtalk.kit.ddshare

import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.ResolveInfo
import android.os.Bundle
import com.android.dingtalk.share.ddsharemodule.message.BaseResp
import com.android.dingtalk.share.ddsharemodule.message.SendMessageToDD
import com.android.dingtalk.share.ddsharemodule.message.SendAuth
import com.android.dingtalk.share.ddsharemodule.IDDShareApi
import com.dingtalk.kit.handlers.IDDShareApiHandler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.lang.reflect.Proxy

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], manifest = Config.NONE)
class DDShareActivityTest {
    class CallbackActivity : DDShareActivity() {
        val responses = mutableListOf<BaseResp>()
        override fun onResp(response: BaseResp?) {
            if (response != null) responses.add(response)
            super.onResp(response)
        }
    }

    @Before fun register() {
        val application = RuntimeEnvironment.getApplication()
        for (name in listOf("dingtalk_kit", "flutter_dingtalk_sdk")) {
            application.getSharedPreferences(name, 0).edit().clear().commit()
        }
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
            .setPackage(application.packageName)
        shadowOf(application.packageManager).addResolveInfoForIntent(launcher, ResolveInfo().apply {
            activityInfo = ActivityInfo().apply {
                packageName = application.packageName
                name = "${application.packageName}.MainActivity"
            }
        })
        IDDShareApiHandler.iddShareApi = null
        IDDShareApiHandler.setRegister(RuntimeEnvironment.getApplication())
        IDDShareApiHandler.registerApp(
            MethodCall("registerApp", mapOf("appId" to "test-client")),
            object : MethodChannel.Result {
                override fun success(result: Any?) { assertEquals(true, result) }
                override fun error(code: String, message: String?, details: Any?) { fail(code) }
                override fun notImplemented() { fail("registerApp") }
            }
        )
    }

    @After fun reset() {
        IDDShareApiHandler.iddShareApi = null
        IDDShareApiHandler.setRegister(null)
    }

    private fun callback(transaction: String, errorCode: Int = BaseResp.ErrCode.ERR_USER_CANCEL): Intent {
        val response = SendMessageToDD.Resp().apply {
            mErrCode = errorCode
            mTransaction = transaction
        }
        return Intent().putExtras(Bundle().also { response.toBundle(it) })
            .putExtra("android.intent.ding.EXTRA_MESSAGE_APP_PACKAGE_NAME", "com.alibaba.android.rimet")
    }

    @Test fun coldStartDecodesResponseWithoutRegisteredSingleton() {
        IDDShareApiHandler.iddShareApi = null // Process-local state was lost.
        IDDShareApiHandler.setRegister(null)
        val activity = Robolectric.buildActivity(CallbackActivity::class.java, callback("cold"))
            .create().get()
        assertEquals(listOf("cold"), activity.responses.map { it.mTransaction })
        assertTrue(activity.isFinishing)
        assertNull(IDDShareApiHandler.iddShareApi) // Callback must not retain its Activity globally.
    }

    @Test fun newIntentReplacesTheStoredIntentAndDecodesOnlyTheNewResponse() {
        val controller = Robolectric.buildActivity(CallbackActivity::class.java, callback("first"))
            .create()
        val activity = controller.get()
        assertNotNull(shadowOf(activity).nextStartedActivity)
        val next = callback("second")
        controller.newIntent(next)
        assertSame(next, activity.intent)
        assertEquals(listOf("first", "second"), activity.responses.map { it.mTransaction })
        assertEquals(activity.packageName, shadowOf(activity).nextStartedActivity.component?.packageName)
    }

    @Test fun unrecognizedIntentFinishesWithoutReportingSuccess() {
        val activity = Robolectric.buildActivity(CallbackActivity::class.java, Intent()).create().get()
        assertTrue(activity.responses.isEmpty())
        assertTrue(activity.isFinishing)
        assertNull(shadowOf(activity).nextStartedActivity)
    }

    @Test fun coldStartAlsoPreservesAuthResponseFields() {
        IDDShareApiHandler.iddShareApi = null
        IDDShareApiHandler.setRegister(null)
        val response = SendAuth.Resp().apply {
            mErrCode = BaseResp.ErrCode.ERR_OK
            code = "synthetic-test-code"
            state = "test-state"
        }
        val intent = Intent().putExtras(Bundle().also { response.toBundle(it) })
            .putExtra("android.intent.ding.EXTRA_MESSAGE_APP_PACKAGE_NAME", "com.alibaba.android.rimet")
        val activity = Robolectric.buildActivity(CallbackActivity::class.java, intent).create().get()
        val decoded = activity.responses.single() as SendAuth.Resp
        assertEquals("synthetic-test-code", decoded.code)
        assertEquals("test-state", decoded.state)
        assertTrue(activity.isFinishing)
    }

    @Test fun coldStartMigratesLegacyRegistrationToTheNewStorage() {
        val application = RuntimeEnvironment.getApplication()
        val preferences = application.getSharedPreferences("dingtalk_kit", 0)
        preferences.edit().clear().commit()
        application.getSharedPreferences("flutter_dingtalk_sdk", 0).edit()
            .putString("registered_app_id", "legacy-client").commit()
        IDDShareApiHandler.iddShareApi = null
        IDDShareApiHandler.setRegister(null)
        val activity = Robolectric.buildActivity(CallbackActivity::class.java, callback("migrated"))
            .create().get()
        assertEquals(listOf("migrated"), activity.responses.map { it.mTransaction })
        assertEquals("legacy-client", preferences.getString("registered_app_id", null))
        assertTrue(activity.isFinishing)
        assertNull(IDDShareApiHandler.iddShareApi)
    }

    @Test fun currentRegistrationTakesPrecedenceOverLegacyStorage() {
        val application = RuntimeEnvironment.getApplication()
        application.getSharedPreferences("flutter_dingtalk_sdk", 0).edit()
            .putString("registered_app_id", "legacy-client").commit()
        IDDShareApiHandler.iddShareApi = null
        val activity = Robolectric.buildActivity(CallbackActivity::class.java, callback("current"))
            .create().get()
        assertEquals(listOf("current"), activity.responses.map { it.mTransaction })
        assertEquals("test-client", application.getSharedPreferences("dingtalk_kit", 0)
            .getString("registered_app_id", null))
    }

    @Test fun missingRegistrationFinishesWithoutCreatingAnInvalidApi() {
        RuntimeEnvironment.getApplication().getSharedPreferences("dingtalk_kit", 0)
            .edit().clear().commit()
        IDDShareApiHandler.iddShareApi = null
        IDDShareApiHandler.setRegister(null)
        val activity = Robolectric.buildActivity(CallbackActivity::class.java, callback("unknown"))
            .create().get()
        assertTrue(activity.responses.isEmpty())
        assertTrue(activity.isFinishing)
        assertNull(shadowOf(activity).nextStartedActivity)
    }

    @Test fun sdkExceptionFinishesTheExportedActivity() {
        IDDShareApiHandler.iddShareApi = Proxy.newProxyInstance(
            IDDShareApi::class.java.classLoader, arrayOf(IDDShareApi::class.java)
        ) { _, _, _ -> throw IllegalArgumentException("synthetic malformed callback") } as IDDShareApi
        val activity = Robolectric.buildActivity(CallbackActivity::class.java, callback("malformed"))
            .create().get()
        assertTrue(activity.responses.isEmpty())
        assertTrue(activity.isFinishing)
        assertNull(shadowOf(activity).nextStartedActivity)
    }

    @Test fun successfulShareRestoresHostWithoutClearingItsCurrentPage() {
        val activity = Robolectric.buildActivity(CallbackActivity::class.java,
            callback("success", BaseResp.ErrCode.ERR_OK)).create().get()
        val launch = shadowOf(activity).nextStartedActivity
        assertNotNull("A successful callback must bring the host task to the foreground", launch)
        assertEquals(activity.packageName, launch.component?.packageName)
        assertEquals("${activity.packageName}.MainActivity", launch.component?.className)
        assertFalse(launch.hasExtra("android.intent.ding.EXTRA_COMMAND_TYPE"))
        assertTrue(launch.flags and Intent.FLAG_ACTIVITY_NEW_TASK != 0)
        assertTrue(launch.flags and Intent.FLAG_ACTIVITY_SINGLE_TOP != 0)
        assertEquals(0, launch.flags and (Intent.FLAG_ACTIVITY_CLEAR_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP))
        assertTrue(activity.isFinishing)
    }

    @Test fun coldStartCancellationAlsoReturnsToHost() {
        IDDShareApiHandler.iddShareApi = null
        IDDShareApiHandler.setRegister(null)
        val activity = Robolectric.buildActivity(CallbackActivity::class.java, callback("cancel"))
            .create().get()
        assertNotNull(shadowOf(activity).nextStartedActivity)
        assertEquals(BaseResp.ErrCode.ERR_USER_CANCEL, activity.responses.single().mErrCode)
    }
}
