# contacts_helper

help you manage contacts

#  Usage
Add this to your package's pubspec.yaml file:
```
contacts_helper:
      git:
        url: https://github.com/keluokeda/contacts_helper.git
```

Add the following keys to your Info.plist file, located in <project root>/ios/Runner/Info.plist
```
      <key>NSContactsUsageDescription</key>
      <string>This app requires contacts access to function properly.</string>
```
      
# Example
```
// Import package
import 'package:contacts_helper/contacts_helper.dart';

//Custom query
Query query = new Query(keywords: "han",sortKey: true,avatar: true,name: true,
phoneNumber: true,email: true,company: true,address: true,note: true,
instantMessage: true,url: true);

//Get all contacts
Iterable<Contact> contacts = await ContactsHelper.getContacts(query);

//Add contact
bool result = await ContactsHelper.insertContact(contact);

//Delete contact
bool result = await ContactsHelper.deleteContact(contactId);

//Get default phone labels,like iphone mobile work
Iterable<String> phoneLabels = await ContactsHelper.getPhoneLabels();

//Get default email labels,like work home iCloud
Iterable<String> emailLabels = await ContactsHelper.getEmailLabels();

//Get default url labels,like homepage home work
Iterable<String> urlLabels = await ContactsHelper.getUrlLabels();

//Get default address labels,like home work other
Iterable<String> addressLabels = await ContactsHelper.getAddressLabels();

//Get default IM labels,like Skype MSN QQ
Iterable<String> instantMessageLabels = await ContactsHelper.getInstantMessageLabels();

```
