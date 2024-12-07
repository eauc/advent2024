require('../init');
const {
  parseSafetyManualUpdatesFile,
  auditSafetyManualUpdates,
  middlePageNumber,
  checkSafetyManualUpdates,
} = require('./safetyManualUpdates');

describe('day04/parseSafetyManualUpdatesFile', () => {
  it('reads pages orders header {before}|{after}', () => {
    const { pageOrders } = parseSafetyManualUpdatesFile({
      fileName: 'data/day05/test.txt',
    });
    expect({ pageOrders }).to.eql({
      pageOrders: {
        29: [13],
        47: [53, 13, 61, 29],
        53: [29, 13],
        61: [13, 53, 29],
        75: [29, 53, 47, 61, 13],
        97: [13, 61, 47, 29, 53, 75],
      },
    });
  });

  it('reads pages updates lines', () => {
    const { pageUpdates } = parseSafetyManualUpdatesFile({
      fileName: 'data/day05/test.txt',
    });
    expect({ pageUpdates }).to.eql({
      pageUpdates: [
        [75, 47, 61, 53, 29],
        [97, 61, 53, 29, 13],
        [75, 29, 13],
        [75, 97, 47, 61, 53],
        [61, 13, 29],
        [97, 13, 75, 29, 47],
      ],
    });
  });
});

describe('day04/auditSafetyManualUpdates', () => {
  describe(`Safety protocols clearly indicate that new pages for the safety manuals must be printed in a very specific order. 
    The notation X|Y means that if both page number X and page number Y are to be produced as part of an update,
    page number X must be printed at some point before page number Y.`, () => {
    it(`75,47,61,53,29 is ok
      - 75 is correctly first because there are rules that put each other page after it: 75|47, 75|61, 75|53, and 75|29.
      - 47 is correctly second because 75 must be before it (75|47) and every other page must be after it according to 47|61, 47|53, and 47|29.
      - 61 is correctly in the middle because 75 and 47 are before it (75|61 and 47|61) and 53 and 29 are after it (61|53 and 61|29).
      - 53 is correctly fourth because it is before page number 29 (53|29).
      - 29 is the only page left and so is correctly last. `, () => {
      expect(
        auditSafetyManualUpdates({
          pageUpdates: [75, 47, 61, 53, 29],
          pageOrders: {
            29: [13],
            47: [53, 13, 61, 29],
            53: [29, 13],
            61: [13, 53, 29],
            75: [29, 53, 47, 61, 13],
            97: [13, 61, 47, 29, 53, 75],
          },
        })
      ).to.eql({
        isOk: true,
        correctPageUpdates: [75, 47, 61, 53, 29],
        errors: {},
      });
    });

    it(`97,61,53,29,13 is ok`, () => {
      expect(
        auditSafetyManualUpdates({
          pageUpdates: [97, 61, 53, 29, 13],
          pageOrders: {
            29: [13],
            47: [53, 13, 61, 29],
            53: [29, 13],
            61: [13, 53, 29],
            75: [29, 53, 47, 61, 13],
            97: [13, 61, 47, 29, 53, 75],
          },
        })
      ).to.eql({
        isOk: true,
        correctPageUpdates: [97, 61, 53, 29, 13],
        errors: {},
      });
    });

    it(`75,29,13 is ok`, () => {
      expect(
        auditSafetyManualUpdates({
          pageUpdates: [75, 29, 13],
          pageOrders: {
            29: [13],
            47: [53, 13, 61, 29],
            53: [29, 13],
            61: [13, 53, 29],
            75: [29, 53, 47, 61, 13],
            97: [13, 61, 47, 29, 53, 75],
          },
        })
      ).to.eql({
        isOk: true,
        correctPageUpdates: [75, 29, 13],
        errors: {},
      });
    });

    it(`75,97,47,61,53 is not ok: it would print 75 before 97, which violates the rule 97|75`, () => {
      expect(
        auditSafetyManualUpdates({
          pageUpdates: [75, 97, 47, 61, 53],
          pageOrders: {
            29: [13],
            47: [53, 13, 61, 29],
            53: [29, 13],
            61: [13, 53, 29],
            75: [29, 53, 47, 61, 13],
            97: [13, 61, 47, 29, 53, 75],
          },
        })
      ).to.eql({
        isOk: false,
        correctPageUpdates: [97, 75, 47, 61, 53],
        errors: {
          97: [75],
        },
      });
    });

    it(`61,13,29 is not ok: it breaks the rule 29|13`, () => {
      expect(
        auditSafetyManualUpdates({
          pageUpdates: [61, 13, 29],
          pageOrders: {
            29: [13],
            47: [53, 13, 61, 29],
            53: [29, 13],
            61: [13, 53, 29],
            75: [29, 53, 47, 61, 13],
            97: [13, 61, 47, 29, 53, 75],
          },
        })
      ).to.eql({
        isOk: false,
        correctPageUpdates: [61, 29, 13],
        errors: {
          29: [13],
        },
      });
    });

    it(`97,13,75,29,47 is not ok: it breaks several rules`, () => {
      expect(
        auditSafetyManualUpdates({
          pageUpdates: [97, 13, 75, 29, 47],
          pageOrders: {
            29: [13],
            47: [53, 13, 61, 29],
            53: [29, 13],
            61: [13, 53, 29],
            75: [29, 53, 47, 61, 13],
            97: [13, 61, 47, 29, 53, 75],
          },
        })
      ).to.eql({
        isOk: false,
        correctPageUpdates: [97, 75, 47, 29, 13],
        errors: {
          29: [13],
          47: [13, 29],
          75: [13],
        },
      });
    });
  });
});

describe('day04/middlePageNumber', () => {
  it(`For some reason, the Elves also need to know the middle page number of each update being printed`, () => {
    expect(middlePageNumber({ pageUpdates: [75, 47, 61, 53, 29] })).to.equal(
      61
    );
    expect(middlePageNumber({ pageUpdates: [97, 61, 53, 29, 13] })).to.equal(
      53
    );
    expect(middlePageNumber({ pageUpdates: [75, 29, 13] })).to.equal(29);
  });
});

describe('day04/checkPageUpdates', () => {
  it(`adds middle page numbers of all valid and invalid updates`, () => {
    expect(
      checkSafetyManualUpdates({
        pageUpdates: [
          [75, 47, 61, 53, 29],
          [97, 61, 53, 29, 13],
          [75, 29, 13],
          [75, 97, 47, 61, 53],
          [61, 13, 29],
          [97, 13, 75, 29, 47],
        ],
        pageOrders: {
          29: [13],
          47: [53, 13, 61, 29],
          53: [29, 13],
          61: [13, 53, 29],
          75: [29, 53, 47, 61, 13],
          97: [13, 61, 47, 29, 53, 75],
        },
      })
    ).to.eql({
      correctPageUpdatesCheck: 143,
      incorrectPageUpdatesCheck: 123,
    });
  });
});
