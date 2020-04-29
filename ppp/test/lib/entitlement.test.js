const expect = require('chai').expect;
const Entitlement = require("../../lib/entitlement.js");

describe("EntitlementComparisonResult", () => {
  it("is exported or available globally", () => {
   expect(EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey).to.equal(-1);
  });
});

describe("Entitlement", () => {
  it("is a class with a constructor", () => {
    const instance = new Entitlement("key", "value");
    expect(instance.key).to.equal("key");
    expect(instance.value).to.equal("value");
  });

  describe("#hasArrayValue", () => {
    it("returns true when value is an array", () => {
      const instance = new Entitlement("key", ["a", "b", "c"]);
      expect(instance.hasArrayValue()).is.equal(true);
    });

    it("returns false when value is not an array", () => {
      const instance = new Entitlement("key", "string");
      expect(instance.hasArrayValue()).is.equal(false);
    });
  });

  describe("#hasStringValue", () => {
    it("returns true when value is a string", () => {
      let instance = new Entitlement("key", "string");
      expect(instance.hasStringValue()).is.equal(true);

      instance = new Entitlement("key", new String("string"));
      expect(instance.hasStringValue()).is.equal(true);
    });

    it("returns false when value is not a string", () => {
      const instance = new Entitlement("key", ["a", "b", "c"]);
      expect(instance.hasStringValue()).is.equal(false);
    });
  });

  describe("#hasBoolValue", () => {
    it("returns true when value is a boolean", () => {
      let instance = new Entitlement("key", false);
      expect(instance.hasBoolValue()).is.equal(true);

      instance = new Entitlement("key", true);
      expect(instance.hasBoolValue()).is.equal(true);
    });

    it("returns false when value is not a boolean", () => {
      const instance = new Entitlement("key", ["a", "b", "c"]);
      expect(instance.hasBoolValue()).is.equal(false);
    });
  });

  describe(".compare", () => {
    it("returns profile does not have required key", () => {
      expect(Entitlement.compare(null, null)).to.equal(0);
    });
  });
});
