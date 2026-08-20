-- =========================================================
-- Add city locations to medical institutes
--
-- The city filter on rankings.html was dropping all medical
-- colleges because every medical row had location = NULL and
-- no campuses in the original seed. This migration adds the
-- correct locations, verified from:
--   - Wikipedia / List of medical schools in Punjab, Pakistan
--   - topgrade.pk / PMDC college directory
--   - Dawn.com UHS selection list reporting
--   - Individual college Wikipedia pages
--
-- Run once in the Supabase SQL Editor.
-- =========================================================

update public.institutes set location = 'Lahore'     where name = 'King Edward Medical University';
update public.institutes set location = 'Lahore'     where name = 'Allama Iqbal Medical College';
update public.institutes set location = 'Lahore'     where name = 'Services Institute of Medical Sciences';
update public.institutes set location = 'Lahore'     where name = 'Fatima Jinnah Medical University';
update public.institutes set location = 'Lahore'     where name = 'Ameer-ud-Din Medical College';
update public.institutes set location = 'Multan'     where name = 'Nishtar Medical University';
update public.institutes set location = 'Rawalpindi' where name = 'Rawalpindi Medical University';
update public.institutes set location = 'Faisalabad' where name = 'Punjab Medical College';
update public.institutes set location = 'Bahawalpur' where name = 'Quaid-Azam Medical College';
update public.institutes set location = 'Sargodha'   where name = 'Sargodha Medical College';
update public.institutes set location = 'Sialkot'    where name = 'Khawaja Muhammad Safdar Medical College';
update public.institutes set location = 'Gujranwala' where name = 'Gujranwala Medical College';
update public.institutes set location = 'Sahiwal'    where name = 'Sahiwal Medical College';
update public.institutes set location = 'Gujrat'     where name = 'Nawaz Sharif Medical College';
update public.institutes set location = 'Rahim Yar Khan' where name = 'Sheikh Zayed Medical College';
update public.institutes set location = 'Lahore'     where name = 'Shaikh Khalifa Bin Zayed Al Nahyan Medical & Dental College';
update public.institutes set location = 'Dera Ghazi Khan' where name = 'DG Khan Medical College';
update public.institutes set location = 'Narowal'    where name = 'Narowal Medical College';
-- BDS / Dental
update public.institutes set location = 'Lahore'     where name = 'De''Montmorency College of Dentistry';
update public.institutes set location = 'Multan'     where name = 'Nishtar Institute of Dentistry';
update public.institutes set location = 'Faisalabad' where name = 'Dental Section Punjab Medical College';
update public.institutes set location = 'Lahore'     where name = 'Fatima Jinnah Institute of Dental Sciences';
-- Other
update public.institutes set location = 'Karachi'    where name = 'Aga Khan University';
update public.institutes set location = 'Islamabad'  where name = 'SZABMU';
update public.institutes set location = 'Islamabad'  where name = 'Federal Medical & Dental Colleges';
