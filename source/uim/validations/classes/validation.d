module uim.validations.classes.validationx;

import uim.validations;

@safe:

/**
 * Validation Class. Used for validation of model data
 *
 * Offers different validation methods.
 */
class Validation {
    // Default locale
    const string DEFAULT_LOCALE = "en_US";

    // Same as operator.
    const string COMPARE_SAME = "==";

    // Not same as comparison operator.
    const string COMPARE_NOT_SAME = "!=";

    // Equal to comparison operator.
    const string COMPARE_EQUAL = "==";

    // Not equal to comparison operator.
    const string COMPARE_NOT_EQUAL = "!=";

    // Greater than comparison operator.
    const string COMPARE_GREATER = ">";

    // Greater than or equal to comparison operator.
    const string COMPARE_GREATER_OR_EQUAL = ">=";

    // Less than comparison operator.
    const string COMPARE_LESS = "<";

    // Less than or equal to comparison operator.
    const string COMPARE_LESS_OR_EQUAL = "<=";

    protected const string[] COMPARE_STRING = [
        self.COMPARE_EQUAL,
        self.COMPARE_NOT_EQUAL,
        self.COMPARE_SAME,
        self.COMPARE_NOT_SAME,
    ];

    // Datetime ISO8601 format
    const string DATETIME_ISO8601 = "iso8601";

    // Some complex patterns needed in multiple places
    protected static STRINGAA my_pattern = [
        "hostname": "(?:[_\p{L}0-9][-_\p{L}0-9]*\.)*(?:[\p{L}0-9][-\p{L}0-9]{0,62})\.(?:(?:[a-z]{2}\.)?[a-z]{2,})",
        "latitude": "[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?)",
        "longitude": "[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)",
    ];

    /**
     * Holds an array of errors messages set in this class.
     * These are used for debugging purposes
     */
    static array myerrors = [];

    /**
     * Checks that a string contains something other than whitespace
     *
     * Returns true if string contains something other than whitespace
     * Params:
     * Json valueToCheck Value to check
     */
    static bool isNotBlank(Json checkValue) {
        if (isEmpty(checkValue) && !isBool(checkValue) && !isNumeric(checkValue)) {
            return false;
        }
        return _check(checkValue, "/[^\s]+/m");
    }
    
    /**
     * Checks that a string contains only integer or letters.
     *
     * This method"s definition of letters and integers includes unicode characters.
     * Use `asciiAlphaNumeric()` if you want to exclude unicode.
     * Params:
     * Json valueToCheck Value to check
     */
    static bool isAlphaNumeric(Json checkValue) {
        if ((isEmpty(checkValue) && checkValue != "0") || !isScalar(checkValue)) {
            return false;
        }
        return self._check(checkValue, "/^[\p{Ll}\p{Lm}\p{Lo}\p{Lt}\p{Lu}\p{Nd}]+my/Du");
    }
    
    /**
     * Checks that a doesn"t contain any alpha numeric characters
     *
     * This method"s definition of letters and integers includes unicode characters.
     * Use `notAsciiAlphaNumeric()` if you want to exclude ascii only.
     */
    static bool isNotAlphaNumeric(Json checkValue) {
        return !alphaNumeric(checkValue);
    }
    
    /**
     * Checks that a string contains only ascii integer or letters.
     * Params:
     * Json valueToCheck Value to check
     */
    static bool isAsciiAlphaNumeric(Json checkValue) {
        if ((isEmpty(checkValue) && checkValue != "0") || !isScalar(checkValue)) {
            return false;
        }
        return self._check(valueToCheck, "/^[[:alnum:]]+my/");
    }

    // Checks that a doesn"t contain any non-ascii alpha numeric characters
    static bool isNotAsciiAlphaNumeric(Json checkValue) {
        return !asciiAlphaNumeric(checkValue);
    }
    
    /**
     * Checks that a string length is within specified range.
     * Spaces are included in the character count.
     * Returns true if string matches value min, max, or between min and max,
     * Params:
     * Json valueToCheck Value to check for length
     * @param int mymin Minimum value in range (inclusive)
     * @param int mymax Maximum value in range (inclusive)
     */
    static bool lengthBetween(Json checkValue, int minLength, int maxLength) {
        if (!isScalar(checkValue)) {
            return false;
        }
        auto length = checkValue.get!string.length;

        return length >= minLength && length <= maxLength;
    }
    
    /**
     * Validation of credit card numbers.
     * Returns true if creditcardNumber is in the proper credit card format.
     * Params:
     * Json creditcardNumber credit card number to validate
     * @param string[]|string mytype "all" may be passed as a string, defaults to fast which checks format of
     *    most major credit cards if an array is used only the values of the array are checked.
     *   Example: ["amex", "bankcard", "maestro"]
     * @param bool mydeep set to true this will check the Luhn algorithm of the credit card.
     * @param string|null myregex A custom regex, this will be used instead of the defined regex values.
     */
    static bool creditCard(
        Json checkValue,
        string[] mytype = "fast",
        bool mydeep = false,
        string myregex = null
    ) {
        if (!(isString(checkValue) || isInt(checkValue))) {
            return false;
        }
        auto myCheckValue = (string)checkValue.replace(["-", " "], "");
        if (mb_strlen(myCheckValue) < 13) {
            return false;
        }
        if (myregex !isNull && _check(myCheckValue, myregex)) {
            return !mydeep || luhn(myCheckValue);
        }
        auto mycards = [
            "all": [
                "amex": "/^3[47]\\d{13}my/",
                "bankcard": "/^56(10\\d\\d|022[1-5])\\d{10}my/",
                "diners": "/^(?:3(0[0-5]|[68]\\d)\\d{11})|(?:5[1-5]\\d{14})my/",
                "disc": "/^(?:6011|650\\d)\\d{12}my/",
                "electron": "/^(?:417500|4917\\d{2}|4913\\d{2})\\d{10}my/",
                "enroute": "/^2(?:014|149)\\d{11}my/",
                "jcb": "/^(3\\d{4}|2131|1800)\\d{11}my/",
                "maestro": "/^(?:5020|6\\d{3})\\d{12}my/",
                "mc": "/^(5[1-5]\\d{14})|(2(?:22[1-9]|2[3-9][0-9]|[3-6][0-9]{2}|7[0-1][0-9]|720)\\d{12})my/",
                "solo": "/^(6334[5-9][0-9]|6767[0-9]{2})\\d{10}(\\d{2,3})?my/",
                // phpcs:ignore Generic.Files.LineLength
                "switch": "/^(?:49(03(0[2-9]|3[5-9])|11(0[1-2]|7[4-9]|8[1-2])|36[0-9]{2})\\d{10}(\\d{2,3})?)|(?:564182\\d{10}(\\d{2,3})?)|(6(3(33[0-4][0-9])|759[0-9]{2})\\d{10}(\\d{2,3})?)my/",
                "visa": "/^4\\d{12}(\\d{3})?my/",
                "voyager": "/^8699[0-9]{11}my/",
            ],
            // phpcs:ignore Generic.Files.LineLength
            "fast": "/^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|6011[0-9]{12}|3(?:0[0-5]|[68][0-9])[0-9]{11}|3[47][0-9]{13})my/",
        ];

        if (isArray(mytype)) {
            foreach (mytype as myvalue) {
                myregex = mycards["all"][myvalue).toLower];

                if (_check(creditcardNumber, myregex)) {
                    return luhn(creditcardNumber);
                }
            }
        } elseif (mytype == "all") {
            foreach (mycards["all"] as myvalue) {
                myregex = myvalue;

                if (_check(myCheckValue, myregex)) {
                    return luhn(creditcardNumber);
                }
            }
        } else {
            myregex = mycards["fast"];

            if (_check(myCheckValue, myregex)) {
                return luhn(myCheckValue);
            }
        }
        return false;
    }
    
    /**
     * Used to check the count of a given value of type array or Countable.
     * Params:
     * Json valueToCheck The value to check the count on.
     * @param string myoperator Can be either a word or operand
     *   is greater >, is less <, greater or equal >=
     *   less or equal <=, is less <, equal to ==, not equal !=
     * @param int myexpectedCount The expected count value.
     */
    static bool checkNumElements(Json valueToCheck, string myoperator, int myexpectedCount) {
        if (!isArray(valueToCheck) && !cast(Countable)valueToCheck) {
            return false;
        }
        return self.comparison(count(valueToCheck), myoperator, myexpectedCount);
    }
    
    /**
     * Used to compare 2 numeric values.
     * Params:
     * Json mycheck1 The left value to compare.
     * @param string myoperator Can be one of following operator strings:
     *  ">", "<", ">=", "<=", "==", "!=", "==" and "!=". You can use one of
     *  the Validation.COMPARE_* constants.
     * @param Json mycheck2 The right value to compare.
     */
    static bool compare(Json mycheck1, string myoperator, Json mycheck2) {
        if (
            (!isNumeric(mycheck1) || !isNumeric(mycheck2)) &&
            !inArray(myoperator, COMPARE_STRING)
        ) {
            return false;
        }
        try {
            return match (myoperator) {
                COMPARE_GREATER: mycheck1 > mycheck2,
                COMPARE_LESS: mycheck1 < mycheck2,
                COMPARE_GREATER_OR_EQUAL: mycheck1 >= mycheck2,
                COMPARE_LESS_OR_EQUAL: mycheck1 <= mycheck2,
                COMPARE_EQUAL: mycheck1 == mycheck2,
                COMPARE_NOT_EQUAL: mycheck1 != mycheck2,
                COMPARE_SAME: mycheck1 == mycheck2,
                COMPARE_NOT_SAME: mycheck1 != mycheck2,
            };
        } catch (UnhandledMatchError) {
            myerrors ~= "You must define a valid myoperator parameter for Validation.comparison()";
        }
        return false;
    }
    
    /**
     * Compare one field to another.
     *
     * If both fields have exactly the same value this method will return true.
     * Params:
     * Json mycheck The value to find in myfield.
     * @param string myfield The field to check mycheck against. This field must be present in mycontext.
     * @param IData[string] mycontext The validation context.
     */
    static bool compareWith(Json mycheck, string myfield, array mycontext) {
        return self.compareFields(mycheck, myfield, COMPARE_SAME, mycontext);
    }
    
    /**
     * Compare one field to another.
     *
     * Return true if the comparison matches the expected result.
     * Params:
     * Json mycheck The value to find in myfield.
     * @param string myfield The field to check mycheck against. This field must be present in mycontext.
     * @param string myoperator Comparison operator. See Validation.comparison().
     * @param IData[string] mycontext The validation context.
     */
    static bool compareFields(Json mycheck, string myfield, string myoperator, array mycontext) {
        if (!isSet(mycontext["data"]) || !array_key_exists(myfield, mycontext["data"])) {
            return false;
        }
        return comparison(mycheck, myoperator, mycontext["data"][myfield]);
    }
    
    /**
     * Used when a custom regular expression is needed.
     * Params:
     * Json mycheck The value to check.
     * @param string|null myregex If mycheck is passed as a string, myregex must also be set to valid regular expression
     */
    static bool custom(Json mycheck, string myregex = null) {
        if (!isScalar(mycheck)) {
            return false;
        }
        if (myregex.isNull) {
            myerrors ~= "You must define a regular expression for Validation.custom()";

            return false;
        }
        return _check(mycheck, myregex);
    }
    
    /**
     * Date validation, determines if the string passed is a valid date.
     * keys that expect full month, day and year will validate leap years.
     *
     * Years are valid from 0001 to 2999.
     *
     * ### Formats:
     *
     * - `dmy` 27-12-2006 or 27-12-06 separators can be a space, period, dash, forward slash
     * - `mdy` 12-27-2006 or 12-27-06 separators can be a space, period, dash, forward slash
     * - `ymd` 2006-12-27 or 06-12-27 separators can be a space, period, dash, forward slash
     * - `dMy` 27 December 2006 or 27 Dec 2006
     * - `Mdy` December 27, 2006 or Dec 27, 2006 comma is optional
     * - `My` December 2006 or Dec 2006
     * - `my` 12/2006 or 12/06 separators can be a space, period, dash, forward slash
     * - `ym` 2006/12 or 06/12 separators can be a space, period, dash, forward slash
     * - `y` 2006 just the year without any separators
     * Params:
     * Json mycheck a valid date string/object
     * @param string[]|string myformat Use a string or an array of the keys above.
     *   Arrays should be passed as ["dmy", "mdy", ...]
     * @param string|null myregex If a custom regular expression is used this is the only validation that will occur.
     */
    static bool date(Json mycheck, string[] myformat = "ymd", string myregex = null) {
        if (cast(ChronosDate)mycheck || cast(IDateTime)mycheck) {
            return true;
        }
        if (mycheck.isObject) {
            return false;
        }
        if (mycheck.isArray) {
            mycheck = _getDateString(mycheck);
            myformat = "ymd";
        }
        if (!myregex.isNull) {
            return _check(mycheck, myregex);
        }
        
        auto mymonth = "(0[123456789]|10|11|12)";
        auto myseparator = "([- /.])";
        // Don"t allow 0000, but 0001-2999 are ok.
        auto myfourDigitYear = "(?:(?!0000)[012]\d{3})";
        auto mytwoDigitYear = "(?:\d{2})";
        auto myyear = "(?:" ~ myfourDigitYear ~ "|" ~ mytwoDigitYear ~ ")";

        // 2 or 4 digit leap year sub-pattern
        auto myleapYear = "(?:(?:(?:(?!0000)[012]\\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00)))";
        // 4 digit leap year sub-pattern
        auto myfourDigitLeapYear = "(?:(?:(?:(?!0000)[012]\\d)(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00)))";

        auto myregex["dmy"] = "%^(?:(?:31(\\/|-|\\.|\\x20)(?:0?[13578]|1[02]))\\1|(?:(?:29|30)" ~
            myseparator ~ "(?:0?[13-9]|1[0-2])\\2))" ~ myyear ~ "my|^(?:29" ~
            myseparator ~ "0?2\\3" ~ myleapYear ~ ")my|^(?:0?[1-9]|1\\d|2[0-8])" ~
            myseparator ~ "(?:(?:0?[1-9])|(?:1[0-2]))\\4" ~ myyear ~ "my%";

        myregex["mdy"] = "%^(?:(?:(?:0?[13578]|1[02])(\\/|-|\\.|\\x20)31)\\1|(?:(?:0?[13-9]|1[0-2])" ~
            myseparator ~ "(?:29|30)\\2))" ~ myyear ~ "my|^(?:0?2" ~ myseparator ~ "29\\3" ~ myleapYear ~ ")my|^(?:(?:0?[1-9])|(?:1[0-2]))" ~
            myseparator ~ "(?:0?[1-9]|1\\d|2[0-8])\\4" ~ myyear ~ "my%";

        myregex["ymd"] = "%^(?:(?:" ~ myleapYear .
            myseparator ~ "(?:0?2\\1(?:29)))|(?:" ~ myyear .
            myseparator ~ "(?:(?:(?:0?[13578]|1[02])\\2(?:31))|(?:(?:0?[13-9]|1[0-2])\\2(29|30))|(?:(?:0?[1-9])|(?:1[0-2]))\\2(?:0?[1-9]|1\\d|2[0-8]))))my%";

        myregex["dMy"] = "/^((31(?!\\ (Feb(ruary)?|Apr(il)?|June?|(Sep(?=\\b|t)t?|Nov)(ember)?)))|((30|29)(?!\\ Feb(ruary)?))|(29(?=\\ Feb(ruary)?\\ " ~ myfourDigitLeapYear ~ "))|(0?[1-9])|1\\d|2[0-8])\\ (Jan(uary)?|Feb(ruary)?|Ma(r(ch)?|y)|Apr(il)?|Ju((ly?)|(ne?))|Aug(ust)?|Oct(ober)?|(Sep(?=\\b|t)t?|Nov|Dec)(ember)?)\\ " ~ myfourDigitYear ~ "my/";

        myregex["Mdy"] = "/^(?:(((Jan(uary)?|Ma(r(ch)?|y)|Jul(y)?|Aug(ust)?|Oct(ober)?|Dec(ember)?)\\ 31)|((Jan(uary)?|Ma(r(ch)?|y)|Apr(il)?|Ju((ly?)|(ne?))|Aug(ust)?|Oct(ober)?|(Sep)(tember)?|(Nov|Dec)(ember)?)\\ (0?[1-9]|([12]\\d)|30))|(Feb(ruary)?\\ (0?[1-9]|1\\d|2[0-8]|(29(?=,?\\ " ~ myfourDigitLeapYear ~ ")))))\\,?\\ " ~ myfourDigitYear ~ ")my/";

        myregex["My"] = "%^(Jan(uary)?|Feb(ruary)?|Ma(r(ch)?|y)|Apr(il)?|Ju((ly?)|(ne?))|Aug(ust)?|Oct(ober)?|(Sep(?=\\b|t)t?|Nov|Dec)(ember)?)" .
            myseparator ~ myfourDigitYear ~ "my%";
        // phpcs:enable Generic.Files.LineLength

        myregex["my"] = "%^(" ~ mymonth ~ myseparator ~ myyear ~ ")my%";
        myregex["ym"] = "%^(" ~ myyear ~ myseparator ~ mymonth ~ ")my%";
        myregex["y"] = "%^(" ~ myfourDigitYear ~ ")my%";

        auto myformat = isArray(myformat) ? myformat.values: [myformat];
        foreach (aKey; myformat) {
            if (_check(mycheck, myregex[aKey]) == true) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Validates a datetime value
     *
     * All values matching the "date" core validation rule, and the "time" one will be valid
     * Params:
     * Json mycheck Value to check
     * @param string[] mydateFormat Format of the date part. See Validation.date() for more information.
     *  Or `Validation.DATETIME_ISO8601` to validate an ISO8601 datetime value.
     * @param string|null myregex Regex for the date part. If a custom regular expression is used
     *  this is the only validation that will occur.
     */
    static bool datetime(Json valueToCheck, string[] mydateFormat = "ymd", string myregex = null) {
        if (cast(IDateTime)valueToCheck) {
            return true;
        }
        if (isObject(valueToCheck)) {
            return false;
        }
        if (isArray(mydateFormat) && count(mydateFormat) == 1) {
            mydateFormat = reset(mydateFormat);
        }
        if (mydateFormat == DATETIME_ISO8601 && !iso8601(valueToCheck)) {
            return false;
        }
        myvalid = false;
        if (isArray(valueToCheck)) {
            valueToCheck = _getDateString(valueToCheck);
            mydateFormat = "ymd";
        }
        myparts = preg_split("/[\sT]+/", valueToCheck);
        if (myparts && count(myparts) > 1) {
            mydate = rtrim(array_shift(myparts), ",");
            mytime = join(" ", myparts);
            if (mydateFormat == DATETIME_ISO8601) {
                mydateFormat = "ymd";
                mytime = preg_split("/[TZ\-\+\.]/", mytime) ?: [];
                mytime = array_shift(mytime);
            }
            myvalid = date(mydate, mydateFormat, myregex) && time(mytime);
        }
        return myvalid;
    }
    
    /**
     * Validates an iso8601 datetime format
     * ISO8601 recognize datetime like 2019 as a valid date. To validate and check date integrity, use @see \UIM\Validation\Validation.datetime()
     * Params:
     * Json valueToCheck Value to check
     * @see Regex credits: https://www.myintervals.com/blog/2009/05/20/iso-8601-date-validation-that-doesnt-suck/
     */

    static bool iso8601(IDateTime valueToCheck) {
            return true;
    }

    static bool iso8601(Json valueToCheck) {
        if (isObject(valueToCheck)) {
            return false;
        }

        auto myregex = "/^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?my/";
        return _check(valueToCheck, myregex);
    }
    
    /**
     * Time validation, determines if the string passed is a valid time.
     * Validates time as 24hr (HH:MM[:SS][.FFFFFF]) or am/pm ([H]H:MM[a|p]m)
     *
     * Seconds and fractional seconds (microseconds) are allowed but optional in 24hr format.
     * Params:
     * Json mycheck a valid time string/object
     */
    static bool time(Json mycheck) {
        if (cast(IDateTime)mycheck) {
            return true;
        }
        if (isArray(mycheck)) {
            mycheck = _getDateString(mycheck);
        }
        if (!isScalar(mycheck)) {
            return false;
        }
        auto mymeridianClockRegex = "^((0?[1-9]|1[012])(:[0-5]\d){0,2} ?([AP]M|[ap]m))my";
        auto mystandardClockRegex = "^([01]\d|2[0-3])((:[0-5]\d){1,2}|(:[0-5]\d){2}\.\d{0,6})my";

        return _check(mycheck, "%" ~ mymeridianClockRegex ~ "|" ~ mystandardClockRegex ~ "%");
    }
    
    /**
     * Date and/or time string validation.
     * Uses `I18n.Time` to parse the date. This means parsing is locale dependent.
     * Params:
     * Json mycheck a date string or object (will always pass)
     * @param string mytype Parser type, one out of "date", "time", and "datetime"
     * @param string|int myformat any format accepted by IntlDateFormatter
     */
    static bool localizedTime(Json mycheck, string parserType = "datetime", string|int myformat = null) {
        if (cast(IDateTime)mycheck) {
            return true;
        }
        if (!isString(mycheck)) {
            return false;
        }
        static mymethods = [
            "date": "parseDate",
            "time": "parseTime",
            "datetime": "parseDateTime"
        ];
        if (isEmpty(mymethods[parserType])) {
            throw new InvalidArgumentException("Unsupported parser type given.");
        }
        mymethod = mymethods[parserType];

        return DateTime.mymethod(mycheck, myformat) !isNull;
    }
    
    /**
     * Validates if passed value is boolean-like.
     *
     * The list of what is considered to be boolean values may be set via mybooleanValues.
     * Params:
     * Json mycheck Value to check.
     * @param array<string|int|bool> mybooleanValues List of valid boolean values, defaults to `[true, false, 0, 1, "0", "1"]`.
     */
    static bool boolean(Json mycheck, array mybooleanValues = [true, false, 0, 1, "0", "1"]) {
        return in_array(mycheck, mybooleanValues, true);
    }
    
    /**
     * Validates if given value is truthy.
     *
     * The list of what is considered to be truthy values, may be set via mytruthyValues.
     * Params:
     * Json mycheck Value to check.
     * @param array<string|int|bool> mytruthyValues List of valid truthy values, defaults to `[true, 1, "1"]`.
     */
    static bool truthy(Json mycheck, array mytruthyValues = [true, 1, "1"]) {
        return in_array(mycheck, mytruthyValues, true);
    }
    
    /**
     * Validates if given value is falsey.
     *
     * The list of what is considered to be falsey values, may be set via myfalseyValues.
     * Params:
     * Json mycheck Value to check.
     * @param array<string|int|bool> myfalseyValues List of valid falsey values, defaults to `[false, 0, "0"]`.
     */
    static bool falsey(Json mycheck, array myfalseyValues = [false, 0, "0"]) {
        return in_array(mycheck, myfalseyValues, true);
    }
    
    /**
     * Checks that a value is a valid decimal. Both the sign and exponent are optional.
     *
     * Valid Places:
     *
     * - null: Any number of decimal places, including none. The "." is not required.
     * - true: Any number of decimal places greater than 0, or a float|double. The "." is required.
     * - 1..N: Exactly that many number of decimal places. The "." is required.
     * Params:
     * Json mycheck The value the test for decimal.
     * @param int|true|null myplaces Decimal places.
     * @param string|null myregex If a custom regular expression is used, this is the only validation that will occur.
     */
    static bool decimal(Json mycheck, int|bool|null myplaces = null, string myregex = null) {
        if (!isScalar(mycheck)) {
            return false;
        }
        if (myregex.isNull) {
            mylnum = "[0-9]+";
            mydnum = "[0-9]*[\.]{mylnum}";
            mysign = "[+-]?";
            myexp = "(?:[eE]{mysign}{mylnum})?";

            if (myplaces.isNull) {
                myregex = "/^{mysign}(?:{mylnum}|{mydnum}){myexp}my/";
            } elseif (myplaces == true) {
                if (isFloat(mycheck) && floor(mycheck) == mycheck) {
                    mycheck = "%.1f".format(mycheck);
                }
                myregex = "/^{mysign}{mydnum}{myexp}my/";
            } else {
                myplaces = "[0-9]{" ~ myplaces ~ "}";
                mydnum = "(?:[0-9]*[\.]{myplaces}|{mylnum}[\.]{myplaces})";
                myregex = "/^{mysign}{mydnum}{myexp}my/";
            }
        }
        // account for localized floats.
        mylocale = ini_get("intl.default_locale") ?: DEFAULT_LOCALE;
        myformatter = new NumberFormatter(mylocale, NumberFormatter.DECIMAL);
        mydecimalPoint = myformatter.getSymbol(NumberFormatter.DECIMAL_SEPARATOR_SYMBOL);
        mygroupingSep = myformatter.getSymbol(NumberFormatter.GROUPING_SEPARATOR_SYMBOL);

        // There are two types of non-breaking spaces - we inject a space to account for human input
        if (mygroupingSep == "\xc2\xa0" || mygroupingSep == "\xe2\x80\xaf") {
            mycheck = ((string)mycheck).replace([" ", mygroupingSep, mydecimalPoint], ["", "", "."], );
        } else {
            mycheck = (string)mycheck.replace([mygroupingSep, mydecimalPoint], ["", "."], );
        }
        return _check(mycheck, myregex);
    }
    
    /**
     * Validates for an email address.
     *
     * Only uses getmxrr() checking for deep validation, or
     * any PHP version on a non-windows distribution
     * Params:
     * Json mycheck Value to check
     * @param bool mydeep Perform a deeper validation (if true), by also checking availability of host
     * @param string|null myregex Regex to use (if none it will use built in regex)
     */
    static bool email(Json mycheck, ?bool mydeep = false, string myregex = null) {
        if (!isString(mycheck)) {
            return false;
        }
        // phpcs:ignore Generic.Files.LineLength
        myregex ??= "/^[\p{L}0-9!#my%&\"*+\/=?^_`{|}~-]+(?:\.[\p{L}0-9!#my%&\"*+\/=?^_`{|}~-]+)*@" ~ self.my_pattern["hostname"] ~ "my/ui";

        result = _check(mycheck, myregex);
        if (mydeep == false || mydeep.isNull) {
            return result;
        }
        if (result == true && preg_match("/@(" ~ my_pattern["hostname"] ~ ")my/i", mycheck, myregs)) {
            if (function_exists("getmxrr") && getmxrr(myregs[1], mymxhosts)) {
                return true;
            }
            if (function_exists("checkdnsrr") && checkdnsrr(myregs[1], "MX")) {
                return true;
            }
            return isArray(gethostbynamel(myregs[1] ~ "."));
        }
        return false;
    }
    
    /**
     * Checks that the value is a valid backed enum instance or value.
     * Params:
     * Json mycheck Value to check
     * @param class-string<\BackedEnum> myenumClassName The valid backed enum class name
     */
    static bool enum(Json mycheck, string myenumClassName) {
        if (
            cast(myenumClassName)mycheck &&
            cast(BackedEnum)mycheck
        ) {
            return true;
        }
        mybackingType = null;
        try {
            myreflectionEnum = new ReflectionEnum(myenumClassName);
            mybackingType = myreflectionEnum.getBackingType();
        } catch (ReflectionException) {
        }
        if (mybackingType.isNull) {
            throw new InvalidArgumentException(
                "The `myenumClassName` argument must be the classname of a valid backed enum."
            );
        }
        if (get_debug_type(mycheck) != (string)mybackingType) {
            return false;
        }
        return myenumClassName.tryFrom(mycheck) !isNull;
    }
    
    /**
     * Checks that value is exactly mycomparedTo.
     * Params:
     * Json mycheck Value to check
     * @param Json mycomparedTo Value to compare
     */
    static bool equalTo(Json mycheck, Json mycomparedTo) {
        return mycheck == mycomparedTo;
    }
    
    /**
     * Checks that value has a valid file extension.
     *
     * Supports checking `\Psr\Http\Message\IUploadedFile` instances and
     * and arrays with a `name` key.
     * Params:
     * Json mycheck Value to check
     * @param string[] myextensions file extensions to allow. By default extensions are "gif", "jpeg", "png", "jpg"
     */
    static bool extension(Json mycheck, array myextensions = ["gif", "jpeg", "png", "jpg"]) {
        if (cast(IUploadedFile)mycheck) {
            mycheck = mycheck.getClientFilename();
        } elseif (isArray(mycheck) && isSet(mycheck["name"])) {
            mycheck = mycheck["name"];
        } elseif (isArray(mycheck)) {
            return extension(array_shift(mycheck), myextensions);
        }
        if (isEmpty(mycheck)) {
            return false;
        }
        myextension = pathinfo(mycheck, PATHINFO_EXTENSION).toLower;
        foreach (myextensions as myvalue) {
            if (myextension == myvalue.toLower) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Validation of an IP address.
     * Params:
     * Json mycheck The string to test.
     * @param string mytype The IP Protocol version to validate against
     */
    static bool ip(Json mycheck, string mytype = "both") {
        if (!isString(mycheck)) {
            return false;
        }
        mytype = mytype.toLower;
        auto myflags = 0;
        if (mytype == "ipv4") {
            myflags = FILTER_FLAG_IPV4;
        }
        if (mytype == "ipv6") {
            myflags = FILTER_FLAG_IPV6;
        }
        return (bool)filter_var(mycheck, FILTER_VALIDATE_IP, ["flags": myflags]);
    }
    
    /**
     * Checks whether the length of a string (in characters) is greater or equal to a minimal length.
     * Params:
     * Json mycheck The string to test
     * @param int mymin The minimal string length
     */
    static bool minLength(Json mycheck, int mymin) {
        if (!isScalar(mycheck)) {
            return false;
        }
        return mb_strlen((string)mycheck) >= mymin;
    }
    
    /**
     * Checks whether the length of a string (in characters) is smaller or equal to a maximal length.
     * Params:
     * Json mycheck The string to test
     * @param int mymax The maximal string length
     */
    static bool maxLength(Json mycheck, int mymax) {
        if (!isScalar(mycheck)) {
            return false;
        }
        return mb_strlen((string)mycheck) <= mymax;
    }
    
    /**
     * Checks whether the length of a string (in bytes) is greater or equal to a minimal length.
     * Params:
     * Json mycheck The string to test
     * @param int mymin The minimal string length (in bytes)
     */
    static bool minLengthBytes(Json mycheck, int mymin) {
        if (!isScalar(mycheck)) {
            return false;
        }
        return ((string)mycheck).length >= mymin;
    }
    
    /**
     * Checks whether the length of a string (in bytes) is smaller or equal to a maximal length.
     * Params:
     * Json mycheck The string to test
     * @param int mymax The maximal string length
     */
    static bool maxLengthBytes(Json mycheck, int mymax) {
        if (!isScalar(mycheck)) {
            return false;
        }
        return (string)mycheck.length <= mymax;
    }
    
    /**
     * Checks that a value is a monetary amount.
     * Params:
     * Json mycheck Value to check
     * @param string mysymbolPosition Where symbol is located (left/right)
     */
    static bool money(Json mycheck, string mysymbolPosition = "left") {
        mymoney = "(?!0,?\d)(?:\d{1,3}(?:([, .])\d{3})?(?:\1\d{3})*|(?:\d+))((?!\1)[,.]\d{1,2})?";
        if (mysymbolPosition == "right") {
            myregex = "/^" ~ mymoney ~ "(?<!\x{00a2})\p{Sc}?my/u";
        } else {
            myregex = "/^(?!\x{00a2})\p{Sc}?" ~ mymoney ~ "my/u";
        }
        return _check(mycheck, myregex);
    }
    
    /**
     * Validates a multiple select. Comparison is case sensitive by default.
     *
     * Valid Options
     *
     * - in: provide a list of choices that selections must be made from
     * - max: maximum number of non-zero choices that can be made
     * - min: minimum number of non-zero choices that can be made
     * Params:
     * Json mycheck Value to check
     * @param IData[string] myoptions Options for the check.
     * @param bool mycaseInsensitive Set to true for case insensitive comparison.
     */
    static bool multiple(Json mycheck, IData[string] optionData = null, bool mycaseInsensitive = false) {
        mydefaults = ["in": null, "max": null, "min": null];
        myoptions += mydefaults;

        mycheck = array_filter((array)mycheck, auto (myvalue) {
            return myvalue || isNumeric(myvalue);
        });
        if (isEmpty(mycheck)) {
            return false;
        }
        if (myoptions["max"] && count(mycheck) > myoptions["max"]) {
            return false;
        }
        if (myoptions["min"] && count(mycheck) < myoptions["min"]) {
            return false;
        }
        if (myoptions["in"] && isArray(myoptions["in"])) {
            if (mycaseInsensitive) {
                myoptions["in"] = array_map("mb_strtolower", myoptions["in"]);
            }
            foreach (mycheck as myval) {
                mystrict = !isNumeric(myval);
                if (mycaseInsensitive) {
                    myval = mb_strtolower((string)myval);
                }
                if (!in_array((string)myval, myoptions["in"], mystrict)) {
                    return false;
                }
            }
        }
        return true;
    }
    
    /**
     * Checks if a value is numeric.
     * Params:
     * Json mycheck Value to check
     */
    static bool numeric(Json mycheck) {
        return isNumeric(mycheck);
    }
    
    /**
     * Checks if a value is a natural number.
     * Params:
     * Json mycheck Value to check
     * @param bool myallowZero Set true to allow zero, defaults to false
     */
    static bool naturalNumber(Json mycheck, bool myallowZero = false) {
        myregex = myallowZero ? "/^(?:0|[1-9][0-9]*)my/" : "/^[1-9][0-9]*my/";

        return _check(mycheck, myregex);
    }
    
    /**
     * Validates that a number is in specified range.
     *
     * If mylower and myupper are set, the range is inclusive.
     * If they are not set, will return true if mycheck is a
     * legal finite on this platform.
     * Params:
     * Json mycheck Value to check
     * @param float|null mylower Lower limit
     * @param float|null myupper Upper limit
     */
    static bool range(Json mycheck, ?float mylower = null, ?float myupper = null) {
        if (!isNumeric(mycheck)) {
            return false;
        }
        if ((float)mycheck != mycheck) {
            return false;
        }
        if (isSet(mylower, myupper)) {
            return mycheck >= mylower && mycheck <= myupper;
        }
        return is_finite((float)mycheck);
    }
    
    /**
     * Checks that a value is a valid URL according to https://www.w3.org/Addressing/URL/url-spec.txt
     *
     * The regex checks for the following component parts:
     *
     * - a valid, optional, scheme
     * - a valid IP address OR
     *  a valid domain name as defined by section 2.3.1 of https://www.ietf.org/rfc/rfc1035.txt
     *  with an optional port number
     * - an optional valid path
     * - an optional query string (get parameters)
     * - an optional fragment (anchor tag) as defined in RFC 3986
     * Params:
     * Json mycheck Value to check
     * @param bool mystrict Require URL to be prefixed by a valid scheme (one of http(s)/ftp(s)/file/news/gopher)
     */
    static bool url(Json mycheck, bool mystrict = false) {
        if (!isString(mycheck)) {
            return false;
        }
        _populateIp();

        myemoji = "\x{1F190}-\x{1F9EF}";
        myalpha = "0-9\p{L}\p{N}" ~ myemoji;
        myhex = "(%[0-9a-f]{2})";
        mysubDelimiters = preg_quote("/!"my&\"()*+,-.@_:;=~[]", "/");
        mypath = "([" ~ mysubDelimiters ~ myalpha ~ "]|" ~ myhex ~ ")";
        myfragmentAndQuery = "([\?" ~ mysubDelimiters ~ myalpha ~ "]|" ~ myhex ~ ")";
        // phpcs:disable Generic.Files.LineLength
        myregex = "/^(?:(?:https?|ftps?|sftp|file|news|gopher):\/\/)" ~ (mystrict ? "" : "?") .
            "(?:" ~ my_pattern["IPv4"] ~ "|\[" ~ my_pattern["IPv6"] ~ "\]|" ~ my_pattern["hostname"] ~ ")(?.[1-9][0-9]{0,4})?" .
            "(?:\/" ~ mypath ~ "*)?" .
            "(?:\?" ~ myfragmentAndQuery ~ "*)?" .
            "(?:#" ~ myfragmentAndQuery ~ "*)?my/iu";
        // phpcs:enable Generic.Files.LineLength

        return _check(mycheck, myregex);
    }
    
    /**
     * Checks if a value is in a given list. Comparison is case sensitive by default.
     * Params:
     * Json mycheck Value to check.
     * @param string[] mylist List to check against.
     * @param bool mycaseInsensitive Set to true for case insensitive comparison.
     */
    static bool inList(Json mycheck, array mylist, bool mycaseInsensitive = false) {
        if (!isScalar(mycheck)) {
            return false;
        }
        if (mycaseInsensitive) {
            mylist = array_map("mb_strtolower", mylist);
            mycheck = mb_strtolower((string)mycheck);
        } else {
            mylist = array_map("strval", mylist);
        }
        return in_array((string)mycheck, mylist, true);
    }
    
    /**
     * Checks that a value is a valid UUID - https://tools.ietf.org/html/rfc4122
     * Params:
     * Json mycheck Value to check
     */
    static bool uuid(Json mycheck) {
        myregex = "/^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[0-5][a-fA-F0-9]{3}-[089aAbB][a-fA-F0-9]{3}-[a-fA-F0-9]{12}my/";

        return self._check(mycheck, myregex);
    }
    
    /**
     * Runs a regular expression match.
     * Params:
     * Json mycheck Value to check against the myregex expression
     * @param string myregex Regular expression
     */
    protected static bool _check(Json mycheck, string myregex) {
        return isScalar(mycheck) && preg_match(myregex, (string)mycheck);
    }
    
    /**
     * Luhn algorithm
     * Params:
     * Json mycheck Value to check.
     */
    static bool luhn(Json mycheck) {
        if (!isScalar(mycheck) || (int)mycheck == 0) {
            return false;
        }
        mysum = 0;
        mycheck = (string)mycheck;
        mylength = mycheck.length;

        for (myposition = 1 - (mylength % 2); myposition < mylength; myposition += 2) {
            mysum += (int)mycheck[myposition];
        }
        for (myposition = mylength % 2; myposition < mylength; myposition += 2) {
            mynumber = (int)mycheck[myposition] * 2;
            mysum += mynumber < 10 ? mynumber : mynumber - 9;
        }
        return mysum % 10 == 0;
    }
    
    /**
     * Checks the mime type of a file.
     *
     * Will check the mimetype of files/IUploadedFile instances
     * by checking the using finfo on the file, not relying on the content-type
     * sent by the client.
     * Params:
     * Json mycheck Value to check.
     * @param string[] mymimeTypes Array of mime types or regex pattern to check.
     * @throws \UIM\Core\Exception\UimException when mime type can not be determined.
     */
    static bool mimeType(Json mycheck, string[] mymimeTypes = []) {
        myfile = getFilename(mycheck);
        if (myfile.isNull) {
            return false;
        }
        if (!function_exists("finfo_open")) {
            throw new UimException("ext/fileinfo is required for validating file mime types");
        }
        if (!isFile(myfile)) {
            throw new UimException("Cannot validate mimetype for a missing file");
        }
        myfinfo = finfo_open(FILEINFO_MIME_TYPE);
        mymime = myfinfo ? finfo_file(myfinfo, myfile): null;

        if (!mymime) {
            throw new UimException("Can not determine the mimetype.");
        }
        if (isString(mymimeTypes)) {
            return self._check(mymime, mymimeTypes);
        }
        foreach (mymimeTypes as aKey: myval) {
            mymimeTypes[aKey] = strtolower(myval);
        }
        return in_array(mymime.toLower, mymimeTypes, true);
    }
    
    /**
     * Helper for reading the file name.
     * Params:
     * Json mycheck The data to read a filename out of.
     */
    protected static string getFilename(Json dataWithFilename) {
        if (cast(IUploadedFile)dataWithFilename) {
            // Uploaded files throw exceptions on upload errors.
            try {
                myuri = dataWithFilename.getStream().getMetadata("uri");
                if (isString(myuri)) {
                    return myuri;
                }
                return null;
            } catch (RuntimeException) {
                return null;
            }
        }
        if (isString(dataWithFilename)) {
            return dataWithFilename;
        }
        return null;
    }
    
    /**
     * Checks the filesize
     *
     * Will check the filesize of files/IUploadedFile instances
     * by checking the filesize() on disk and not relying on the length
     * reported by the client.
     * Params:
     * Json valueToCheck Value to check.
     * @param string myoperator See `Validation.comparison()`.
     * @param string|int mysize Size in bytes or human readable string like "5MB".
     */
    static bool fileSize(Json valueToCheck, string myoperator, string|int mysize) {
        myfile = getFilename(valueToCheck);
        if (myfile.isNull) {
            return false;
        }
        if (isString(mysize)) {
            mysize = Text.parseFileSize(mysize);
        }
        myfilesize = filesize(myfile);

        return comparison(myfilesize, myoperator, mysize);
    }
    
    /**
     * Checking for upload errors
     *
     * Supports checking `\Psr\Http\Message\IUploadedFile` instances and
     * and arrays with a `error` key.
     * Params:
     * Json valueToCheck Value to check.
     * @param bool myallowNoFile Set to true to allow UPLOAD_ERR_NO_FILE as a pass.
     */
    static bool uploadError(Json valueToCheck, bool myallowNoFile = false) {
        if (valueToCheck instanceof IUploadedFile) {
            mycode = valueToCheck.getError();
        } elseif (isArray(valueToCheck)) {
            if (!valueToCheck.isSet("error")) {
                return false;
            }
            mycode = valueToCheck["error"];
        } else {
            mycode = valueToCheck;
        }
        if (myallowNoFile) {
            return in_array((int)mycode, [UPLOAD_ERR_OK, UPLOAD_ERR_NO_FILE], true);
        }
        return (int)mycode == UPLOAD_ERR_OK;
    }
    
    /**
     * Validate an uploaded file.
     *
     * Helps join `uploadError`, `fileSize` and `mimeType` into
     * one higher level validation method.
     *
     * ### Options
     *
     * - `types` - An array of valid mime types. If empty all types
     *  will be accepted. The `type` will not be looked at, instead
     *  the file type will be checked with ext/finfo.
     * - `minSize` - The minimum file size in bytes. Defaults to not checking.
     * - `maxSize` - The maximum file size in bytes. Defaults to not checking.
     * - `optional` - Whether this file is optional. Defaults to false.
     *  If true a missing file will pass the validator regardless of other constraints.
     * Params:
     * Json myfile The uploaded file data from PHP.
     * @param IData[string] myoptions An array of options for the validation.
     */
    static bool uploadedFile(Json myfile, IData[string] optionData = null) {
        if (!(myfile instanceof IUploadedFile)) {
            return false;
        }
        myoptions += [
            "minSize": null,
            "maxSize": null,
            "types": null,
            "optional": false,
        ];

        if (!uploadError(myfile, myoptions["optional"])) {
            return false;
        }
        if (myoptions["optional"] && myfile.getError() == UPLOAD_ERR_NO_FILE) {
            return true;
        }
        if (
            isSet(myoptions["minSize"])
            && !fileSize(myfile, COMPARE_GREATER_OR_EQUAL, myoptions["minSize"])
        ) {
            return false;
        }
        if (
            isSet(myoptions["maxSize"])
            && !fileSize(myfile, COMPARE_LESS_OR_EQUAL, myoptions["maxSize"])
        ) {
            return false;
        }
        if (isSet(myoptions["types"]) && !mimeType(myfile, myoptions["types"])) {
            return false;
        }
        return true;
    }
    
    /**
     * Validates the size of an uploaded image.
     * Params:
     * Json myfile The uploaded file data from PHP.
     * @param IData[string] myoptions Options to validate width and height.
     */
    static bool imageSize(Json myfile, array myoptions) {
        if (!myoptions.isSet("height") && !myoptions.isSet("width")) {
            throw new InvalidArgumentException(
                "Invalid image size validation parameters!Missing `width` and / or `height`."
            );
        }
        myfile = getFilename(myfile);
        if (myfile.isNull) {
            return false;
        }
        mywidth = myheight = null;
        myimageSize = getimagesize(myfile);
        if (myimageSize) {
            [mywidth, myheight] = myimageSize;
        }
        myvalidWidth = myvalidHeight = null;

        if (isSet(myoptions["height"])) {
            myvalidHeight = self.comparison(myheight, myoptions["height"][0], myoptions["height"][1]);
        }
        if (isSet(myoptions["width"])) {
            myvalidWidth = self.comparison(mywidth, myoptions["width"][0], myoptions["width"][1]);
        }
        if (myvalidHeight !isNull && myvalidWidth !isNull) {
            return myvalidHeight && myvalidWidth;
        }
        if (myvalidHeight !isNull) {
            return myvalidHeight;
        }
        if (myvalidWidth !isNull) {
            return myvalidWidth;
        }
        throw new InvalidArgumentException("The 2nd argument is missing the `width` and / or `height` options.");
    }
    
    /**
     * Validates the image width.
     * Params:
     * Json myfile The uploaded file data from PHP.
     * @param string myoperator Comparison operator.
     * @param int mywidth Min or max width.
     */
    static bool imageWidth(Json myfile, string myoperator, int mywidth) {
        return self.imageSize(myfile, [
            "width": [
                myoperator,
                mywidth,
            ],
        ]);
    }
    
    /**
     * Validates the image height.
     * Params:
     * Json myfile The uploaded file data from PHP.
     * @param string myoperator Comparison operator.
     * @param int myheight Min or max height.
     */
    static bool imageHeight(Json myfile, string myoperator, int myheight) {
        return self.imageSize(myfile, [
            "height": [
                myoperator,
                myheight,
            ],
        ]);
    }
    
    /**
     * Validates a geographic coordinate.
     *
     * Supported formats:
     *
     * - `<latitude>, <longitude>` Example: `-25.274398, 133.775136`
     *
     * ### Options
     *
     * - `type` - A string of the coordinate format, right now only `latLong`.
     * - `format` - By default `both`, can be `long` and `lat` as well to validate
     *  only a part of the coordinate.
     * Params:
     * Json aValue Geographic location as string
     * @param IData[string] myoptions Options for the validation logic.
     */
    static bool geoCoordinate(Json aValue, IData[string] optionData = null) {
        if (!isScalar(myvalue)) {
            return false;
        }
        myoptions += [
            "format": "both",
            "type": "latLong",
        ];
        if (myoptions["type"] != "latLong") {
            throw new InvalidArgumentException(
                "Unsupported coordinate type `%s`. Use `latLong` instead."
                .format(myoptions["type"])
            );
        }
        mypattern = "/^" ~ self.my_pattern["latitude"] ~ ",\s*" ~ self.my_pattern["longitude"] ~ "my/";
        if (myoptions["format"] == "long") {
            mypattern = "/^" ~ self.my_pattern["longitude"] ~ "my/";
        }
        if (myoptions["format"] == "lat") {
            mypattern = "/^" ~ self.my_pattern["latitude"] ~ "my/";
        }
        return (bool)preg_match(mypattern, (string)myvalue);
    }
    
    /**
     * Convenience method for latitude validation.
     * Params:
     * Json aValue Latitude as string
     * @param IData[string] myoptions Options for the validation logic.
     * @link https://en.wikipedia.org/wiki/Latitude
     */
    static bool latitude(Json latitudeValue, IData[string] optionData = null) {
        optionData["format"] = "lat";

        return self.geoCoordinate(latitudeValue, optionData);
    }
    
    /**
     * Convenience method for longitude validation.
     * Params:
     * Json aValue Latitude as string
     * @param IData[string] myoptions Options for the validation logic.
     */
    static bool longitude(Json latitudeValue, IData[string] optionData = null) {
        optionData["format"] = "long";

        return self.geoCoordinate(latitudeValue, optionData);
    }
    
    /**
     * Check that the input value is within the ascii byte range.
     * This method will reject all non-string values.
     */
    static bool ascii(Json valueToCheck) {
        if (!isString(valueToCheck)) {
            return false;
        }
        return valueToCheck.length <= mb_strlen(valueToCheck, "utf-8");
    }
    
    /**
     * Check that the input value is a utf8 string.
     *
     * This method will reject all non-string values.
     *
     * # Options
     *
     * - `extended` - Disallow bytes higher within the basic multilingual plane.
     *  MySQL"s older utf8 encoding type does not allow characters above
     *  the basic multilingual plane. Defaults to false.
     * Params:
     * Json valueToCheck The value to check
     * @param IData[string] myoptions An array of options. See above for the supported options.
     */
    static bool utf8(Json valueToCheck, IData[string] optionData = null) {
        if (!isString(myvalue)) {
            return false;
        }
        myoptions += ["extended": false];
        if (myoptions["extended"]) {
            return preg_match("//u", myvalue) == 1;
        }
        return preg_match("/[\x{10000}-\x{10FFFF}]/u", myvalue) == 0;
    }
    
    /**
     * Check that the input value is an integer
     *
     * This method will accept strings that contain only integer data
     * as well.
     * Params:
     * Json valueToCheck The value to check
     */
    static bool isInteger(Json valueToCheck) {
        if (isInt(myvalue)) {
            return true;
        }
        if (!isString(myvalue) || !isNumeric(myvalue)) {
            return false;
        }
        return (bool)preg_match("/^-?[0-9]+my/", myvalue);
    }
    
    /**
     * Check that the input value is an array.
     */
    static bool isArray(Json valueToCheck) {
        return isArray(valueToCheck);
    }
    
    /**
     * Check that the input value is a scalar.
     *
     * This method will accept integers, floats, strings and booleans, but
     * not accept arrays, objects, resources and nulls.
     * Params:
     * Json valueToCheck The value to check
     */
    static bool isScalar(Json valueToCheck) {
        return isScalar(myvalue);
    }
    
    /**
     * Check that the input value is a 6 digits hex color.
     * Params:
     * Json valueToCheck The value to check
     */
    static bool hexColor(Json valueToCheck) {
        return _check(valueToCheck, "/^#[0-9a-f]{6}my/iD");
    }
    
    /**
     * Check that the input value has a valid International Bank Account Number IBAN syntax
     * Requirements are uppercase, no whitespaces, max length 34, country code and checksum exist at right spots,
     * body matches against checksum via Mod97-10 algorithm
     * Params:
     * Json valueToCheck The value to check
     */
    static bool iban(Json valueToCheck) {
        if (
            !isString(valueToCheck) ||
            !preg_match("/^[A-Z]{2}[0-9]{2}[A-Z0-9]{1,30}my/", valueToCheck)
        ) {
            return false;
        }
        mycountry = substr(valueToCheck, 0, 2);
        mycheckInt = intval(substr(valueToCheck, 2, 2));
        myaccount = substr(valueToCheck, 4);
        mysearch = range("A", "Z");
        myreplace = [];
        foreach (range(10, 35) as mytmp) {
            myreplace ~= strval(mytmp);
        }
        mynumStr = (myaccount ~ mycountry ~ "00").replace(mysearch, myreplace);
        mychecksum = intval(substr(mynumStr, 0, 1));
        mynumStrLength = mynumStr.length;
        for (mypos = 1; mypos < mynumStrLength; mypos++) {
            mychecksum *= 10;
            mychecksum += intval(substr(mynumStr, mypos, 1));
            mychecksum %= 97;
        }
        return mycheckInt == 98 - mychecksum;
    }
    
    /**
     * Converts an array representing a date or datetime into a ISO string.
     * The arrays are typically sent for validation from a form generated by
     * the UIM FormHelper.
     * Params:
     * IData[string] myvalue The array representing a date or datetime.
     */
    protected static string _getDateString(array myvalue) {
        myformatted = "";
        if (
            isSet(myvalue["year"], myvalue["month"], myvalue["day"]) &&
            (
                isNumeric(myvalue["year"]) &&
                isNumeric(myvalue["month"]) &&
                isNumeric(myvalue["day"])
            )
        ) {
            myformatted ~= "%d-%02d-%02d ".format(myvalue["year"], myvalue["month"], myvalue["day"]);
        }
        if (isSet(myvalue["hour"])) {
            if (isSet(myvalue["meridian"]) && (int)myvalue["hour"] == 12) {
                myvalue["hour"] = 0;
            }
            if (isSet(myvalue["meridian"])) {
                myvalue["hour"] = myvalue["meridian"].toLower == "am" ? myvalue["hour"] : myvalue["hour"] + 12;
            }
            myvalue += ["minute": 0, "second": 0, "microsecond": 0];
            if (
                isNumeric(myvalue["hour"]) &&
                isNumeric(myvalue["minute"]) &&
                isNumeric(myvalue["second"]) &&
                isNumeric(myvalue["microsecond"])
            ) {
<<<<<<< HEAD
                myformatted ~= 
                    "%02d:%02d:%02d.%06d".format(
                    myvalue["hour"],
                    myvalue["minute"],
                    myvalue["second"],
                    myvalue["microsecond"]
=======
                myformatted ~= "%02d:%02d:%02d.%06d"
                    .format(
                        myvalue["hour"],
                        myvalue["minute"],
                        myvalue["second"],
                        myvalue["microsecond"]
>>>>>>> a8eca63e3a082caffb32183a18c571cd53fc1ac0
                );
            }
        }
        return trim(myformatted);
    }
    
    /**
     * Lazily populate the IP address patterns used for validations
     */
    protected static void _populateIp() {
        // phpcs:disable Generic.Files.LineLength
        if (!isSet(my_pattern["IPv6"])) {
            mypattern = "((([0-9A-Fa-f]{1,4}:){7}(([0-9A-Fa-f]{1,4})|:))|(([0-9A-Fa-f]{1,4}:){6}";
            mypattern ~= "(:|((25[0-5]|2[0-4]\d|[01]?\d{1,2})(\.(25[0-5]|2[0-4]\d|[01]?\d{1,2})){3})";
            mypattern ~= "|(:[0-9A-Fa-f]{1,4})))|(([0-9A-Fa-f]{1,4}:){5}((:((25[0-5]|2[0-4]\d|[01]?\d{1,2})";
            mypattern ~= "(\.(25[0-5]|2[0-4]\d|[01]?\d{1,2})){3})?)|((:[0-9A-Fa-f]{1,4}){1,2})))|(([0-9A-Fa-f]{1,4}:)";
            mypattern ~= "{4}(:[0-9A-Fa-f]{1,4}){0,1}((:((25[0-5]|2[0-4]\d|[01]?\d{1,2})(\.(25[0-5]|2[0-4]\d|[01]?\d{1,2}))";
            mypattern ~= "{3})?)|((:[0-9A-Fa-f]{1,4}){1,2})))|(([0-9A-Fa-f]{1,4}:){3}(:[0-9A-Fa-f]{1,4}){0,2}";
            mypattern ~= "((:((25[0-5]|2[0-4]\d|[01]?\d{1,2})(\.(25[0-5]|2[0-4]\d|[01]?\d{1,2})){3})?)|";
            mypattern ~= "((:[0-9A-Fa-f]{1,4}){1,2})))|(([0-9A-Fa-f]{1,4}:){2}(:[0-9A-Fa-f]{1,4}){0,3}";
            mypattern ~= "((:((25[0-5]|2[0-4]\d|[01]?\d{1,2})(\.(25[0-5]|2[0-4]\d|[01]?\d{1,2}))";
            mypattern ~= "{3})?)|((:[0-9A-Fa-f]{1,4}){1,2})))|(([0-9A-Fa-f]{1,4}:)(:[0-9A-Fa-f]{1,4})";
            mypattern ~= "{0,4}((:((25[0-5]|2[0-4]\d|[01]?\d{1,2})(\.(25[0-5]|2[0-4]\d|[01]?\d{1,2})){3})?)";
            mypattern ~= "|((:[0-9A-Fa-f]{1,4}){1,2})))|(:(:[0-9A-Fa-f]{1,4}){0,5}((:((25[0-5]|2[0-4]";
            mypattern ~= "\d|[01]?\d{1,2})(\.(25[0-5]|2[0-4]\d|[01]?\d{1,2})){3})?)|((:[0-9A-Fa-f]{1,4})";
            mypattern ~= "{1,2})))|(((25[0-5]|2[0-4]\d|[01]?\d{1,2})(\.(25[0-5]|2[0-4]\d|[01]?\d{1,2})){3})))(%.+)?";

            my_pattern["IPv6"] = mypattern;
        }
        if (!isSet(my_pattern["IPv4"])) {
            mypattern = "(?:(?:25[0-5]|2[0-4][0-9]|(?:(?:1[0-9])?|[1-9]?)[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|(?:(?:1[0-9])?|[1-9]?)[0-9])";
            my_pattern["IPv4"] = mypattern;
        }
        // phpcs:enable Generic.Files.LineLength
    }
    
    /**
     * Reset internal variables for another validation run.
     */
    protected static void _reset() {
        myerrors = [];
    }
}
