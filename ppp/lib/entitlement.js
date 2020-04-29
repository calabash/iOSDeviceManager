
global.EntitlementComparisonResult = {
    // Reject
    ProfileDoesNotHaveRequiredKey: -1,

    // Key is not in either app or profile
    AppNorProfileHasKey: 0,

    // Accept
    ProfileHasKeyExactly: 1,
    ProfileHasKey: 100,
    ProfileHasUnRequiredKey: 1000
};

class Entitlement {
  constructor(key, value) {
    this.key = key;
    if (value === undefined) {
      this.value = null;
    } else {
      this.value = value;
    }
  }

  hasArrayValue() {
    return Array.isArray(this.value);
  }

  hasStringValue() {
    return (typeof this.value === "string" || this.value instanceof String);
  }

  hasBoolValue() {
    return (typeof this.value === "boolean");
  }

  static compareEntitlementArrays(appArray, profileArray) {
    if (appArray.length > profileArray.length) {
      return this.compareLargerAppArray(appArray, profileArray);
    } else if (appArray.length < profileArray.length) {
      return this.compareLargerProfileArray(appArray, profileArray);
    } else {
      return this.compareEqualSizedArrays(appArray, profileArray);
    }
  }

  static compareEqualSizedArrays(appArray, profileArray) {
    // We know they are equal sized
    for (let elm of appArray) {
      if (!profileArray.includes(elm)) {
        return EntitlementComparisonResult.ProfileHasKey;
      }
    }

    for (let elm of profileArray) {
      if (!appArray.includes(elm)) {
        return EntitlementComparisonResult.ProfileHasKey;
      }
    }
    return EntitlementComparisonResult.ProfileHasKeyExactly;
  }

  static compareLargerProfileArray(appArray, profileArray) {
    // Prefer profiles with _fewer_ entitlements
    return (profileArray.length - appArray.length) *
      EntitlementComparisonResult.ProfileHasKey;
  }

  static compareLargerAppArray(appArray, profileArray) {
    // Can match if profile has one element that is the wildcard or wildcard
    // Team ID.
    //
    // Maybe this could be expanded to 'profile has _any_ element that is
    // the wildcard or wildcard Team ID
    if (profileArray.length === 1) {
      const profileValue = profileArray[0];
      if (profileValue === "*" ||
        // e.g. FYD86LA7RE.* - looks like a Team ID
        (profileValue.length === 12 && profileValue.endsWith("*"))) {
        return EntitlementComparisonResult.ProfileHasKey;
      }
    }
    return EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey;
  }

  static compare(profileEntitlement, appEntitlement) {
    if (appEntitlement.value && (profileEntitlement.value === null)) {
      return EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey;
    }

    if (appEntitlement.value === null) {
      if (profileEntitlement.value === null) {
        return EntitlementComparisonResult.AppNorProfileHasKey;
      } else {
        return EntitlementComparisonResult.ProfileHasUnRequiredKey;
      }
    }

    if (appEntitlement.hasArrayValue()) {
      if (profileEntitlement.hasArrayValue()) {
        const appArray = appEntitlement.value;
        const profileArray = profileEntitlement.value;
        return this.compareEntitlementArrays(appArray, profileArray);
      } else if (profileEntitlement.hasStringValue()) {
        if (profileEntitlement.value === "*") {
          return EntitlementComparisonResult.ProfileHasKey;
        } else {
          return EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey;
        }
      } else {
        // Profile entitlement is neither a string or array.
        // Assume profile does not have the required key.
      }
    } else if (appEntitlement.hasStringValue()) {
      if (profileEntitlement.hasStringValue()) {
        if (appEntitlement.value === profileEntitlement.value) {
          return EntitlementComparisonResult.ProfileHasKeyExactly;
        } else {
          return EntitlementComparisonResult.ProfileHasKey;
        }
      } else if (profileEntitlement.hasArrayValue()) {
         if (appEntitlement.value === "*") {
           // I don't understand this one.
           return EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey;
         } else {
           const profileArr = profileEntitlement.value;
           if (profileArr.includes(appEntitlement.value)) {
             return EntitlementComparisonResult.ProfileHasKey;
           } else {
             return EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey;
           }
         }
      } else {
        // Profile entitlment is neither a string or array.
        // Assume profile does not have the required key.
      }
    } else if (appEntitlement.hasBoolValue()) {
      if (profileEntitlement.hasBoolValue()) {
        console.log("in the bool / bool case");
        if (appEntitlement.value == profileEntitlement.value) {
          return EntitlementComparisonResult.ProfileHasKeyExactly;
        } else {
          // Maybe revisit this
          return EntitlementComparisonResult.ProfileHasKey;
        }
      } else {
         return EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey;
      }
    }

    console.error("Unable to match entitlement, unexpected type(s)");
    console.error(`                      key: ${profileEntitlement.key}`);
    console.error(` profile entitlement type: ${typeof(profileEntitlement.value)}`);
    console.error(`profile entitlement value: ${profileEntitlement.value}`);
    console.error(`     app entitlement type: ${typeof(appEntitlement.value)}`);
    console.error(`    app entitlement value: ${appEntitlement.value}`);
    return EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey;
  }

}

module.exports = Entitlement;
