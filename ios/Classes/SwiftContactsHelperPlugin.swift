import Flutter
import UIKit
import Contacts

@available(iOS 9.0, *)
public class SwiftContactsHelperPlugin: NSObject, FlutterPlugin {
    let contactsStore = CNContactStore()
    
    let phoneTypeLabels :[Pair]
    
    let emailTypeLabels:[Pair]
    
    let urlTypeLabels :[Pair]
    
    let addressTypeLabels:[Pair]
    
    
    let instantMessageTypeLabels:[Pair]
    
    public override init() {
        let phoneTypes = [CNLabelPhoneNumberiPhone,CNLabelPhoneNumberMobile,CNLabelPhoneNumberMain,CNLabelPhoneNumberHomeFax,CNLabelPhoneNumberWorkFax,CNLabelPhoneNumberOtherFax,CNLabelPhoneNumberPager]
        
        phoneTypeLabels = phoneTypes.map { (label) -> Pair in
            Pair(first: label, second:  CNLabeledValue<NSString>.localizedString(forLabel: label))
        }
        
        let emailTypes = [CNLabelHome,CNLabelWork,CNLabelEmailiCloud,CNLabelOther]
        
        emailTypeLabels = emailTypes.map({ (label) -> Pair in
            Pair(first: label, second:  CNLabeledValue<NSString>.localizedString(forLabel: label))
        })
        
        let urlTypes = [CNLabelHome,CNLabelWork,CNLabelURLAddressHomePage,CNLabelOther]
        
        urlTypeLabels = urlTypes.map({ (label) -> Pair in
            Pair(first: label, second:  CNLabeledValue<NSString>.localizedString(forLabel: label))
        })
        
        let addressTypes = [CNLabelHome,CNLabelWork,CNLabelOther]
        
        addressTypeLabels = addressTypes.map({ (label) -> Pair in
            Pair(first: label, second:  CNLabeledValue<NSString>.localizedString(forLabel: label))
        })
        
   
        
        
        let instantMessageTypes = [CNInstantMessageServiceAIM,CNInstantMessageServiceFacebook,CNInstantMessageServiceGaduGadu,CNInstantMessageServiceGoogleTalk,CNInstantMessageServiceICQ,CNInstantMessageServiceJabber,CNInstantMessageServiceMSN,CNInstantMessageServiceQQ,CNInstantMessageServiceSkype,CNInstantMessageServiceYahoo]
        
        instantMessageTypeLabels = instantMessageTypes.map({ (label) -> Pair in
            Pair(first: label, second:  CNLabeledValue<NSString>.localizedString(forLabel: label))
        })
        
        
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "github.com/keluokeda/contacts_helper", binaryMessenger: registrar.messenger())
        let instance = SwiftContactsHelperPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "getPhoneLabels" {
            result(phoneTypeLabels.map({ (pair) -> String in
                pair.second
            }))
        }else if call.method == "getEmailLabels"{
            result(emailTypeLabels.map({ (pair) -> String in
                pair.second
            }))
        }else if call.method == "getUrlLabels"{
            result(urlTypeLabels.map({ (pair) -> String in
                pair.second
            }))
        }else if call.method == "getAddressLabels"{
            result(addressTypeLabels.map({ (pair) -> String in
                pair.second
            }))
        }else if call.method == "getInstantMessageLabels"{
            result(instantMessageTypeLabels.map({ (pair) -> String in
                pair.second
            }))
        }
        else{
            contactsStore.requestAccess(for: .contacts) { (r, error) in
                if r{
                    if call.method == "getContacts"{
                        self.loadContacts(call: call, result: result)
                    }else if call.method == "deleteContact"{
                        result(self.deleteContact(id: call.arguments as? String))
                    }else if call.method == "insertContact"{
                        let contact = self.dictionaryToContact(dictionary: call.arguments as! [String : Any])
                        result(self.insertContact(contact: contact))
                    } else{
                        result(FlutterError(code: "notImplemented", message: "notImplemented", details: nil))
                    }
                }else{
                    let e = FlutterError(code: "no permission", message: "no permission", details: nil)
                    result(e)
                }
            }
        }
    }
    
    
    func loadContacts(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let argument = call.arguments as! [String:Any]
        
        let query = Query(argument: argument)
        
        let keys = NSMutableArray(object: CNContactFormatter.descriptorForRequiredKeys(for: .fullName))
        
        if query.avatar{
            keys.add(CNContactThumbnailImageDataKey)
        }
        
        if query.name{
            keys.add(CNContactGivenNameKey)
            keys.add(CNContactFamilyNameKey)
            keys.add(CNContactMiddleNameKey)
            keys.add(CNContactNameSuffixKey)
            keys.add(CNContactNamePrefixKey)
        }
        
        
        if query.phoneNumber {
            keys.add(CNContactPhoneNumbersKey)
        }
        
        if query.email{
            keys.add(CNContactEmailAddressesKey)
        }
        if query.company {
            keys.add(CNContactOrganizationNameKey)
            keys.add(CNContactDepartmentNameKey)
            keys.add(CNContactJobTitleKey)
        }
        if query.address {
            keys.add(CNContactPostalAddressesKey)
        }
        
        if query.note {
            keys.add(CNContactNoteKey)
        }
        if query.instantMessage {
            keys.add(CNContactInstantMessageAddressesKey)
        }
        if query.url{
            keys.add(CNContactUrlAddressesKey)
        }
        
        let fetchRequest = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        
        fetchRequest.sortOrder = CNContactSortOrder.familyName
        
        if !query.keywords.isEmpty {
            fetchRequest.predicate = CNContact.predicateForContacts(matchingName: query.keywords)
        }
        var contacts:[CNContact] = []
        
        do {
            try contactsStore.enumerateContacts(with: fetchRequest, usingBlock: { (contact, stop) in
                contacts.append(contact)
            })
        } catch  {
            print(error.localizedDescription)
        }
        
        var resultList:[[String:Any]] = []
        
        for contact in contacts {
            resultList.append(contactToDictionary(contact: contact, query: query))
        }
        
        result(resultList)
        
    }
    
    func deleteContact(id:String?) -> Bool{
        guard let identifier = id else {
            return false
        }
        
        let store = CNContactStore()
        let keys = [CNContactIdentifierKey as NSString]
        do{
            if let contact = try store.unifiedContact(withIdentifier: identifier, keysToFetch: keys).mutableCopy() as? CNMutableContact{
                let request = CNSaveRequest()
                request.delete(contact)
                try store.execute(request)
            }
        }
        catch{
            print(error.localizedDescription)
            return false;
        }
        return true;
    }
    
    func insertContact(contact : CNMutableContact) -> Bool {
        
        do{
            let saveRequest = CNSaveRequest()
            saveRequest.add(contact, toContainerWithIdentifier: nil)
            try contactsStore.execute(saveRequest)
        }
        catch {
            print(error.localizedDescription)
            return false
        }
        return true
    }
    
    func dictionaryToContact(dictionary : [String:Any]) -> CNMutableContact{
        let contact = CNMutableContact()
        
        contact.givenName = dictionary["givenName"] as? String ?? ""
        contact.familyName = dictionary["familyName"] as? String ?? ""
        contact.middleName = dictionary["middleName"] as? String ?? ""
        contact.namePrefix = dictionary["namePrefix"] as? String ?? ""
        contact.nameSuffix = dictionary["nameSuffix"] as? String ?? ""
        contact.organizationName = dictionary["organization"] as? String ?? ""
        contact.jobTitle = dictionary["jobTitle"] as? String ?? ""
        contact.departmentName = dictionary["departmentName"] as? String ?? ""
        contact.note = dictionary["note"] as? String ?? ""
//        contact.imageData = (dictionary["avatar"] as? FlutterStandardTypedData)?.data ?? Data()
        
        if let phoneNumbers = dictionary["phones"] as? [[String:String]]{
            for phone in phoneNumbers where phone["value"] != nil {
                contact.phoneNumbers.append(CNLabeledValue(label:getLabel(map:phone, list: phoneTypeLabels),value:CNPhoneNumber(stringValue:phone["value"]!)))
                
            }
        }
        
        //Emails
        if let emails = dictionary["emails"] as? [[String:String]]{
            for email in emails where  email["value"] != nil{
                
                contact.emailAddresses.append(CNLabeledValue(label:getLabel(map:email, list: emailTypeLabels), value:email["value"]! as NSString))
            }
        }
        
        //url
        if let urls = dictionary["urls"] as? [[String:String]] {
            for url in urls where url["value"] != nil{
                contact.urlAddresses.append(CNLabeledValue(label: getLabel(map: url, list: urlTypeLabels), value: url["value"]! as NSString))
            }
        }
        
        //IM
        if let instantMessages = dictionary["instantMessages"] as? [[String:String]] {
            for instantMessage in instantMessages where instantMessage["value"] != nil{
                contact.instantMessageAddresses.append(CNLabeledValue(label: getLabel(map: instantMessage, list: instantMessageTypeLabels), value: CNInstantMessageAddress(username: instantMessage["value"]!, service: "")))
            }
        }
        
       
        
        //Postal addresses
        if let postalAddresses = dictionary["addresses"] as? [[String:String]]{
            for postalAddress in postalAddresses{
                let newAddress = CNMutablePostalAddress()
                newAddress.street = postalAddress["street"] ?? ""
                newAddress.city = postalAddress["city"] ?? ""
                newAddress.postalCode = postalAddress["postcode"] ?? ""
                newAddress.country = postalAddress["country"] ?? ""
                newAddress.state = postalAddress["state"] ?? ""
       
                contact.postalAddresses.append(CNLabeledValue(label:getLabel(map: postalAddress, list: addressTypeLabels), value:newAddress))
            }
        }
        
        return contact
    }
    
    
    func getLabel(map :[String:String],list:[Pair]) -> String {
        let label = map["label"] as String? ?? ""
        var result = label
        
        list.forEach { (pair) in
            if label == pair.second{
               result = pair.first
            }
        }
        return result
    }
    
    func contactToDictionary(contact:CNContact,query:Query) -> [String:Any] {
        var result = [String:Any]()
        result["id"] = contact.identifier
        let displayName = CNContactFormatter.string(from: contact, style: CNContactFormatterStyle.fullName) ?? ""
        result["displayName"] = displayName
        
        if query.avatar{
            if let avatarData = contact.thumbnailImageData {
                result["avatar"] = FlutterStandardTypedData(bytes: avatarData)
            }
        }
        
        if query.name {
            result["familyName"] = contact.familyName
            result["givenName"] = contact.givenName
            result["middleName"] = contact.middleName
            result["namePrefix"] = contact.namePrefix
            result["nameSuffix"] = contact.nameSuffix
        }
        
        if query.sortKey{
            result["sortKey"] = getFirstLetterFromString(familyName: displayName)
        }
        
        if query.phoneNumber {
            var phoneNumbers = [[String:String]]()
            
            for phone in contact.phoneNumbers{
                var phoneDictionary = [String:String]()
                
                phoneDictionary["label"] = CNLabeledValue<NSString>.localizedString(forLabel: phone.label!)
                phoneDictionary["value"] = phone.value.stringValue
                
                phoneNumbers.append(phoneDictionary)
            }
            
            result["phones"] = phoneNumbers
        }
        
        if query.email {
            var emailAddresses = [[String:String]]()
            for email in contact.emailAddresses{
                var emailDictionary = [String:String]()
                emailDictionary["value"] = String(email.value)
                emailDictionary["label"] = CNLabeledValue<NSString>.localizedString(forLabel: email.label!)
                
                emailAddresses.append(emailDictionary)
            }
            
            result["emails"] = emailAddresses
        }
        
        if query.company{
            result["organization"] = contact.organizationName
            result["departmentName"] = contact.departmentName
            result["jobTitle"] = contact.jobTitle
        }
        
        if query.address{
            var postalAddresses = [[String:String]]()
            for address in contact.postalAddresses{
                var addressDictionary = [String:String]()
                addressDictionary["label"] = CNLabeledValue<NSString>.localizedString(forLabel: address.label!)
                addressDictionary["street"] = address.value.street
                addressDictionary["city"] = address.value.city
                addressDictionary["postcode"] = address.value.postalCode
                addressDictionary["state"] = address.value.state
                addressDictionary["country"] = address.value.country
                
                postalAddresses.append(addressDictionary)
            }
            result["addresses"] = postalAddresses
        }
        
        if query.note{
            result["note"] = contact.note
        }
        
        if query.url {
            var urls = [[String:String]]()
            
            for url in contact.urlAddresses{
                var urlDictionary = [String:String]()
                urlDictionary["label"] = CNLabeledValue<NSString>.localizedString(forLabel: url.label!)
                
                urlDictionary["value"] = String(url.value)
                urls.append(urlDictionary)
            }
            
            result["urls"] = urls
        }
        
        if query.instantMessage {
            var instantMessages = [[String:String]]()
            
            for instantMessage in contact.instantMessageAddresses{
                var instantMessageDictionary = [String:String]()
                instantMessageDictionary["label"] = CNLabeledValue<NSString>.localizedString(forLabel: instantMessage.label!)
                
                instantMessageDictionary["value"] = instantMessage.value.username
                instantMessages.append(instantMessageDictionary)
            }
            
            result["instantMessages"] = instantMessages
        }
        
        return result
        
    }
    
    func getFirstLetterFromString(familyName: String) -> (String) {
        if familyName.isEmpty {
            return ""
        }
        
        
        let mutableString = NSMutableString.init(string: familyName)
        
        CFStringTransform(mutableString as CFMutableString, nil, kCFStringTransformToLatin, false)
        
        let pinyinString = mutableString.folding(options: String.CompareOptions.diacriticInsensitive, locale: NSLocale.current)
        
        let strPinYin = polyphoneStringHandle(nameString: familyName, pinyinString: pinyinString).uppercased()
        
        let firstString = String(strPinYin[..<strPinYin.index(strPinYin.startIndex, offsetBy:1)])
        //            strPinYin.substring(to: strPinYin.index(strPinYin.startIndex, offsetBy:1))
        let regexA = "^[A-Z]$"
        let predA = NSPredicate.init(format: "SELF MATCHES %@", regexA)
        return predA.evaluate(with: firstString) ? firstString : "#"
    }
    
    /// 多音字处理
    func polyphoneStringHandle(nameString:String, pinyinString:String) -> String {
        if nameString.hasPrefix("长") {return "chang"}
        if nameString.hasPrefix("沈") {return "shen"}
        if nameString.hasPrefix("厦") {return "xia"}
        if nameString.hasPrefix("地") {return "di"}
        if nameString.hasPrefix("重") {return "chong"}
        
        return pinyinString;
    }
    
}

struct Pair {
    let first:String
    let second:String
    
    init(first:String,second:String) {
        self.first = first
        self.second = second
    }

}

struct Query {
    var keywords:String
    var sortKey:Bool
    var name :Bool
    var avatar:Bool
    var phoneNumber:Bool
    var email:Bool
    var company:Bool
    var address:Bool
    var note:Bool
    var instantMessage:Bool
    var url:Bool
    
    init(argument : [String:Any]) {
        keywords = argument["keywords"] as! String
        sortKey = argument["sortKey"] as! Bool
        name = argument["name"] as! Bool
        avatar = argument["avatar"] as! Bool
        phoneNumber = argument["phoneNumber"] as!Bool
        email = argument["email"] as! Bool
        company = argument["company"] as! Bool
        address = argument["address"] as!Bool
        note = argument["note"] as! Bool
        instantMessage = argument["instantMessage"] as! Bool
        url = argument["url"] as! Bool
    }
    
}
