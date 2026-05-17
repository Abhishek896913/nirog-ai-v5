// ================================================================
// NIROGAI — DOCTOR AUTH SYSTEM
// Register | Login with Doctor ID | Forgot Doctor ID
// ================================================================

const SB_URL = 'https://snsmcmxxlsolnkeukyog.supabase.co';
const SB_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNuc21jbXh4bHNvbG5rZXVreW9nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1NDY1MTEsImV4cCI6MjA4ODEyMjUxMX0.svnnhqmMTdTZOmdr0TcKi3yRi_hdPeyAUYz0sOOExHY';

// Initialize Supabase
const { createClient } = supabase;
const sb = createClient(SB_URL, SB_KEY);

// ────────────────────────────────────────────────────────────────
// UTILITY FUNCTIONS
// ────────────────────────────────────────────────────────────────

/**
 * Generate unique Doctor ID like DR-A1B2C
 */
function generateDoctorId() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const random = Array.from({ length: 5 }, () =>
    chars[Math.floor(Math.random() * chars.length)]
  ).join('');
  return `DR-${random}`;
}

/**
 * Show error message in a UI element
 */
function showError(elementId, message) {
  const el = document.getElementById(elementId);
  if (!el) return;
  el.innerHTML = `⚠️ ${message}`;
  el.style.display = 'block';
  el.style.background = 'rgba(239,68,68,0.07)';
  el.style.border = '1px solid rgba(239,68,68,0.25)';
  el.style.color = '#DC2626';
  el.style.borderRadius = '10px';
  el.style.padding = '10px 14px';
  el.style.fontSize = '13px';
  el.style.marginBottom = '12px';
  setTimeout(() => { el.style.display = 'none'; }, 7000);
}

/**
 * Show success message in a UI element
 */
function showSuccess(elementId, message) {
  const el = document.getElementById(elementId);
  if (!el) return;
  el.innerHTML = `✅ ${message}`;
  el.style.display = 'block';
  el.style.background = 'rgba(16,185,129,0.07)';
  el.style.border = '1px solid rgba(16,185,129,0.25)';
  el.style.color = '#059669';
  el.style.borderRadius = '10px';
  el.style.padding = '10px 14px';
  el.style.fontSize = '13px';
  el.style.marginBottom = '12px';
}

/**
 * Set button loading state
 */
function setLoading(buttonId, isLoading, originalText) {
  const btn = document.getElementById(buttonId);
  if (!btn) return;
  btn.disabled = isLoading;
  btn.innerHTML = isLoading
    ? `<span style="display:inline-flex;align-items:center;gap:8px;">
        <span style="width:14px;height:14px;border:2px solid rgba(255,255,255,0.3);border-top-color:white;border-radius:50%;animation:spin 0.7s linear infinite;"></span>
        Please wait...
       </span>`
    : originalText;
}

/**
 * Parse Supabase error into user-friendly message
 */
function parseError(error) {
  if (!error) return 'Something went wrong. Please try again.';
  const msg = error.message || String(error);

  if (/invalid.login|invalid_credentials/i.test(msg))
    return 'Email ya password galat hai. Check karein.';
  if (/email not confirmed/i.test(msg))
    return 'Email verify nahi hua. Gmail check karein aur link click karein.';
  if (/already registered|User already/i.test(msg))
    return 'Yeh email already registered hai. Login karein ya forgot doctor ID use karein.';
  if (/fetch|network|Failed to fetch/i.test(msg))
    return 'Network error. Internet check karein aur page refresh karein.';
  if (/duplicate key|unique.*violation/i.test(msg))
    return 'Doctor ID conflict hua. Dobara try karein.';
  return msg || 'Unknown error occurred.';
}

// ────────────────────────────────────────────────────────────────
// 1. DOCTOR REGISTRATION
// ────────────────────────────────────────────────────────────────

/**
 * Register a new doctor
 * - Creates Supabase Auth user
 * - Generates unique Doctor ID
 * - Saves to doctors table
 *
 * Expected HTML fields:
 * #reg-fullname, #reg-email, #reg-phone, #reg-specialization,
 * #reg-experience, #reg-regno, #reg-password, #reg-terms
 * Buttons: #reg-btn
 * Messages: #reg-error, #reg-success
 * Result: #reg-doctor-id (to display the generated ID)
 */
async function registerDoctor() {
  // Get form values
  const fullName    = document.getElementById('reg-fullname')?.value.trim();
  const email       = document.getElementById('reg-email')?.value.trim();
  const phone       = document.getElementById('reg-phone')?.value.trim();
  const spec        = document.getElementById('reg-specialization')?.value;
  const exp         = document.getElementById('reg-experience')?.value;
  const regNo       = document.getElementById('reg-regno')?.value.trim();
  const password    = document.getElementById('reg-password')?.value;
  const termsChecked= document.getElementById('reg-terms')?.checked;

  // Validation
  if (!fullName)        return showError('reg-error', 'Full name daalo');
  if (!email || !email.includes('@')) return showError('reg-error', 'Valid email daalo');
  if (!spec)            return showError('reg-error', 'Specialization select karo');
  if (!regNo)           return showError('reg-error', 'Medical registration number daalo');
  if (!password || password.length < 6) return showError('reg-error', 'Password minimum 6 characters hona chahiye');
  if (!termsChecked)    return showError('reg-error', 'Terms & Conditions accept karo');

  setLoading('reg-btn', true);

  try {
    // Step 1: Create Supabase Auth user
    const { data: authData, error: authError } = await sb.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
          role: 'doctor'
        },
        emailRedirectTo: window.location.origin + '/auth'
      }
    });

    if (authError) throw authError;
    if (!authData.user) throw new Error('User creation failed. Try again.');

    // Step 2: Generate unique Doctor ID (retry if collision)
    let doctorId = '';
    let attempts = 0;
    while (attempts < 5) {
      doctorId = generateDoctorId();
      // Check if ID already exists
      const { data: existing } = await sb
        .from('doctors')
        .select('doctor_id')
        .eq('doctor_id', doctorId)
        .maybeSingle();
      if (!existing) break; // ID is unique, use it
      attempts++;
    }
    if (!doctorId) throw new Error('Could not generate unique Doctor ID. Try again.');

    // Step 3: Insert into doctors table
    const { error: insertError } = await sb.from('doctors').insert({
      user_id:             authData.user.id,
      email:               email,
      full_name:           fullName,
      doctor_id:           doctorId,
      phone:               phone || null,
      specialization:      spec || null,
      experience_years:    exp ? parseInt(exp) : null,
      registration_number: regNo || null,
      status:              'pending',
      created_at:          new Date().toISOString()
    });

    if (insertError) throw insertError;

    // Step 4: Show success with Doctor ID
    setLoading('reg-btn', false, 'Register →');

    // Display Doctor ID prominently
    const idEl = document.getElementById('reg-doctor-id');
    if (idEl) {
      idEl.textContent = doctorId;
      idEl.style.display = 'block';
    }

    showSuccess('reg-success',
      `Registration successful! Your Doctor ID is <strong>${doctorId}</strong>. 
       Please save this ID — you will need it to login. 
       Also check your email to verify your account.`
    );

    // Hide register button, show ID box
    document.getElementById('reg-btn').style.display = 'none';

    console.log('Doctor registered successfully:', { doctorId, email });

  } catch (error) {
    console.error('Registration error:', error);
    showError('reg-error', parseError(error));
    setLoading('reg-btn', false, 'Register →');
  }
}

// ────────────────────────────────────────────────────────────────
// 2. DOCTOR LOGIN (using Doctor ID + Password)
// ────────────────────────────────────────────────────────────────

/**
 * Login a doctor using Doctor ID + password
 * - Fetches email from doctors table using doctor_id
 * - Logs in via Supabase Auth (email + password)
 *
 * Expected HTML fields:
 * #login-doctorid, #login-password
 * Button: #login-btn
 * Messages: #login-error, #login-success
 */
async function loginDoctor() {
  const rawId   = document.getElementById('login-doctorid')?.value.trim().toUpperCase();
  const password= document.getElementById('login-password')?.value;

  // Validation
  if (!rawId || !rawId.startsWith('DR-')) {
    return showError('login-error', 'Valid Doctor ID daalo (format: DR-XXXXX)');
  }
  if (!password) {
    return showError('login-error', 'Password daalo');
  }

  setLoading('login-btn', true);

  try {
    // Step 1: Fetch email from doctors table using doctor_id
    const { data: doctorRow, error: fetchError } = await sb
      .from('doctors')
      .select('email, full_name, status')
      .eq('doctor_id', rawId)
      .maybeSingle();

    if (fetchError) throw fetchError;

    if (!doctorRow) {
      setLoading('login-btn', false, 'Login →');
      return showError('login-error',
        `Doctor ID "${rawId}" nahi mila. Check karo ya register karo.`
      );
    }

    // Step 2: Login with Supabase Auth using fetched email
    const { data: authData, error: loginError } = await sb.auth.signInWithPassword({
      email:    doctorRow.email,
      password: password
    });

    if (loginError) throw loginError;

    // Step 3: Success
    setLoading('login-btn', false, 'Login →');
    showSuccess('login-success',
      `Welcome Dr. ${doctorRow.full_name || rawId}! Redirecting...`
    );

    console.log('Doctor logged in:', doctorRow);

    // Redirect to doctor dashboard
    setTimeout(() => {
      window.location.href = '/doctor-dashboard';
    }, 1500);

  } catch (error) {
    console.error('Login error:', error);
    showError('login-error', parseError(error));
    setLoading('login-btn', false, 'Login →');
  }
}

// ────────────────────────────────────────────────────────────────
// 3. FORGOT DOCTOR ID
// ────────────────────────────────────────────────────────────────

/**
 * Retrieve Doctor ID using email + password
 * - Verifies credentials via Supabase Auth
 * - Fetches doctor_id from doctors table
 * - Displays it to the user
 *
 * Expected HTML fields:
 * #forgot-email, #forgot-password
 * Button: #forgot-btn
 * Messages: #forgot-error, #forgot-success
 * Result: #forgot-doctor-id (shows the found ID)
 */
async function forgotDoctorId() {
  const email    = document.getElementById('forgot-email')?.value.trim();
  const password = document.getElementById('forgot-password')?.value;

  // Validation
  if (!email || !email.includes('@')) {
    return showError('forgot-error', 'Valid email daalo');
  }
  if (!password) {
    return showError('forgot-error', 'Password daalo');
  }

  setLoading('forgot-btn', true);

  try {
    // Step 1: Verify credentials via Supabase Auth
    const { data: authData, error: loginError } = await sb.auth.signInWithPassword({
      email,
      password
    });

    if (loginError) throw loginError;

    // Step 2: Fetch doctor_id from doctors table
    const { data: doctorRow, error: fetchError } = await sb
      .from('doctors')
      .select('doctor_id, full_name')
      .eq('user_id', authData.user.id)
      .maybeSingle();

    if (fetchError) throw fetchError;

    if (!doctorRow) {
      // Auth worked but no doctor record found
      await sb.auth.signOut();
      setLoading('forgot-btn', false, 'Find My Doctor ID →');
      return showError('forgot-error',
        'Credentials sahi hain but doctor record nahi mila. Support se contact karein.'
      );
    }

    // Step 3: Display the Doctor ID
    setLoading('forgot-btn', false, 'Find My Doctor ID →');

    const idEl = document.getElementById('forgot-doctor-id');
    if (idEl) {
      idEl.textContent = doctorRow.doctor_id;
      idEl.style.display = 'block';
    }

    showSuccess('forgot-success',
      `Mila! Dr. ${doctorRow.full_name || ''} ka Doctor ID hai: 
       <strong style="font-size:18px;letter-spacing:2px;">${doctorRow.doctor_id}</strong>. 
       Is ID se login karo.`
    );

    // Sign out after showing (don't auto-login here)
    await sb.auth.signOut();

    console.log('Doctor ID retrieved:', doctorRow.doctor_id);

  } catch (error) {
    console.error('Forgot Doctor ID error:', error);
    showError('forgot-error', parseError(error));
    setLoading('forgot-btn', false, 'Find My Doctor ID →');
  }
}

// ────────────────────────────────────────────────────────────────
// AUTO-UPPERCASE DOCTOR ID INPUT
// ────────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  const drIdInput = document.getElementById('login-doctorid');
  if (drIdInput) {
    drIdInput.addEventListener('input', function () {
      const pos = this.selectionStart;
      this.value = this.value.toUpperCase();
      this.setSelectionRange(pos, pos);
    });
  }
});

// Add spinner CSS dynamically
const style = document.createElement('style');
style.textContent = `
  @keyframes spin {
    to { transform: rotate(360deg); }
  }
`;
document.head.appendChild(style);
