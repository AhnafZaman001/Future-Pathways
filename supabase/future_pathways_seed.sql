-- =========================================================
-- Future Pathways — seed master data.
-- Run once, after future_pathways_schema.sql.
-- Safe to re-run: clears and re-inserts each table below.
-- =========================================================

truncate table public.institutes, public.fp_faculties, public.program_options, public.career_options;

-- ---------------------------------------------------------
-- Engineering / Non-Medical institutes
-- ---------------------------------------------------------
insert into public.institutes (name, category, location, campuses, pathway, display_order) values
('LUMS', 'engineering', 'Lahore', '{}', 'engineering', 1),
('NUST', 'engineering', null, '{"Islamabad","Rawalpindi","Risalpur","Karachi","Quetta"}', 'engineering', 2),
('FAST-NUCES', 'engineering', null, '{"Lahore","Islamabad","Karachi","Faisalabad","Peshawar","Multan"}', 'engineering', 3),
('PIEAS', 'engineering', 'Islamabad', '{}', 'engineering', 4),
('UET Lahore', 'engineering', null, '{"Lahore","Kasur","Gujranwala","Faisalabad","Narowal"}', 'engineering', 5),
('GIK', 'engineering', 'Swabi', '{}', 'engineering', 6),
('Punjab University/PUCIT', 'engineering', 'Lahore', '{}', 'engineering', 7),
('Punjab University Engineering Programs', 'engineering', 'Lahore', '{}', 'engineering', 8),
('UET Taxila / Chakwal', 'engineering', null, '{"Taxila","Chakwal"}', 'engineering', 9),
('COMSATS', 'engineering', null, '{"Lahore","Islamabad","Abbottabad","Sahiwal","Wah","Vehari"}', 'engineering', 10),
('IBA', 'engineering', 'Karachi', '{}', 'engineering', 11),
('ITU', 'engineering', 'Lahore', '{}', 'engineering', 12),
('NCA', 'engineering', 'Lahore', '{}', 'engineering', 13),
('PIFD', 'engineering', 'Lahore', '{}', 'engineering', 14),
('NTU', 'engineering', 'Faisalabad', '{}', 'engineering', 15),
('IST', 'engineering', 'Islamabad', '{}', 'engineering', 16),
('Namal', 'engineering', 'Mianwali', '{}', 'engineering', 17),
('Air University', 'engineering', null, '{"Islamabad","Multan","Kamra","Kharian","Shorkot","Karachi"}', 'engineering', 18),
('NASTP', 'engineering', 'Lahore', '{}', 'engineering', 19),
('LSE', 'engineering', 'Lahore', '{}', 'engineering', 20),
('International Islamic University', 'engineering', 'Islamabad', '{}', 'engineering', 21),
('Quaid-i-Azam University', 'engineering', 'Islamabad', '{}', 'engineering', 22),
('Bahria University', 'engineering', null, '{"Karachi","Lahore","Islamabad"}', 'engineering', 23),
('Other', 'engineering', null, '{}', 'engineering', 999);

-- ---------------------------------------------------------
-- Engineering / Non-Medical faculties
-- ---------------------------------------------------------
insert into public.fp_faculties (name, category, pathway, display_order) values
('Electrical', 'engineering', 'engineering', 1),
('Mechatronics', 'engineering', 'engineering', 2),
('Mechanical', 'engineering', 'engineering', 3),
('Civil', 'engineering', 'engineering', 4),
('Architecture', 'engineering', 'engineering', 5),
('Chemical', 'engineering', 'engineering', 6),
('Architectural', 'engineering', 'engineering', 7),
('Petroleum', 'engineering', 'engineering', 8),
('Industrial & Manufacturing', 'engineering', 'engineering', 9),
('Environmental', 'engineering', 'engineering', 10),
('Metallurgical', 'engineering', 'engineering', 11),
('Transportation', 'engineering', 'engineering', 12),
('Mining', 'engineering', 'engineering', 13),
('Biomedical', 'engineering', 'engineering', 14),
('Polymer', 'engineering', 'engineering', 15),
('Textile', 'engineering', 'engineering', 16),
('Telecommunication', 'engineering', 'engineering', 17),
('Aerospace', 'engineering', 'engineering', 18),
('Electronics', 'engineering', 'engineering', 19),
('Avionics', 'engineering', 'engineering', 20),
('Aeronautical', 'engineering', 'engineering', 21),
('Agricultural', 'engineering', 'engineering', 22),
('Other', 'engineering', 'engineering', 998),
-- Computer & IT
('Computer Science', 'computer_it', 'engineering', 23),
('Computer Engineering', 'computer_it', 'engineering', 24),
('IT', 'computer_it', 'engineering', 25),
('Hardware Engineering', 'computer_it', 'engineering', 26),
('Software Engineering', 'computer_it', 'engineering', 27),
('Artificial Intelligence', 'computer_it', 'engineering', 28),
('Cybersecurity', 'computer_it', 'engineering', 29),
('Data Sciences', 'computer_it', 'engineering', 30),
('Other', 'computer_it', 'engineering', 999);

-- ---------------------------------------------------------
-- General career options — available to both pathways
-- ---------------------------------------------------------
insert into public.career_options (name, category, display_order) values
('Computer Sciences', 'general', 1),
('Engineering', 'general', 2),
('Forces (PAF/Army/Navy)', 'general', 3),
('CSS/PMS', 'general', 4),
('CA/ACCA', 'general', 5),
('BBA', 'general', 6),
('Accounting & Finance', 'general', 7),
('BS (Hons) Leading to ___', 'general', 8),
('MS/PHD Teaching', 'general', 9),
('Fashion Designing', 'general', 10),
('LAW', 'general', 11),
('Architecture', 'general', 12);

-- ---------------------------------------------------------
-- Medical institutes
-- ---------------------------------------------------------
insert into public.institutes (name, category, location, pathway, display_order) values
-- Government
('King Edward Medical University', 'medical', null, 'medical', 1),
('Allama Iqbal Medical College', 'medical', null, 'medical', 2),
('Services Institute of Medical Sciences', 'medical', null, 'medical', 3),
('Fatima Jinnah Medical University', 'medical', null, 'medical', 4),
('Ameer-ud-Din Medical College', 'medical', null, 'medical', 5),
('Nishtar Medical University', 'medical', null, 'medical', 6),
('Rawalpindi Medical University', 'medical', null, 'medical', 7),
('Punjab Medical College', 'medical', null, 'medical', 8),
('Quaid-Azam Medical College', 'medical', null, 'medical', 9),
('Sargodha Medical College', 'medical', null, 'medical', 10),
('Khawaja Muhammad Safdar Medical College', 'medical', null, 'medical', 11),
('Gujranwala Medical College', 'medical', null, 'medical', 12),
('Sahiwal Medical College', 'medical', null, 'medical', 13),
('Nawaz Sharif Medical College', 'medical', null, 'medical', 14),
('Sheikh Zayed Medical College', 'medical', null, 'medical', 15),
('Shaikh Khalifa Bin Zayed Al Nahyan Medical & Dental College', 'medical', null, 'medical', 16),
('DG Khan Medical College', 'medical', null, 'medical', 17),
('Narowal Medical College', 'medical', null, 'medical', 18),
-- BDS/Dental
('De''Montmorency College of Dentistry', 'medical', null, 'medical', 19),
('Nishtar Institute of Dentistry', 'medical', null, 'medical', 20),
('Dental Section Punjab Medical College', 'medical', null, 'medical', 21),
('Fatima Jinnah Institute of Dental Sciences', 'medical', null, 'medical', 22),
-- AKU/Other
('Aga Khan University', 'other', null, 'medical', 23),
('SZABMU', 'other', null, 'medical', 24),
('Federal Medical & Dental Colleges', 'other', null, 'medical', 25),
-- NUMS
('National University of Medical Sciences', 'nums', null, 'medical', 26),
('CMH Lahore Medical College', 'nums', null, 'medical', 27),
('CIMS Bahawalpur', 'nums', null, 'medical', 28),
('CMH Kharian', 'nums', null, 'medical', 29),
('CIMS Multan', 'nums', null, 'medical', 30),
('QIMS Quetta', 'nums', null, 'medical', 31),
('Fazal Medical College', 'nums', null, 'medical', 32),
('KIMS Karachi', 'nums', null, 'medical', 33),
('HITEC-IMS Taxila', 'nums', null, 'medical', 34),
('Wah Medical College', 'nums', null, 'medical', 35),
('FUMC Islamabad', 'nums', null, 'medical', 36),
('Army Medical College Rawalpindi', 'nums', null, 'medical', 37),
('NUST School of Health Sciences Islamabad', 'nums', null, 'medical', 38),
-- Private
('Lahore Medical & Dental College', 'private', null, 'medical', 39),
('FMH College of Medicine & Dentistry', 'private', null, 'medical', 40),
('Shalamar Medical & Dental College', 'private', null, 'medical', 41),
('Sharif Medical & Dental College', 'private', null, 'medical', 42),
('University College of Medicine & Dentistry', 'private', null, 'medical', 43),
('Rashid Latif Medical College', 'private', null, 'medical', 44),
('Azra Naheed Medical College', 'private', null, 'medical', 45),
('Shifa College of Medicine', 'private', null, 'medical', 46),
('Islamic International Medical College', 'private', null, 'medical', 47),
('Multan Medical & Dental College', 'private', null, 'medical', 48),
('Bakhtawar Amin Medical & Dental College', 'private', null, 'medical', 49),
('Islam Medical College', 'private', null, 'medical', 50),
('Aziz Fatimah Medical & Dental College', 'private', null, 'medical', 51),
('University Medical & Dental College', 'private', null, 'medical', 52),
('Other', 'private', null, 'medical', 999);

-- ---------------------------------------------------------
-- Medical programs (faculties table reused as "programs" for
-- the medical pathway's 2x5 faculty preference groups)
-- ---------------------------------------------------------
insert into public.fp_faculties (name, category, pathway, display_order) values
('MBBS', 'medical', 'medical', 1),
('BDS', 'medical', 'medical', 2),
('Pharm D', 'medical', 'medical', 3),
('DVM', 'medical', 'medical', 4),
('DPT', 'medical', 'medical', 5),
('BS (Hons)', 'medical', 'medical', 6),
('MLT', 'medical', 'medical', 7),
('MIT', 'medical', 'medical', 8),
('Engineering & IT', 'medical', 'medical', 9),
('Others', 'medical', 'medical', 999);

-- ---------------------------------------------------------
-- program_options — used by the "programs/career interests"
-- step; both pathways share the general career list plus
-- their own program set for the ranked-program-preference step.
-- ---------------------------------------------------------
insert into public.program_options (name, category, pathway, display_order)
select name, category, 'engineering', display_order
from public.fp_faculties where pathway = 'engineering' and category = 'computer_it';

insert into public.program_options (name, category, pathway, display_order)
select name, category, 'medical', display_order
from public.fp_faculties where pathway = 'medical';
