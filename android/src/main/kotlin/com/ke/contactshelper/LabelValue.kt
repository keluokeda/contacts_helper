package com.ke.contactshelper


data class LabelValue(override val label: String, val value: String) :Label{
    fun toMap(): HashMap<String, String> {
        val map = hashMapOf<String, String>()
        map["label"] = label
        map["value"] = value
        return map
    }

    companion object {
        @JvmStatic
        fun fromMap(map: Map<*, *>): LabelValue {
            val label: String = (map["label"] as String?) ?: ""
            val value: String = (map["value"] as String?) ?: ""
            return LabelValue(label, value)
        }
    }
}