/* =========================================================
   data.js — all static data lives here.
   When you have real university / closing-merit data, replace
   the UNIVERSITIES array below. Nothing else needs to change —
   calculations.js and suggestions.js just read this shape.
   ========================================================= */

window.Counsellor = window.Counsellor || {};

Counsellor.FIELDS = [
  { id: "engineering",  label: "Engineering" },
  { id: "cs",            label: "Computer Science / IT" },
  { id: "medical",      label: "Medical (MBBS/BDS)" },
  { id: "business",      label: "Business / Commerce" },
  { id: "social",        label: "Social Sciences" },
  { id: "arts",          label: "Arts & Design" },
  { id: "natural",      label: "Natural Sciences" }
];

Counsellor.AREAS = [
  { id: "islamabad", label: "Islamabad" },
  { id: "rawalpindi", label: "Rawalpindi" },
  { id: "lahore",      label: "Lahore" },
  { id: "karachi",    label: "Karachi" },
  { id: "peshawar",    label: "Peshawar" },
  { id: "multan",      label: "Multan" },
  { id: "faisalabad", label: "Faisalabad" },
  { id: "any",        label: "No preference / anywhere" }
];

/* Merit formula weights per field, as % of total 100.
   "test" is the entry-test / interview component that isn't
   available at intake time — its weight is shown to the user
   as "pending" rather than scored as zero.
   TODO: tune these per real admission criteria per field. */
Counsellor.MERIT_WEIGHTS = {
  engineering: { matric: 10, fsc: 40, test: 50 },
  cs:          { matric: 10, fsc: 40, test: 50 },
  medical:      { matric: 10, fsc: 50, test: 40 },
  business:    { matric: 10, fsc: 90, test: 0 },
  social:      { matric: 10, fsc: 90, test: 0 },
  arts:        { matric: 10, fsc: 90, test: 0 },
  natural:      { matric: 10, fsc: 90, test: 0 }
};

/* -----------------------------------------------------------
   UNIVERSITIES — replace / extend this with real data.

   Shape of each entry:
   {
     id:            unique string
     name:          university name
     area:          one id from Counsellor.AREAS (city it's in)
     programs: [
       {
         field:        one id from Counsellor.FIELDS
         programName:  display name, e.g. "BS Computer Science"
         closingMerit: number 0-100, or null if unknown (TODO)
       }
     ]
   }

   closingMerit: null means "no data yet" — the UI will show a
   clear "add data" state instead of guessing.
   ----------------------------------------------------------- */
Counsellor.UNIVERSITIES = [
  {
    id: "nust",
    name: "NUST",
    area: "islamabad",
    programs: [
      { field: "engineering", programName: "BE Software Engineering", closingMerit: null },
      { field: "cs",          programName: "BS Computer Science",      closingMerit: null }
    ]
  },
  {
    id: "fast-isb",
    name: "FAST-NUCES, Islamabad",
    area: "islamabad",
    programs: [
      { field: "cs",          programName: "BS Computer Science", closingMerit: null },
      { field: "business",    programName: "BBA",                  closingMerit: null }
    ]
  },
  {
    id: "quaid-i-azam",
    name: "Quaid-i-Azam University",
    area: "islamabad",
    programs: [
      { field: "natural",    programName: "BS Physics",            closingMerit: null },
      { field: "social",      programName: "BS Economics",          closingMerit: null }
    ]
  },
  {
    id: "uet-lhr",
    name: "UET Lahore",
    area: "lahore",
    programs: [
      { field: "engineering", programName: "BSc Electrical Engineering", closingMerit: null }
    ]
  },
  {
    id: "lums",
    name: "LUMS",
    area: "lahore",
    programs: [
      { field: "cs",        programName: "BS Computer Science", closingMerit: null },
      { field: "business",  programName: "BSc Accounting & Finance", closingMerit: null }
    ]
  },
  {
    id: "kemu",
    name: "King Edward Medical University",
    area: "lahore",
    programs: [
      { field: "medical", programName: "MBBS", closingMerit: null }
    ]
  },
  {
    id: "nedu",
    name: "NED University",
    area: "karachi",
    programs: [
      { field: "engineering", programName: "BE Civil Engineering", closingMerit: null }
    ]
  },
  {
    id: "iba-khi",
    name: "IBA Karachi",
    area: "karachi",
    programs: [
      { field: "business", programName: "BBA",                  closingMerit: null },
      { field: "cs",        programName: "BS Computer Science", closingMerit: null }
    ]
  },
  {
    id: "duhs",
    name: "Dow University of Health Sciences",
    area: "karachi",
    programs: [
      { field: "medical", programName: "MBBS", closingMerit: null }
    ]
  },
  {
    id: "uop",
    name: "University of Peshawar",
    area: "peshawar",
    programs: [
      { field: "social",    programName: "BS Psychology",          closingMerit: null },
      { field: "natural",  programName: "BS Chemistry",            closingMerit: null }
    ]
  },
  {
    id: "buitems",
    name: "COMSATS Islamabad",
    area: "islamabad",
    programs: [
      { field: "cs",          programName: "BS Software Engineering", closingMerit: null },
      { field: "engineering", programName: "BS Electrical Engineering", closingMerit: null }
    ]
  }
];
