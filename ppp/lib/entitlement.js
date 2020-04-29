
global.EntitlementComparisonResult = {
    // Reject
    ProfileDoesNotHaveRequiredKey: -1,

    // Key is not in either app or profile
    AppNorProfileHasKey: 0,

    // Accept
    ProfileHasKeyExactly: 1,
    ProfileHasKey: 100,
    ProfileHasUnrequiredKey: 1000
};

class Entitlement {
  constructor(key, value) {
    this.key = key;
    this.value = value;
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

  static compare(profileEntitlement, appEntitlement) {
    return EntitlementComparisonResult.AppNorProfileHasKey;
  }
}

module.exports = Entitlement;
