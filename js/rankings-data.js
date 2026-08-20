/* =========================================================
   rankings-data.js — curated data for the University Explorer
   (rankings.html). Field → subset → ranked universities.

   SOURCING POLICY: every ranked entry either cites a real,
   checkable source, or is explicitly marked unranked with a
   plain-language reason. No invented positions, ever.

   Last verified: August 2026 against:
   - QS World University Rankings by Subject 2026
     (Dawn, Express Tribune, LUMS official release Mar 2026)
   - QS World University Rankings 2026 (overall)
   - Times Higher Education 2026 (Gulf News coverage)
   - HEC Pakistan category rankings
   - UAF official news / TopUniversities.com subject data
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
    baseRanking: [
      { rank: 1, name: "NUST", detail: "QS Engineering & Technology 201\u2013250 globally (2026) \u2014 #1 in Pakistan for engineering", source: "QS Subject Rankings 2026 / Dawn Mar 2026", sourceUrl: "https://www.dawn.com/news/1985415", theBand: "601\u2013800" },
      { rank: 2, name: "PIEAS", detail: "QS overall #721 globally (2026); HEC #2 Engineering & Technology institution in Pakistan", source: "QS World University Rankings 2026", sourceUrl: null, theBand: null },
      { rank: 3, name: "GIK Institute (GIKI)", detail: "THE 2026 band 801\u20131000; historically HEC #3 Engineering & Technology institution", source: "THE World University Rankings 2026 / HEC", sourceUrl: null, theBand: "801\u20131000" },
      { rank: 4, name: "UET Lahore", detail: "QS overall #801 globally (2026); QS Engineering 251\u2013400", source: "QS World University Rankings 2026 / QS Subject Rankings 2026", sourceUrl: null, theBand: "801\u20131000" },
      { rank: 5, name: "COMSATS University Islamabad", detail: "QS overall #664 globally (2026); QS Engineering 251\u2013300", source: "QS World University Rankings 2026 / QS Subject Rankings 2026", sourceUrl: null, theBand: "601\u2013800" }
    ],
    overrides: {
      "Electrical Engineering": [
        { rank: 1, name: "NUST", detail: "QS Electrical Engineering top 150 globally", source: "QS Subject Rankings 2025/2026", sourceUrl: "https://nust.edu.pk/about-us/nust-rankings/" }
      ],
      "Chemical Engineering": [
        { rank: 1, name: "NUST", detail: "QS Chemical Engineering top 200 globally", source: "QS Subject Rankings 2025", sourceUrl: "https://parhlai.com/blog/nust-qs-rankings" }
      ],
      "Civil Engineering": [
        { rank: 1, name: "NUST", detail: "QS Civil Engineering top 375 globally", source: "QS Subject Rankings 2025", sourceUrl: "https://parhlai.com/blog/nust-qs-rankings" }
      ],
      "Aerospace / Aeronautical": [
        { rank: 1, name: "NUST", detail: "QS Mechanical & Aeronautical Engineering top 250 globally", source: "QS Subject Rankings 2025", sourceUrl: "https://parhlai.com/blog/nust-qs-rankings" }
      ]
    },
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
      { rank: 1, name: "NUST (SEECS)", detail: "QS Computer Science & Information Systems 201\u2013300 globally (2026)", source: "QS Subject Rankings 2026 / Dawn Mar 2026", sourceUrl: "https://www.dawn.com/news/1985415", theBand: "601\u2013800" },
      { rank: 2, name: "University of the Punjab (PUCIT)", detail: "QS Computer Science 301\u2013350 globally (2025)", source: "QS Subject Rankings 2025", sourceUrl: null, theBand: "801\u20131000" },
      { rank: 3, name: "LUMS", detail: "QS Computer Science 401\u2013450 globally (2025); QS overall #555 (2026)", source: "QS Subject Rankings 2025 / QS 2026", sourceUrl: null, theBand: "801\u20131000" },
      { rank: 3, name: "UET Lahore", detail: "QS Computer Science 401\u2013450 globally (tied band with LUMS)", source: "QS Subject Rankings 2025", sourceUrl: null, theBand: "801\u20131000" },
      { rank: 5, name: "COMSATS University Islamabad", detail: "QS Computer Science & IT 201\u2013250 globally (2026)", source: "QS Subject Rankings 2026 / Express Tribune Mar 2026", sourceUrl: "https://tribune.com.pk/story/2599389/35-pakistani-universities-feature-in-qs-subject-rankings-2026", theBand: "601\u2013800" }
    ],
    industryReputation: {
      note: "Named repeatedly across independent Pakistani education/career sources as the most employer-respected computing programs \u2014 this reflects informal consensus, not a published ranking with a stated methodology.",
      names: ["FAST-NUCES", "COMSATS University Islamabad", "NUST", "Punjab University College of IT (PUCIT)"]
    },
    overrides: {},
    alsoOffered: [
      "FAST-NUCES (widely regarded as Pakistan\u2019s leading dedicated computing university by employer surveys \u2014 not separately QS subject-ranked at a confirmed position)",
      "GIK Institute (GIKI)", "PIEAS", "ITU Lahore",
      "Air University", "Bahria University", "Namal University"
    ]
  },

  business: {
    label: "Business & Management",
    subsets: [
      "BBA / Business Administration", "Accounting & Finance", "Economics",
      "MBA", "Marketing", "Human Resource Management", "Supply Chain / Operations"
    ],
    baseRanking: [
      { rank: 1, name: "LUMS", detail: "QS Business & Management Studies 101\u2013150 globally (2026) \u2014 #1 in Pakistan. QS Accounting & Finance 101\u2013150 globally \u2014 #1 in Pakistan. QS overall #555 (2026).", source: "LUMS official / QS Subject Rankings 2026 / Dawn Mar 2026", sourceUrl: "https://lums.edu.pk/news/lums-recognised-top-pakistani-university-multiple-subjects-qs-rankings-2026", theBand: "801\u20131000" },
      { rank: 2, name: "IBA Karachi", detail: "QS Business & Management Studies 251\u2013300 globally (2026); QS Economics 151\u2013250 \u2014 consistently HEC #1 public business school. QS South Asia rank 70.", source: "QS Subject Rankings 2026 / TopUniversities / Express Tribune Mar 2026", sourceUrl: "https://www.topuniversities.com/universities/institute-business-administration-iba", theBand: null },
      { rank: 3, name: "University of the Punjab", detail: "QS Business & Management 201\u2013400 globally (2026); Pakistan\u2019s oldest university, largest by enrolment", source: "QS Subject Rankings 2026 / Express Tribune Mar 2026", sourceUrl: null, theBand: "801\u20131000" },
      { rank: 4, name: "Quaid-i-Azam University", detail: "QS Economics 201\u2013250 globally (joint top in Pakistan with LUMS); QS overall #354 \u2014 highest-ranked Pakistani university overall", source: "QS Subject Rankings 2026 / Dawn Mar 2026", sourceUrl: "https://www.dawn.com/news/1985415", theBand: "401\u2013500" }
    ],
    overrides: {},
    alsoOffered: [
      "NUST Business School", "GCU Lahore", "Bahria University",
      "COMSATS University Islamabad", "Air University", "UMT Lahore"
    ],
    dataNote: "No law-specific QS subject ranking exists for Pakistani universities. For law specifically, LUMS SAHSOL and University of the Punjab Law College are the most cited institutions \u2014 see the Law field."
  },

  law: {
    label: "Law",
    subsets: ["LLB (Hons) 5-year", "LLM", "Shariah & Law"],
    // No QS subject ranking for law in Pakistan. Best available signal
    // is consistent multi-source expert/employer reputation consensus
    // and HEC recognition -- labeled explicitly as that.
    baseRanking: [],
    overrides: { "LLB (Hons) 5-year": "unranked", "LLM": "unranked", "Shariah & Law": "unranked" },
    industryReputation: {
      note: "No QS or HEC subject ranking exists for law in Pakistan. This reflects consistent cross-source expert and employer reputation consensus as of 2025\u20132026 \u2014 not a published ranking with a stated methodology. LAT (Law Admission Test) is mandatory for all law programs.",
      names: [
        "LUMS (SAHSOL)",
        "University of the Punjab Law College",
        "International Islamic University Islamabad",
        "Superior University College of Law",
        "Government College University Lahore"
      ]
    },
    alsoOffered: [
      "SZABIST Islamabad / Karachi", "University of Karachi (School of Law)",
      "Bahauddin Zakariya University", "University of Peshawar"
    ],
    dataNote: "LUMS Shaikh Ahmad Hassan School of Law (SAHSOL) is widely cited as Pakistan\u2019s leading private law school (corporate / international law focus). Punjab University Law College is the most cited public institution with the longest history of producing judges and senior counsel. Islamabad is noted for constitutional law; Karachi for corporate and maritime law. HEC LAT is now mandatory for all admissions."
  },

  social_sciences: {
    label: "Social Sciences",
    subsets: [
      "Psychology", "Sociology", "Political Science", "International Relations",
      "Public Administration", "Media & Communication", "Development Studies"
    ],
    baseRanking: [
      { rank: 1, name: "LUMS", detail: "QS Social Sciences & Management 251\u2013300 globally (2026) \u2014 #1 in Pakistan for Social Sciences and also for Politics. QS overall #555 (2026).", source: "LUMS official / QS Subject Rankings 2026", sourceUrl: "https://lums.edu.pk/news/lums-recognised-top-pakistani-university-multiple-subjects-qs-rankings-2026", theBand: "801\u20131000" },
      { rank: 2, name: "University of the Punjab", detail: "QS Social Sciences 201\u2013400 globally (2026); largest social sciences faculty in Pakistan", source: "QS Subject Rankings 2026 / Express Tribune Mar 2026", sourceUrl: null, theBand: "801\u20131000" },
      { rank: 3, name: "Quaid-i-Azam University", detail: "QS overall #354 globally (2026); strong in political science and international relations", source: "QS World University Rankings 2026", sourceUrl: null, theBand: "401\u20131000" }
    ],
    overrides: {},
    alsoOffered: [
      "Habib University (social sciences, 400+ globally QS 2026)",
      "GCU Lahore", "Forman Christian College", "University of Karachi",
      "International Islamic University Islamabad", "Bahauddin Zakariya University"
    ]
  },

  natural_sciences: {
    label: "Natural Sciences",
    subsets: [
      "Physics", "Chemistry", "Biology / Biosciences",
      "Mathematics", "Statistics", "Environmental Sciences", "Geology"
    ],
    baseRanking: [
      { rank: 1, name: "Quaid-i-Azam University", detail: "QS Natural Sciences 201\u2013250 globally (2026); QS Physics & Astronomy 250\u2013400 \u2014 #1 in Pakistan for natural sciences. QS overall #354 \u2014 highest-ranked Pakistani university overall.", source: "QS Subject Rankings 2026 / Dawn Mar 2026", sourceUrl: "https://www.dawn.com/news/1985415", theBand: "401\u2013500" },
      { rank: 2, name: "NUST", detail: "Strong in applied sciences and research; QS overall #371 globally (2026)", source: "QS World University Rankings 2026", sourceUrl: null, theBand: "601\u2013800" },
      { rank: 3, name: "University of the Punjab", detail: "Large sciences faculty; QS overall #542 globally (2026); renown in chemistry and biological sciences", source: "QS World University Rankings 2026", sourceUrl: null, theBand: "801\u20131000" }
    ],
    overrides: {},
    alsoOffered: [
      "COMSATS University Islamabad", "GCU Lahore",
      "University of Karachi", "Bahauddin Zakariya University",
      "University of Agriculture Faisalabad"
    ]
  },

  agriculture: {
    label: "Agriculture & Veterinary",
    subsets: [
      "Agriculture", "Food Science & Technology", "Horticulture",
      "Veterinary Sciences", "Animal Husbandry", "Agricultural Engineering"
    ],
    baseRanking: [
      { rank: 1, name: "University of Agriculture Faisalabad", detail: "QS Agriculture & Forestry top 50\u201351 globally (2026) \u2014 #1 in Pakistan and one of the top 50 agriculture universities in the world. QS overall #654 globally.", source: "UAF official / QS Subject Rankings 2026 / Express Tribune Mar 2026", sourceUrl: "https://tribune.com.pk/story/2599389/35-pakistani-universities-feature-in-qs-subject-rankings-2026", theBand: "601\u2013800" },
      { rank: 2, name: "University of Veterinary & Animal Sciences Lahore", detail: "QS Subject Rankings 2026 participant; Pakistan\u2019s leading dedicated veterinary institution", source: "QS Subject Rankings 2026 / Express Tribune Mar 2026", sourceUrl: null, theBand: "601\u2013800" },
      { rank: 3, name: "NUST", detail: "Growing agriculture/biosciences research; QS overall #371 globally (2026)", source: "QS World University Rankings 2026", sourceUrl: null, theBand: "601\u2013800" }
    ],
    overrides: {},
    alsoOffered: [
      "Pir Mehr Ali Shah Arid Agriculture University Rawalpindi",
      "Muhammad Nawaz Shareef University of Agriculture Multan",
      "Sindh Agriculture University Tandojam",
      "University of Agriculture Peshawar"
    ]
  },

  medical: {
    label: "Medical",
    subsets: ["MBBS", "BDS", "Pharm D", "DPT", "DVM"],
    baseRanking: [
      { rank: 1, name: "King Edward Medical University", detail: "Open-merit MBBS closing aggregate: 93.55% \u2014 consistently the highest cutoff in Pakistan", source: "UHS official selection list, reported by Dawn", sourceUrl: "https://www.dawn.com/news/1727898" },
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
      "BDS": "unranked", "Pharm D": "unranked", "DPT": "unranked", "DVM": "unranked"
    },
    alsoOffered: [
      "Aga Khan University (AKU Karachi \u2014 QS Medicine 201\u2013250 globally, 2026; Pakistan\u2019s only internationally accredited medical school)",
      "Shifa College of Medicine", "CMH Lahore Medical College",
      "Army Medical College Rawalpindi", "Sheikh Zayed Medical College", "DG Khan Medical College"
    ],
    dataNote: "This list reflects UHS admission-cycle closing aggregates, cited via Dawn\u2019s coverage. Closing merit shifts every year \u2014 always confirm against the current UHS selection list. Aga Khan University holds QS Medicine 201\u2013250 globally (2026) and is Pakistan\u2019s only internationally accredited medical school \u2014 it operates separately from the UHS system on its own merit."
  }

};
