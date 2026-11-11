package com.ceosmos.practicas.bdflutter

import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Source

class FirestoreReportes(private val db: FirebaseFirestore, private val uid: String) {
    private fun doc(id: String) = db.collection("reportes").document(id)

    fun crear(reporte: Reporte, fin: (Result<Unit>) -> Unit) {
        val ref = doc(reporte.id)
        db.runTransaction { tx ->
            if (tx.get(ref).exists()) throw IllegalStateException("El ID ${reporte.id} ya existe; no se sobrescribió.")
            tx.set(ref, mapOf(
                "equipo" to reporte.equipo,
                "descripcion" to reporte.descripcion,
                "prioridad" to reporte.prioridad,
                "ownerUid" to uid,
                "createdAt" to FieldValue.serverTimestamp(),
                "updatedAt" to FieldValue.serverTimestamp()
            ))
            Unit
        }.addOnSuccessListener { fin(Result.success(Unit)) }
            .addOnFailureListener { fin(Result.failure(it)) }
    }

    fun consultar(id: String, fin: (Result<Reporte?>) -> Unit) {
        doc(id).get(Source.SERVER)
            .addOnSuccessListener { snapshot ->
                if (!snapshot.exists()) {
                    fin(Result.success(null))
                } else if (snapshot.getString("ownerUid") != uid) {
                    fin(Result.failure(IllegalStateException("El reporte no pertenece a este usuario.")))
                } else {
                    val equipo = snapshot.getString("equipo")
                    val descripcion = snapshot.getString("descripcion")
                    val prioridad = snapshot.getString("prioridad")
                    if (equipo == null || descripcion == null || prioridad == null) {
                        fin(Result.failure(IllegalStateException("El documento tiene campos inválidos.")))
                    } else {
                        fin(Result.success(Reporte(id, equipo, descripcion, prioridad)))
                    }
                }
            }
            .addOnFailureListener { fin(Result.failure(it)) }
    }

    fun actualizarPrioridad(id: String, prioridad: String, fin: (Result<Unit>) -> Unit) {
        val ref = doc(id)
        db.runTransaction { tx ->
            val actual = tx.get(ref)
            if (!actual.exists()) throw NoSuchElementException("El reporte $id no existe.")
            if (actual.getString("ownerUid") != uid) throw IllegalStateException("Acceso denegado.")
            tx.update(ref, mapOf("prioridad" to prioridad, "updatedAt" to FieldValue.serverTimestamp()))
            Unit
        }.addOnSuccessListener { fin(Result.success(Unit)) }
            .addOnFailureListener { fin(Result.failure(it)) }
    }

    fun eliminar(id: String, fin: (Result<Unit>) -> Unit) {
        val ref = doc(id)
        db.runTransaction { tx ->
            val actual = tx.get(ref)
            if (!actual.exists()) throw NoSuchElementException("El reporte $id no existe.")
            if (actual.getString("ownerUid") != uid) throw IllegalStateException("Acceso denegado.")
            tx.delete(ref)
            Unit
        }.addOnSuccessListener { fin(Result.success(Unit)) }
            .addOnFailureListener { fin(Result.failure(it)) }
    }
}
