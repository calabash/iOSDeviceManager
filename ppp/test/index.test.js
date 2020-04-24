const expect = require('chai').expect;

describe("Simple Math Test", () => {
  it("1+1 = 2", () => {
    expect(1+1).to.equal(2);
  });

  it("3 * 3 = 9", () => {
    expect(3*3).to.equal(9);
  });
});
