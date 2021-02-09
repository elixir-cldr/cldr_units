# Updates the unit test data from CLDR

# The location of the `ex_cldr` repo
export EX_CLDR_UNIT="${EX_CLDR:=$HOME/Development/cldr_units}"
[ ! -d $EX_CLDR_UNIT ] && { echo "ex_cldr_units repository $EX_CLDR_UNIT was not found."; exit 1; }

# The location of the cloned CLDR repo
export CLDR_REPO="${CLDR_REPO:=$HOME/Development/cldr_repo}"
[ ! -d $CLDR_REPO ] && { echo "Unicode CLDR repository $CLDR_REPO was not found."; exit 1; }

cp $CLDR_REPO/common/testData/units/unitPreferencesTest.txt $EX_CLDR_UNIT/test/support/data/preference_test_data.txt
cp $CLDR_REPO/common/testData/units/unitsTest.txt $EX_CLDR_UNIT/test/support/data/conversion_test_data.txt
