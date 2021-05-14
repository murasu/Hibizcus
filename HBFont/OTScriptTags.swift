//
//  OTScriptTags.swift
//
//  Created by Muthu Nedumaran on 28/2/21.
//

//  Taken from : https://docs.microsoft.com/en-us/typography/opentype/spec/scripttags

import Foundation

struct OTScriptTags {
    let scripts : [String : String] = [
        "adlm" : "Adlam",
        "aghb" : "Caucasian Albanian",
        "ahom" : "Ahom",
        "arab" : "Arabic",
        "armi" : "Imperial Aramaic",
        "armn" : "Armenian",
        "avst" : "Avestan",
        "bali" : "Balinese",
        "bamu" : "Bamum",
        "bass" : "Bassa Vah",
        "batk" : "Batak",
        "beng" : "Bengali",
        "bhks" : "Bhaiksuki",
        "bng2" : "Bengali v.2",
        "bopo" : "Bopomofo",
        "brah" : "Brahmi",
        "brai" : "Braille",
        "bugi" : "Buginese",
        "buhd" : "Buhid",
        "byzm" : "Byzantine Music",
        "cakm" : "Chakma",
        "cans" : "Canadian Syllabics",
        "cari" : "Carian",
        "cham" : "Cham",
        "cher" : "Cherokee",
        "chrs" : "Chorasmian",
        "copt" : "Coptic",
        "cprt" : "Cypriot Syllabary",
        "cyrl" : "Cyrillic",
        "dev2" : "Devanagari v.2",
        "deva" : "Devanagari",
        "DFLT" : "Default",
        "diak" : "Dives Akuru",
        "dogr" : "Dogra",
        "dsrt" : "Deseret",
        "dupl" : "Duployan",
        "egyp" : "Egyptian Hieroglyphs",
        "elba" : "Elbasan",
        "elym" : "Elymaic",
        "ethi" : "Ethiopic",
        "geor" : "Georgian",
        "gjr2" : "Gujarati v.2",
        "glag" : "Glagolitic",
        "gong" : "Gunjala Gondi",
        "gonm" : "Masaram Gondi",
        "goth" : "Gothic",
        "gran" : "Grantha",
        "grek" : "Greek",
        "gujr" : "Gujarati",
        "gur2" : "Gurmukhi v.2",
        "guru" : "Gurmukhi",
        "hang" : "Hangul",
        "hani" : "CJK Ideographic",
        "hano" : "Hanunoo",
        "hatr" : "Hatran",
        "hebr" : "Hebrew",
        "hluw" : "Anatolian Hieroglyphs",
        "hmng" : "Pahawh Hmong",
        "hmnp" : "Nyiakeng Puachue Hmong",
        "hung" : "Old Hungarian",
        "ital" : "Old Italic",
        "jamo" : "Hangul Jamo",
        "java" : "Javanese",
        "kali" : "Kayah Li",
//        "kana" : "Hiragana",
        "kana" : "Katakana",
        "khar" : "Kharosthi",
        "khmr" : "Khmer",
        "khoj" : "Khojki",
        "kits" : "Khitan Small Script",
        "knd2" : "Kannada v.2",
        "knda" : "Kannada",
        "kthi" : "Kaithi",
        "lana" : "Tai Tham (Lanna)",
        "lao " : "Lao",
        "latn" : "Latin",
        "lepc" : "Lepcha",
        "limb" : "Limbu",
        "lina" : "Linear A",
        "linb" : "Linear B",
        "lisu" : "Lisu (Fraser)",
        "lyci" : "Lycian",
        "lydi" : "Lydian",
        "mahj" : "Mahajani",
        "maka" : "Makasar",
        "mand" : "Mandaic, Mandaean",
        "mani" : "Manichaean",
        "marc" : "Marchen",
        "math" : "Mathematical Alphanumeric Symbols",
        "medf" : "Medefaidrin (Oberi Okaime, Oberi Ɔkaimɛ)",
        "mend" : "Mende Kikakui",
        "merc" : "Meroitic Cursive",
        "mero" : "Meroitic Hieroglyphs",
        "mlm2" : "Malayalam v.2",
        "mlym" : "Malayalam",
        "modi" : "Modi",
        "mong" : "Mongolian",
        "mroo" : "Mro",
        "mtei" : "Meitei Mayek (Meithei, Meetei)",
        "mult" : "Multani",
        "musc" : "Musical Symbols",
        "mym2" : "Myanmar v.2",
        "mymr" : "Myanmar",
        "nand" : "Nandinagari",
        "narb" : "Old North Arabian",
        "nbat" : "Nabataean",
        "newa" : "Newa",
        "nko " : "N'Ko",
        "nshu" : "Nüshu",
        "ogam" : "Ogham",
        "olck" : "Ol Chiki",
        "orkh" : "Old Turkic, Orkhon Runic",
        "ory2" : "Odia v.2 (formerly Oriya v.2)",
        "orya" : "Odia (formerly Oriya)",
        "osge" : "Osage",
        "osma" : "Osmanya",
        "palm" : "Palmyrene",
        "pauc" : "Pau Cin Hau",
        "perm" : "Old Permic",
        "phag" : "Phags-pa",
        "phli" : "Inscriptional Pahlavi",
        "phlp" : "Psalter Pahlavi",
        "phnx" : "Phoenician",
        "plrd" : "Miao",
        "prti" : "Inscriptional Parthian",
        "rjng" : "Rejang",
        "rohg" : "Hanifi Rohingya",
        "runr" : "Runic",
        "samr" : "Samaritan",
        "sarb" : "Old South Arabian",
        "saur" : "Saurashtra",
        "sgnw" : "Sign Writing",
        "shaw" : "Shavian",
        "shrd" : "Sharada",
        "sidd" : "Siddham",
        "sind" : "Khudawadi",
        "sinh" : "Sinhala",
        "sogd" : "Sogdian",
        "sogo" : "Old Sogdian",
        "sora" : "Sora Sompeng",
        "soyo" : "Soyombo",
        "sund" : "Sundanese",
        "sylo" : "Syloti Nagri",
        "syrc" : "Syriac",
        "tagb" : "Tagbanwa",
        "takr" : "Takri",
        "tale" : "Tai Le",
        "talu" : "New Tai Lue",
        "taml" : "Tamil",
        "tang" : "Tangut",
        "tavt" : "Tai Viet",
        "tel2" : "Telugu v.2",
        "telu" : "Telugu",
        "tfng" : "Tifinagh",
        "tglg" : "Tagalog",
        "thaa" : "Thaana",
        "thai" : "Thai",
        "tibt" : "Tibetan",
        "tirh" : "Tirhuta",
        "tml2" : "Tamil v.2",
        "ugar" : "Ugaritic Cuneiform",
        "vai " : "Vai",
        "wara" : "Warang Citi",
        "wcho" : "Wancho",
        "xpeo" : "Old Persian Cuneiform",
        "xsux" : "Sumero-Akkadian Cuneiform",
        "yezi" : "Yezidi",
        "yi " : "Yi"
    ]
}

func scriptsFromUnicodes(unicodes: [UInt32]) -> [String] {
    var collectedScripts = [String]()
    
    // Collect the script tags for all unicodes in array
    var tagcounts = [String : Int]()
    for unicode in unicodes {
        let tag = scriptTagForUnicode(unicode: unicode)
        if tag != "" {
            if tagcounts[tag] != nil {
                tagcounts[tag]! += 1
            }
            else {
                tagcounts[tag] = 0
            }
        }
    }
    
    // Only pick those with > 10 entries
    let scriptTags = OTScriptTags()
    for tagcount in tagcounts {
        if tagcount.value >= 10 {
            collectedScripts.append( scriptTags.scripts[tagcount.key]! )
        }
    }
    
    return collectedScripts
}

func scriptTagForUnicode(unicode: UInt32) -> String {
    //TODO: Need a better structure to hold this data which can then
    //      include all of SA, SEA and Indonesian scripts
    var script = ""
    
    if (unicode >= 0x0980 && unicode <= 0x09FF) {
        script = "beng"
    }
    else if (unicode >= 0x11000 && unicode <= 0x1107F) {
        script = "brah"
    }
    else if (unicode >= 0x11100 && unicode <= 0x1114F ) {
        script = "cakm"
    }
    else if (unicode >= 0x0900 && unicode <= 0x097F) || (unicode >= 0xA8E0 && unicode <= 0xA8FF) {
        script = "deva"
    }
    else if (unicode >= 0x11300 && unicode <= 0x1137F ) {
        script = "gran"
    }
    else if (unicode >= 0x0A80 && unicode <= 0x0AFF ) {
        script = "gujr"
    }
    else if (unicode >= 0x0A00 && unicode <= 0x0A7F ) {
        script = "guru"
    }
    else if (unicode >= 0x0C80 && unicode <= 0x0CFF ) {
        script = "knda"
    }
    else if (unicode >= 0x0D00 && unicode <= 0x0D7F ) {
        script = "mlym"
    }
    else if (unicode >= 0xABC0 && unicode <= 0xABFF) || (unicode >= 0xAAE0 && unicode <= 0xAAFF) {
        script = "mtei"
    }
    else if (unicode >= 0x119A0 && unicode <= 0x119FF ) {
        script = "nand"
    }
    else if (unicode >= 0x1C50 && unicode <= 0x1C7F ) {
        script = "olck"
    }
    else if (unicode >= 0x0B00 && unicode <= 0x0B7F ) {
        script = "orya"
    }
    else if (unicode >= 0xA880 && unicode <= 0xA8DF ) {
        script = "saur"
    }
    else if (unicode >= 0x11180 && unicode <= 0x111DF ) {
        script = "shrd"
    }
    else if (unicode >= 0x11580 && unicode <= 0x115FF ) {
        script = "sidd"
    }
    else if (unicode >= 0x0D80 && unicode <= 0x0DFF) || (unicode >= 0x111E0 && unicode <= 0x111FF) {
        script = "sinh"
    }
    else if (unicode >= 0x0B80 && unicode <= 0x0BFF) || (unicode >= 0x11FC0 && unicode <= 0x11FFF) {
        script = "taml"
    }
    else if (unicode >= 0x0C00 && unicode <= 0x0C7F ) {
        script = "telu"
    }
    else if (unicode >= 0x0780 && unicode <= 0x07BF ) {
        script = "thaa"
    }
    else if (unicode >= 0x11480 && unicode <= 0x114DF ) {
        script = "tirh"
    }
    else if (unicode >= 0xAA00 && unicode <= 0xAA5F ) {
        script = "cham"
    }
    else if (unicode >= 0x1780 && unicode <= 0x17FF) || (unicode >= 0x19E0 && unicode <= 0x19FF) {
        script = "khmr"
    }
    else if (unicode >= 0x0E80 && unicode <= 0x0EFF ) {
        script = "lao "
    }
    else if (unicode >= 0x1000 && unicode <= 0x109F) || (unicode >= 0xAA60 && unicode <= 0xAA7F) || (unicode >= 0xA9E0 && unicode <= 0xA9FF){
        script = "mymr"
    }
    else if (unicode >= 0x1A20 && unicode <= 0x1AAF ) {
        script = "lana"
    }
    else if (unicode >= 0x0E00 && unicode <= 0x0E7F ) {
        script = "thai"
    }
    else if (unicode >= 0x1B00 && unicode <= 0x1B7F ) {
        script = "bali"
    }
    else if (unicode >= 0x1BC0 && unicode <= 0x1BFF ) {
        script = "batk"
    }
    else if (unicode >= 0x1A00 && unicode <= 0x1A1F ) {
        script = "bugi"
    }
    else if (unicode >= 0xA980 && unicode <= 0xA9DF ) {
        script = "java"
    }
    else if (unicode >= 0x11EE0 && unicode <= 0x11EFF ) {
        script = "maka"
    }
    else if (unicode >= 0xA930 && unicode <= 0xA95F ) {
        script = "rjng"
    }
    else if (unicode >= 0x1B80 && unicode <= 0x1BBF ) {
        script = "sund"
    }
    
    return script
}
