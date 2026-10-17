# SPEC.md - Reto Mibanco: Agente de caja de Doña Rosa

## 1. Objetivo del reto

Construir un agente para una bodega en Lima que permita a Doña Rosa registrar sus operaciones con mensajes de texto o notas de voz de Telegram. El agente convierte cada mensaje en cero, una o varias transacciones, pide los datos que faltan y mantiene el flujo de caja del negocio.

El producto debe priorizar registros correctos. No debe inventar montos, aprobar créditos ni prometer préstamos.

## 2. Flujo principal

1. Recibir mensajes de texto o audio desde Telegram.
2. Conservar el mensaje original y, para audio, su transcripción.
3. Interpretar cada operación y validarla con las reglas de este documento.
4. Guardar una fila por producto u operación. Un mensaje personal o ajeno al negocio puede no producir transacciones.
5. Si falta un dato necesario, guardar el monto como nulo, marcar la transacción como pendiente de confirmación y preguntar en lenguaje sencillo.
6. Permitir corregir un registro. Si la usuaria se corrige, usar el dato corregido y no duplicar la versión anterior.
7. Consultar el flujo de caja semanal y responder cuánto podría pagar de cuota al mes, mostrando los datos y el cálculo usados.

## 3. Contrato de datos del reto

### Mensajes de entrada

El archivo de ejemplos usa estas columnas:

- id_mensaje: identificador estable del mensaje.
- dia: día de la semana del mensaje de ejemplo.
- mensaje: texto original.

En producción, conservar además el identificador del chat y del evento de Telegram para evitar procesar dos veces la misma actualización. Para los audios, conservar la transcripción asociada al mensaje original.

### Transacciones normalizadas

Cada fila de salida tiene estas columnas exactas y en este orden:

id_mensaje,tipo,producto,cantidad,monto,requiere_confirmacion

Reglas de representación:

- tipo: venta, gasto, fiado o cobro_fiado.
- producto: producto u operación descrita con un nombre breve.
- cantidad: cantidad de la línea.
- monto: total de la línea en soles, como número decimal con dos decimales al exportar. Puede ser nulo en la base de datos cuando no se conoce.
- requiere_confirmacion: booleano en la base de datos; exportar como SI o NO.
- Una venta con varios productos produce una fila por producto.
- Un mensaje sin operaciones del negocio produce cero filas de transacción.

La salida correcta de ejemplos y la plantilla de entrega son la referencia para nombres, valores permitidos y formato de exportación. La exportación del set oculto debe conservar el orden de los mensajes y agrupar las filas de cada mensaje.

## 4. Reglas de negocio

- Venta: cobro recibido en el momento; suma al flujo de caja.
- Gasto: compras, servicios, pagos, ayudantes y devoluciones a clientes; resta del flujo de caja.
- Fiado: producto entregado para pago posterior; no suma al flujo de caja mientras no se cobre.
- Cobro de fiado: dinero recibido por una deuda anterior; suma al flujo de caja.
- monto es el total de la línea: cantidad por precio unitario, con descuentos aplicados.
- Un monto desconocido se guarda como NULL, nunca como cero. Marcar requiere_confirmacion = true y preguntar; no inferir un precio.
- Si un cobro no indica monto y existe un fiado previo identificable, recordar la deuda para preguntar o registrar el pago correcto. Los pagos parciales deben reducir el saldo pendiente.
- Si hay varias deudas posibles para una persona y no se sabe cuál está pagando, pedir aclaración antes de asignar el pago.
- Si el mensaje corrige un dato anterior, conservar como vigente la versión corregida y evitar duplicar la operación.
- No registrar como gasto del negocio una compra explícitamente personal.
- Flujo de caja semanal = ventas cobradas + cobros de fiado - gastos. Los fiados sin cobrar no se incluyen.
- La cuota mensual es una estimación de sostenibilidad basada en el flujo observado. Explicar el período y las operaciones considerados, y no presentarla como aprobación de crédito.

## 5. Modelo de datos recomendado en Supabase

Usar PostgreSQL en Supabase con al menos estas entidades:

- mensajes: mensaje original, identificador de origen (id_mensaje), día o fecha, chat de Telegram, identificador de actualización y transcripción cuando corresponda.
- transacciones: referencia al mensaje, tipo, producto, cantidad, monto anulable y estado de confirmación. La relación mensaje-transacción es uno a muchos.
- deudas: referencia al fiado original y a la persona que debe.
- cobros_fiado o un vínculo equivalente desde la transacción de cobro a la deuda correspondiente, para calcular saldos y pagos parciales sin duplicar montos.

Usar tipos decimales para cantidades y dinero; almacenar dinero con dos decimales. El CSV es una vista de exportación, no obliga a perder en la base los vínculos necesarios para identificar mensajes, deudas y cobros.

## 6. Telegram, audio y experiencia

El bot de la demo es @reto_mibanco_bot. Leer su token desde API_TOKEN_TELEGRAM en .env.local, solo en el servidor y nunca desde una variable NEXT_PUBLIC_*.

- La interacción principal es Telegram; aceptar texto y notas de voz.
- Transcribir el audio antes de aplicar la misma validación de negocio que al texto.
- Responder en español simple, con preguntas cortas y una operación por confirmación cuando falten datos.
- No pedir a Doña Rosa que use hojas de cálculo ni términos técnicos.
- No depender de una API de IA para que la demostración básica funcione. Si el modelo o transcriptor no está disponible, usar reglas deterministas para casos conocidos y preguntar cuando no alcance la información.

## 7. Seguridad y configuración

- Leer las variables existentes desde .env.local; nunca imprimirlas, incluirlas en el repositorio ni enviarlas al navegador si son secretas.
- La URL de Supabase y la clave publicable/anon pueden usarse según el modelo de acceso. Una clave service_role o secreta solo puede vivir en el servidor y nunca en variables NEXT_PUBLIC_*.
- Mantener RLS habilitado en tablas expuestas por la API y crear políticas que correspondan al acceso real. No deshabilitar RLS para facilitar la demostración.
- El token del bot de Telegram y cualquier clave de proveedor de IA deben permanecer en variables privadas del servidor.
- Usar el identificador de actualización de Telegram para hacer idempotente la recepción de mensajes.

## 8. Criterios de éxito

- Registrar correctamente las operaciones y sus montos.
- No inventar datos faltantes; repreguntar.
- Calcular correctamente el flujo de caja semanal.
- Estimar una cuota sostenible y explicar el cálculo sin prometer crédito.
- Procesar audio, tolerar errores de tipeo y mantener una conversación simple.
- Exportar el set oculto con las seis columnas exactas de la plantilla.



