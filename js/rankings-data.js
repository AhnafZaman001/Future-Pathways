/* =========================================================
   rankings-data.js — curated data for the University Explorer
   (rankings.html). Field → subset → ranked universities.

   SOURCING POLICY (mirrors the merit-data verification rule
   for this project): every ranked entry either cites a real,
   checkable source (QS Subject Rankings, QS World University
   Rankings, or UHS official closing-merit announcements as
   reported by Dawn), or is explicitly marked unranked with a
   plain-language reason. No invented positions, ever. Where a
   subject-specific rank doesn't exist, the institution's
   overall/subject-family rank is shown with that fact stated,
   not disguised as a subject rank.

   Update this file, don't hardcode ranking numbers elsewhere.
   ========================================================= */

window.RANKING_DATA = {

  engineering: {
    label: "Engineering",
    subsets: [
      "Electrical Engineering", "Mechanical Engineering", "Civil Engineering",
      "Chemical Engineering", "Industrial & Manufacturing", "Biomedical Engineering",
      "Petroleum Engineering", "Telecommunication Engineering", "Aerospace / Aeronautical",
      "Environmental Engineering", "Metallurgical Engineering", "Mining Engineering",
      "Textile Engineering"
    ],
    // Applies to all subsets above unless a subset has its own
    // override block further down — see `overrides`.
    baseRanking: [
      { rank: 1, name: "NUST", detail: "QS Engineering & Technology #127 globally — #1 in Pakistan for engineering", source: "QS Subject Rankings 2025", sourceUrl: "https://nust.edu.pk/about-us/nust-rankings/" },
      { rank: 2, name: "PIEAS", detail: "QS overall #721 globally (2026); historically HEC's #2 Engineering & Technology institution", source: "QS World University Rankings 2026 / HEC category ranking", sourceUrl: null },
      { rank: 3, name: "GIK Institute (GIKI)", detail: "Not currently listed in QS's global ranking; historically HEC's #3 Engineering & Technology institution", source: "HEC category ranking (dated methodology — verify current cycle)", sourceUrl: null },
      { rank: 4, name: "UET Lahore", detail: "QS overall #801 globally (2026)", source: "QS World University Rankings 2026", sourceUrl: null },
      { rank: 5, name: "COMSATS University Islamabad", detail: "QS overall #664 globally (2026)", source: "QS World University Rankings 2026", sourceUrl: null }
    ],
    overrides: {
      "Electrical Engineering": [
        { rank: 1, name: "NUST", detail: "QS Electrical Engineering #143 globally", source: "QS Subject Rankings 2025", sourceUrl: "https://parhlai.com/blog/nust-qs-rankings" }
      ],
      "Chemical Engineering": [
        { rank: 1, name: "NUST", detail: "QS Chemical Engineering — top 200 globally", source: "QS Subject Rankings 2025", sourceUrl: "https://parhlai.com/blog/nust-qs-rankings" }
      ],
      "Civil Engineering": [
        { rank: 1, name: "NUST", detail: "QS Civil Engineering — top 375 globally", source: "QS Subject Rankings 2025", sourceUrl: "https://parhlai.com/blog/nust-qs-rankings" }
      ],
      "Aerospace / Aeronautical": [
        { rank: 1, name: "NUST", detail: "QS Mechanical & Aeronautical Engineering — top 250 globally", source: "QS Subject Rankings 2025", sourceUrl: "https://parhlai.com/blog/nust-qs-rankings" }
      ]
    },
    // Institutes that offer programs in this field but have no
    // independently verifiable subject/QS/HEC ranking we could
    // confirm — listed for completeness, not scored.
    alsoOffered: [
      "UET Taxila / Chakwal", "Punjab University Engineering Programs", "Air University",
      "Bahria University", "NTU Faisalabad", "IST Islamabad", "International Islamic University",
      "NASTP", "Namal University"
    ]
  },

  computing: {
    label: "Computing",
    subsets: [
      "Computer Science", "Software Engineering", "Artificial Intelligence",
      "Data Science", "Cybersecurity", "Information Technology", "Computer Engineering"
    ],
    baseRanking: [
      { rank: 1, name: "NUST (SEECS)", detail: "QS Computer Science & Information Systems #164 globally", source: "QS Subject Rankings 2025", sourceUrl: "https://nust.edu.pk/about-us/nust-rankings/" },
      { rank: 2, name: "University of the Punjab (PUCIT)", detail: "QS Computer Science & Information Systems #301–350 globally", source: "QS Subject Rankings 2025", sourceUrl: null },
      { rank: 3, name: "LUMS", detail: "QS Computer Science & Information Systems #401–450 globally", source: "QS Subject Rankings 2025", sourceUrl: null },
      { rank: 3, name: "UET Lahore", detail: "QS Computer Science & Information Systems #401–450 globally (tied band with LUMS)", source: "QS Subject Rankings 2025", sourceUrl: null }
    ],
    overrides: {},
    // FAST-NUCES is deliberately here, not in the ranked list —
    // sources conflicted on its exact QS subject position, and
    // per this project's data policy we don't publish a number
    // we can't independently confirm. It is widely regarded by
    // employers as Pakistan's leading dedicated computing
    // institution; that reputation just isn't a QS number.
    alsoOffered: [
      "FAST-NUCES (widely regarded as Pakistan's leading dedicated computing university by employer surveys — not separately QS subject-ranked at a confirmed position)",
      "GIK Institute (GIKI)", "COMSATS University Islamabad", "PIEAS", "ITU Lahore",
      "Air University", "Bahria University", "Namal University"
    ]
  },

  medical: {
    label: "Medical",
    subsets: ["MBBS", "BDS", "Pharm D", "DPT", "DVM"],
    // Pakistan has no independent QS-style subject ranking that
    // covers individual Punjab medical colleges by name. The
    // most honest, real signal available is admission
    // competitiveness itself — open-merit closing aggregate —
    // which is exactly what students use in practice to judge
    // relative standing. Labeled explicitly as that, not as a
    // quality ranking.
    baseRanking: [
      { rank: 1, name: "King Edward Medical University", detail: "Open-merit MBBS closing aggregate: 93.55%", source: "UHS official selection list, reported by Dawn", sourceUrl: "https://www.dawn.com/news/1727898" },
      { rank: 2, name: "Rawalpindi Medical University", detail: "Open-merit MBBS closing aggregate: 93.23%", source: "UHS official selection list, reported by Dawn", sourceUrl: "https://www.dawn.com/news/1727898" },
      { rank: 3, name: "Allama Iqbal Medical College", detail: "Open-merit MBBS closing aggregate: 92.64%", source: "UHS official selection list, reported by Dawn", sourceUrl: "https://www.dawn.com/news/1727898" },
      { rank: 4, name: "Services Institute of Medical Sciences", detail: "Open-merit MBBS closing aggregate: 92.10%", source: "UHS official selection list, reported by Dawn", sourceUrl: "https://www.dawn.com/news/1727898" },
      { rank: 5, name: "Ameer-ud-Din Medical College", detail: "Open-merit MBBS closing aggregate: 91.75%", source: "UHS official selection list, reported by Dawn", sourceUrl: "https://www.dawn.com/news/1727898" },
      { rank: 6, name: "Nishtar Medical University", detail: "Open-merit MBBS closing aggregate: 91.49%", source: "UHS official selection list, reported by Dawn", sourceUrl: "https://www.dawn.com/news/1727898" },
      { rank: 7, name: "Fatima Jinnah Medical University", detail: "Open-merit MBBS closing aggregate: 91.34%", source: "UHS official selection list, reported by Dawn", sourceUrl: "https://www.dawn.com/news/1727898" },
      { rank: 8, name: "Punjab Medical College", detail: "Open-merit MBBS closing aggregate: 91.17%", source: "UHS official selection list, reported by Dawn", sourceUrl: "https://www.dawn.com/news/1727898" },
      { rank: 9, name: "Gujranwala Medical College", detail: "Open-merit MBBS closing aggregate: 91.04%", source: "UHS official selection list, reported by Dawn", sourceUrl: "https://www.dawn.com/news/1727898" },
      { rank: 10, name: "Quaid-Azam Medical College", detail: "Open-merit MBBS closing aggregate: 90.76%", source: "UHS official selection list, reported by Dawn", sourceUrl: "https://www.dawn.com/news/1727898" }
    ],
    overrides: {
      // BDS/Pharm D/DPT/DVM closing merit runs on separate UHS
      // lists we haven't verified yet — shown unranked rather
      // than reusing the MBBS list, which would misrepresent it.
      "BDS": "unranked", "Pharm D": "unranked", "DPT": "unranked", "DVM": "unranked"
    },
    alsoOffered: [
      "Aga Khan University", "Shifa College of Medicine", "CMH Lahore Medical College",
      "Army Medical College Rawalpindi", "Sheikh Zayed Medical College", "DG Khan Medical College"
    ],
    dataNote: "This list reflects one officially reported UHS admission cycle, cited via Dawn's coverage of the announcement. Closing merit shifts every year — always confirm against the current UHS selection list before relying on this for a real decision."
  }
};
