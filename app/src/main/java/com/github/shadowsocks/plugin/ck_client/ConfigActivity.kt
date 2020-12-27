package com.github.shadowsocks.plugin.ck_client

import android.os.Bundle
import android.util.Log
import android.view.MenuItem
import androidx.appcompat.widget.Toolbar
import com.github.shadowsocks.plugin.ConfigurationActivity
import com.github.shadowsocks.plugin.PluginOptions


class ConfigActivity : ConfigurationActivity(), Toolbar.OnMenuItemClickListener {

    private fun getChild(): ConfigFragment {
        return supportFragmentManager.findFragmentById(R.id.content) as ConfigFragment
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_config)
        val toolbar = findViewById<Toolbar>(R.id.toolbar)
        toolbar.title = title
        toolbar.setNavigationIcon(R.drawable.ic_navigation_close)
        toolbar.setNavigationOnClickListener { onBackPressed()}
        toolbar.inflateMenu(R.menu.menu_config)
        toolbar.setOnMenuItemClickListener(this)
    }

    override fun onInitializePluginOptions(options: PluginOptions) {
        getChild().onInitializePluginOptions(options)
    }

    override fun onMenuItemClick(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_apply -> {
                Log.d("options", getChild().options.toString())
                saveChanges(getChild().options)
                finish()
                true
            }
            else -> false
        }
    }
}
