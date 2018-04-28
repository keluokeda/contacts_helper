package com.ke.contactshelper

import java.util.*


class Contact {


    var id: String? = null
    var displayName: String? = null
    var familyName: String? = null
    var givenName: String? = null
    var middleName: String? = null
    var namePrefix: String? = null
    var nameSuffix: String? = null
    var sortKey: String? = null

    val phones: MutableList<LabelValue> = mutableListOf()
    val emails: MutableList<LabelValue> = mutableListOf()
    val urls: MutableList<LabelValue> = mutableListOf()
    val addresses: MutableList<PostalAddress> = mutableListOf()
    val instantMessages: MutableList<LabelValue> = mutableListOf()
    var organization: String? = null
    var jobTitle: String? = null
    var note: String? = null
    var avatar: ByteArray? = null




    fun toMap(): HashMap<String, Any?> {
        val map = hashMapOf<String, Any?>()
        map["id"] = id
        map["displayName"] = displayName
        map["familyName"] = familyName
        map["givenName"] = givenName
        map["middleName"] = middleName
        map["namePrefix"] = namePrefix
        map["nameSuffix"] = nameSuffix

        map["sortKey"] = sortKey



        map["phones"] = phones.map { it.toMap() }

        map["emails"] = emails.map { it.toMap() }

        map["urls"] = urls.map { it.toMap() }

        map["addresses"] = addresses.map { it.toMap() }

        map["instantMessages"] = instantMessages.map { it.toMap() }

        map["organization"] = organization
        map["jobTitle"] = jobTitle
        map["departmentName"] = null
        map["note"] = note
        map["avatar"] = avatar

        return map
    }

    override fun toString(): String {
        return "Contact(id=$id, displayName=$displayName, familyName=$familyName, givenName=$givenName, middleName=$middleName, namePrefix=$namePrefix, nameSuffix=$nameSuffix, sortKey=$sortKey, phones=$phones, emails=$emails, urls=$urls, addresses=$addresses, instantMessages=$instantMessages, organization=$organization, jobTitle=$jobTitle, note=$note, avatar=${Arrays.toString(avatar)})"
    }

    companion object {
        @JvmStatic
        fun fromMap(map: Map<*, *>): Contact {
            val contact = Contact()
            contact.id = map["identifier"] as String?
            contact.givenName = map["givenName"] as String?
            contact.middleName = map["middleName"] as String?
            contact.familyName = map["familyName"] as String?
            contact.namePrefix = map["prefix"] as String?
            contact.nameSuffix = map["suffix"] as String?
            contact.organization = map["organization"] as String?
            contact.jobTitle = map["jobTitle"] as String?
            contact.note = map["note"] as String?
            contact.avatar = map["avatar"] as ByteArray?

            val phones = map["phones"] as List<*>?

            phones?.let {
                it.map {
                    return@map (it as Map<*, *>?) ?: mapOf<String, String>()
                }.map { LabelValue.fromMap(it) }.forEach({ contact.phones.add(it) })
            }

            val emails = map["emails"] as List<*>?
            emails?.let {
                it.map {
                    return@map (it as Map<*, *>?) ?: mapOf<String, String>()
                }.map { LabelValue.fromMap(it) }.forEach({ contact.emails.add(it) })
            }

            val urls = map["urls"] as List<*>?
            urls?.let {
                it.map {
                    return@map (it as Map<*, *>?) ?: mapOf<String, String>()
                }.map { LabelValue.fromMap(it) }.forEach({ contact.urls.add(it) })
            }

            val addresses = map["addresses"] as List<*>?
            addresses?.let {
                it.map {
                    return@map (it as Map<*, *>?) ?: mapOf<String, String>()
                }.map { PostalAddress.fromMap(it) }.forEach({ contact.addresses.add(it) })
            }

            val instantMessages = map["instantMessages"] as List<*>?

            instantMessages?.let {
                it.map {
                    return@map (it as Map<*, *>?) ?: mapOf<String, String>()
                }.map { LabelValue.fromMap(it) }.forEach({ contact.instantMessages.add(it) })
            }


            return contact
        }
    }


}

