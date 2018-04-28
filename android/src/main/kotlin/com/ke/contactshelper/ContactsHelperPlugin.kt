package com.ke.contactshelper

import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.PluginRegistry.Registrar

class ContactsHelperPlugin(private val delegate: ContactsHelperDelegate) : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), CHANNEL)
            val delegate = ContactsHelperDelegate(registrar.activity())
            channel.setMethodCallHandler(ContactsHelperPlugin(delegate))
        }

        private const val CHANNEL = "github.com/keluokeda/contacts_helper"
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
//        if(registrar.activity() == null){
//            result.error("no activity","no activity",null)
//            return
//        }


        when {
            call.method == "getContacts" -> delegate.getContacts(call, result)
            call.method == "deleteContact" -> delegate.deleteContact(call, result)
            call.method == "insertContact" -> delegate.insertContact(call, result)
            call.method == "getPhoneLabels" -> result.success(delegate.getPhoneLabels())
            call.method == "getEmailLabels" -> result.success(delegate.getEmailLabels())
            call.method == "getUrlLabels" -> result.success(delegate.getUrlLabels())
            call.method == "getAddressLabels" -> result.success(delegate.getAddressLabels())
            call.method == "getInstantMessageLabels" -> result.success(delegate.getIMLabels())

            else -> result.notImplemented()
        }
    }
}
