import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class ContactsHelper {
  static const MethodChannel _channel =
  const MethodChannel('github.com/keluokeda/contacts_helper');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<Iterable<Contact>> getContacts(Query query) async {
    Iterable contacts = await _channel.invokeMethod(
        "getContacts", query == null ? new Query().toMap() : query.toMap());
    return contacts.map((value) => new Contact.fromMap(value));
  }

  static Future<bool> deleteContact(String contactId) async {
    return await _channel.invokeMethod(
        "deleteContact", contactId);
  }

  static Future<bool> insertContact(Contact contact) async {
    return await _channel.invokeMethod("insertContact", contact.toMap());
  }

  static Future<Iterable<String>> getPhoneLabels() async {
    Iterable iterable = await _channel.invokeMethod("getPhoneLabels");
    return iterable.map((v) => v.toString());
  }

  static Future<Iterable<String>> getEmailLabels() async {
    Iterable iterable = await _channel.invokeMethod("getEmailLabels");
    return iterable.map((v) => v.toString());
  }

  static Future<Iterable<String>> getUrlLabels() async {
    Iterable iterable = await _channel.invokeMethod("getUrlLabels");
    return iterable.map((v) => v.toString());
  }

  static Future<Iterable<String>> getAddressLabels() async {
    Iterable iterable = await _channel.invokeMethod("getAddressLabels");
    return iterable.map((v) => v.toString());
  }

  static Future<Iterable<String>> getInstantMessageLabels() async {
    Iterable iterable = await _channel.invokeMethod("getInstantMessageLabels");
    return iterable.map((v) => v.toString());
  }
}

class Query {
  String keywords;
  bool sortKey;
  bool avatar;
  bool name;
  bool phoneNumber;
  bool email;

  //contains organization ,job title,department name(iOS only)
  bool company;
  bool address;
  bool note;

  //IM
  bool instantMessage;
  bool url;


  Query(
      {this.keywords = "", this.sortKey = true, this.avatar = false, this.name = true, this.phoneNumber = true,
        this.email = true, this.company = true, this.address = true, this.note = true, this.instantMessage = true,
        this.url = true});


  Map toMap() {
    assert(sortKey != null);
    assert(avatar != null);
    assert(name != null);
    assert(phoneNumber != null);
    assert(email != null);
    assert(company != null);
    assert(address != null);
    assert(note != null);
    assert(instantMessage != null);
    assert(url != null);

    return {
      "keywords": keywords == null ? "" : keywords,
      "sortKey": sortKey,
      "avatar": avatar,
      "name": name,
      "phoneNumber": phoneNumber,
      "email": email,
      "company": company,
      "address": address,
      "note": note,
      "instantMessage": instantMessage,
      "url": url,
    };
  }


}

class LabelValue {
  String label;
  String value;

  LabelValue.fromMap(Map map){
    label = map["label"];
    value = map["value"];
  }


  LabelValue();

  @override
  String toString() {
    return 'LabelValue{label: $label, value: $value}';
  }

  static Map _toMap(LabelValue l) => {"label": l.label, "value": l.value};
}


class PostalAddress {
  String label;
  String formattedAddress;
  String country;
  String state;
  String city;
  String street;
  String postcode;

  PostalAddress.fromMap(Map map){
    label = map["label"];
    formattedAddress = map["formattedAddress"];
    country = map["country"];
    state = map["state"];
    city = map["city"];
    street = map["street"];
    postcode = map["postcode"];
  }


  PostalAddress();

  static Map _toMap(PostalAddress address) =>
      {
        "label": address.label,
        "street": address.street,
        "city": address.city,
        "postcode": address.postcode,
        "state": address.state,
        "country": address.country
      };

  @override
  String toString() {
    return 'PostalAddress{label: $label, formattedAddress: $formattedAddress, country: $country, state: $state, city: $city, street: $street, postcode: $postcode}';
  }


}

class Contact {
  String id;
  String displayName;
  String sortKey;
  String familyName;
  String givenName;
  String middleName;
  String namePrefix;
  String nameSuffix;
  List<LabelValue> phones = [];
  List<LabelValue> emails = [];
  List<LabelValue> urls = [];
  List<PostalAddress> addresses = [];
  List<LabelValue> instantMessages = [];

  String organization;
  String jobTitle;
  String departmentName; //iOS only
  String note;

  Uint8List avatar;

  Contact.fromMap(Map map){
    id = map["id"];
    displayName = map["displayName"];
    sortKey = map["sortKey"];
    familyName = map["familyName"];
    givenName = map["givenName"];
    middleName = map["middleName"];
    namePrefix = map["namePrefix"];
    nameSuffix = map["nameSuffix"];
    organization = map["organization"];
    jobTitle = map["jobTitle"];
    departmentName = map["departmentName"];
    note = map["note"];
    avatar = map["avatar"];


    Iterable<LabelValue> phoneList = (map["phones"] as Iterable)?.map((value) =>
    new LabelValue.fromMap(value));
    if (phoneList != null) {
      phoneList.forEach((value) {
        phones.add(value);
      });
    }


    Iterable<LabelValue> emailList = (map["emails"] as Iterable)?.map((value) =>
    new LabelValue.fromMap(value));
    if (emailList != null) {
      emailList.forEach((value) {
        emails.add(value);
      });
    }


    Iterable<LabelValue> urlList = (map["urls"] as Iterable)?.map((value) =>
    new LabelValue.fromMap(value));
    if (urlList != null) {
      urlList.forEach((value) {
        urls.add(value);
      });
    }

    Iterable<
        LabelValue> instantMessageList = (map["instantMessages"] as Iterable)
        ?.map((value) =>
    new LabelValue.fromMap(value));
    if (instantMessageList != null) {
      instantMessageList.forEach((value) {
        instantMessages.add(value);
      });
    }

    Iterable<PostalAddress> addressList = (map["addresses"] as Iterable)?.map((
        value) =>
    new PostalAddress.fromMap(value));

    if (addressList != null) {
      addressList.forEach((value) {
        addresses.add(value);
      });
    }
//    emails =
//        (map["emails"] as Iterable)?.map((value) =>
//        new LabelValue.fromMap(value));

//    urls = (map["urls"] as Iterable)?.map((value) =>
//    new LabelValue.fromMap(value));
//
//    instantMessages = (map["instantMessages"] as Iterable)?.map((value) =>
//    new LabelValue.fromMap(value));
//
//    addresses =
//        (map["addresses"] as Iterable)?.map((value) =>
//        new PostalAddress.fromMap(
//            value));
  }

  Contact();

  Map toMap() {
    var _emails = [];
    for (LabelValue email in emails ?? []) {
      _emails.add(LabelValue._toMap(email));
    }
    var _phones = [];
    for (LabelValue phone in phones ?? []) {
      _phones.add(LabelValue._toMap(phone));
    }
    var _addresses = [];
    for (PostalAddress address in addresses ?? []) {
      _addresses.add(PostalAddress._toMap(address));
    }

    var _urls = [];
    for (LabelValue url in urls ?? []) {
      _urls.add(LabelValue._toMap(url));
    }

    var _instantMessages = [];
    for (LabelValue im in instantMessages ?? []) {
      _instantMessages.add(LabelValue._toMap(im));
    }

//    print("phones = $_phones");

    return {
      "id": id,
      "displayName": displayName,
      "givenName": givenName,
      "middleName": middleName,
      "familyName": familyName,
      "namePrefix": namePrefix,
      "nameSuffix": nameSuffix,

      "avatar": avatar,

      "organization": organization,
      "departmentName": departmentName,
      "jobTitle": jobTitle,

      "note": note,

      "emails": _emails,
      "phones": _phones,
      "addresses": _addresses,
      "urls": _urls,
      "instantMessages": _instantMessages
    };
  }


  @override
  String toString() {
    return 'Contact{id: $id, displayName: $displayName, sortKey: $sortKey, familyName: $familyName, givenName: $givenName, middleName: $middleName, namePrefix: $namePrefix, nameSuffix: $nameSuffix, phones: $phones, emails: $emails, urls: $urls, addresses: $addresses, instantMessages: $instantMessages, organization: $organization, jobTitle: $jobTitle, departmentName: $departmentName, note: $note, avatar: $avatar}';
  }


}
