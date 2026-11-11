package com.ceosmos.practicas

import android.app.Activity
import android.app.Application
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.graphics.Insets
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

/**
 * [CEOSMOS] Barra «← Prácticas» para las prácticas nativas abiertas dentro de CEOSMOS.
 *
 * No modifica el código de las prácticas: cuando una de sus actividades termina
 * onCreate, se coloca encima de su contenido una barra con el botón para volver a
 * la lista de prácticas (finish()). El botón Atrás del sistema hace lo mismo.
 */
object BarraPracticas : Application.ActivityLifecycleCallbacks {
    const val EXTRA_TITULO = "ceosmos_titulo"
    private const val TAG_BARRA = "ceosmos_barra_practicas"

    /** Prácticas nativas que CEOSMOS puede abrir (id → actividad). */
    val actividades: Map<String, Class<out Activity>> = mapOf(
        "bd_nativo" to com.ceosmos.practicas.bdnativo.MainActivity::class.java,
        "p09" to com.ceosmos.practicas.p09.MainActivity::class.java,
        "p10" to com.ceosmos.practicas.p10.MainActivity::class.java,
    )

    private var instalada = false

    fun instalar(app: Application) {
        if (instalada) return
        app.registerActivityLifecycleCallbacks(this)
        instalada = true
    }

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
        if (activity.javaClass !in actividades.values) return
        // onActivityCreated se emite antes del setContent de la práctica: se espera
        // a que termine su onCreate para envolver su contenido.
        activity.window.decorView.post { envolver(activity) }
    }

    private fun envolver(activity: Activity) {
        val contenido = activity.findViewById<FrameLayout>(android.R.id.content) ?: return
        if (contenido.findViewWithTag<View>(TAG_BARRA) != null) return
        val original = (0 until contenido.childCount).map { contenido.getChildAt(it) }
        contenido.removeAllViews()

        val densidad = activity.resources.displayMetrics.density
        fun dp(v: Int) = (v * densidad).toInt()
        val titulo = activity.intent.getStringExtra(EXTRA_TITULO).orEmpty()

        val barra = LinearLayout(activity).apply {
            tag = TAG_BARRA
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setBackgroundColor(Color.parseColor("#141725"))
            setPadding(dp(8), dp(6), dp(16), dp(6))
        }
        val volver = TextView(activity).apply {
            text = "←  Prácticas"
            contentDescription = "Volver a la lista de prácticas"
            setTextColor(Color.parseColor("#C2ADFF"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            typeface = Typeface.DEFAULT_BOLD
            setPadding(dp(12), dp(10), dp(12), dp(10))
            isClickable = true
            isFocusable = true
            setOnClickListener { activity.finish() }
        }
        val nombre = TextView(activity).apply {
            text = titulo
            setTextColor(Color.parseColor("#F3F0FF"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            maxLines = 1
            ellipsize = android.text.TextUtils.TruncateAt.END
        }
        barra.addView(volver)
        barra.addView(nombre, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))

        val cuerpo = FrameLayout(activity)
        original.forEach { cuerpo.addView(it) }

        val columna = LinearLayout(activity).apply { orientation = LinearLayout.VERTICAL }
        columna.addView(barra, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        columna.addView(cuerpo, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        contenido.addView(columna, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))

        // Si la práctica dibuja bajo la barra de estado (edge-to-edge), la barra
        // absorbe ese margen superior y el contenido de la práctica ya no lo repite.
        ViewCompat.setOnApplyWindowInsetsListener(columna) { _, insets ->
            val arriba = insets.getInsets(WindowInsetsCompat.Type.statusBars() or WindowInsetsCompat.Type.displayCutout())
            barra.setPadding(dp(8) + arriba.left, dp(6) + arriba.top, dp(16) + arriba.right, dp(6))
            val resto = WindowInsetsCompat.Builder(insets)
                .setInsets(WindowInsetsCompat.Type.statusBars(), Insets.of(arriba.left, 0, arriba.right, 0))
                .setInsets(WindowInsetsCompat.Type.displayCutout(), Insets.NONE)
                .build()
            ViewCompat.dispatchApplyWindowInsets(cuerpo, resto)
            WindowInsetsCompat.CONSUMED
        }
        ViewCompat.requestApplyInsets(columna)
    }

    override fun onActivityStarted(activity: Activity) {}
    override fun onActivityResumed(activity: Activity) {}
    override fun onActivityPaused(activity: Activity) {}
    override fun onActivityStopped(activity: Activity) {}
    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
    override fun onActivityDestroyed(activity: Activity) {}
}
