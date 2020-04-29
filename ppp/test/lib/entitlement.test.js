const expect = require('chai').expect;
const Entitlement = require("../../lib/entitlement.js");

describe("EntitlementComparisonResult", () => {
  it("is exported or available globally", () => {
   expect(EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey).to.equal(-1);
  });
});

describe("Entitlement", () => {

  describe(".contructor", () => {
    it("binds key and value correctly", () => {
      const instance = new Entitlement("key", "value");
      expect(instance.key).to.equal("key");
      expect(instance.value).to.equal("value");
    });

    it("handles null and undefined values correctly", () => {
      let instance = new Entitlement("key", undefined);
      expect(instance.value).to.equal(null);

      instance = new Entitlement("key", null);
      expect(instance.value).to.equal(null);
    });

    it("handles true/false liternals", () => {
      let a = new Entitlement("key", false);
      let b = new Entitlement("key", false);

      expect(a.value === b.value).to.equal(true);

      a = new Entitlement("key", true);
      b = new Entitlement("key", true);

      expect(a.value === b.value).to.equal(true);
    });
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
    describe("simple cases", () => {
      it("returns ProfileDoesNotHaveRequiredKey when app has entitlement " +
        "but profile does not", () => {
          const app = new Entitlement("key", ["a", "b", "c"]);
          const profile = new Entitlement("key", null);

          actual = Entitlement.compare(profile, app);
          expected = EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey;
          expect(actual).to.equal(expected);
        });

      it("returns AppNorProfileHasKey when app does not contain the entitlement " +
        "and the profile does not contain the entitlement", () => {
          const app = new Entitlement("key", null);
          const profile = new Entitlement("key", null);

          actual = Entitlement.compare(profile, app);
          expected = EntitlementComparisonResult.AppNorProfileHasKey;
          expect(actual).to.equal(expected);
        });

      it("returns ProfileHasUnRequiredKey when app does not have the entitlement " +
        "but the profile does have the entitlement", () => {
          const app = new Entitlement("key", null);
          const profile = new Entitlement("key", "value");

          actual = Entitlement.compare(profile, app);
          expected = EntitlementComparisonResult.ProfileHasUnRequiredKey;
          expect(actual).to.equal(expected);
        });
    });

    describe("app entitlement is an array", () => {
      let app = new Entitlement("key", ["a", "b", "c"]);

      describe("profile entitlement is an array", () => {
        describe("app array count is > profile array count", () => {
          describe("profile array count == 1", () => {
            it("returns ProfileHasKey when profile[0] is == '*'", () => {
              const profile = new Entitlement("key", ["*"]);

              actual = Entitlement.compare(profile, app);
              expected = EntitlementComparisonResult.ProfileHasKey;
              expect(actual).to.equal(expected);
            });

            // suspicious!
            it("returns ProfileHasKey when profile[0] looks like a Team ID", () => {
              const profile = new Entitlement("key", ["FYD86LA7RE.*"]);

              actual = Entitlement.compare(profile, app);
              expected = EntitlementComparisonResult.ProfileHasKey;
              expect(actual).to.equal(expected);
            });

            it("returns ProfileDoesNotHaveRequiredKey in other cases", () => {
              const profile = new Entitlement("key", ["ABCE"]);

              actual = Entitlement.compare(profile, app);
              expected = EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey;
              expect(actual).to.equal(expected);
            });
          });

          describe("profile array count != 1", () => {
            it("return ProfileDoesNotHaveRequiredKey", () => {
              const profile = new Entitlement("key", ["a", "b"]);

              actual = Entitlement.compare(profile, app);
              expected = EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey;
              expect(actual).to.equal(expected);
            });
          });
        });

        describe("app array count < profile array count", () => {
          it("returns (profile count - app count) * ProfileHasKey", () => {
            const profile = new Entitlement("key", ["a", "b", "c", "d", "e"]);

            actual = Entitlement.compare(profile, app);
            expected = EntitlementComparisonResult.ProfileHasKey * 2
            expect(actual).to.equal(expected);
          });
        });

        describe("app array count == profile count", () => {
          it("returns ProfileHasKeyExactly when app and profile arrays are " +
            "the same", () => {
              const profile = new Entitlement("key", ["a", "b", "c"]);

              actual = Entitlement.compare(profile, app);
              expected = EntitlementComparisonResult.ProfileHasKeyExactly;
              expect(actual).to.equal(expected);
            });
          it("returns ProfileHasKey otherwise", () => {
              const profile = new Entitlement("key", ["a", "b", "d"]);

              actual = Entitlement.compare(profile, app);
              expected = EntitlementComparisonResult.ProfileHasKey;
              expect(actual).to.equal(expected);
          });
        });
      });

      describe("profile entitlement is a string", () => {
        it("returns ProfileHasKey if string value is '*'", () => {
          const profile = new Entitlement("key", "*");

          actual = Entitlement.compare(profile, app);
          expected = EntitlementComparisonResult.ProfileHasKey;
          expect(actual).to.equal(expected);
        });

        it("returns ProfileDoesNotHaveRequiredKey otherwise", () => {
          const profile = new Entitlement("key", "not a wildcard");

          actual = Entitlement.compare(profile, app);
          expected = EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey;
          expect(actual).to.equal(expected);
        });
      });

      it("returns ProfileDoesNotHaveRequiredKey when profile value is not a " +
        "string or array", () => {
          const profile = new Entitlement("key", 6.23);

          actual = Entitlement.compare(profile, app);
          expected = EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey;
          expect(actual).to.equal(expected);
       });
    });

    describe("app entitlement is string", () => {
      let app = new Entitlement("key", "string entitlement");

      describe("profile entitlement is a string", () => {
        it("returns ProfileHasKeyExactly when app and profile are exactly the " +
          "same", () => {
            const profile = new Entitlement("key", app.value);

            actual = Entitlement.compare(profile, app);
            expected = EntitlementComparisonResult.ProfileHasKeyExactly;
            expect(actual).to.equal(expected);
        });

        it("returns ProfileHasKey otherwise", () => {
            const profile = new Entitlement("key", "string value");

            actual = Entitlement.compare(profile, app);
            expected = EntitlementComparisonResult.ProfileHasKey;
            expect(actual).to.equal(expected);
        });
      });

      describe("profile entitlement is an array", () => {
        it("returns ProfileDoesNotHaveRequiredKey when app entitlement is '*'", () => {
          app = new Entitlement("key", "*");
          const profile = new Entitlement("key", ["a", "b", "c"]);

          actual = Entitlement.compare(profile, app);
          expected = EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey;
          expect(actual).to.equal(expected);
        });

        it("returns ProfileHasKey if profile array contains app value", () => {
          // let does not work like rspec let.  if 'app' is assigned here
          // it's value persists across tests. :(
          const otherApp = new Entitlement("key", "a");
          const profile = new Entitlement("key", ["a", "b", "c"]);

          actual = Entitlement.compare(profile, otherApp);
          expected = EntitlementComparisonResult.ProfileHasKey;
          expect(actual).to.equal(expected);
        });

        it("returns ProfileDoesNotHaveRequiredKey when profile does not " +
          "contain app value", () => {
          const profile = new Entitlement("key", ["a", "b", "c"]);

          actual = Entitlement.compare(profile, app);
          expected = EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey;
          expect(actual).to.equal(expected);
        });
      });

      it("returns ProfileDoesNotHaveRequiredKey when profile entitlement is " +
        "not a string or array", () => {
          const profile = new Entitlement("key", 11.11);

          actual = Entitlement.compare(profile, app);
          expected = EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey;
          expect(actual).to.equal(expected);
      });
    });

    describe("app entitlement is a bool", () => {
      describe("profile entitlement is a bool", () => {
        it("returns ProfileDoesNotHaveRequiredKey when profile entitlement " +
          "is not a bool value", () => {
          const app = new Entitlement("key", false);
          const profile = new Entitlement("key", "string");

          actual = Entitlement.compare(profile, app);
          expected = EntitlementComparisonResult.ProfileDoesNotHaveRequiredKey;
          expect(actual).to.equal(expected);
        });

        it("returns ProfileHasKeyExactly if app value == profile value", () => {
          let app = new Entitlement("key", true);
          let profile = new Entitlement("key", true);

          actual = Entitlement.compare(profile, app);
          expected = EntitlementComparisonResult.ProfileHasKeyExactly;
          expect(actual).to.equal(expected);

          app = new Entitlement("key", true);
          profile = new Entitlement("key", true);

          actual = Entitlement.compare(profile, app);
          expected = EntitlementComparisonResult.ProfileHasKeyExactly;
          expect(actual).to.equal(expected);
        });

        it("returns ProfileHasKey when app value != profile value", () => {
          let app = new Entitlement("key", true);
          let profile = new Entitlement("key", false);

          actual = Entitlement.compare(profile, app);
          expected = EntitlementComparisonResult.ProfileHasKey;
          expect(actual).to.equal(expected);

          app = new Entitlement("key", false);
          profile = new Entitlement("key", true);

          actual = Entitlement.compare(profile, app);
          expected = EntitlementComparisonResult.ProfileHasKey;
          expect(actual).to.equal(expected);
        });
      });
    });
  });
});