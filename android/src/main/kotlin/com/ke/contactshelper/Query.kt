package com.ke.contactshelper


data class Query(val keywords: String, val sortKey: Boolean, val name: Boolean, val avatar: Boolean, val phoneNumber: Boolean, val email: Boolean, val company: Boolean, val address: Boolean, val note: Boolean, val instantMessage: Boolean, val url: Boolean) {

    companion object {
        @JvmStatic
        fun fromMap(map: Map<*, *>): Query {
            val keywords = map["keywords"] as String
            val sortKey = map["sortKey"] as Boolean
            val avatar = map["avatar"] as Boolean
            val name = map["name"] as Boolean
            val phoneNumber = map["phoneNumber"] as Boolean
            val email = map["email"] as Boolean
            val company = map["company"] as Boolean
            val address = map["address"] as Boolean
            val note = map["note"] as Boolean
            val instantMessage = map["instantMessage"] as Boolean
            val url = map["url"] as Boolean

            return Query(keywords, sortKey, name, avatar, phoneNumber, email, company, address, note, instantMessage, url)
        }
    }
}