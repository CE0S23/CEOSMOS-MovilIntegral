package com.ceosmos.practicas.bdnativo

data class Reporte(
    val id: String,
    val equipo: String,
    val descripcion: String,
    val prioridad: String
)

object ReporteValidator {
    private val idPattern = Regex("REP[0-9]{3}")
    val prioridades = setOf("Baja", "Media", "Alta")

    fun validar(id: String, equipo: String, descripcion: String, prioridad: String): String? {
        if (!idPattern.matches(id)) return "El ID debe tener el formato REP001."
        if (equipo.isBlank()) return "El equipo es obligatorio."
        if (descripcion.isBlank()) return "La descripción es obligatoria."
        if (equipo.length > 100 || descripcion.length > 500) return "El texto supera el límite permitido."
        if (prioridad !in prioridades) return "La prioridad debe ser Baja, Media o Alta."
        return null
    }

    fun validarId(id: String): String? =
        if (idPattern.matches(id)) null else "El ID debe tener el formato REP001."
}
