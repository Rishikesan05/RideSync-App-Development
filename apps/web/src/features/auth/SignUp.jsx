import React, { useState } from 'react';
import { Link as RouterLink, useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import {
  createUserWithEmailAndPassword,
  updateProfile,
} from 'firebase/auth';
import { auth } from '../../api/firebase';

const signupSchema = z.object({
  displayName: z
    .string()
    .min(2, 'Name must be at least 2 characters')
    .max(60, 'Name must be under 60 characters'),
  email: z.string().email('Please enter a valid email address'),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/[0-9]/, 'Password must contain at least one number'),
  confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ['confirmPassword'],
});

const PasswordStrength = ({ password }) => {
  const checks = [
    { label: '8+ characters', valid: password.length >= 8 },
    { label: 'Uppercase letter', valid: /[A-Z]/.test(password) },
    { label: 'Number', valid: /[0-9]/.test(password) },
  ];
  const score = checks.filter(c => c.valid).length;
  const colors = ['#ef4444', '#f97316', '#22c55e'];
  const labels = ['Weak', 'Fair', 'Strong'];

  if (!password) return null;

  return (
    <div style={{ marginTop: '10px' }}>
      <div style={{ display: 'flex', gap: '4px', marginBottom: '8px' }}>
        {[0, 1, 2].map(i => (
          <div
            key={i}
            style={{
              flex: 1,
              height: '3px',
              borderRadius: '2px',
              background: i < score ? colors[score - 1] : 'rgba(255,255,255,0.1)',
              transition: 'background 0.3s',
            }}
          />
        ))}
      </div>
      <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
        {checks.map((c, i) => (
          <span key={i} style={{
            fontSize: '11px',
            color: c.valid ? '#22c55e' : '#475569',
            display: 'flex',
            alignItems: 'center',
            gap: '4px',
          }}>
            <svg width="10" height="10" viewBox="0 0 12 12" fill="none">
              {c.valid
                ? <><circle cx="6" cy="6" r="5" fill="rgba(34,197,94,0.2)"/><path d="M3.5 6L5.5 8L8.5 4.5" stroke="#22c55e" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/></>
                : <circle cx="6" cy="6" r="5" fill="rgba(71,85,105,0.3)"/>
              }
            </svg>
            {c.label}
          </span>
        ))}
      </div>
    </div>
  );
};

export const SignUp = () => {
  const navigate = useNavigate();
  const [authError, setAuthError] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [success, setSuccess] = useState(false);

  const {
    register,
    handleSubmit,
    watch,
    formState: { errors, isSubmitting },
  } = useForm({ resolver: zodResolver(signupSchema) });

  const passwordValue = watch('password', '');

  const onSubmit = async (data) => {
    setAuthError('');
    try {
      const credential = await createUserWithEmailAndPassword(auth, data.email, data.password);
      await updateProfile(credential.user, { displayName: data.displayName });
      setSuccess(true);
      setTimeout(() => navigate('/'), 1500);
    } catch (error) {
      console.error('Signup error:', error);
      switch (error.code) {
        case 'auth/email-already-in-use':
          setAuthError('An account with this email already exists.');
          break;
        case 'auth/invalid-email':
          setAuthError('Invalid email address format.');
          break;
        case 'auth/weak-password':
          setAuthError('Password is too weak. Please choose a stronger password.');
          break;
        case 'auth/operation-not-allowed':
          setAuthError('Email/password sign-up is not enabled. Contact support.');
          break;
        default:
          setAuthError('Failed to create account. Please try again.');
      }
    }
  };

  return (
    <div style={styles.page}>
      <div style={styles.orb1} />
      <div style={styles.orb2} />
      <div style={styles.orb3} />
      <div style={styles.gridOverlay} />

      <div style={styles.container}>
        {/* Brand */}
        <div style={styles.brand}>
          <RouterLink to="/login" style={styles.backLink} id="signup-back-btn">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
              <path d="M19 12H5M12 5l-7 7 7 7" stroke="#94a3b8" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            Back to login
          </RouterLink>
          <img
            src="/ridesync-logo.jpeg"
            alt="RideSync"
            style={styles.logoImg}
          />
          <p style={styles.brandSub}>Create Your Admin Account</p>
        </div>

        {/* Card */}
        <div style={styles.card}>
          {success ? (
            <div style={styles.successState}>
              <div style={styles.successIcon}>
                <svg width="40" height="40" viewBox="0 0 40 40" fill="none">
                  <circle cx="20" cy="20" r="19" stroke="#22c55e" strokeWidth="2"/>
                  <path d="M12 20L17 25L28 14" stroke="#22c55e" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>
              <h3 style={{ color: '#f8fafc', fontSize: '20px', fontWeight: 700, marginBottom: '8px' }}>
                Account Created!
              </h3>
              <p style={{ color: '#64748b', fontSize: '14px' }}>
                Redirecting you to the dashboard…
              </p>
            </div>
          ) : (
            <>
              <div style={styles.cardHeader}>
                <h2 style={styles.cardTitle}>Create account</h2>
                <p style={styles.cardSubtitle}>Fill in your details to get started</p>
              </div>

              {authError && (
                <div style={styles.errorBanner}>
                  <svg width="16" height="16" viewBox="0 0 16 16" fill="none" style={{flexShrink: 0}}>
                    <circle cx="8" cy="8" r="7" stroke="#f87171" strokeWidth="1.5"/>
                    <path d="M8 5v3M8 11v.5" stroke="#f87171" strokeWidth="1.5" strokeLinecap="round"/>
                  </svg>
                  <span>{authError}</span>
                </div>
              )}

              <form onSubmit={handleSubmit(onSubmit)} style={styles.form} noValidate>
                {/* Full Name */}
                <div style={styles.fieldGroup}>
                  <label style={styles.label} htmlFor="signup-name">Full Name</label>
                  <div style={styles.inputWrapper}>
                    <svg style={styles.inputIcon} width="18" height="18" viewBox="0 0 24 24" fill="none">
                      <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                      <circle cx="12" cy="7" r="4" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                    <input
                      id="signup-name"
                      type="text"
                      placeholder="John Doe"
                      style={{ ...styles.input, ...(errors.displayName ? styles.inputError : {}) }}
                      {...register('displayName')}
                      autoComplete="name"
                    />
                  </div>
                  {errors.displayName && <p style={styles.fieldError}>{errors.displayName.message}</p>}
                </div>

                {/* Email */}
                <div style={styles.fieldGroup}>
                  <label style={styles.label} htmlFor="signup-email">Email Address</label>
                  <div style={styles.inputWrapper}>
                    <svg style={styles.inputIcon} width="18" height="18" viewBox="0 0 24 24" fill="none">
                      <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                      <polyline points="22,6 12,13 2,6" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                    <input
                      id="signup-email"
                      type="email"
                      placeholder="admin@ridesync.lk"
                      style={{ ...styles.input, ...(errors.email ? styles.inputError : {}) }}
                      {...register('email')}
                      autoComplete="email"
                    />
                  </div>
                  {errors.email && <p style={styles.fieldError}>{errors.email.message}</p>}
                </div>

                {/* Password */}
                <div style={styles.fieldGroup}>
                  <label style={styles.label} htmlFor="signup-password">Password</label>
                  <div style={styles.inputWrapper}>
                    <svg style={styles.inputIcon} width="18" height="18" viewBox="0 0 24 24" fill="none">
                      <rect x="3" y="11" width="18" height="11" rx="2" ry="2" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M7 11V7a5 5 0 0 1 10 0v4" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                    <input
                      id="signup-password"
                      type={showPassword ? 'text' : 'password'}
                      placeholder="Min. 8 characters"
                      style={{ ...styles.input, ...styles.inputWithEndIcon, ...(errors.password ? styles.inputError : {}) }}
                      {...register('password')}
                      autoComplete="new-password"
                    />
                    <button
                      type="button"
                      style={styles.eyeBtn}
                      onClick={() => setShowPassword(v => !v)}
                      aria-label={showPassword ? 'Hide password' : 'Show password'}
                    >
                      {showPassword ? (
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                          <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                          <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                          <line x1="1" y1="1" x2="23" y2="23" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round"/>
                        </svg>
                      ) : (
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                          <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                          <circle cx="12" cy="12" r="3" stroke="#94a3b8" strokeWidth="1.5"/>
                        </svg>
                      )}
                    </button>
                  </div>
                  {errors.password && <p style={styles.fieldError}>{errors.password.message}</p>}
                  <PasswordStrength password={passwordValue} />
                </div>

                {/* Confirm Password */}
                <div style={styles.fieldGroup}>
                  <label style={styles.label} htmlFor="signup-confirm-password">Confirm Password</label>
                  <div style={styles.inputWrapper}>
                    <svg style={styles.inputIcon} width="18" height="18" viewBox="0 0 24 24" fill="none">
                      <path d="M9 12l2 2 4-4" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                      <rect x="3" y="11" width="18" height="11" rx="2" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                      <path d="M7 11V7a5 5 0 0 1 10 0v4" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                    <input
                      id="signup-confirm-password"
                      type={showConfirm ? 'text' : 'password'}
                      placeholder="Repeat your password"
                      style={{ ...styles.input, ...styles.inputWithEndIcon, ...(errors.confirmPassword ? styles.inputError : {}) }}
                      {...register('confirmPassword')}
                      autoComplete="new-password"
                    />
                    <button
                      type="button"
                      style={styles.eyeBtn}
                      onClick={() => setShowConfirm(v => !v)}
                      aria-label={showConfirm ? 'Hide password' : 'Show password'}
                    >
                      {showConfirm ? (
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                          <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                          <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                          <line x1="1" y1="1" x2="23" y2="23" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round"/>
                        </svg>
                      ) : (
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                          <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                          <circle cx="12" cy="12" r="3" stroke="#94a3b8" strokeWidth="1.5"/>
                        </svg>
                      )}
                    </button>
                  </div>
                  {errors.confirmPassword && <p style={styles.fieldError}>{errors.confirmPassword.message}</p>}
                </div>

                <button
                  id="signup-submit-btn"
                  type="submit"
                  disabled={isSubmitting}
                  style={{ ...styles.submitBtn, ...(isSubmitting ? styles.submitBtnDisabled : {}) }}
                >
                  {isSubmitting ? (
                    <span style={styles.spinnerWrap}>
                      <span style={styles.spinner} />
                      Creating account…
                    </span>
                  ) : (
                    <>
                      Create Account
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" style={{marginLeft: 8}}>
                        <path d="M5 12h14M12 5l7 7-7 7" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                      </svg>
                    </>
                  )}
                </button>
              </form>

              <p style={styles.loginPrompt}>
                Already have an account?{' '}
                <RouterLink to="/login" style={styles.loginLink} id="signup-go-login-link">
                  Sign in
                </RouterLink>
              </p>
            </>
          )}
        </div>

        <p style={styles.footer}>© 2025 RideSync LK · All rights reserved</p>
      </div>

      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');
        * { box-sizing: border-box; margin: 0; padding: 0; }
        @keyframes orb1Float { 0%,100% { transform: translate(0,0) scale(1); } 50% { transform: translate(40px,-60px) scale(1.1); } }
        @keyframes orb2Float { 0%,100% { transform: translate(0,0) scale(1); } 50% { transform: translate(-50px,40px) scale(0.9); } }
        @keyframes orb3Float { 0%,100% { transform: translate(0,0) scale(1); } 50% { transform: translate(30px,50px) scale(1.05); } }
        @keyframes spin { to { transform: rotate(360deg); } }
        @keyframes fadeUp { from { opacity: 0; transform: translateY(24px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes successPop { 0% { opacity: 0; transform: scale(0.8); } 60% { transform: scale(1.05); } 100% { opacity: 1; transform: scale(1); } }

        #signup-submit-btn:hover:not(:disabled) {
          transform: translateY(-2px);
          box-shadow: 0 8px 30px rgba(245, 158, 11, 0.5) !important;
        }
        #signup-submit-btn:active:not(:disabled) { transform: translateY(0); }

        input:focus {
          border-color: rgba(245,158,11,0.5) !important;
          box-shadow: 0 0 0 3px rgba(245,158,11,0.1) !important;
          outline: none;
        }
      `}</style>
    </div>
  );
};

const styles = {
  page: {
    minHeight: '100vh',
    background: 'linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #0f172a 100%)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontFamily: '"Inter", sans-serif',
    position: 'relative',
    overflow: 'hidden',
    padding: '24px 0',
  },
  orb1: {
    position: 'fixed',
    top: '-10%',
    left: '-5%',
    width: '500px',
    height: '500px',
    borderRadius: '50%',
    background: 'radial-gradient(circle, rgba(245,158,11,0.15) 0%, transparent 70%)',
    animation: 'orb1Float 8s ease-in-out infinite',
    pointerEvents: 'none',
  },
  orb2: {
    position: 'fixed',
    bottom: '-15%',
    right: '-10%',
    width: '600px',
    height: '600px',
    borderRadius: '50%',
    background: 'radial-gradient(circle, rgba(99,102,241,0.12) 0%, transparent 70%)',
    animation: 'orb2Float 10s ease-in-out infinite',
    pointerEvents: 'none',
  },
  orb3: {
    position: 'fixed',
    top: '50%',
    left: '60%',
    width: '300px',
    height: '300px',
    borderRadius: '50%',
    background: 'radial-gradient(circle, rgba(16,185,129,0.08) 0%, transparent 70%)',
    animation: 'orb3Float 12s ease-in-out infinite',
    pointerEvents: 'none',
  },
  gridOverlay: {
    position: 'fixed',
    inset: 0,
    backgroundImage: 'linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px)',
    backgroundSize: '60px 60px',
    pointerEvents: 'none',
  },
  container: {
    position: 'relative',
    zIndex: 10,
    width: '100%',
    maxWidth: '460px',
    padding: '24px 20px',
    animation: 'fadeUp 0.6s ease-out',
  },
  brand: {
    textAlign: 'center',
    marginBottom: '28px',
    position: 'relative',
  },
  backLink: {
    position: 'absolute',
    left: 0,
    top: '4px',
    display: 'flex',
    alignItems: 'center',
    gap: '6px',
    color: '#94a3b8',
    textDecoration: 'none',
    fontSize: '13px',
    fontWeight: 500,
    transition: 'color 0.2s',
  },
  logoImg: {
    width: '200px',
    height: 'auto',
    objectFit: 'contain',
    marginBottom: '8px',
    filter: 'drop-shadow(0 0 20px rgba(245,158,11,0.4))',
  },
  brandSub: {
    fontSize: '12px',
    color: '#64748b',
    letterSpacing: '0.08em',
    textTransform: 'uppercase',
    fontWeight: 500,
  },
  card: {
    background: 'rgba(30, 41, 59, 0.7)',
    backdropFilter: 'blur(24px)',
    WebkitBackdropFilter: 'blur(24px)',
    border: '1px solid rgba(255,255,255,0.08)',
    borderRadius: '24px',
    padding: '36px',
    boxShadow: '0 32px 80px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.06)',
  },
  cardHeader: {
    marginBottom: '24px',
  },
  cardTitle: {
    fontSize: '22px',
    fontWeight: 700,
    color: '#f8fafc',
    marginBottom: '4px',
  },
  cardSubtitle: {
    fontSize: '13px',
    color: '#64748b',
  },
  successState: {
    textAlign: 'center',
    padding: '20px 0',
    animation: 'successPop 0.5s ease-out',
  },
  successIcon: {
    marginBottom: '20px',
  },
  errorBanner: {
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    background: 'rgba(239,68,68,0.1)',
    border: '1px solid rgba(239,68,68,0.3)',
    borderRadius: '10px',
    padding: '12px 14px',
    marginBottom: '18px',
    fontSize: '13px',
    color: '#fca5a5',
  },
  form: {
    display: 'flex',
    flexDirection: 'column',
    gap: '18px',
  },
  fieldGroup: {
    display: 'flex',
    flexDirection: 'column',
    gap: '6px',
  },
  label: {
    fontSize: '13px',
    fontWeight: 500,
    color: '#94a3b8',
    letterSpacing: '0.02em',
  },
  inputWrapper: {
    position: 'relative',
  },
  inputIcon: {
    position: 'absolute',
    left: '14px',
    top: '50%',
    transform: 'translateY(-50%)',
    pointerEvents: 'none',
  },
  input: {
    width: '100%',
    height: '48px',
    paddingLeft: '42px',
    paddingRight: '16px',
    background: 'rgba(15,23,42,0.6)',
    border: '1px solid rgba(255,255,255,0.1)',
    borderRadius: '12px',
    color: '#f8fafc',
    fontSize: '14px',
    fontFamily: '"Inter", sans-serif',
    outline: 'none',
    transition: 'border-color 0.2s, box-shadow 0.2s',
  },
  inputWithEndIcon: {
    paddingRight: '44px',
  },
  inputError: {
    borderColor: 'rgba(239,68,68,0.5)',
  },
  eyeBtn: {
    position: 'absolute',
    right: '12px',
    top: '50%',
    transform: 'translateY(-50%)',
    background: 'none',
    border: 'none',
    cursor: 'pointer',
    padding: '4px',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: '6px',
  },
  fieldError: {
    fontSize: '12px',
    color: '#f87171',
    marginTop: '2px',
  },
  submitBtn: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    width: '100%',
    height: '50px',
    background: 'linear-gradient(135deg, #f59e0b, #d97706)',
    color: '#0f172a',
    border: 'none',
    borderRadius: '12px',
    fontSize: '15px',
    fontWeight: 700,
    fontFamily: '"Inter", sans-serif',
    cursor: 'pointer',
    transition: 'all 0.2s ease',
    boxShadow: '0 4px 20px rgba(245,158,11,0.35)',
    marginTop: '4px',
  },
  submitBtnDisabled: {
    opacity: 0.7,
    cursor: 'not-allowed',
  },
  spinnerWrap: {
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
  },
  spinner: {
    display: 'inline-block',
    width: '18px',
    height: '18px',
    border: '2px solid rgba(15,23,42,0.3)',
    borderTopColor: '#0f172a',
    borderRadius: '50%',
    animation: 'spin 0.8s linear infinite',
  },
  loginPrompt: {
    textAlign: 'center',
    marginTop: '24px',
    fontSize: '14px',
    color: '#475569',
  },
  loginLink: {
    color: '#f59e0b',
    textDecoration: 'none',
    fontWeight: 600,
  },
  footer: {
    textAlign: 'center',
    marginTop: '24px',
    fontSize: '12px',
    color: '#334155',
  },
};
