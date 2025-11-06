// 📁 android/app/src/main/kotlin/com/smartassist/app/CallLogManager.kt
package com.smartassist.app

import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.CallLog
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.telephony.SubscriptionInfo
import android.telephony.SubscriptionManager
import android.util.Log

class CallLogManager(private val context: Context) {
    private val TAG = "CallLogManager"

    fun listSimAccounts(): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()

        try {
            val telecom = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            val handles: List<PhoneAccountHandle> = try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    telecom.callCapablePhoneAccounts
                } else {
                    emptyList()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error getting phone accounts", e)
                emptyList()
            }

            val subMgr = context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
            val subs: List<SubscriptionInfo> = try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                    subMgr.activeSubscriptionInfoList ?: emptyList()
                } else {
                    emptyList()
                }
            } catch (e: SecurityException) {
                Log.w(TAG, "Missing READ_PHONE_STATE permission", e)
                emptyList()
            } catch (e: Exception) {
                Log.e(TAG, "Error getting subscription info", e)
                emptyList()
            }

            // Create maps with SIM account details
            for (h in handles) {
                val acc: PhoneAccount? = try {
                    telecom.getPhoneAccount(h)
                } catch (e: Exception) {
                    Log.e(TAG, "Error getting phone account for handle: $h", e)
                    null
                }

                val id = h.id ?: ""
                val guessSub = subs.firstOrNull {
                    it.subscriptionId.toString() == id || it.iccId == id
                }

                val label = acc?.label?.toString()
                val subId = guessSub?.subscriptionId
                val slot = guessSub?.simSlotIndex
                val number = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    guessSub?.number ?: acc?.subscriptionAddress?.schemeSpecificPart
                } else {
                    guessSub?.number ?: acc?.subscriptionAddress?.schemeSpecificPart
                }
                val carrier = guessSub?.carrierName?.toString()

                out.add(
                    mapOf(
                        "phoneAccountId" to id,
                        "componentName" to h.componentName.flattenToString(),
                        "label" to (label ?: carrier ?: "SIM"),
                        "subscriptionId" to subId,
                        "simSlotIndex" to slot,
                        "number" to number,
                        "carrierName" to carrier
                    )
                )
            }

            // Fallback: if no phone accounts found, try to read distinct PHONE_ACCOUNT_ID from CallLog
            if (out.isEmpty()) {
                val distinct = distinctAccountIdsFromLogs()
                for (accId in distinct) {
                    out.add(
                        mapOf(
                            "phoneAccountId" to accId,
                            "componentName" to null,
                            "label" to "SIM ($accId)",
                            "subscriptionId" to null,
                            "simSlotIndex" to null,
                            "number" to null,
                            "carrierName" to null
                        )
                    )
                }
            }

            Log.d(TAG, "Found ${out.size} SIM accounts")
        } catch (e: Exception) {
            Log.e(TAG, "Error listing SIM accounts", e)
        }

        return out
    }

    private fun distinctAccountIdsFromLogs(): List<String> {
        val list = mutableSetOf<String>()
        val uri: Uri = CallLog.Calls.CONTENT_URI
        val projection = arrayOf(CallLog.Calls.PHONE_ACCOUNT_ID)
        
        try {
            val cursor: Cursor? = context.contentResolver.query(uri, projection, null, null, null)
            cursor?.use {
                val idx = it.getColumnIndex(CallLog.Calls.PHONE_ACCOUNT_ID)
                while (it.moveToNext()) {
                    if (idx >= 0) {
                        val v = it.getString(idx)
                        if (!v.isNullOrEmpty()) list.add(v)
                    }
                }
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Missing READ_CALL_LOG permission", e)
        } catch (e: Exception) {
            Log.e(TAG, "Error reading distinct account IDs", e)
        }
        
        return list.toList()
    }

    fun getCallLogsForAccount(accountId: String, limit: Int, after: Long?): List<Map<String, Any?>> {
        val logs = mutableListOf<Map<String, Any?>>()
        val uri: Uri = CallLog.Calls.CONTENT_URI

        try {
            // First try the official PHONE_ACCOUNT_ID column
            var selection = "${CallLog.Calls.PHONE_ACCOUNT_ID} = ?"
            val args = mutableListOf(accountId)

            if (after != null) {
                selection += " AND ${CallLog.Calls.DATE} >= ?"
                args.add(after.toString())
            }

            val projection = arrayOf(
                CallLog.Calls._ID,
                CallLog.Calls.NUMBER,
                CallLog.Calls.DATE,
                CallLog.Calls.DURATION,
                CallLog.Calls.TYPE,
                CallLog.Calls.CACHED_NAME,
                CallLog.Calls.PHONE_ACCOUNT_ID,
                CallLog.Calls.PHONE_ACCOUNT_COMPONENT_NAME,
                CallLog.Calls.NEW
            )

            // Replace the readCursor function in getCallLogsForAccount method with this:
            fun readCursor(c: Cursor?) {
                c?.use { cur ->
                    val idxNumber = cur.getColumnIndex(CallLog.Calls.NUMBER)
                    val idxDate = cur.getColumnIndex(CallLog.Calls.DATE)
                    val idxDuration = cur.getColumnIndex(CallLog.Calls.DURATION)
                    val idxType = cur.getColumnIndex(CallLog.Calls.TYPE)
                    val idxName = cur.getColumnIndex(CallLog.Calls.CACHED_NAME)
                    val idxAcc = cur.getColumnIndex(CallLog.Calls.PHONE_ACCOUNT_ID)
                    val idxComp = cur.getColumnIndex(CallLog.Calls.PHONE_ACCOUNT_COMPONENT_NAME)
                    val idxNew = cur.getColumnIndex(CallLog.Calls.NEW)

                    while (cur.moveToNext() && logs.size < limit) {
                        val callType = if (idxType >= 0) cur.getInt(idxType) else 0
                        val typeString = when (callType) {
                            CallLog.Calls.INCOMING_TYPE -> "incoming"
                            CallLog.Calls.OUTGOING_TYPE -> "outgoing"
                            CallLog.Calls.MISSED_TYPE -> "missed"
                            CallLog.Calls.REJECTED_TYPE -> "rejected"
                            else -> "other"
                        }

                        val map = mapOf(
                            "unique_key" to "${if (idxNumber >= 0) cur.getString(idxNumber) else "unknown"}_${if (idxDate >= 0) cur.getLong(idxDate) else System.currentTimeMillis()}",
                            "name" to (if (idxName >= 0) cur.getString(idxName) else null),
                            "mobile" to (if (idxNumber >= 0) cur.getString(idxNumber) else null),
                            "number" to (if (idxNumber >= 0) cur.getString(idxNumber) else null),
                            "date" to (if (idxDate >= 0) cur.getLong(idxDate) else null),
                            "timestamp" to (if (idxDate >= 0) cur.getLong(idxDate).toString() else null),
                            "duration" to (if (idxDuration >= 0) cur.getLong(idxDuration).toString() else null),
                            "type" to callType,
                            "call_type" to typeString, // Add this line
                            "phoneAccountId" to (if (idxAcc >= 0) cur.getString(idxAcc) else null),
                            "phoneAccountComponent" to (if (idxComp >= 0) cur.getString(idxComp) else null),
                            "isNew" to (if (idxNew >= 0) cur.getInt(idxNew) else null),
                            "is_excluded" to false
                        )
                        logs.add(map)
                    }
                }
            }
            // fun readCursor(c: Cursor?) {
            //     c?.use { cur ->
            //         val idxNumber = cur.getColumnIndex(CallLog.Calls.NUMBER)
            //         val idxDate = cur.getColumnIndex(CallLog.Calls.DATE)
            //         val idxDuration = cur.getColumnIndex(CallLog.Calls.DURATION)
            //         val idxType = cur.getColumnIndex(CallLog.Calls.TYPE)
            //         val idxName = cur.getColumnIndex(CallLog.Calls.CACHED_NAME)
            //         val idxAcc = cur.getColumnIndex(CallLog.Calls.PHONE_ACCOUNT_ID)
            //         val idxComp = cur.getColumnIndex(CallLog.Calls.PHONE_ACCOUNT_COMPONENT_NAME)
            //         val idxNew = cur.getColumnIndex(CallLog.Calls.NEW)

            //         while (cur.moveToNext() && logs.size < limit) {
            //             val map = mapOf(
            //                 "number" to (if (idxNumber >= 0) cur.getString(idxNumber) else null),
            //                 "date" to (if (idxDate >= 0) cur.getLong(idxDate) else null),
            //                 "duration" to (if (idxDuration >= 0) cur.getLong(idxDuration) else null),
            //                 "type" to (if (idxType >= 0) cur.getInt(idxType) else null), // 1=incoming,2=outgoing,3=missed,5=rejected
            //                 "name" to (if (idxName >= 0) cur.getString(idxName) else null),
            //                 "phoneAccountId" to (if (idxAcc >= 0) cur.getString(idxAcc) else null),
            //                 "phoneAccountComponent" to (if (idxComp >= 0) cur.getString(idxComp) else null),
            //                 "isNew" to (if (idxNew >= 0) cur.getInt(idxNew) else null)
            //             )
            //             logs.add(map)
            //         }
            //     }
            // }

            // Try query by PHONE_ACCOUNT_ID
            try {
                val cursor = context.contentResolver.query(
                    uri,
                    projection,
                    selection,
                    args.toTypedArray(),
                    "${CallLog.Calls.DATE} DESC"
                )
                readCursor(cursor)
            } catch (e: Exception) {
                Log.e(TAG, "Error querying call logs by PHONE_ACCOUNT_ID", e)
            }

            // Fallback: Some OEMs store "subscription_id" instead
            if (logs.isEmpty()) {
                try {
                    val selection2 = "subscription_id = ?" + (if (after != null) " AND ${CallLog.Calls.DATE} >= ?" else "")
                    val args2 = mutableListOf(accountId)
                    if (after != null) args2.add(after.toString())

                    val cursor2 = context.contentResolver.query(
                        uri,
                        projection,
                        selection2,
                        args2.toTypedArray(),
                        "${CallLog.Calls.DATE} DESC"
                    )
                    readCursor(cursor2)
                } catch (e: Exception) {
                    Log.e(TAG, "Error querying call logs by subscription_id", e)
                }
            }

            Log.d(TAG, "Retrieved ${logs.size} call logs for account: $accountId")
        } catch (e: Exception) {
            Log.e(TAG, "Error getting call logs for account: $accountId", e)
        }

        return logs
    }

    fun getAllCallLogs(limit: Int = 100, after: Long? = null): List<Map<String, Any?>> {
        val logs = mutableListOf<Map<String, Any?>>()
        val uri: Uri = CallLog.Calls.CONTENT_URI

        try {
            var selection: String? = null
            var args: Array<String>? = null

            if (after != null) {
                selection = "${CallLog.Calls.DATE} >= ?"
                args = arrayOf(after.toString())
            }

            val projection = arrayOf(
                CallLog.Calls._ID,
                CallLog.Calls.NUMBER,
                CallLog.Calls.DATE,
                CallLog.Calls.DURATION,
                CallLog.Calls.TYPE,
                CallLog.Calls.CACHED_NAME,
                CallLog.Calls.PHONE_ACCOUNT_ID,
                CallLog.Calls.PHONE_ACCOUNT_COMPONENT_NAME,
                CallLog.Calls.NEW
            )

            val cursor = context.contentResolver.query(
                uri,
                projection,
                selection,
                args,
                "${CallLog.Calls.DATE} DESC LIMIT $limit"
            )

            cursor?.use { cur ->
                val idxNumber = cur.getColumnIndex(CallLog.Calls.NUMBER)
                val idxDate = cur.getColumnIndex(CallLog.Calls.DATE)
                val idxDuration = cur.getColumnIndex(CallLog.Calls.DURATION)
                val idxType = cur.getColumnIndex(CallLog.Calls.TYPE)
                val idxName = cur.getColumnIndex(CallLog.Calls.CACHED_NAME)
                val idxAcc = cur.getColumnIndex(CallLog.Calls.PHONE_ACCOUNT_ID)
                val idxComp = cur.getColumnIndex(CallLog.Calls.PHONE_ACCOUNT_COMPONENT_NAME)
                val idxNew = cur.getColumnIndex(CallLog.Calls.NEW)

                while (cur.moveToNext()) {
                    val callType = if (idxType >= 0) cur.getInt(idxType) else 0
                    val typeString = when (callType) {
                        CallLog.Calls.INCOMING_TYPE -> "incoming"
                        CallLog.Calls.OUTGOING_TYPE -> "outgoing"
                        CallLog.Calls.MISSED_TYPE -> "missed"
                        CallLog.Calls.REJECTED_TYPE -> "rejected"
                        else -> "other"
                    }

                    val map = mapOf(
                        "unique_key" to "${if (idxNumber >= 0) cur.getString(idxNumber) else "unknown"}_${if (idxDate >= 0) cur.getLong(idxDate) else System.currentTimeMillis()}",
                        "name" to (if (idxName >= 0) cur.getString(idxName) else null),
                        "mobile" to (if (idxNumber >= 0) cur.getString(idxNumber) else null),
                        "number" to (if (idxNumber >= 0) cur.getString(idxNumber) else null),
                        "date" to (if (idxDate >= 0) cur.getLong(idxDate) else null),
                        "timestamp" to (if (idxDate >= 0) cur.getLong(idxDate).toString() else null),
                        "duration" to (if (idxDuration >= 0) cur.getLong(idxDuration).toString() else null),
                        "type" to callType,
                        "call_type" to typeString,
                        "phoneAccountId" to (if (idxAcc >= 0) cur.getString(idxAcc) else null),
                        "phoneAccountComponent" to (if (idxComp >= 0) cur.getString(idxComp) else null),
                        "isNew" to (if (idxNew >= 0) cur.getInt(idxNew) else null),
                        "is_excluded" to false
                    )
                    logs.add(map)
                }
            }

            Log.d(TAG, "Retrieved ${logs.size} total call logs")
        } catch (e: SecurityException) {
            Log.e(TAG, "Missing READ_CALL_LOG permission", e)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting all call logs", e)
        }

        return logs
    }
}