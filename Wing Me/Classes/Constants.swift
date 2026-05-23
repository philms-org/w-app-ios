
import UIKit

class Constants {
    static let url = "https://app.wingme.app/v03/"
    static let appURL = "https://wingme.app/"
    static let deleteAccountURL = "https://app.wingme.app/delete_account"
    
    static var savedImages: [String: String] = [:]
    static var queueArray: [CustomCell] = []
    
    static var imagesDownloading = Int()
    
    static var beta = true
    
    static func getUID() -> String {
        if let device = UIDevice.current.identifierForVendor {
            return device.uuidString
        }
        return ""
    }
    
    static func deleteUserData() {
        UserDefaults.standard.removeObject(forKey: "Token")
        UserDefaults.standard.removeObject(forKey: "Sent")
        UserDefaults.standard.removeObject(forKey: "LocationID")
        UserDefaults.standard.removeObject(forKey: "LocationName")
        UserDefaults.standard.removeObject(forKey: "Setup")
        UserDefaults.standard.removeObject(forKey: "LastDate")
        UserDefaults.standard.removeObject(forKey: "LastLocationAlert")
        UserDefaults.standard.removeObject(forKey: "LastLocationNotification")
    }
    
    static let relashionships = [
        CustomCell.init(string1: "1", string2: "Single"),
        CustomCell.init(string1: "2", string2: "Dating"),
        CustomCell.init(string1: "3", string2: "In a Relationship"),
        CustomCell.init(string1: "4", string2: "Married"),
        CustomCell.init(string1: "5", string2: "Other")
    ]
    
    static let lookingFor = [
        CustomCell.init(string1: "Socializing",
                        emoji1: ("🚫", "None"),
                        emoji2: ("🌎", "Community"),
                        emoji3: ("👩🏻‍🤝‍👩🏾", "Close friends"),
                        emoji4: ("✈️", "Travel"),
                        progress: 0),
        
        CustomCell.init(string1: "Business",
                        emoji1: ("🚫", "None"),
                        emoji2: ("🤝", "Opportunities"),
                        emoji3: ("👩🏻‍🏫", "Mentorship"),
                        emoji4: ("🧠", "Personal Growth"),
                        progress: 0),
        
        CustomCell.init(string1: "Love",
                        emoji1: ("🚫", "None"),
                        emoji2: ("❤️", "Open to love"),
                        emoji3: ("🔓", "Taken"),
                        emoji4: ("🪩", "Fun"),
                        progress: 0)
    ]
    
    static func getLookingFor(datingID: String, socialisingID: String, networkingID: String) -> String {
        var string = String()
        
        let datingArray = ["🌎", "👩🏻‍🤝‍👩🏾", "✈️"]
        let socialisingArray = ["🤝", "👩🏻‍🏫", "🧠"]
        let networkingArray = ["❤️", "🔓", "🪩"]
        
        if let index = Int(datingID), index != 0 {
            string += "  " + datingArray[index - 1]
        }
        if let index = Int(socialisingID), index != 0 {
            string += "  " + socialisingArray[index - 1]
        }
        if let index = Int(networkingID), index != 0 {
            string += "  " + networkingArray[index - 1]
        }
        return string
    }
    
    static let coutriesDictionary = [
        "Abkhazia 1"                                   : "7840",
        "Abkhazia 2"                                   : "7940",
        "Afghanistan"                                  : "93",
        "Albania"                                      : "355",
        "Algeria"                                      : "213",
        "American Samoa"                               : "1684",
        "Andorra"                                      : "376",
        "Angola"                                       : "244",
        "Anguilla"                                     : "1264",
        "Antigua and Barbuda"                          : "1268",
        "Argentina"                                    : "54",
        "Armenia"                                      : "374",
        "Aruba"                                        : "297",
        "Ascension"                                    : "247",
        "Australia"                                    : "61",
        "Australian External Territories"              : "672",
        "Austria"                                      : "43",
        "Azerbaijan"                                   : "994",
        "Bahamas"                                      : "1242",
        "Bahrain"                                      : "973",
        "Bangladesh"                                   : "880",
        "Barbados"                                     : "1246",
        "Barbuda"                                      : "1268",
        "Belarus"                                      : "375",
        "Belgium"                                      : "32",
        "Belize"                                       : "501",
        "Benin"                                        : "229",
        "Bermuda"                                      : "1441",
        "Bhutan"                                       : "975",
        "Bolivia"                                      : "591",
        "Bosnia and Herzegovina"                       : "387",
        "Botswana"                                     : "267",
        "Brazil"                                       : "55",
        "British Indian Ocean Territory"               : "246",
        "British Virgin Islands"                       : "1284",
        "Brunei"                                       : "673",
        "Bulgaria"                                     : "359",
        "Burkina Faso"                                 : "226",
        "Burundi"                                      : "257",
        "Cambodia"                                     : "855",
        "Cameroon"                                     : "237",
        "Canada"                                       : "1",
        "Cape Verde"                                   : "238",
        "Cayman Islands"                               : "345",
        "Central African Republic"                     : "236",
        "Chad"                                         : "235",
        "Chile"                                        : "56",
        "China"                                        : "86",
        "Christmas Island"                             : "61",
        "Cocos-Keeling Islands"                        : "61",
        "Colombia"                                     : "57",
        "Comoros"                                      : "269",
        "Congo"                                        : "242",
        "Congo, Dem. Rep. of (Zaire)"                  : "243",
        "Cook Islands"                                 : "682",
        "Costa Rica"                                   : "506",
        "Croatia"                                      : "385",
        "Cuba"                                         : "53",
        "Curacao"                                      : "599",
        "Cyprus"                                       : "537",
        "Czech Republic"                               : "420",
        "Denmark"                                      : "45",
        "Diego Garcia"                                 : "246",
        "Djibouti"                                     : "253",
        "Dominica"                                     : "1767",
        "Dominican Republic 1"                         : "1809",
        "Dominican Republic 2"                         : "1829",
        "Dominican Republic 3"                         : "1849",
        "East Timor"                                   : "670",
        "Easter Island"                                : "56",
        "Ecuador"                                      : "593",
        "Egypt"                                        : "20",
        "El Salvador"                                  : "503",
        "Equatorial Guinea"                            : "240",
        "Eritrea"                                      : "291",
        "Estonia"                                      : "372",
        "Ethiopia"                                     : "251",
        "Falkland Islands"                             : "500",
        "Faroe Islands"                                : "298",
        "Fiji"                                         : "679",
        "Finland"                                      : "358",
        "France"                                       : "33",
        "French Antilles"                              : "596",
        "French Guiana"                                : "594",
        "French Polynesia"                             : "689",
        "Gabon"                                        : "241",
        "Gambia"                                       : "220",
        "Georgia"                                      : "995",
        "Germany"                                      : "49",
        "Ghana"                                        : "233",
        "Gibraltar"                                    : "350",
        "Greece"                                       : "30",
        "Greenland"                                    : "299",
        "Grenada"                                      : "1473",
        "Guadeloupe"                                   : "590",
        "Guam"                                         : "1671",
        "Guatemala"                                    : "502",
        "Guinea"                                       : "224",
        "Guinea-Bissau"                                : "245",
        "Guyana"                                       : "595",
        "Haiti"                                        : "509",
        "Honduras"                                     : "504",
        "Hong Kong SAR China"                          : "852",
        "Hungary"                                      : "36",
        "Iceland"                                      : "354",
        "India"                                        : "91",
        "Indonesia"                                    : "62",
        "Iran"                                         : "98",
        "Iraq"                                         : "964",
        "Ireland"                                      : "353",
        "Italy"                                        : "39",
        "Ivory Coast"                                  : "225",
        "Jamaica"                                      : "1876",
        "Japan"                                        : "81",
        "Jordan"                                       : "962",
        "Kazakhstan"                                   : "77",
        "Kenya"                                        : "254",
        "Kiribati"                                     : "686",
        "Kuwait"                                       : "965",
        "Kyrgyzstan"                                   : "996",
        "Laos"                                         : "856",
        "Latvia"                                       : "371",
        "Lebanon"                                      : "961",
        "Lesotho"                                      : "266",
        "Liberia"                                      : "231",
        "Libya"                                        : "218",
        "Liechtenstein"                                : "423",
        "Lithuania"                                    : "370",
        "Luxembourg"                                   : "352",
        "Macau SAR China"                              : "853",
        "Macedonia"                                    : "389",
        "Madagascar"                                   : "261",
        "Malawi"                                       : "265",
        "Malaysia"                                     : "60",
        "Maldives"                                     : "960",
        "Mali"                                         : "223",
        "Malta"                                        : "356",
        "Marshall Islands"                             : "692",
        "Martinique"                                   : "596",
        "Mauritania"                                   : "222",
        "Mauritius"                                    : "230",
        "Mayotte"                                      : "262",
        "Mexico"                                       : "52",
        "Micronesia"                                   : "691",
        "Midway Island"                                : "1808",
        "Moldova"                                      : "373",
        "Monaco"                                       : "377",
        "Mongolia"                                     : "976",
        "Montenegro"                                   : "382",
        "Montserrat"                                   : "1664",
        "Morocco"                                      : "212",
        "Myanmar"                                      : "95",
        "Namibia"                                      : "264",
        "Nauru"                                        : "674",
        "Nepal"                                        : "977",
        "Netherlands"                                  : "31",
        "Netherlands Antilles"                         : "599",
        "Nevis"                                        : "1869",
        "New Caledonia"                                : "687",
        "New Zealand"                                  : "64",
        "Nicaragua"                                    : "505",
        "Niger"                                        : "227",
        "Nigeria"                                      : "234",
        "Niue"                                         : "683",
        "Norfolk Island"                               : "672",
        "North Korea"                                  : "850",
        "Northern Mariana Islands"                     : "1670",
        "Norway"                                       : "47",
        "Oman"                                         : "968",
        "Pakistan"                                     : "92",
        "Palau"                                        : "680",
        "Palestinian Territory"                        : "970",
        "Panama"                                       : "507",
        "Papua New Guinea"                             : "675",
        "Paraguay"                                     : "595",
        "Peru"                                         : "51",
        "Philippines"                                  : "63",
        "Poland"                                       : "48",
        "Portugal"                                     : "351",
        "Puerto Rico 1"                                : "1787",
        "Puerto Rico 2"                                : "1939",
        "Qatar"                                        : "974",
        "Reunion"                                      : "262",
        "Romania"                                      : "40",
        "Russia"                                       : "7",
        "Rwanda"                                       : "250",
        "Samoa"                                        : "685",
        "San Marino"                                   : "378",
        "Saudi Arabia"                                 : "966",
        "Senegal"                                      : "221",
        "Serbia"                                       : "381",
        "Seychelles"                                   : "248",
        "Sierra Leone"                                 : "232",
        "Singapore"                                    : "65",
        "Slovakia"                                     : "421",
        "Slovenia"                                     : "386",
        "Solomon Islands"                              : "677",
        "South Africa"                                 : "27",
        "South Georgia and the South Sandwich Islands" : "500",
        "South Korea"                                  : "82",
        "Spain"                                        : "34",
        "Sri Lanka"                                    : "94",
        "Sudan"                                        : "249",
        "Suriname"                                     : "597",
        "Swaziland"                                    : "268",
        "Sweden"                                       : "46",
        "Switzerland"                                  : "41",
        "Syria"                                        : "963",
        "Taiwan"                                       : "886",
        "Tajikistan"                                   : "992",
        "Tanzania"                                     : "255",
        "Thailand"                                     : "66",
        "Timor Leste"                                  : "670",
        "Togo"                                         : "228",
        "Tokelau"                                      : "690",
        "Tonga"                                        : "676",
        "Trinidad and Tobago"                          : "1868",
        "Tunisia"                                      : "216",
        "Turkey"                                       : "90",
        "Turkmenistan"                                 : "993",
        "Turks and Caicos Islands"                     : "1649",
        "Tuvalu"                                       : "688",
        "Uganda"                                       : "256",
        "Ukraine"                                      : "380",
        "United Arab Emirates"                         : "971",
        "United Kingdom"                               : "44",
        "United States"                                : "1",
        "Uruguay"                                      : "598",
        "U.S. Virgin Islands"                          : "1340",
        "Uzbekistan"                                   : "998",
        "Vanuatu"                                      : "678",
        "Venezuela"                                    : "58",
        "Vietnam"                                      : "84",
        "Wake Island"                                  : "1808",
        "Wallis and Futuna"                            : "681",
        "Yemen"                                        : "967",
        "Zambia"                                       : "260",
        "Zanzibar"                                     : "255",
        "Zimbabwe"                                     : "263"
    ]
    
    static let flags: [String: String] = [
        "AD": "🇦🇩", "AE": "🇦🇪", "AF": "🇦🇫", "AG": "🇦🇬", "AI": "🇦🇮", "AL": "🇦🇱", "AM": "🇦🇲", "AO": "🇦🇴", "AQ": "🇦🇶", "AR": "🇦🇷", "AS": "🇦🇸",
        "AT": "🇦🇹", "AU": "🇦🇺", "AW": "🇦🇼", "AX": "🇦🇽", "AZ": "🇦🇿", "BA": "🇧🇦", "BB": "🇧🇧", "BD": "🇧🇩", "BE": "🇧🇪", "BF": "🇧🇫", "BG": "🇧🇬",
        "BH": "🇧🇭", "BI": "🇧🇮", "BJ": "🇧🇯", "BL": "🇧🇱", "BM": "🇧🇲", "BN": "🇧🇳", "BO": "🇧🇴", "BQ": "🇧🇶", "BR": "🇧🇷", "BS": "🇧🇸", "BT": "🇧🇹",
        "BV": "🇧🇻", "BW": "🇧🇼", "BY": "🇧🇾", "BZ": "🇧🇿", "CA": "🇨🇦", "CC": "🇨🇨", "CD": "🇨🇩", "CF": "🇨🇫", "CG": "🇨🇬", "CH": "🇨🇭", "CI": "🇨🇮",
        "CK": "🇨🇰", "CL": "🇨🇱", "CM": "🇨🇲", "CN": "🇨🇳", "CO": "🇨🇴", "CR": "🇨🇷", "CU": "🇨🇺", "CV": "🇨🇻", "CW": "🇨🇼", "CX": "🇨🇽", "CY": "🇨🇾",
        "CZ": "🇨🇿", "DE": "🇩🇪", "DJ": "🇩🇯", "DK": "🇩🇰", "DM": "🇩🇲", "DO": "🇩🇴", "DZ": "🇩🇿", "EC": "🇪🇨", "EE": "🇪🇪", "EG": "🇪🇬", "EH": "🇪🇭",
        "ER": "🇪🇷", "ES": "🇪🇸", "ET": "🇪🇹", "FI": "🇫🇮", "FJ": "🇫🇯", "FK": "🇫🇰", "FM": "🇫🇲", "FO": "🇫🇴", "FR": "🇫🇷", "GA": "🇬🇦", "GB": "🇬🇧",
        "GD": "🇬🇩", "GE": "🇬🇪", "GF": "🇬🇫", "GG": "🇬🇬", "GH": "🇬🇭", "GI": "🇬🇮", "GL": "🇬🇱", "GM": "🇬🇲", "GN": "🇬🇳", "GP": "🇬🇵", "GQ": "🇬🇶",
        "GR": "🇬🇷", "GS": "🇬🇸", "GT": "🇬🇹", "GU": "🇬🇺", "GW": "🇬🇼", "GY": "🇬🇾", "HK": "🇭🇰", "HM": "🇭🇲", "HN": "🇭🇳", "HR": "🇭🇷", "HT": "🇭🇹",
        "HU": "🇭🇺", "ID": "🇮🇩", "IE": "🇮🇪", "IM": "🇮🇲", "IN": "🇮🇳", "IO": "🇮🇴", "IQ": "🇮🇶", "IR": "🇮🇷", "IS": "🇮🇸", "IT": "🇮🇹", "JE": "🇯🇪",
        "JM": "🇯🇲", "JO": "🇯🇴", "JP": "🇯🇵", "KE": "🇰🇪", "KG": "🇰🇬", "KH": "🇰🇭", "KI": "🇰🇮", "KM": "🇰🇲", "KN": "🇰🇳", "KP": "🇰🇵", "KR": "🇰🇷",
        "KW": "🇰🇼", "KY": "🇰🇾", "KZ": "🇰🇿", "LA": "🇱🇦", "LB": "🇱🇧", "LC": "🇱🇨", "LI": "🇱🇮", "LK": "🇱🇰", "LR": "🇱🇷", "LS": "🇱🇸", "LT": "🇱🇹",
        "LU": "🇱🇺", "LV": "🇱🇻", "LY": "🇱🇾", "MA": "🇲🇦", "MC": "🇲🇨", "MD": "🇲🇩", "ME": "🇲🇪", "MF": "🇲🇫", "MG": "🇲🇬", "MH": "🇲🇭", "MK": "🇲🇰",
        "ML": "🇲🇱", "MM": "🇲🇲", "MN": "🇲🇳", "MO": "🇲🇴", "MP": "🇲🇵", "MQ": "🇲🇶", "MR": "🇲🇷", "MS": "🇲🇸", "MT": "🇲🇹", "MU": "🇲🇺", "MV": "🇲🇻",
        "MW": "🇲🇼", "MX": "🇲🇽", "MY": "🇲🇾", "MZ": "🇲🇿", "NA": "🇳🇦", "NC": "🇳🇨", "NE": "🇳🇪", "NF": "🇳🇫", "NG": "🇳🇬", "NI": "🇳🇮", "NL": "🇳🇱",
        "NO": "🇳🇴", "NP": "🇳🇵", "NR": "🇳🇷", "NU": "🇳🇺", "NZ": "🇳🇿", "OM": "🇴🇲", "PA": "🇵🇦", "PE": "🇵🇪", "PF": "🇵🇫", "PG": "🇵🇬", "PH": "🇵🇭",
        "PK": "🇵🇰", "PL": "🇵🇱", "PM": "🇵🇲", "PN": "🇵🇳", "PR": "🇵🇷", "PS": "🇵🇸", "PT": "🇵🇹", "PW": "🇵🇼", "PY": "🇵🇾", "QA": "🇶🇦", "RE": "🇷🇪",
        "RO": "🇷🇴", "RS": "🇷🇸", "RU": "🇷🇺", "RW": "🇷🇼", "SA": "🇸🇦", "SB": "🇸🇧", "SC": "🇸🇨", "SD": "🇸🇩", "SE": "🇸🇪", "SG": "🇸🇬", "SH": "🇸🇭",
        "SI": "🇸🇮", "SJ": "🇸🇯", "SK": "🇸🇰", "SL": "🇸🇱", "SM": "🇸🇲", "SN": "🇸🇳", "SO": "🇸🇴", "SR": "🇸🇷", "SS": "🇸🇸", "ST": "🇸🇹", "SV": "🇸🇻",
        "SX": "🇸🇽", "SY": "🇸🇾", "SZ": "🇸🇿", "TC": "🇹🇨", "TD": "🇹🇩", "TF": "🇹🇫", "TG": "🇹🇬", "TH": "🇹🇭", "TJ": "🇹🇯", "TK": "🇹🇰", "TL": "🇹🇱",
        "TM": "🇹🇲", "TN": "🇹🇳", "TO": "🇹🇴", "TR": "🇹🇷", "TT": "🇹🇹", "TV": "🇹🇻", "TW": "🇹🇼", "TZ": "🇹🇿", "UA": "🇺🇦", "UG": "🇺🇬", "UM": "🇺🇲",
        "US": "🇺🇸", "UY": "🇺🇾", "UZ": "🇺🇿", "VA": "🇻🇦", "VC": "🇻🇨", "VE": "🇻🇪", "VG": "🇻🇬", "VI": "🇻🇮", "VN": "🇻🇳", "VU": "🇻🇺", "WF": "🇼🇫",
        "WS": "🇼🇸", "YE": "🇾🇪", "YT": "🇾🇹", "ZA": "🇿🇦", "ZM": "🇿🇲", "ZW": "🇿🇼"
    ]
}
