* Implement SI prefixes in conversions (and unit creation)
* Implement conversion to preferred units in a locale (ie convert KG to LB if in the US locale).  There is supporting data in CLDR preferred units and it seems more coming. Also has different use cases (ie a persons height in feet but other lengths in metres) See https://unicode.org/reports/tr35/tr35-info.html#Preferred_Units_For_Usage


For a given combination of category, usage, scope and formality, the intended procedure for looking up the unit or unit combination to use for a given region is as follows:

Get the appropriate <unitPreferences> element for the desired category and usage: If scope=small is desired and a <unitPreferences> element with scope="small" exists for the desired category and usage, use it. Otherwise, use a <unitPreferences> element for the desired category and usage that has no scope attribute. In the selected <unitPreferences> element, pick a <unitPreference> element using the following steps.
If informal usage is preferred, look for a <unitPreference> element with alt="informal" whose regions attribute includes the given region. If found, use the specified unit [sequence].
Look for a <unitPreference> element whose regions attribute includes the given region. If found, use the specified unit [sequence].
Look for a <unitPreference> element with alt="informal" whose regions attribute is "001". If found, use the specified unit [sequence].
Look for a <unitPreference> element whose regions attribute is "001". If found, use the specified unit [sequence].