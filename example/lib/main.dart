import 'dart:async';

import 'package:contacts_helper/contacts_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(new MaterialApp(home: new MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {


  Iterable<Contact> _contacts;


  Query query = new Query();


  @override
  initState() {
    super.initState();

    loadContacts();
  }

  loadContacts() async {
    var list;

    print("start query");

    try {
      list = await ContactsHelper.getContacts(query);
    } on PlatformException catch (e) {
      print(e);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _contacts = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Contacts"),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.refresh), onPressed: () {
            setState(() {
              _contacts = null;
            });

            loadContacts();
          }),
          new IconButton(
              icon: new Icon(Icons.more_vert), onPressed: getQueryParameters),
          new IconButton(icon: new Icon(Icons.add), onPressed: () {
            toContactDetailView(null);
          })
        ],
      ),
      body: _contacts == null ? new Center(
          child: new CircularProgressIndicator()) : _buildContactListView(),
    );
  }

  getQueryParameters() async {
    query = await Navigator.push(
        context, new MaterialPageRoute(builder: (_) => new QueryParameters()));

    setState(() {
      _contacts = null;
    });
    loadContacts();
  }


  Widget _buildContactListView() {
    return new ListView.builder(itemBuilder: (_, position) {
      Contact c = _contacts.elementAt(position);
      return new ListTile(
        leading: c.avatar != null ? new CircleAvatar(
          backgroundImage: new MemoryImage(c.avatar),) : new CircleAvatar(
          child: new Text(c.sortKey != null ? c.sortKey : c.displayName[0]),),
        title: new Text(c.displayName),
        onTap: () {
          toContactDetailView(c);
        },
      );
    }, itemCount: _contacts == null ? 0 : _contacts.length,);
  }


  toContactDetailView(Contact contact) async {
    Contact result = await Navigator.push(context, new MaterialPageRoute(
        builder: (_) => new ContactDetail(contact: contact,)));

    if (result == null) { //delete

      setState(() {
        _contacts = null;
      });
      loadContacts();
    }
  }
}

class QueryParameters extends StatefulWidget {
  @override
  _QueryParametersState createState() => new _QueryParametersState();
}

class _QueryParametersState extends State<QueryParameters>
    with AutomaticKeepAliveClientMixin {
  Query query = new Query();

  TextEditingController _controller = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Query paramaters"),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.done), onPressed: () {
            query.keywords = _controller.text;
            Navigator.pop(context, query);
          })
        ],
      ),
      body: new ListView(
        children: <Widget>[
          new ListTile(
            title: new TextFormField(
              decoration: new InputDecoration(hintText: "Keywords"),
              controller: _controller,),
          ),
          new SwitchListTile(value: query.sortKey,
            onChanged: (v) {
              setState(() {
                query.sortKey = v;
              });
            },
            title: new Text("Contain sort key"),),
          new SwitchListTile(value: query.avatar,
            onChanged: (v) {
              setState(() {
                query.avatar = v;
              });
            },
            title: new Text("Contain avatar"),),
          new SwitchListTile(value: query.name,
            onChanged: (v) {
              setState(() {
                query.name = v;
              });
            },
            title: new Text("Contain name"),
            subtitle: new Text("Always contain display name"),),
          new SwitchListTile(value: query.phoneNumber,
            onChanged: (v) {
              setState(() {
                query.phoneNumber = v;
              });
            },
            title: new Text("Contains phone number"),),
          new SwitchListTile(value: query.email,
            onChanged: (v) {
              setState(() {
                query.email = v;
              });
            },
            title: new Text("Contains email"),),
          new SwitchListTile(
            value: query.company,
            onChanged: (v) {
              setState(() {
                query.company = v;
              });
            },
            title: new Text("Contain company"),
            subtitle: new Text("organization,department name and job title"),),

          new SwitchListTile(value: query.address,
            onChanged: (v) {
              setState(() {
                query.address = v;
              });
            },
            title: new Text("Contains postal address"),),

          new SwitchListTile(value: query.note,
            onChanged: (v) {
              setState(() {
                query.note = v;
              });
            },
            title: new Text("Contain note"),),

          new SwitchListTile(value: query.instantMessage,
            onChanged: (v) {
              setState(() {
                query.instantMessage = v;
              });
            },
            title: new Text("Contains IM"),
            subtitle: new Text("Like MSN Skype"),),

          new SwitchListTile(value: query.url,
            onChanged: (v) {
              setState(() {
                query.url = v;
              });
            },
            title: new Text("Contains URL"),),
        ],
      ),
    );
  }

  // TODO: implement wantKeepAlive
  @override
  bool get wantKeepAlive => true;
}


class ContactDetail extends StatefulWidget {
  final Contact contact;


  ContactDetail({this.contact});

  @override
  _ContactInfoState createState() => new _ContactInfoState();
}

const start_index = 10;

class _ContactInfoState extends State<ContactDetail> {


  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();


  Contact contact;

  bool _editable;

  List<String> _phoneLabels = [];

  List<String> _emailLabels = [];

  List<String> _urlLabels = [];

  List<String> _addressLabels = [];

  List<String> _instantMessageLabels = [];

  TextEditingController _givenNameController = new TextEditingController();

  TextEditingController _middleNameController = new TextEditingController();

  TextEditingController _familyNameController = new TextEditingController();

  TextEditingController _namePrefixController = new TextEditingController();

  TextEditingController _nameSuffixController = new TextEditingController();

  TextEditingController _organizationController = new TextEditingController();

  TextEditingController _departmentController = new TextEditingController();

  TextEditingController _jobTitleController = new TextEditingController();

  TextEditingController _noteController = new TextEditingController();

  @override
  void initState() {
    super.initState();
    _editable = widget.contact == null;

    initData();

    _givenNameController.addListener(() {
      contact.givenName = _givenNameController.text;
    });

    _middleNameController.addListener(() {
      contact.middleName = _middleNameController.text;
    });

    _familyNameController.addListener(() {
      contact.familyName = _familyNameController.text;
    });

    _namePrefixController.addListener(() {
      contact.namePrefix = _namePrefixController.text;
    });

    _nameSuffixController.addListener(() {
      contact.nameSuffix = _nameSuffixController.text;
    });

    _organizationController.addListener(() {
      contact.organization = _organizationController.text;
    });

    _departmentController.addListener(() {
      contact.departmentName = _departmentController.text;
    });

    _jobTitleController.addListener(() {
      contact.jobTitle = _jobTitleController.text;
    });

    _noteController.addListener(() {
      contact.note = _noteController.text;
    });
  }


  initData() async {
    Iterable<String> list = await ContactsHelper.getPhoneLabels();
    list.forEach((value) => _phoneLabels.add(value));

    list = await ContactsHelper.getEmailLabels();
    list.forEach((value) => _emailLabels.add(value));

    list = await ContactsHelper.getUrlLabels();

    list.forEach((value) => _urlLabels.add(value));

    list = await ContactsHelper.getAddressLabels();

    list.forEach((value) => _addressLabels.add(value));

    list = await ContactsHelper.getInstantMessageLabels();

    list.forEach((value) => _instantMessageLabels.add(value));
    contact = widget.contact == null ? new Contact() : widget.contact;

    _givenNameController.text = contact.givenName;
    _middleNameController.text = contact.middleName;
    _familyNameController.text = contact.familyName;
    _namePrefixController.text = contact.namePrefix;
    _nameSuffixController.text = contact.nameSuffix;
    _organizationController.text = contact.organization;
    _departmentController.text = contact.departmentName;
    _jobTitleController.text = contact.jobTitle;
    _noteController.text = contact.note;

    setState(() {
//      print(contact);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text(
            widget.contact == null ? "Create new contact" : widget.contact
                .displayName),
        actions: widget.contact == null
            ? _buildNewContactActions()
            : _buildPreViewActions(),
      ),
      body: contact == null
          ? new Center(child: new CircularProgressIndicator())
          : _buildContactView(),
    );
  }


  Widget _buildContactView() {
    //fix delete bug
//    String key = new DateTime.now().millisecondsSinceEpoch.toString();
//    return new Form(
//        key: _formKey,
//        child: new ListView.builder(
////            key: new Key(key),
//            itemCount: getListViewCount(),
//            itemBuilder: (_, position) => _buildListItem(position)));

//    return _buildContentWidgets();

    return _buildContentView1();
  }

  Widget _buildContentView1() {
    return new ListView(
      children: <Widget>[
        _buildAvatar(),
        _buildGivenNameForm(),
        _buildMiddleNameForm(),
        _buildFamilyNameForm(),
        _buildNamePrefixForm(),
        _buildNameSuffixForm(),
        _buildOrganizationForm(),
        _buildDepartmentNameForm(),
        _buildJobTitleForm(),
        new LabelValueView(labels: _phoneLabels,
          type: "phone",
          labelValues: contact.phones,
          editable: _editable,),
        new LabelValueView(labels: _emailLabels,
          type: "email",
          labelValues: contact.emails,
          editable: _editable,),
        new LabelValueView(labels: _urlLabels,
          type: "url",
          labelValues: contact.urls,
          editable: _editable,),
        new AddressView(labels: _addressLabels,addresses: contact.addresses,editable: _editable,),
        new LabelValueView(labels: _instantMessageLabels,
          type: "IM",
          labelValues: contact.instantMessages,
          editable: _editable,),
      ],
    );
  }

  void onDataChanged() {
    setState(() {

    });
  }


  Widget _buildContentWidgets() {
    return new SingleChildScrollView(
      child: new Form(
        key: _formKey,
        child: new Column(
          children: <Widget>[
            _buildAvatar(),
            _buildGivenNameForm(),
            _buildMiddleNameForm(),
            _buildFamilyNameForm(),
            _buildNamePrefixForm(),
            _buildNameSuffixForm(),
            _buildOrganizationForm(),
            _buildDepartmentNameForm(),
            _buildJobTitleForm(),
            _buildNoteForm(),
            _buildPhoneWidgets(),
            _buildEmailWidgets(),
            _buildUrlWidgets(),
            _buildAddressWidgets(),
            _buildIMWidgets()
          ],
        ),
      ),
    );
  }


  Widget _buildPhoneWidgets() {
    if (getPhoneCount() == 0) {
      return new Divider();
    }
    List<Widget> list = contact.phones.map((labelValue) {
      return _buildLabelValueSection(
          labelValue, true, Icons.call, TextInputType.phone, "phone",
          contact.phones);
    }).toList();


    return new Column(
      key: new Key(getKey("phone")),
      children: list,
    );
  }

  Widget _buildEmailWidgets() {
    if (getEmailCount() == 0) {
      return new Divider();
    }
    List<Widget> list = contact.emails.map((labelValue) {
      return _buildLabelValueSection(
          labelValue, true, Icons.email, TextInputType.emailAddress, "email",
          contact.emails);
    }).toList();

    return new Column(
      key: new Key(getKey("email")),
      children: list,
    );
  }


  Widget _buildUrlWidgets() {
    if (getUrlCount() == 0) {
      return new Divider();
    }

    List<Widget> list = contact.urls.map((labelValue) {
      if (_urlLabels.isEmpty) { //android
        return new ListTile(
          leading:
          _buildLeading(Icons.web),
          title: new TextFormField(initialValue: labelValue.value,
            keyboardType: TextInputType.url,
            decoration: new InputDecoration(hintText: "url"),),
          trailing: _editable ? new IconButton(
              icon: new Icon(Icons.clear), onPressed: () {
            removeLabelValue(labelValue, contact.urls);
          }) : null,
        );
      } else {
        return _buildLabelValueSection(
            labelValue, true, Icons.web, TextInputType.url, "url",
            contact.urls);
      }
    }).toList();

    return new Column(
      key: new Key(getKey("url")),
      children: list,
    );
  }

  Widget _buildAddressWidgets() {
    if (getAddressCount() == 0) {
      return new Divider();
    }

    List<Widget> list = contact.addresses.map((address) {
      return _buildAddressWidget(true, address);
    }).toList();

    return new Column(
      key: new Key(getKey("address")),
      children: list,
    );
  }

  Widget _buildIMWidgets() {
    if (getIMCount() == 0) {
      return new Divider();
    }
    List<Widget> list = contact.instantMessages.map((labelValue) {
      return _buildLabelValueSection(
          labelValue, true, Icons.message, TextInputType.text, "IM",
          contact.instantMessages);
    }).toList();

    return new Column(
      key: new Key(getKey("IM")),
      children: list,
    );
  }

  String getKey(String prefix) {
    String time = new DateTime.now().millisecondsSinceEpoch.toString();
    return "$prefix $time";
  }


  Widget _buildListItem(int position) {
    if (position == 0) {
      return _buildAvatar();
    }
    if (position == 1) {
      return _buildGivenNameForm();
    } else if (position == 2) {
      return _buildMiddleNameForm();
    } else if (position == 3) {
      return _buildFamilyNameForm();
    } else if (position == 4) {
      return _buildNamePrefixForm();
    } else if (position == 5) {
      return _buildNameSuffixForm();
    } else if (position == 6) {
      return _buildOrganizationForm();
    } else if (position == 7) {
      return _buildDepartmentNameForm();
    } else if (position == 8) {
      return _buildJobTitleForm();
    } else if (position == 9) {
      return _buildNoteForm();
    } else
    if (position >= getPhoneStartIndex() && position <= getPhoneEndIndex()) {
      return _buildPhoneSection(position);
    } else
    if (position >= getEmailStartIndex() && position <= getEmailEndIndex()) {
      return _buildEmailSection(position);
    } else if (position >= getUrlStartIndex() && position <= getUrlEndIndex()) {
      return _buildUrlSection(position);
    } else if (position >= getAddressStartIndex() &&
        position <= getAddressEndIndex()) {
      return _buildAddressSection(position);
    } else if (position >= getIMStartIndex() && position <= getIMEndIndex()) {
      return _buildInstantMessageSection(position);
    }

    return null;
  }

  Widget _buildAvatar() {
    return new Container(
      decoration: new BoxDecoration(color: Colors.blueGrey),
      child: new SizedBox(
        height: 180.0,
        child: new Stack(
          children: <Widget>[
            new Align(
              alignment: Alignment.center,
              child: contact.avatar == null
                  ? new CircleAvatar(radius: 60.0,
                child: new Icon(
                  Icons.account_circle, size: 120.0, color: Colors.white,),
                backgroundColor: Colors.transparent,)
                  : new CircleAvatar(
                backgroundImage: new MemoryImage(contact.avatar),
                radius: 60.0,),
            ),
            new Align(
              alignment: Alignment.bottomRight,
              child: new IconButton(
                  icon: new Icon(Icons.camera_alt, color: Colors.white,),
                  onPressed: _editable ? takePhoto : null),
            )

          ],
        ),
      ),
    );
  }

  takePhoto() {

  }

  Widget _buildPhoneSection(int position) {
    int index = position - getPhoneStartIndex();

    LabelValue phone = contact.phones.elementAt(index);


    bool isFirst = position == getPhoneStartIndex();

    return _buildLabelValueSection(
        phone,
        isFirst,
        Icons.call,
        TextInputType.phone,
        "phone",
        contact.phones
    );
  }


  Widget _buildEmailSection(int position) {
    int index = position - getEmailStartIndex();

    LabelValue email = contact.emails.elementAt(index);


    bool isFirst = position == getEmailStartIndex();

    return _buildLabelValueSection(
        email,
        isFirst,
        Icons.email,
        TextInputType.emailAddress,
        "email",
        contact.emails
    );
  }

  Widget _buildUrlSection(int position) {
    int index = position - getUrlStartIndex();

    LabelValue url = contact.urls.elementAt(index);


    bool isFirst = position == getUrlStartIndex();

    if (_urlLabels.isEmpty) { //android
      return new ListTile(
        leading: isFirst
            ? _buildLeading(Icons.web)
            : _buildLeading(null),
        title: new TextFormField(initialValue: url.value,
          keyboardType: TextInputType.url,
          decoration: new InputDecoration(hintText: "url"),),
        trailing: _editable ? new IconButton(
            icon: new Icon(Icons.clear), onPressed: () {
          removeLabelValue(url, contact.urls);
        }) : null,
      );
    } else { //ios
      return _buildLabelValueSection(
          url,
          isFirst,
          Icons.web,
          TextInputType.url,
          "email",
          contact.urls
      );
    }
  }

  Widget _buildAddressSection(int position) {
    int index = position - getAddressStartIndex();

    PostalAddress address = contact.addresses.elementAt(index);
    bool isFirst = position == getAddressStartIndex();

    List<String> labels = _addressLabels.map((v) => v).toList();

    if (!labels.contains(address.label)) {
      labels.add(address.label);
    }

    return _buildAddressWidget(isFirst, address);
  }

  Column _buildAddressWidget(bool isFirst, PostalAddress address) {
    return new Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        new ListTile(
          leading: _buildLeading(isFirst ? Icons.location_on : null),
          title: new TextFormField(initialValue: address.country,
            decoration: new InputDecoration(hintText: "country"),
            enabled: false,),
          trailing: _editable ? new IconButton(
              icon: new Icon(Icons.clear), onPressed: () {
            setState(() {
              contact.addresses.remove(address);
            });
          }) : null,
        ),
        new ListTile(
          leading: _buildLeading(null),
          title: new TextFormField(initialValue: address.state,
            decoration: new InputDecoration(hintText: "state"),
            enabled: false,),
        ),
        new ListTile(
          leading: _buildLeading(null),
          title: new TextFormField(initialValue: address.city,
            decoration: new InputDecoration(hintText: "city"),
            enabled: false,),
        ),
        new ListTile(
          leading: _buildLeading(null),
          title: new TextFormField(initialValue: address.street,
            decoration: new InputDecoration(hintText: "street"),
            enabled: false,),
        ),
        new ListTile(
          leading: _buildLeading(null),
          title: new TextFormField(initialValue: address.postcode,
            decoration: new InputDecoration(hintText: "postcode"),
            enabled: false,),
        ),
        new ListTile(
          leading: _buildLeading(null),
          title: new Text(address.label),
        )
      ],
    );
  }

  Widget _buildInstantMessageSection(int position) {
    int index = position - getIMStartIndex();

    LabelValue labelValue = contact.instantMessages.elementAt(index);


    bool isFirst = position == getIMStartIndex();

    return _buildLabelValueSection(
        labelValue,
        isFirst,
        Icons.chat,
        TextInputType.text,
        "IM",
        contact.instantMessages
    );
  }

  Widget _buildLabelValueSection(LabelValue labelValue,
      bool isFirst, IconData icon, TextInputType keyboardType, String hint,
      List<LabelValue> sources) {
    return new Column(
      children: <Widget>[
        new ListTile(
          leading: isFirst
              ? _buildLeading(icon)
              : _buildLeading(null),
          title: new TextFormField(
            initialValue: labelValue.value,
            keyboardType: keyboardType,
            decoration: new InputDecoration(hintText: hint),
            enabled: false,),
          trailing: _editable ? new IconButton(
              icon: new Icon(Icons.clear), onPressed: () {
            removeLabelValue(labelValue, sources);
          }) : null,
        ),
        new ListTile(
          leading: _buildLeading(null),
          title: new Text(labelValue.label),
        )
      ],
    );
  }

  void removeLabelValue(LabelValue labelValue, List<LabelValue> sources) {
    setState(() {
      sources.remove(labelValue);
//      print("contact remove = $labelValue,contact = $contact");
    });
  }


  ListTile _buildNoteForm() {
    return new ListTile(
      leading: _buildLeading(Icons.comment),
      title: new TextFormField(
//          initialValue: contact.note,
        controller: _noteController,
        decoration: new InputDecoration(hintText: "note"), enabled: _editable,),
    );
  }


  ListTile _buildJobTitleForm() {
    return new ListTile(
      leading: _buildLeading(null),
      title: new TextFormField(
//          initialValue: contact.jobTitle,
        controller: _jobTitleController,
        enabled: _editable,
        onSaved: (s) => (contact.jobTitle = s),
        decoration: new InputDecoration(hintText: "job title"),
      ),
    );
  }

  ListTile _buildDepartmentNameForm() {
    return new ListTile(
      leading: _buildLeading(null),
      title: new TextFormField(
//          initialValue: contact.departmentName,
        controller: _departmentController,
        enabled: _editable,
        onSaved: (s) => (contact.departmentName = s),
        decoration: new InputDecoration(hintText: "department"),
      ),
    );
  }

  ListTile _buildOrganizationForm() {
    return new ListTile(
      leading: _buildLeading(Icons.group_work),
      title: new TextFormField(
//          initialValue: contact.organization,
        controller: _organizationController,
        enabled: _editable,
        onSaved: (s) => (contact.organization = s),
        decoration: new InputDecoration(hintText: "organization"),
      ),
    );
  }

  ListTile _buildNameSuffixForm() {
    return new ListTile(
      leading: _buildLeading(null),
      title: new TextFormField(
//          initialValue: contact.nameSuffix,
        controller: _nameSuffixController,
        enabled: _editable,
        onSaved: (s) => (contact.nameSuffix = s),
        decoration: new InputDecoration(hintText: "suffix"),
      ),
    );
  }

  ListTile _buildNamePrefixForm() {
    return new ListTile(
      leading: _buildLeading(null),
      title: new TextFormField(
//          initialValue: contact.namePrefix,
        controller: _namePrefixController,
        enabled: _editable,
        onSaved: (s) => (contact.namePrefix = s),
        decoration: new InputDecoration(hintText: "prefix"),
      ),
    );
  }

  ListTile _buildFamilyNameForm() {
    return new ListTile(
      leading: _buildLeading(null),
      title: new TextFormField(
//          initialValue: contact.familyName,
        controller: _familyNameController,
        enabled: _editable,
        onSaved: (s) => (contact.familyName = s),
        decoration: new InputDecoration(hintText: "family name"),
      ),
    );
  }

  ListTile _buildMiddleNameForm() {
    return new ListTile(
      leading: _buildLeading(null),
      title: new TextFormField(
//          initialValue: contact.middleName,
        controller: _middleNameController,
        enabled: _editable,
        onSaved: (s) => (contact.middleName = s),
        decoration: new InputDecoration(hintText: "middle name"),
      ),
    );
  }

  ListTile _buildGivenNameForm() {
    return new ListTile(
      leading: _buildLeading(Icons.account_circle),
      title: new TextFormField(
//          initialValue: contact.givenName,
        enabled: _editable,
        controller: _givenNameController,
        onSaved: (s) => (contact.givenName = s),
//        onFieldSubmitted: (s)=>(),
        decoration: new InputDecoration(hintText: "given name"),
      ),
    );
  }

  Widget _buildLeading(IconData iconData) {
    return new CircleAvatar(
      child: new Icon(iconData, color: Colors.grey, size: 26.0,),
      backgroundColor: Colors.transparent,);
  }

  int getListViewCount() {
    return start_index + getPhoneCount() + getEmailCount() + getUrlCount() +
        getAddressCount() + getIMCount();
  }


  int getPhoneCount() {
    return contact.phones == null ? 0 : contact.phones.length;
  }

  int getPhoneStartIndex() => getPhoneCount() == 0 ? -1 : start_index;

  int getPhoneEndIndex() =>
      getPhoneCount() == 0 ? -1 : getPhoneStartIndex() + getPhoneCount() - 1;


  int getEmailStartIndex() =>
      getEmailCount() == 0 ? -1 : start_index + getPhoneCount();

  int getEmailEndIndex() =>
      getEmailCount() == 0 ? -1 : getEmailStartIndex() + getEmailCount() - 1;

  int getEmailCount() {
    return contact.emails == null ? 0 : contact.emails.length;
  }

  int getUrlCount() => contact.urls == null ? 0 : contact.urls.length;

  int getUrlStartIndex() =>
      getUrlCount() == 0 ? -1 : start_index + getPhoneCount() + getEmailCount();

  int getUrlEndIndex() =>
      getUrlCount() == 0 ? -1 : getUrlStartIndex() + getUrlCount() - 1;

  int getAddressCount() =>
      contact.addresses == null ? 0 : contact.addresses.length;

  int getAddressStartIndex() =>
      getAddressCount() == 0 ? -1 : start_index + getPhoneCount() +
          getEmailCount() + getUrlCount();

  int getAddressEndIndex() =>
      getAddressCount() == 0 ? -1 : getAddressStartIndex() + getAddressCount() -
          1;

  int getIMCount() =>
      contact.instantMessages == null ? 0 : contact.instantMessages.length;

  int getIMStartIndex() =>
      getIMCount() == 0 ? -1 : start_index + getPhoneCount() + getEmailCount() +
          getUrlCount() + getAddressCount();

  int getIMEndIndex() =>
      getIMCount() == 0 ? -1 : getIMStartIndex() + getIMCount() - 1;

  void deleteContact() {
    showDialog<bool>(context: context, builder: (c) {
      return new AlertDialog(
        title: new Text("Delete this contact?"),
        actions: <Widget>[
          new FlatButton(onPressed: () {
            Navigator.pop(c, false);
          }, child: new Text("CANCEL")),
          new FlatButton(onPressed: () {
            Navigator.pop(c, true);
          }, child: new Text("DELETE")),
        ],
      );
    }).then((result) {
      if (result) {
        deleteContactById(contact.id);
      }
    });
  }


  deleteContactById(String contactId) async {
    bool result = await ContactsHelper.deleteContact(contactId);
    if (result) {
      Navigator.pop(context, null);
    } else {
      print("delete failed");
    }
  }

  void edit() {
    setState(() {
      _editable = !_editable;
    });
    _scaffoldKey.currentState.showSnackBar(
        new SnackBar(content: new Text("Not support")));
  }

  List<Widget> _buildPreViewActions() {
    return [
      new IconButton(icon: new Icon(Icons.delete), onPressed: deleteContact),
      new IconButton(icon: new Icon(Icons.edit), onPressed: edit)
    ];
  }

  List<Widget> _buildNewContactActions() {
    return [
      new IconButton(icon: new Icon(Icons.done), onPressed: () {
        insertContact();
      }),
      new PopupMenuButton<String>(
        itemBuilder: (_) {
          return ["phone", "email", "url", "address", "IM"].map((label) =>
          new PopupMenuItem<String>(child: new Text(label), value: label,))
              .toList();
        }, onSelected: (value) {
        insertItem(value);
      },),

    ];
  }

  insertItem(String type) {
    if ("address" == type) {
      insertAddress();
    } else {
      insertLabelValue(type);
    }
  }

  insertAddress() async {
    PostalAddress address = await Navigator.push(context, new MaterialPageRoute(
        builder: (_) => new AddAddressView(labels: _addressLabels,)));
    if (address != null) {
      setState(() {
        contact.addresses.add(address);
      });
    }
  }

  insertLabelValue(String type) async {
    LabelValue labelValue = await Navigator.push(
        context, new MaterialPageRoute(
        builder: (_) => new AddItemView(type: type, labels: getLabels(type),)));

    if (labelValue != null) {
      print("add item result $labelValue");
      insertLabelValueToContact(type, labelValue);
    }
  }

  insertLabelValueToContact(String type, LabelValue labelValue) {
    if ("phone" == type) {
      contact.phones.add(labelValue);
    } else if ("url" == type) {
      contact.urls.add(labelValue);
    } else if ("email" == type) {
      contact.emails.add(labelValue);
    } else if ("IM" == type) {
      contact.instantMessages.add(labelValue);
    }

//    print("contact = $contact");

    setState(() {

    });
  }

  List<String> getLabels(String type) {
    if ("phone" == type) {
      return _phoneLabels;
    } else if ("email" == type) {
      return _emailLabels;
    } else if ("IM" == type) {
      return _instantMessageLabels;
    } else if ("url" == type) {
      return _urlLabels;
    } else if ("address" == type) {
      return _addressLabels;
    }

    return [];
  }

  insertContact() async {
//    _formKey.currentState.save();

    print("insert contact = $contact");

    bool result = await ContactsHelper.insertContact(contact);
    print("insert result = $result");

    Navigator.pop(context);
  }
}

class NameSection extends StatefulWidget {
  final Contact contact;


  NameSection({this.contact});

  @override
  _NameSectionState createState() => new _NameSectionState();
}

class _NameSectionState extends State<NameSection> {
  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}


class AddItemView extends StatefulWidget {
  final String type;
  final List<String> labels;


  AddItemView({this.type, this.labels});

  @override
  _AddItemViewState createState() => new _AddItemViewState();
}

class _AddItemViewState extends State<AddItemView> {
  LabelValue labelValue = new LabelValue();

  TextEditingController _controller = new TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    if (widget.labels.isNotEmpty) {
      labelValue.label = widget.labels.elementAt(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Add ${widget.type}"),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.done), onPressed: () {
            labelValue.value = _controller.text;
            Navigator.pop(context, labelValue);
          })
        ],
      ),
      body: new Column(
        children: <Widget>[
          new ListTile(
            title: new TextFormField(
              decoration: new InputDecoration(hintText: widget.type),
              controller: _controller,),
          ),
          widget.labels.isNotEmpty ?
          new ListTile(
            title: new Row(
              children: <Widget>[
                new DropdownButton<String>(
                    value: labelValue.label,
                    items: widget.labels.map((label) {
                      return new DropdownMenuItem<String>(
                        child: new Text(label), value: label,);
                    }).toList(),
                    onChanged: (label) {
                      setState(() {
                        labelValue.label = label;
                      });
                    }),
              ],
            ),
          ) : new ListTile()
        ],
      ),
    );
  }
}

class LabelValueView extends StatefulWidget {
  final List<String> labels;
  final String type;
  final List<LabelValue> labelValues;
  final bool editable;


  LabelValueView({this.labels, this.type, this.labelValues, this.editable});

  @override
  _LabelValueViewState createState() => new _LabelValueViewState();
}

class _LabelValueViewState extends MyState<LabelValueView> {

  @override
  Widget build(BuildContext context) {
    List<Widget> list = widget.labelValues.map((v) =>
        _buildLabelValueSection(v)).toList();

    if (widget.editable) {
      list.add(_buildAddSection(insertLabelValue, "Add ${widget.type}"));
      list.add(new Divider());
    }


    return new Column(
      key: getKey(widget.type),
      children: list,
    );
  }


  Widget _buildLabelValueSection(LabelValue labelValue,) {
    List<Widget> list = [];

    list.add(new ListTile(
      leading:
      _buildLeading(getIcon()),
      title: new TextFormField(
        initialValue: labelValue.value,
        enabled: false,),
      trailing: widget.editable ? new IconButton(
          icon: new Icon(Icons.clear), onPressed: () {
        removeLabelValue(labelValue);
      }) : null,
    ));

    if (labelValue.label != null) {
      list.add(new ListTile(
        leading: _buildLeading(null),
        title: new Text(labelValue.label),
      ));
    }


    return new Column(
      children: list,
    );
  }

  IconData getIcon() {
    if (widget.type == "phone") {
      return Icons.call;
    } else if (widget.type == "email") {
      return Icons.email;
    } else if (widget.type == "url") {
      return Icons.web;
    }

    return Icons.message;
  }

  insertLabelValue() async {
    LabelValue labelValue = await Navigator.push(
        context, new MaterialPageRoute(
        builder: (_) =>
        new AddItemView(type: widget.type, labels: widget.labels,)));

    if (labelValue != null) {
      widget.labelValues.add(labelValue);
    }
  }


  removeLabelValue(LabelValue labelValue) {
    setState(() {
      widget.labelValues.remove(labelValue);
    });
  }
}

class AddressView extends StatefulWidget {
  final List<PostalAddress> addresses;
  final bool editable;
  final List<String> labels;


  AddressView({this.addresses, this.editable, this.labels});

  @override
  _AddressViewState createState() => new _AddressViewState();
}

class _AddressViewState extends MyState<AddressView> {


  @override
  Widget build(BuildContext context) {
    List<Widget> list = widget.addresses.map((address) =>
        _buildAddressWidget(address)).toList();

    if (widget.editable) {
      list.add(_buildAddSection(insertAddress, "Add address"));
      list.add(new Divider());
    }


    return new Column(
      children: list,
    );
  }

  Widget _buildAddressWidget(PostalAddress address) {
    return new Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        new ListTile(
          leading: _buildLeading(Icons.location_on),
          title: new TextFormField(initialValue: address.country,
            decoration: new InputDecoration(hintText: "country"),
            enabled: false,),
          trailing: widget.editable ? new IconButton(
              icon: new Icon(Icons.clear), onPressed: () {
            setState(() {
              widget.addresses.remove(address);
            });
          }) : null,
        ),
        new ListTile(
          leading: _buildLeading(null),
          title: new TextFormField(initialValue: address.state,
            decoration: new InputDecoration(hintText: "state"),
            enabled: false,),
        ),
        new ListTile(
          leading: _buildLeading(null),
          title: new TextFormField(initialValue: address.city,
            decoration: new InputDecoration(hintText: "city"),
            enabled: false,),
        ),
        new ListTile(
          leading: _buildLeading(null),
          title: new TextFormField(initialValue: address.street,
            decoration: new InputDecoration(hintText: "street"),
            enabled: false,),
        ),
        new ListTile(
          leading: _buildLeading(null),
          title: new TextFormField(initialValue: address.postcode,
            decoration: new InputDecoration(hintText: "postcode"),
            enabled: false,),
        ),
        new ListTile(
          leading: _buildLeading(null),
          title: new Text(address.label),
        )
      ],
    );
  }


  void insertAddress() async {
    PostalAddress address = await Navigator.push(context, new MaterialPageRoute(
        builder: (_) => new AddAddressView(labels: widget.labels,)));
    if (address != null) {
      widget.addresses.add(address);
    }
  }
}


class AddAddressView extends StatefulWidget {
  final List<String> labels;


  AddAddressView({this.labels});

  @override
  _AddAddressViewState createState() => new _AddAddressViewState();
}

class _AddAddressViewState extends State<AddAddressView> {

  PostalAddress address = new PostalAddress();

  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    address.label = widget.labels.elementAt(0);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Add Address"),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.done), onPressed: () {
            _formKey.currentState.save();

            Navigator.pop(context, address);
          })
        ],
      ),
      body: new Form(
        key: _formKey,
        child: new Column(
          children: <Widget>[
            new ListTile(
              title: new TextFormField(
                decoration: new InputDecoration(hintText: "country"),
                onSaved: (value) {
                  address.country = value;
                },
              ),
            ),
            new ListTile(
              title: new TextFormField(
                decoration: new InputDecoration(hintText: "state"),
                onSaved: (value) {
                  address.state = value;
                },
              ),
            ),
            new ListTile(
              title: new TextFormField(
                decoration: new InputDecoration(hintText: "city"),
                onSaved: (value) {
                  address.city = value;
                },
              ),
            ),
            new ListTile(
              title: new TextFormField(
                decoration: new InputDecoration(hintText: "street"),
                onSaved: (value) {
                  address.street = value;
                },
              ),
            ),
            new ListTile(
              title: new TextFormField(
                decoration: new InputDecoration(hintText: "postcode"),
                onSaved: (value) {
                  address.postcode = value;
                },
              ),
            ),
            new ListTile(
              title: new Row(
                children: <Widget>[
                  new DropdownButton<String>(
                      value: address.label,
                      items: widget.labels.map((label) {
                        return new DropdownMenuItem<String>(
                          child: new Text(label), value: label,);
                      }).toList(),
                      onChanged: (label) {
                        setState(() {
                          address.label = label;
                        });
                      }),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

}

abstract class MyState<T extends StatefulWidget> extends State<T> {
  final Color color = Colors.pink;


  Widget _buildLeading(IconData iconData) {
    return new CircleAvatar(
      child: new Icon(iconData, color: Colors.grey, size: 26.0,),
      backgroundColor: Colors.transparent,);
  }

  Widget _buildAddSection(VoidCallback callback, String text) {
    return new ListTile(
      title: new FlatButton.icon(onPressed: callback,
        icon: new Icon(Icons.add_circle_outline, color: color,),
        label: new Text(
          text, style: new TextStyle(color: color),),),
    );
  }

  Key getKey(String type) {
    String time = new DateTime.now().millisecondsSinceEpoch.toString();
    return new Key("$type $time");
  }
}





