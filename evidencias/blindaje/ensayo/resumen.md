# Ensayo del plan de contingencia (20 minutos)

Fecha: 2026-11-21 17:02 · dispositivos: R52W80BXQHP

| Fallo | Área | ¿Lo detectaron las pruebas? | Detección | Corrección | ¿Verificado e instalado? | Verificación | Total |
|---|---|---|---|---|---|---|---|
| F1 · campo sin validar (correo) | `login` | sí | 20 s | 0 s | sí | 125 s | 2.4 min |
| F2 · timeout mal puesto (cliente de la API) | `red` | sí | 22 s | 0 s | sí | 92 s | 1.9 min |
| F3 · permiso de Bluetooth mal manejado | `ble` | sí | 26 s | 0 s | sí | 86 s | 1.9 min |

La corrección se hizo restaurando el código correcto (el arreglo real se escribe a mano; aquí se mide el ciclo detectar → corregir → probar → compilar → instalar → revisar logcat).

Código final sin cambios: sí
