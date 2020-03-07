package com.github.shadowsocks.plugin.ck_client

import android.os.Bundle
import android.util.Log
import android.view.MenuItem
import androidx.appcompat.widget.Toolbar
import com.github.shadowsocks.plugin.ConfigurationActivity
import com.github.shadowsocks.plugin.PluginOptions


class ConfigActivity : ConfigurationActivity(), Toolbar.OnMenuItemClickListener {

    fun getChild(): ConfigFragment {
        return getFragmentManager().findFragmentById(R.id.content) as ConfigFragment
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_config)
        val toolbar = findViewById<Toolbar>(R.id.toolbar) as Toolbar
        toolbar.setTitle(getTitle())
        toolbar.setNavigationIcon(R.drawable.ic_navigation_close)
        toolbar.setNavigationOnClickListener(
                fun(_) {
                    onBackPressed()
                })
        toolbar.inflateMenu(R.menu.menu_config)
        toolbar.setOnMenuItemClickListener(this)
    }

    override fun onInitializePluginOptions(options: PluginOptions) {
        getChild().onInitializePluginOptions(options)
    }

    override fun onMenuItemClick(item: MenuItem): Boolean {
        when (item.getItemId()) {
            R.id.action_apply -> {
                Log.d("options", getChild()._options.toString())
                saveChanges(getChild()._options)
                finish()
                return true
            }
            else -> return false
        }
    }
}
