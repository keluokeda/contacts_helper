package com.ke.contactshelper

import android.Manifest
import android.app.Activity
import android.content.ContentProviderOperation
import android.content.ContentResolver
import android.content.ContentUris
import android.content.Intent
import android.content.res.Resources
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.provider.ContactsContract.CommonDataKinds
import android.provider.ContactsContract.CommonDataKinds.Organization
import android.provider.ContactsContract.CommonDataKinds.StructuredName
import android.text.TextUtils
import com.tbruyelle.rxpermissions2.RxPermissions
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.reactivex.schedulers.Schedulers


class ContactsHelperDelegate(private val activity: Activity) : PluginRegistry.ActivityResultListener {
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_PICK_CONTACT) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    val projection = arrayOf(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME, ContactsContract.CommonDataKinds.Phone.NUMBER, CommonDataKinds.Phone.TYPE, CommonDataKinds.Phone.LABEL)
                    val cursor = contentResolver.query(uri, projection, null, null, null)
                    if (cursor != null && cursor.moveToFirst()) {
                        val name = cursor.getString(0)
                        val mobile = cursor.getString(1)
                        val type = cursor.getInt(2)
                        val label = cursor.getString(3)
                        val typeLabel = ContactsContract.CommonDataKinds.Phone.getTypeLabel(resources, type, label)

                        val contact = Contact().apply {
                            displayName = name
                            phones.add(LabelValue(typeLabel.toString(), mobile))
                        }

                        result?.success(contact.toMap())

                        cursor.close()
                    }
                }

            }


            result = null

            return true
        }

        return false
    }

    private var result: MethodChannel.Result? = null

    private val phoneTypeLabels: List<Pair<Int, String>>

    private val emailTypeLabels: List<Pair<Int, String>>
    private val addressTypeLabels: List<Pair<Int, String>>
    private val instantMessageTypeLabels: List<Pair<Int, String>>

    private val contentResolver: ContentResolver = activity.contentResolver

    private val resources: Resources = activity.resources

//    var disposable: Disposable = Observable.just(1).subscribe()

    init {

        val phoneTypes = Array(20) { i -> i + 1 }
        val defaultValue = "#"

        phoneTypeLabels = phoneTypes.map { Pair(it, ContactsContract.CommonDataKinds.Phone.getTypeLabel(resources, it, defaultValue).toString()) }.filterNot { it.second == defaultValue }

        emailTypeLabels = arrayOf(1, 2, 3, 4).map { Pair(it, ContactsContract.CommonDataKinds.Email.getTypeLabel(resources, it, defaultValue).toString()) }.filterNot { it.second == defaultValue }

        addressTypeLabels = arrayOf(1, 2, 3, 4).map { Pair(it, ContactsContract.CommonDataKinds.Email.getTypeLabel(resources, it, defaultValue).toString()) }.filterNot { it.second == defaultValue }

        instantMessageTypeLabels = Array(9) { i -> i }.map { Pair(it, ContactsContract.CommonDataKinds.Im.getProtocolLabel(resources, it, defaultValue).toString()) }.filterNot { it.second == defaultValue }
    }


    fun getContacts(call: MethodCall, result: MethodChannel.Result) {

        val rxPermission = RxPermissions(activity)
        rxPermission
                .request(Manifest.permission.READ_CONTACTS)
                .observeOn(Schedulers.io())
                .map { permissionGranted -> return@map if (permissionGranted) getContacts(convertQuery(call.arguments)) else arrayListOf() }
                .subscribe({ result.success(it) }, { result.success(emptyList<HashMap<String, Any?>>()) })

    }

    fun insertContact(call: MethodCall, result: MethodChannel.Result) {
        val map = call.arguments as Map<*, *>?

        if (map == null) {
            result.success(false)
        } else {
            RxPermissions(activity)
                    .request(Manifest.permission.WRITE_CONTACTS)
                    .map {
                        if (it) {
                            val contact = Contact.fromMap(map)
                            insertContact(contact)
                        }
                        return@map true
                    }.subscribe({ result.success(it) }, { result.success(false) })
        }


    }


    fun pickContact(result: MethodChannel.Result) {
        RxPermissions(activity).request(Manifest.permission.READ_CONTACTS)
                .subscribe {
                    if (it) {
                        val intent = Intent(Intent.ACTION_PICK, ContactsContract.CommonDataKinds.Phone.CONTENT_URI)
                        activity.startActivityForResult(intent, REQUEST_CODE_PICK_CONTACT)
                        this.result = result
                    }
                }

    }

    private fun insertContact(contact: Contact) {
        val operations = arrayListOf<ContentProviderOperation>()

        var builder: ContentProviderOperation.Builder = ContentProviderOperation.newInsert(ContactsContract.RawContacts.CONTENT_URI)
                .withValue(ContactsContract.RawContacts.ACCOUNT_TYPE, null)
                .withValue(ContactsContract.RawContacts.ACCOUNT_NAME, null)
        operations.add(builder.build())

        builder = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                .withValue(ContactsContract.Data.MIMETYPE, StructuredName.CONTENT_ITEM_TYPE)
                .withValue(StructuredName.GIVEN_NAME, contact.givenName)
                .withValue(StructuredName.MIDDLE_NAME, contact.middleName)
                .withValue(StructuredName.FAMILY_NAME, contact.familyName)
                .withValue(StructuredName.PREFIX, contact.namePrefix)
                .withValue(StructuredName.SUFFIX, contact.nameSuffix)
        operations.add(builder.build())

        builder = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                .withValue(ContactsContract.Data.MIMETYPE, Organization.CONTENT_ITEM_TYPE)
                .withValue(Organization.COMPANY, contact.organization)
                .withValue(Organization.TITLE, contact.jobTitle)
        operations.add(builder.build())

        builder = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.Note.CONTENT_ITEM_TYPE)
                .withValue(CommonDataKinds.Note.NOTE, contact.note)
        operations.add(builder.build())


        builder.withYieldAllowed(true)

        addLabelValue(contact.phones, CommonDataKinds.Phone.CONTENT_ITEM_TYPE, operations, phoneTypeLabels)

        addLabelValue(contact.emails, CommonDataKinds.Email.CONTENT_ITEM_TYPE, operations, emailTypeLabels)

        addLabelValue(contact.urls, CommonDataKinds.Website.CONTENT_ITEM_TYPE, operations, arrayListOf())

        addLabelValue(contact.instantMessages, CommonDataKinds.Im.CONTENT_ITEM_TYPE, operations, instantMessageTypeLabels)


        //Postal addresses
        for (address in contact.addresses) {
            builder = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE)
                    .withValue(CommonDataKinds.StructuredPostal.STREET, address.street)
                    .withValue(CommonDataKinds.StructuredPostal.CITY, address.city)
                    .withValue(CommonDataKinds.StructuredPostal.REGION, address.state)
                    .withValue(CommonDataKinds.StructuredPostal.POSTCODE, address.postcode)
                    .withValue(CommonDataKinds.StructuredPostal.COUNTRY, address.country)
            addType(address, addressTypeLabels, builder)

            operations.add(builder.build())
        }

        contentResolver.applyBatch(ContactsContract.AUTHORITY, operations)


    }

    private fun addLabelValue(list: List<LabelValue>, mimeType: String, operations: ArrayList<ContentProviderOperation>, typeLabelList: List<Pair<Int, String>>) {
        for (labelValue in list) {
            val builder = ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, mimeType)
                    .withValue(ContactsContract.Data.DATA1, labelValue.value)
            if (!typeLabelList.isEmpty())
                addType(labelValue, typeLabelList, builder)

            operations.add(builder.build())
        }
    }


    private fun addType(label: Label, typeLabelList: List<Pair<Int, String>>, builder: ContentProviderOperation.Builder) {
        val result = typeLabelList.filter { it.second == label.label }

        if (result.isEmpty()) {
            builder.withValue(CommonDataKinds.Phone.TYPE, CommonDataKinds.BaseTypes.TYPE_CUSTOM)
                    .withValue(CommonDataKinds.Phone.LABEL, label.label)
        } else {
            val pair = result[0]

            builder.withValue(CommonDataKinds.Phone.TYPE, pair.first)
        }

    }

    fun deleteContact(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments
        if (arguments != null && arguments is String) {
            val contactId = call.arguments as String
            RxPermissions(activity).request(Manifest.permission.WRITE_CONTACTS).map { if (it) return@map contactId else return@map "" }
                    .observeOn(Schedulers.io())
                    .map {
                        if ("" == it) return@map false else {
                            val operations = arrayListOf<ContentProviderOperation>()
                            operations.add(ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI).withSelection(ContactsContract.Data.CONTACT_ID + " = ?", arrayOf(contactId)).build())
                            contentResolver.applyBatch(ContactsContract.AUTHORITY, operations)
                            return@map true

                        }
                    }.subscribe({ result.success(it) }, { result.success(false) })


        } else {
            result.success(false)
        }


    }

    fun getPhoneLabels(): List<String> {
        return phoneTypeLabels.map { it.second }
    }

    fun getEmailLabels(): List<String> {
        return emailTypeLabels.map { it.second }
    }

    fun getUrlLabels(): List<String> {
        return arrayListOf()
    }

    fun getAddressLabels(): List<String> {
        return addressTypeLabels.map { it.second }
    }

    fun getIMLabels(): List<String> {
        return instantMessageTypeLabels.map { it.second }
    }


    private fun convertQuery(arguments: Any): Query? = if (arguments is Map<*, *>) Query.fromMap(arguments) else null


    private fun getSortKeyProjection(): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) "phonebook_label" else ContactsContract.CommonDataKinds.Phone.SORT_KEY_PRIMARY
    }


    private fun getContacts(query: Query?): ArrayList<HashMap<String, Any?>> {


        val selection = mutableListOf<String>()
        val selectionArgs = mutableListOf<String>()

        val projection = mutableListOf(ContactsContract.Data.CONTACT_ID, ContactsContract.Data.MIMETYPE, ContactsContract.Data.DISPLAY_NAME)

        if (query == null || query.sortKey) {
            projection.add(getSortKeyProjection())
        }

        if (query == null || query.name) {
            projection.addAll(STRUCTURED_NAME_PROJECTION)
            selection.add(MIMETYPE_SELECTION)
            selectionArgs.add(ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
        }

        if (query == null || query.phoneNumber) {
            projection.addAll(PHONE_PROJECTION)
            selection.add(MIMETYPE_SELECTION)
            selectionArgs.add(ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
        }
        if (query == null || query.email) {
            projection.addAll(EMAIL_PROJECTION)
            selection.add(MIMETYPE_SELECTION)
            selectionArgs.add(ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE)
        }

        if (query == null || query.company) {
            projection.addAll(COMPANY_PROJECTION)
            selection.add(MIMETYPE_SELECTION)
            selectionArgs.add(ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE)
        }

        if (query == null || query.address) {
            projection.addAll(STRUCTURED_POSTAL_PROJECTION)
            selection.add(MIMETYPE_SELECTION)
            selectionArgs.add(ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE)
        }

        if (query == null || query.url) {
            projection.addAll(URL_PROJECTION)
            selection.add(MIMETYPE_SELECTION)
            selectionArgs.add(ContactsContract.CommonDataKinds.Website.CONTENT_ITEM_TYPE)
        }

        if (query == null || query.note) {
            projection.addAll(NOTE_PROJECTION)
            selection.add(MIMETYPE_SELECTION)
            selectionArgs.add(ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE)
        }

        if (query == null || query.instantMessage) {
            projection.addAll(IM_PROJECTION)
            selection.add(MIMETYPE_SELECTION)
            selectionArgs.add(ContactsContract.CommonDataKinds.Im.CONTENT_ITEM_TYPE)
        }

        var querySelection = TextUtils.join(" OR ", selection)

        if (query != null && !TextUtils.isEmpty(query.keywords)) {
            querySelection = ContactsContract.Contacts.DISPLAY_NAME + " LIKE ? "
            selectionArgs.clear()
            selectionArgs.add("%" + query.keywords + "%")
        }


        val cursor = contentResolver.query(ContactsContract.Data.CONTENT_URI, projection.toTypedArray(), querySelection, selectionArgs.toTypedArray(), null)



        cursor.moveToFirst()

        val map = linkedMapOf<String, Contact>()



        while (cursor.moveToNext()) {
            val id = cursor.getString(0)
            if (!map.containsKey(id)) {
                val disPlayName = cursor.getString(2)
                val sortKey = if (query == null || query.sortKey) cursor.getString(cursor.getColumnIndex(getSortKeyProjection())) else null

                val contact = Contact()
                contact.id = id
                contact.displayName = disPlayName

                contact.sortKey = sortKey ?: ""

                if (query != null && query.avatar) {
                    setContactAvatar(contact)
                }

                map[id] = contact
            }
            val contact = map[id] ?: throw RuntimeException()

            val mimeType = cursor.getString(1)


            when (mimeType) {
                ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE -> {//name
                    if (query == null || query.name) {
                        contact.givenName = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME))
                        contact.familyName = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME))
                        contact.middleName = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.StructuredName.MIDDLE_NAME))
                        contact.namePrefix = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.StructuredName.PREFIX))
                        contact.nameSuffix = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.StructuredName.SUFFIX))
                    }
                }
                ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE -> {//phone
                    if (query == null || query.phoneNumber) {
                        val phoneNumber = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER))
                        val type = cursor.getInt(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.TYPE))
                        val label = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.LABEL))
                        val typeLabel = ContactsContract.CommonDataKinds.Phone.getTypeLabel(resources, type, label)
                        contact.phones.add(LabelValue(typeLabel.toString(), phoneNumber))
                    }

                }
                ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE -> {//email
                    if (query == null || query.email) {
                        val email = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Email.ADDRESS))
                        val type = cursor.getInt(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Email.TYPE))
                        val label = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Email.LABEL))
                        val typeLabel = ContactsContract.CommonDataKinds.Email.getTypeLabel(resources, type, label)
                        contact.emails.add(LabelValue(typeLabel.toString(), email))
                    }
                }
                ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE -> {//company
                    if (query == null || query.company) {
                        contact.organization = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Organization.COMPANY))
                        contact.jobTitle = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Organization.TITLE))
                    }
                }
                ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE -> {//address
                    if (query == null || query.address) {
                        val formattedAddress = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.StructuredPostal.FORMATTED_ADDRESS))
                                ?: ""
                        val addressType = cursor.getInt(cursor.getColumnIndex(ContactsContract.CommonDataKinds.StructuredPostal.TYPE))
                        val label = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.StructuredPostal.LABEL))
                                ?: ""
                        val typeLabel = ContactsContract.CommonDataKinds.StructuredPostal.getTypeLabel(resources, addressType, label)
                        val country = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.StructuredPostal.COUNTRY))
                                ?: ""
                        val state = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.StructuredPostal.REGION))
                                ?: ""
                        val city = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.StructuredPostal.CITY))
                                ?: ""
                        val street = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.StructuredPostal.STREET))
                                ?: ""
                        val postcode = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.StructuredPostal.POSTCODE))
                                ?: ""
                        contact.addresses.add(PostalAddress(typeLabel.toString(), formattedAddress, country, state, city, street, postcode))
                    }
                }
                ContactsContract.CommonDataKinds.Website.CONTENT_ITEM_TYPE -> {//url
                    if (query == null || query.url) {
                        val url = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Website.URL))
                        contact.urls.add(LabelValue("", url))
                    }
                }
                ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE -> {
                    if (query == null || query.note) {
                        contact.note = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Note.NOTE))
                    }
                }
                ContactsContract.CommonDataKinds.Im.CONTENT_ITEM_TYPE -> {
                    if (query == null || query.instantMessage) {
                        val value = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Im.DATA))
                        val protocol = cursor.getInt(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Im.PROTOCOL))
                        val customProtocol = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Im.CUSTOM_PROTOCOL))
                        val typeLabel = ContactsContract.CommonDataKinds.Im.getProtocolLabel(resources, protocol, customProtocol)
                        contact.instantMessages.add(LabelValue(typeLabel.toString(), value))
                    }
                }
            }

        }

        cursor.close()


        val list = map.map { it.value.toMap() }
        val arrayList = arrayListOf<HashMap<String, Any?>>()
        arrayList.addAll(list)



        return arrayList


    }


    private fun setContactAvatar(contact: Contact) {
        val contactUri = ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, Integer.parseInt(contact.id).toLong())
        val photoUri = Uri.withAppendedPath(contactUri, ContactsContract.Contacts.Photo.CONTENT_DIRECTORY)
        val avatarCursor = contentResolver.query(photoUri,
                arrayOf(ContactsContract.Contacts.Photo.PHOTO), null, null, null)
        if (avatarCursor != null && avatarCursor.moveToFirst()) {
            val avatar = avatarCursor.getBlob(0)
            contact.avatar = avatar
            avatarCursor.close()
        }
    }


    companion object {
        val COMPANY_PROJECTION = arrayOf(ContactsContract.CommonDataKinds.Organization.COMPANY, ContactsContract.CommonDataKinds.Organization.TITLE)
        val STRUCTURED_NAME_PROJECTION = arrayOf(ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME,
                ContactsContract.CommonDataKinds.StructuredName.MIDDLE_NAME,
                ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME,
                ContactsContract.CommonDataKinds.StructuredName.PREFIX,
                ContactsContract.CommonDataKinds.StructuredName.SUFFIX)
        val PHONE_PROJECTION = arrayOf(ContactsContract.CommonDataKinds.Phone.NUMBER,
                ContactsContract.CommonDataKinds.Phone.TYPE,
                ContactsContract.CommonDataKinds.Phone.LABEL)
        val EMAIL_PROJECTION = arrayOf(ContactsContract.CommonDataKinds.Email.ADDRESS, ContactsContract.CommonDataKinds.Email.TYPE, ContactsContract.CommonDataKinds.Email.LABEL)

        val STRUCTURED_POSTAL_PROJECTION = arrayOf(ContactsContract.CommonDataKinds.StructuredPostal.FORMATTED_ADDRESS,
                ContactsContract.CommonDataKinds.StructuredPostal.TYPE,
                ContactsContract.CommonDataKinds.StructuredPostal.LABEL,
                ContactsContract.CommonDataKinds.StructuredPostal.STREET,
                ContactsContract.CommonDataKinds.StructuredPostal.CITY,
                ContactsContract.CommonDataKinds.StructuredPostal.REGION,
                ContactsContract.CommonDataKinds.StructuredPostal.POSTCODE,
                ContactsContract.CommonDataKinds.StructuredPostal.COUNTRY
        )

        val URL_PROJECTION = arrayOf(ContactsContract.CommonDataKinds.Website.URL)

        val NOTE_PROJECTION = arrayOf(ContactsContract.CommonDataKinds.Note.NOTE)

        val IM_PROJECTION = arrayOf(ContactsContract.CommonDataKinds.Im.DATA, ContactsContract.CommonDataKinds.Im.PROTOCOL, ContactsContract.CommonDataKinds.Im.CUSTOM_PROTOCOL)

        const val MIMETYPE_SELECTION = ContactsContract.Data.MIMETYPE + " = ?"

        const val REQUEST_CODE_PICK_CONTACT = 22224
    }
}