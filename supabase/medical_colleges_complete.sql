-- =========================================================
-- medical_colleges_complete.sql
--
-- TWO problems fixed:
-- 1. Every existing medical institute had location=null,
--    so city filtering returned zero results.
-- 2. Entire Sindh, KPK and Balochistan medical college
--    landscapes were missing from the database entirely.
--
-- Sources (verified multi-source):
--   - PMDC official college list (pmdc.pk)
--   - pakadmissions.com/medicalcolleges (PMDC-derived)
--   - Wikipedia: List of medical schools in Punjab/Sindh/KPK/Balochistan
--   - mbbs.com.pk, mbbs.org.pk (2025-2026 data)
--
-- Run once in Supabase Dashboard -> SQL Editor.
-- Safe to re-run (UPDATE and INSERT OR IGNORE pattern).
-- =========================================================

-- ---------------------------------------------------------
-- STEP 1: Add locations to all existing Punjab medical
-- colleges that currently have location=null.
-- ---------------------------------------------------------

-- Lahore
UPDATE public.institutes SET location='Lahore' WHERE name='King Edward Medical University'                          AND pathway='medical';
UPDATE public.institutes SET location='Lahore' WHERE name='Allama Iqbal Medical College'                           AND pathway='medical';
UPDATE public.institutes SET location='Lahore' WHERE name='Services Institute of Medical Sciences'                  AND pathway='medical';
UPDATE public.institutes SET location='Lahore' WHERE name='Fatima Jinnah Medical University'                       AND pathway='medical';
UPDATE public.institutes SET location='Lahore' WHERE name='Ameer-ud-Din Medical College'                           AND pathway='medical';
UPDATE public.institutes SET location='Lahore' WHERE name='De''Montmorency College of Dentistry'                    AND pathway='medical';
UPDATE public.institutes SET location='Lahore' WHERE name='Fatima Jinnah Institute of Dental Sciences'             AND pathway='medical';
UPDATE public.institutes SET location='Lahore' WHERE name='CMH Lahore Medical College'                             AND pathway='medical';
UPDATE public.institutes SET location='Lahore' WHERE name='Lahore Medical & Dental College'                        AND pathway='medical';
UPDATE public.institutes SET location='Lahore' WHERE name='FMH College of Medicine & Dentistry'                    AND pathway='medical';
UPDATE public.institutes SET location='Lahore' WHERE name='Shalamar Medical & Dental College'                      AND pathway='medical';
UPDATE public.institutes SET location='Lahore' WHERE name='Sharif Medical & Dental College'                        AND pathway='medical';
UPDATE public.institutes SET location='Lahore' WHERE name='University College of Medicine & Dentistry'             AND pathway='medical';
UPDATE public.institutes SET location='Lahore' WHERE name='Rashid Latif Medical College'                           AND pathway='medical';
UPDATE public.institutes SET location='Lahore' WHERE name='Azra Naheed Medical College'                            AND pathway='medical';
UPDATE public.institutes SET location='Lahore' WHERE name='Islamic International Medical College'                   AND pathway='medical';
UPDATE public.institutes SET location='Lahore' WHERE name='Shaikh Khalifa Bin Zayed Al Nahyan Medical & Dental College' AND pathway='medical';

-- Rawalpindi
UPDATE public.institutes SET location='Rawalpindi' WHERE name='Rawalpindi Medical University'                      AND pathway='medical';
UPDATE public.institutes SET location='Rawalpindi' WHERE name='Army Medical College Rawalpindi'                    AND pathway='medical';

-- Multan
UPDATE public.institutes SET location='Multan' WHERE name='Nishtar Medical University'                            AND pathway='medical';
UPDATE public.institutes SET location='Multan' WHERE name='Nishtar Institute of Dentistry'                        AND pathway='medical';
UPDATE public.institutes SET location='Multan' WHERE name='CIMS Multan'                                           AND pathway='medical';
UPDATE public.institutes SET location='Multan' WHERE name='Multan Medical & Dental College'                       AND pathway='medical';
UPDATE public.institutes SET location='Multan' WHERE name='Bakhtawar Amin Medical & Dental College'               AND pathway='medical';

-- Faisalabad
UPDATE public.institutes SET location='Faisalabad' WHERE name='Punjab Medical College'                            AND pathway='medical';
UPDATE public.institutes SET location='Faisalabad' WHERE name='Dental Section Punjab Medical College'             AND pathway='medical';
UPDATE public.institutes SET location='Faisalabad' WHERE name='Aziz Fatimah Medical & Dental College'             AND pathway='medical';
UPDATE public.institutes SET location='Faisalabad' WHERE name='University Medical & Dental College'               AND pathway='medical';

-- Other Punjab cities
UPDATE public.institutes SET location='Bahawalpur'  WHERE name='Quaid-Azam Medical College'                      AND pathway='medical';
UPDATE public.institutes SET location='Bahawalpur'  WHERE name='CIMS Bahawalpur'                                  AND pathway='medical';
UPDATE public.institutes SET location='Sargodha'    WHERE name='Sargodha Medical College'                         AND pathway='medical';
UPDATE public.institutes SET location='Sialkot'     WHERE name='Khawaja Muhammad Safdar Medical College'          AND pathway='medical';
UPDATE public.institutes SET location='Sialkot'     WHERE name='Islam Medical College'                            AND pathway='medical';
UPDATE public.institutes SET location='Gujranwala'  WHERE name='Gujranwala Medical College'                       AND pathway='medical';
UPDATE public.institutes SET location='Sahiwal'     WHERE name='Sahiwal Medical College'                          AND pathway='medical';
UPDATE public.institutes SET location='Gujrat'      WHERE name='Nawaz Sharif Medical College'                     AND pathway='medical';
UPDATE public.institutes SET location='Rahim Yar Khan' WHERE name='Sheikh Zayed Medical College'                  AND pathway='medical';
UPDATE public.institutes SET location='Dera Ghazi Khan' WHERE name='DG Khan Medical College'                      AND pathway='medical';
UPDATE public.institutes SET location='Narowal'     WHERE name='Narowal Medical College'                          AND pathway='medical';
UPDATE public.institutes SET location='Gujranwala'  WHERE name='Kharian' WHERE FALSE; -- placeholder

-- Islamabad / Rawalpindi (federal)
UPDATE public.institutes SET location='Islamabad'   WHERE name='SZABMU'                                            AND pathway='medical';
UPDATE public.institutes SET location='Islamabad'   WHERE name='Federal Medical & Dental Colleges'                 AND pathway='medical';
UPDATE public.institutes SET location='Islamabad'   WHERE name='Shifa College of Medicine'                        AND pathway='medical';
UPDATE public.institutes SET location='Islamabad'   WHERE name='FUMC Islamabad'                                   AND pathway='medical';
UPDATE public.institutes SET location='Islamabad'   WHERE name='NUST School of Health Sciences Islamabad'         AND pathway='medical';

-- NUMS campuses
UPDATE public.institutes SET location='Rawalpindi'  WHERE name='National University of Medical Sciences'          AND pathway='medical';
UPDATE public.institutes SET location='Kharian'     WHERE name='CMH Kharian'                                      AND pathway='medical';
UPDATE public.institutes SET location='Quetta'      WHERE name='QIMS Quetta'                                      AND pathway='medical';
UPDATE public.institutes SET location='Taxila'      WHERE name='HITEC-IMS Taxila'                                 AND pathway='medical';
UPDATE public.institutes SET location='Wah'         WHERE name='Wah Medical College'                              AND pathway='medical';

-- Karachi
UPDATE public.institutes SET location='Karachi'     WHERE name='Aga Khan University'                              AND pathway='medical';
UPDATE public.institutes SET location='Karachi'     WHERE name='KIMS Karachi'                                     AND pathway='medical';

-- Fazal Medical College (private, Peshawar)
UPDATE public.institutes SET location='Peshawar'    WHERE name='Fazal Medical College'                            AND pathway='medical';

-- ---------------------------------------------------------
-- STEP 2: Insert missing medical colleges (Sindh, KPK,
-- Balochistan, and additional Punjab/private colleges).
-- Uses INSERT ... WHERE NOT EXISTS to be safe to re-run.
-- ---------------------------------------------------------

-- ---- SINDH (public) ----
INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Dow Medical College (DUHS)', 'medical', 'Karachi', 'medical', 60
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Dow Medical College (DUHS)' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Jinnah Sindh Medical University (JSMU)', 'medical', 'Karachi', 'medical', 61
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Jinnah Sindh Medical University (JSMU)' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Shaheed Mohtarma Benazir Bhutto Medical College (Lyari)', 'medical', 'Karachi', 'medical', 62
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Shaheed Mohtarma Benazir Bhutto Medical College (Lyari)' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Karachi Metropolitan University (KMDC)', 'medical', 'Karachi', 'medical', 63
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Karachi Metropolitan University (KMDC)' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Liaquat University of Medical & Health Sciences (LUMHS)', 'medical', 'Jamshoro', 'medical', 64
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Liaquat University of Medical & Health Sciences (LUMHS)' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Peoples University of Medical & Health Sciences (PUMHS)', 'medical', 'Nawabshah', 'medical', 65
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Peoples University of Medical & Health Sciences (PUMHS)' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Ghulam Muhammad Mahar Medical College', 'medical', 'Sukkur', 'medical', 66
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Ghulam Muhammad Mahar Medical College' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Muhammad Medical College', 'medical', 'Mirpurkhas', 'medical', 67
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Muhammad Medical College' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Bilawal Medical College Jamshoro', 'medical', 'Jamshoro', 'medical', 68
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Bilawal Medical College Jamshoro' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Chandka Medical College (Larkana)', 'medical', 'Larkana', 'medical', 69
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Chandka Medical College (Larkana)' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Isra University (Hyderabad)', 'medical', 'Hyderabad', 'medical', 70
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Isra University (Hyderabad)' AND pathway='medical');

-- ---- KPK (public) ----
INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Khyber Medical College (KMC)', 'medical', 'Peshawar', 'medical', 71
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Khyber Medical College (KMC)' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Khyber Girls Medical College', 'medical', 'Peshawar', 'medical', 72
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Khyber Girls Medical College' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Bacha Khan Medical College', 'medical', 'Mardan', 'medical', 73
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Bacha Khan Medical College' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Gajju Khan Medical College', 'medical', 'Swabi', 'medical', 74
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Gajju Khan Medical College' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Nowshera Medical College', 'medical', 'Nowshera', 'medical', 75
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Nowshera Medical College' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Ayub Medical College (Abbottabad)', 'medical', 'Abbottabad', 'medical', 76
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Ayub Medical College (Abbottabad)' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Saidu Medical College (Swat)', 'medical', 'Swat', 'medical', 77
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Saidu Medical College (Swat)' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Gomal Medical College (DIKhan)', 'medical', 'Dera Ismail Khan', 'medical', 78
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Gomal Medical College (DIKhan)' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Bannu Medical College', 'medical', 'Bannu', 'medical', 79
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Bannu Medical College' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Rehman Medical College (Peshawar)', 'medical', 'Peshawar', 'medical', 80
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Rehman Medical College (Peshawar)' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Frontier Medical College (Abbottabad)', 'medical', 'Abbottabad', 'medical', 81
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Frontier Medical College (Abbottabad)' AND pathway='medical');

-- ---- BALOCHISTAN ----
INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Bolan Medical College (Quetta)', 'medical', 'Quetta', 'medical', 82
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Bolan Medical College (Quetta)' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Loralai Medical College', 'medical', 'Loralai', 'medical', 83
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Loralai Medical College' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Makran Medical College (Turbat)', 'medical', 'Turbat', 'medical', 84
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Makran Medical College (Turbat)' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Jhalawan Medical College (Khuzdar)', 'medical', 'Khuzdar', 'medical', 85
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Jhalawan Medical College (Khuzdar)' AND pathway='medical');

-- ---- AJK ----
INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Azad Jammu & Kashmir Medical College (Muzaffarabad)', 'medical', 'Muzaffarabad', 'medical', 86
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Azad Jammu & Kashmir Medical College (Muzaffarabad)' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Mohtarma Benazir Bhutto Shaheed Medical College (Mirpur)', 'medical', 'Mirpur', 'medical', 87
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Mohtarma Benazir Bhutto Shaheed Medical College (Mirpur)' AND pathway='medical');

INSERT INTO public.institutes (name, category, location, pathway, display_order)
SELECT 'Poonch Medical College (Rawalakot)', 'medical', 'Rawalakot', 'medical', 88
WHERE NOT EXISTS (SELECT 1 FROM public.institutes WHERE name='Poonch Medical College (Rawalakot)' AND pathway='medical');
