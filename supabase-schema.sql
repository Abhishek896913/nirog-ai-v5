-- ================================================================
-- NIROGAI v5 — SUPABASE SCHEMA
-- Complete PostgreSQL schema with RLS policies, indexes, and auth sync
-- ================================================================

-- ════════════════════════════════════════════════════════════════
-- 1. PROFILES (Patient user data)
-- ════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  phone TEXT,
  age INTEGER,
  gender TEXT CHECK (gender IN ('M', 'F', 'Other')),
  height_cm NUMERIC,
  weight_kg NUMERIC,
  goal TEXT CHECK (goal IN ('Lose', 'Maintain', 'Gain')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_own" ON public.profiles
  FOR ALL USING (auth.uid() = id);

CREATE INDEX idx_profiles_email ON public.profiles(email);

-- ════════════════════════════════════════════════════════════════
-- 2. DOCTORS (Doctor profiles with custom IDs)
-- ════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.doctors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  doctor_id TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  specialization TEXT,
  experience_years INTEGER DEFAULT 1,
  consultation_fee NUMERIC DEFAULT 500,
  medical_license TEXT,
  hospital_mode BOOLEAN DEFAULT false,
  online_mode BOOLEAN DEFAULT true,
  hospital_name TEXT,
  hospital_address TEXT,
  google_maps_location TEXT,
  hospital_phone TEXT,
  hospital_image_url TEXT,
  video_consultation_url TEXT,
  bio TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  verified_badge BOOLEAN DEFAULT false,
  rating NUMERIC DEFAULT 0,
  total_ratings INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "doctors_public_approved" ON public.doctors
  FOR SELECT USING (status = 'approved');

CREATE POLICY "doctors_own" ON public.doctors
  FOR ALL USING (auth.uid() = user_id);

CREATE UNIQUE INDEX idx_doctors_doctor_id ON public.doctors(doctor_id);
CREATE UNIQUE INDEX idx_doctors_email ON public.doctors(email);
CREATE UNIQUE INDEX idx_doctors_user_id ON public.doctors(user_id);
CREATE INDEX idx_doctors_status ON public.doctors(status);
CREATE INDEX idx_doctors_specialization ON public.doctors(specialization);

-- ════════════════════════════════════════════════════════════════
-- 3. NADIBOX_CARDS (Health vitals readings)
-- ════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.nadibox_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  heart_rate INTEGER,
  blood_pressure_systolic INTEGER,
  blood_pressure_diastolic INTEGER,
  spo2 INTEGER,
  temperature NUMERIC,
  blood_sugar INTEGER,
  risk_status TEXT DEFAULT 'Normal' CHECK (risk_status IN ('Normal', 'Review', 'High Risk')),
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.nadibox_cards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "nadibox_cards_own" ON public.nadibox_cards
  FOR ALL USING (auth.uid() = user_id);

CREATE INDEX idx_nadibox_user_id ON public.nadibox_cards(user_id);
CREATE INDEX idx_nadibox_created_at ON public.nadibox_cards(created_at DESC);

-- ════════════════════════════════════════════════════════════════
-- 4. SHARED_CARDS (Patient shares health cards with doctor)
-- ════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.shared_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES public.nadibox_cards(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
  doctor_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.shared_cards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "shared_cards_owner_doctor" ON public.shared_cards
  FOR ALL USING (auth.uid() = patient_id OR auth.uid() = doctor_user_id);

CREATE INDEX idx_shared_cards_patient ON public.shared_cards(patient_id);
CREATE INDEX idx_shared_cards_doctor ON public.shared_cards(doctor_user_id);

-- ════════════════════════════════════════════════════════════════
-- 5. PRESCRIPTIONS (Doctor writes prescriptions)
-- ════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.prescriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medicines JSONB NOT NULL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "prescriptions_access" ON public.prescriptions
  FOR SELECT USING (auth.uid() = patient_id OR auth.uid() = (SELECT user_id FROM public.doctors WHERE id = doctor_id));

CREATE INDEX idx_prescriptions_doctor ON public.prescriptions(doctor_id);
CREATE INDEX idx_prescriptions_patient ON public.prescriptions(patient_id);

-- ════════════════════════════════════════════════════════════════
-- 6. PATIENT_DOCTOR_REQUESTS (Access requests)
-- ════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.patient_doctor_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'scheduled')),
  request_notes TEXT,
  scheduled_date TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.patient_doctor_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "requests_access" ON public.patient_doctor_requests
  FOR ALL USING (auth.uid() = patient_id OR auth.uid() = (SELECT user_id FROM public.doctors WHERE id = doctor_id));

CREATE INDEX idx_requests_patient ON public.patient_doctor_requests(patient_id);
CREATE INDEX idx_requests_doctor ON public.patient_doctor_requests(doctor_id);
CREATE INDEX idx_requests_status ON public.patient_doctor_requests(status);

-- ════════════════════════════════════════════════════════════════
-- 7. APPOINTMENTS (Scheduled consultation slots)
-- ════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  appointment_time TIMESTAMP NOT NULL,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled', 'no-show')),
  consultation_notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "appointments_access" ON public.appointments
  FOR ALL USING (auth.uid() = patient_id OR auth.uid() = (SELECT user_id FROM public.doctors WHERE id = doctor_id));

CREATE INDEX idx_appointments_doctor ON public.appointments(doctor_id);
CREATE INDEX idx_appointments_patient ON public.appointments(patient_id);
CREATE INDEX idx_appointments_time ON public.appointments(appointment_time);

-- ════════════════════════════════════════════════════════════════
-- 8. HOSPITALS (Hospital listings)
-- ════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.hospitals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  city TEXT NOT NULL,
  address TEXT NOT NULL,
  phone TEXT,
  specialties TEXT[] DEFAULT ARRAY[]::TEXT[],
  latitude NUMERIC,
  longitude NUMERIC,
  rating NUMERIC DEFAULT 0,
  total_ratings INTEGER DEFAULT 0,
  image_url TEXT,
  website TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.hospitals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "hospitals_public" ON public.hospitals
  FOR SELECT USING (true);

CREATE INDEX idx_hospitals_city ON public.hospitals(city);
CREATE INDEX idx_hospitals_name ON public.hospitals(name);

-- ════════════════════════════════════════════════════════════════
-- 9. HOSPITAL_BOOKINGS (Free slot bookings)
-- ════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.hospital_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id TEXT UNIQUE NOT NULL,
  patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  hospital_id UUID NOT NULL REFERENCES public.hospitals(id) ON DELETE CASCADE,
  doctor_id UUID REFERENCES public.doctors(id) ON DELETE SET NULL,
  patient_name TEXT NOT NULL,
  patient_phone TEXT NOT NULL,
  appointment_date DATE NOT NULL,
  appointment_time TIME NOT NULL,
  status TEXT DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'completed', 'cancelled', 'no-show')),
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.hospital_bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "hospital_bookings_own" ON public.hospital_bookings
  FOR ALL USING (auth.uid() = patient_id);

CREATE POLICY "hospital_bookings_doctor" ON public.hospital_bookings
  FOR SELECT USING (auth.uid() = (SELECT user_id FROM public.doctors WHERE id = doctor_id));

CREATE UNIQUE INDEX idx_booking_id ON public.hospital_bookings(booking_id);
CREATE INDEX idx_hospital_bookings_patient ON public.hospital_bookings(patient_id);
CREATE INDEX idx_hospital_bookings_hospital ON public.hospital_bookings(hospital_id);

-- ════════════════════════════════════════════════════════════════
-- 10. FOOD_LOGS (Daily food diary)
-- ════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.food_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  food_name TEXT NOT NULL,
  quantity_grams NUMERIC NOT NULL,
  meal_type TEXT NOT NULL CHECK (meal_type IN ('Breakfast', 'Lunch', 'Dinner', 'Snacks')),
  calories NUMERIC NOT NULL,
  protein_g NUMERIC,
  carbs_g NUMERIC,
  fat_g NUMERIC,
  logged_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.food_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "food_logs_own" ON public.food_logs
  FOR ALL USING (auth.uid() = user_id);

CREATE INDEX idx_food_logs_user ON public.food_logs(user_id);
CREATE INDEX idx_food_logs_date ON public.food_logs(logged_date DESC);

-- ════════════════════════════════════════════════════════════════
-- 11. WEIGHT_LOGS (Weight history)
-- ════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.weight_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  weight_kg NUMERIC NOT NULL,
  logged_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.weight_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "weight_logs_own" ON public.weight_logs
  FOR ALL USING (auth.uid() = user_id);

CREATE INDEX idx_weight_logs_user ON public.weight_logs(user_id);
CREATE INDEX idx_weight_logs_date ON public.weight_logs(logged_date DESC);

-- ════════════════════════════════════════════════════════════════
-- 12. HEALTH_LOGS (Steps, water, sleep)
-- ════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.health_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  logged_date DATE NOT NULL,
  steps INTEGER,
  water_ml INTEGER,
  sleep_hours NUMERIC,
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.health_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "health_logs_own" ON public.health_logs
  FOR ALL USING (auth.uid() = user_id);

CREATE INDEX idx_health_logs_user ON public.health_logs(user_id);
CREATE INDEX idx_health_logs_date ON public.health_logs(logged_date DESC);

-- ════════════════════════════════════════════════════════════════
-- 13. LAB_REPORTS (PDF/image lab results)
-- ════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.lab_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  report_name TEXT NOT NULL,
  file_url TEXT NOT NULL,
  uploaded_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.lab_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lab_reports_own" ON public.lab_reports
  FOR ALL USING (auth.uid() = user_id);

CREATE INDEX idx_lab_reports_user ON public.lab_reports(user_id);
CREATE INDEX idx_lab_reports_date ON public.lab_reports(uploaded_date DESC);

-- ════════════════════════════════════════════════════════════════
-- 14. ADMINS (Admin users for verification)
-- ════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.admins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  role TEXT DEFAULT 'moderator' CHECK (role IN ('admin', 'moderator')),
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admins_own" ON public.admins
  FOR SELECT USING (auth.uid() = user_id);

CREATE UNIQUE INDEX idx_admins_user_id ON public.admins(user_id);
CREATE UNIQUE INDEX idx_admins_email ON public.admins(email);

-- ════════════════════════════════════════════════════════════════
-- SETUP INSTRUCTIONS
-- ════════════════════════════════════════════════════════════════

/*
AFTER RUNNING THIS SCHEMA:

1. Go to Supabase Dashboard → Authentication → Settings
   - Email Confirm → OFF (for development), ON (for production)

2. Enable Google OAuth:
   - Authentication → Providers → Google → Enable
   - Add redirect URL: https://YOUR_DOMAIN.vercel.app/auth

3. Create Storage Bucket:
   - Storage → New Bucket → Name: "hospital-photos" → Public: ON

4. Test RLS by:
   - Create 2 test users (patient1, patient2)
   - Patient1 should NOT see Patient2's data
   - Try to query: SELECT * FROM profiles WHERE auth.uid() != id (should return 0 rows)

5. Create sample data:
   - 5 test patients
   - 3 test doctors with status='approved'
   - 10 test hospitals
   - Sample food logs, weight logs
*/
