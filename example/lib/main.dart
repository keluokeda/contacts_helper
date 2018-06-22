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

    print("contacts = $list");

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
          new IconButton(
              icon: Icon(Icons.import_contacts), onPressed: pickContact),
          new IconButton(
              icon: new Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _contacts = null;
                });

                loadContacts();
              }),
          new IconButton(
              icon: new Icon(Icons.more_vert), onPressed: getQueryParameters),
          new IconButton(
              icon: new Icon(Icons.add),
              onPressed: () {
                toContactDetailView(null);
              })
        ],
      ),
      body: _contacts == null
          ? new Center(child: new CircularProgressIndicator())
          : _buildContactListView(),
    );
  }

  pickContact() async {
    Contact contact = await ContactsHelper.pickContactPhone();

    print("pick result = $contact");
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
    return new ListView.builder(
      itemBuilder: (_, position) {
        Contact c = _contacts.elementAt(position);

        print("contact = $c");
        return new ListTile(
          leading: c.avatar != null
              ? new CircleAvatar(
                  backgroundImage: new MemoryImage(c.avatar),
                )
              : new CircleAvatar(
                  child: new Text(
                      c.sortKey != null ? c.sortKey : c.displayName[0]),
                ),
          title: new Text(c.displayName ?? "null"),
          onTap: () {
            toContactDetailView(c);
          },
        );
      },
      itemCount: _contacts == null ? 0 : _contacts.length,
    );
  }

  toContactDetailView(Contact contact) async {
    Contact result = await Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (_) => new ContactDetail(
                  contact: contact,
                )));

    if (result == null) {
      //delete

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
          new IconButton(
              icon: new Icon(Icons.done),
              onPressed: () {
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
              controller: _controller,
            ),
          ),
          new SwitchListTile(
            value: query.sortKey,
            onChanged: (v) {
              setState(() {
                query.sortKey = v;
              });
            },
            title: new Text("Contain sort key"),
          ),
          new SwitchListTile(
            value: query.avatar,
            onChanged: (v) {
              setState(() {
                query.avatar = v;
              });
            },
            title: new Text("Contain avatar"),
          ),
          new SwitchListTile(
            value: query.name,
            onChanged: (v) {
              setState(() {
                query.name = v;
              });
            },
            title: new Text("Contain name"),
            subtitle: new Text("Always contain display name"),
          ),
          new SwitchListTile(
            value: query.phoneNumber,
            onChanged: (v) {
              setState(() {
                query.phoneNumber = v;
              });
            },
            title: new Text("Contains phone number"),
          ),
          new SwitchListTile(
            value: query.email,
            onChanged: (v) {
              setState(() {
                query.email = v;
              });
            },
            title: new Text("Contains email"),
          ),
          new SwitchListTile(
            value: query.company,
            onChanged: (v) {
              setState(() {
                query.company = v;
              });
            },
            title: new Text("Contain company"),
            subtitle: new Text("organization,department name and job title"),
          ),
          new SwitchListTile(
            value: query.address,
            onChanged: (v) {
              setState(() {
                query.address = v;
              });
            },
            title: new Text("Contains postal address"),
          ),
          new SwitchListTile(
            value: query.note,
            onChanged: (v) {
              setState(() {
                query.note = v;
              });
            },
            title: new Text("Contain note"),
          ),
          new SwitchListTile(
            value: query.instantMessage,
            onChanged: (v) {
              setState(() {
                query.instantMessage = v;
              });
            },
            title: new Text("Contains IM"),
            subtitle: new Text("Like MSN Skype"),
          ),
          new SwitchListTile(
            value: query.url,
            onChanged: (v) {
              setState(() {
                query.url = v;
              });
            },
            title: new Text("Contains URL"),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class ContactDetail extends StatefulWidget {
  final Contact contact;

  ContactDetail({this.contact});

  @override
  _ContactInfoState createState() => new _ContactInfoState();
}

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

    print("$_urlLabels");

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text(widget.contact == null
            ? "Create new contact"
            : widget.contact.displayName),
        actions: widget.contact == null
            ? _buildNewContactActions()
            : _buildPreViewActions(),
      ),
      body: contact == null
          ? new Center(child: new CircularProgressIndicator())
          : _buildContentView(),
    );
  }

  Widget _buildContentView() {
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
        _buildNoteForm(),
        new LabelValueView(
          labels: _phoneLabels,
          type: "phone",
          labelValues: contact.phones,
          editable: _editable,
        ),
        new LabelValueView(
          labels: _emailLabels,
          type: "email",
          labelValues: contact.emails,
          editable: _editable,
        ),
        new LabelValueView(
          labels: _urlLabels,
          type: "url",
          labelValues: contact.urls,
          editable: _editable,
        ),
        new AddressView(
          labels: _addressLabels,
          addresses: contact.addresses,
          editable: _editable,
        ),
        new LabelValueView(
          labels: _instantMessageLabels,
          type: "IM",
          labelValues: contact.instantMessages,
          editable: _editable,
        ),
      ],
    );
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
                  ? new CircleAvatar(
                      radius: 60.0,
                      child: new Icon(
                        Icons.account_circle,
                        size: 120.0,
                        color: Colors.white,
                      ),
                      backgroundColor: Colors.transparent,
                    )
                  : new CircleAvatar(
                      backgroundImage: new MemoryImage(contact.avatar),
                      radius: 60.0,
                    ),
            ),
            new Align(
              alignment: Alignment.bottomRight,
              child: new IconButton(
                  icon: new Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                  ),
                  onPressed: _editable ? takePhoto : null),
            )
          ],
        ),
      ),
    );
  }

  takePhoto() {}

  ListTile _buildNoteForm() {
    return new ListTile(
      leading: _buildLeading(Icons.comment),
      title: new TextFormField(
        controller: _noteController,
        decoration: new InputDecoration(hintText: "note"),
        enabled: _editable,
      ),
    );
  }

  ListTile _buildJobTitleForm() {
    return new ListTile(
      leading: _buildLeading(null),
      title: new TextFormField(
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
      child: new Icon(
        iconData,
        color: Colors.grey,
        size: 26.0,
      ),
      backgroundColor: Colors.transparent,
    );
  }

  void deleteContact() {
    showDialog<bool>(
        context: context,
        builder: (c) {
          return new AlertDialog(
            title: new Text("Delete this contact?"),
            actions: <Widget>[
              new FlatButton(
                  onPressed: () {
                    Navigator.pop(c, false);
                  },
                  child: new Text("CANCEL")),
              new FlatButton(
                  onPressed: () {
                    Navigator.pop(c, true);
                  },
                  child: new Text("DELETE")),
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
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text("Not support")));
  }

  List<Widget> _buildPreViewActions() {
    return [
      new IconButton(icon: new Icon(Icons.delete), onPressed: deleteContact),
      new IconButton(icon: new Icon(Icons.edit), onPressed: edit)
    ];
  }

  List<Widget> _buildNewContactActions() {
    return [
      new IconButton(
          icon: new Icon(Icons.done),
          onPressed: () {
            insertContact();
          }),
    ];
  }

  insertContact() async {
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
          new IconButton(
              icon: new Icon(Icons.done),
              onPressed: () {
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
              controller: _controller,
            ),
          ),
          widget.labels.isNotEmpty
              ? new ListTile(
                  title: new Row(
                    children: <Widget>[
                      new DropdownButton<String>(
                          value: labelValue.label,
                          items: widget.labels.map((label) {
                            return new DropdownMenuItem<String>(
                              child: new Text(label),
                              value: label,
                            );
                          }).toList(),
                          onChanged: (label) {
                            setState(() {
                              labelValue.label = label;
                            });
                          }),
                    ],
                  ),
                )
              : new ListTile()
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
    List<Widget> list =
        widget.labelValues.map((v) => _buildLabelValueSection(v)).toList();

    if (widget.editable) {
      list.add(_buildAddSection(insertLabelValue, "Add ${widget.type}"));
      list.add(new Divider());
    }

    return new Column(
      key: getKey(widget.type),
      children: list,
    );
  }

  Widget _buildLabelValueSection(
    LabelValue labelValue,
  ) {
    List<Widget> list = [];

    list.add(new ListTile(
      leading: _buildLeading(getIcon()),
      title: new TextFormField(
        initialValue: labelValue.value,
        enabled: false,
      ),
      trailing: widget.editable
          ? new IconButton(
              icon: new Icon(Icons.clear),
              onPressed: () {
                removeLabelValue(labelValue);
              })
          : null,
    ));

    if (widget.labels.isNotEmpty) {
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
        context,
        new MaterialPageRoute(
            builder: (_) => new AddItemView(
                  type: widget.type,
                  labels: widget.labels,
                )));

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
    List<Widget> list = widget.addresses
        .map((address) => _buildAddressWidget(address))
        .toList();

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
          title: new TextFormField(
            initialValue: address.country,
            decoration: new InputDecoration(hintText: "country"),
            enabled: false,
          ),
          trailing: widget.editable
              ? new IconButton(
                  icon: new Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      widget.addresses.remove(address);
                    });
                  })
              : null,
        ),
        new ListTile(
          leading: _buildLeading(null),
          title: new TextFormField(
            initialValue: address.state,
            decoration: new InputDecoration(hintText: "state"),
            enabled: false,
          ),
        ),
        new ListTile(
          leading: _buildLeading(null),
          title: new TextFormField(
            initialValue: address.city,
            decoration: new InputDecoration(hintText: "city"),
            enabled: false,
          ),
        ),
        new ListTile(
          leading: _buildLeading(null),
          title: new TextFormField(
            initialValue: address.street,
            decoration: new InputDecoration(hintText: "street"),
            enabled: false,
          ),
        ),
        new ListTile(
          leading: _buildLeading(null),
          title: new TextFormField(
            initialValue: address.postcode,
            decoration: new InputDecoration(hintText: "postcode"),
            enabled: false,
          ),
        ),
        new ListTile(
          leading: _buildLeading(null),
          title: new Text(address.label),
        )
      ],
    );
  }

  void insertAddress() async {
    PostalAddress address = await Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (_) => new AddAddressView(
                  labels: widget.labels,
                )));
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
    super.initState();
    address.label = widget.labels.elementAt(0);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Add Address"),
        actions: <Widget>[
          new IconButton(
              icon: new Icon(Icons.done),
              onPressed: () {
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
                          child: new Text(label),
                          value: label,
                        );
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
      child: new Icon(
        iconData,
        color: Colors.grey,
        size: 26.0,
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildAddSection(VoidCallback callback, String text) {
    return new ListTile(
      title: new FlatButton.icon(
        onPressed: callback,
        icon: new Icon(
          Icons.add_circle_outline,
          color: color,
        ),
        label: new Text(
          text,
          style: new TextStyle(color: color),
        ),
      ),
    );
  }

  Key getKey(String type) {
    String time = new DateTime.now().millisecondsSinceEpoch.toString();
    return new Key("$type $time");
  }
}
