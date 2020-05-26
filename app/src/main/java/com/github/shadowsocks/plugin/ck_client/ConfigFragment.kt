package com.github.shadowsocks.plugin.ck_client

import android.os.Bundle
import android.preference.EditTextPreference
import android.preference.ListPreference
import android.preference.Preference
import android.preference.PreferenceFragment
import android.view.View
import com.github.shadowsocks.plugin.PluginContract
import com.github.shadowsocks.plugin.PluginOptions


class ConfigFragment : PreferenceFragment() {
    var _options = PluginOptions()

    fun onInitializePluginOptions(options: PluginOptions) {
        this._options = options
        val ary = arrayOf(Pair("ProxyMethod","shadowsocks"), Pair("EncryptionMethod","plain"),
                Pair("Transport", "direct"), Pair("UID", ""), Pair("PublicKey",""), Pair("ServerName", "bing.com"),
                Pair("NumConn","4"), Pair("BrowserSig", "chrome"), Pair("StreamTimeout","300"),
                Pair("KeepAlive", "0"))
        for (element in ary) {
            val key = element.first
            val defaultValue = element.second
            val pref = findPreference(key)
            val current: String? = options.get(key)
            val value = current ?: defaultValue
            when (pref) {
                is ListPreference -> {
                    pref.setValue(value)
                }
                is EditTextPreference -> {
                    pref.setText(value)
                }
            }
            // we want all preferences to be put into the options, not only the changed ones
            options.put(key, value)
            pref.setOnPreferenceChangeListener(
                    fun(_: Preference, value: Any): Boolean {
                        options.put(key, value.toString())
                        return true
                    }
            )
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putString(PluginContract.EXTRA_OPTIONS, _options.toString())
    }

    override fun onViewCreated(vidw: View, savedInstanceState: Bundle?) {
        super.onViewCreated(vidw, savedInstanceState)
        if (savedInstanceState != null) {
            _options = PluginOptions(savedInstanceState.getString(PluginContract.EXTRA_OPTIONS))
            onInitializePluginOptions(_options)
        }
        addPreferencesFromResource(R.xml.config)
    }
}
