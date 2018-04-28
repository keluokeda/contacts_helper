package com.ke.contactshelper


data class PostalAddress(override val label: String, val formattedAddress: String, val country: String, val state: String, val city: String, val street: String, val postcode: String) : Label {
    fun toMap(): HashMap<String, String> {
        val map = hashMapOf<String, String>()
        map["label"] = label
        map["formattedAddress"] = formattedAddress
        map["country"] = country
        map["state"] = state
        map["city"] = city
        map["street"] = street
        map["postcode"] = postcode
        return map
    }


    companion object {
        @JvmStatic
        fun fromMap(map: Map<*, *>): PostalAddress {
            val label = map["label"] as String?
            val country = map["country"] as String?
            val state = map["state"] as String?
            val city = map["city"] as String?
            val street = map["street"] as String?
            val postcode = map["postcode"] as String?

            return PostalAddress(label ?: "", "", country ?: "", state ?: "", city ?: "", street
                    ?: "", postcode ?: "")
        }
    }
}