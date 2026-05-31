import React, { useState } from 'react';
import { Link as RouterLink, useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from '../../api/firebase';

const loginSchema = z.object({
  email: z.string().email('Please enter a valid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
});

export const Login = () => {
  const navigate = useNavigate();
  const [authError, setAuthError] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm({ resolver: zodResolver(loginSchema) });

  const onSubmit = async (data) => {
    setAuthError('');
    try {
      await signInWithEmailAndPassword(auth, data.email, data.password);
      navigate('/');
    } catch (error) {
      console.error('Login error:', error);
      switch (error.code) {
        case 'auth/user-not-found':
        case 'auth/wrong-password':
        case 'auth/invalid-credential':
          setAuthError('Invalid email or password. Please try again.');
          break;
        case 'auth/too-many-requests':
          setAuthError('Too many failed attempts. Please try again later.');
          break;
        case 'auth/user-disabled':
          setAuthError('This account has been disabled. Contact support.');
          break;
        default:
          setAuthError('An error occurred. Please try again.');
      }
    }
  };

  return (
    <div style={styles.page}>
      {/* Animated background orbs */}
      <div style={styles.orb1} />
      <div style={styles.orb2} />
      <div style={styles.orb3} />

      {/* Grid overlay */}
      <div style={styles.gridOverlay} />

      <div style={styles.container}>
        {/* Logo & Brand */}
        <div style={styles.brand}>
          <img
            src="/ridesync-logo.png"
            alt="RideSync"
            style={styles.logoImg}
          />
          <p style={styles.brandSub}>Admin Portal</p>
        </div>

        {/* Card */}
        <div style={styles.card}>
          <div style={styles.cardHeader}>
            <h2 style={styles.cardTitle}>Welcome back</h2>
            <p style={styles.cardSubtitle}>Sign in to your account to continue</p>
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
            <div style={styles.fieldGroup}>
              <label style={styles.label} htmlFor="login-email">Email Address</label>
              <div style={styles.inputWrapper}>
                <svg style={styles.inputIcon} width="18" height="18" viewBox="0 0 24 24" fill="none">
                  <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                  <polyline points="22,6 12,13 2,6" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
                <input
                  id="login-email"
                  type="email"
                  placeholder="admin@ridesync.lk"
                  style={{
                    ...styles.input,
                    ...(errors.email ? styles.inputError : {}),
                  }}
                  {...register('email')}
                  autoComplete="email"
                />
              </div>
              {errors.email && <p style={styles.fieldError}>{errors.email.message}</p>}
            </div>

            <div style={styles.fieldGroup}>
              <div style={styles.labelRow}>
                <label style={styles.label} htmlFor="login-password">Password</label>
              
              </div>
              <div style={styles.inputWrapper}>
                <svg style={styles.inputIcon} width="18" height="18" viewBox="0 0 24 24" fill="none">
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                  <path d="M7 11V7a5 5 0 0 1 10 0v4" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
                <input
                  id="login-password"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="••••••••"
                  style={{
                    ...styles.input,
                    ...styles.inputWithEndIcon,
                    ...(errors.password ? styles.inputError : {}),
                  }}
                  {...register('password')}
                  autoComplete="current-password"
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
                      <circle cx="12" cy="12" r="3" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  )}
                </button>
              </div>
              {errors.password && <p style={styles.fieldError}>{errors.password.message}</p>}
            </div>

            <button
              id="login-submit-btn"
              type="submit"
              disabled={isSubmitting}
              style={{
                ...styles.submitBtn,
                ...(isSubmitting ? styles.submitBtnDisabled : {}),
              }}
            >
              {isSubmitting ? (
                <span style={styles.spinnerWrap}>
                  <span style={styles.spinner} />
                  Signing in…
                </span>
              ) : (
                <>
                  Sign In
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" style={{marginLeft: 8}}>
                    <path d="M5 12h14M12 5l7 7-7 7" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </>
              )}
            </button>
          </form>

          <div style={styles.divider}>
            <span style={styles.dividerLine} />
            <span style={styles.dividerText}>New to RideSync?</span>
            <span style={styles.dividerLine} />
          </div>

        </div>

        <p style={styles.footer}>
          © 2025 RideSync LK · All rights reserved
        </p>
      </div>

      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');

        * { box-sizing: border-box; margin: 0; padding: 0; }

        @keyframes orb1Float {
          0%, 100% { transform: translate(0, 0) scale(1); }
          50% { transform: translate(40px, -60px) scale(1.1); }
        }
        @keyframes orb2Float {
          0%, 100% { transform: translate(0, 0) scale(1); }
          50% { transform: translate(-50px, 40px) scale(0.9); }
        }
        @keyframes orb3Float {
          0%, 100% { transform: translate(0, 0) scale(1); }
          50% { transform: translate(30px, 50px) scale(1.05); }
        }
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
        @keyframes fadeUp {
          from { opacity: 0; transform: translateY(24px); }
          to { opacity: 1; transform: translateY(0); }
        }

        #login-submit-btn:hover:not(:disabled) {
          transform: translateY(-2px);
          box-shadow: 0 8px 30px rgba(245, 158, 11, 0.5) !important;
        }
        #login-submit-btn:active:not(:disabled) {
          transform: translateY(0);
        }
        #go-to-signup-btn:hover {
          background: rgba(245,158,11,0.1) !important;
          border-color: #f59e0b !important;
          color: #f59e0b !important;
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
    maxWidth: '440px',
    padding: '24px 20px',
    animation: 'fadeUp 0.6s ease-out',
  },
  brand: {
    textAlign: 'center',
    marginBottom: '32px',
  },
  logoImg: {
    width: '220px',
    height: 'auto',
    objectFit: 'contain',
    marginBottom: '8px',
    filter: 'drop-shadow(0 0 24px rgba(245,158,11,0.4))',
  },
  brandSub: {
    fontSize: '13px',
    color: '#64748b',
    letterSpacing: '0.1em',
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
    marginBottom: '28px',
  },
  cardTitle: {
    fontSize: '24px',
    fontWeight: 700,
    color: '#f8fafc',
    marginBottom: '6px',
  },
  cardSubtitle: {
    fontSize: '14px',
    color: '#64748b',
    fontWeight: 400,
  },
  errorBanner: {
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    background: 'rgba(239,68,68,0.1)',
    border: '1px solid rgba(239,68,68,0.3)',
    borderRadius: '10px',
    padding: '12px 14px',
    marginBottom: '20px',
    fontSize: '13px',
    color: '#fca5a5',
  },
  form: {
    display: 'flex',
    flexDirection: 'column',
    gap: '20px',
  },
  fieldGroup: {
    display: 'flex',
    flexDirection: 'column',
    gap: '8px',
  },
  label: {
    fontSize: '13px',
    fontWeight: 500,
    color: '#94a3b8',
    letterSpacing: '0.02em',
  },
  labelRow: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  forgotLink: {
    fontSize: '12px',
    color: '#f59e0b',
    textDecoration: 'none',
    fontWeight: 500,
    transition: 'color 0.2s',
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
    zIndex: 1,
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
    transition: 'background 0.2s',
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
    transform: 'none',
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
  divider: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
    margin: '24px 0',
  },
  dividerLine: {
    flex: 1,
    height: '1px',
    background: 'rgba(255,255,255,0.07)',
  },
  dividerText: {
    fontSize: '12px',
    color: '#475569',
    whiteSpace: 'nowrap',
  },
  signupBtn: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    width: '100%',
    height: '46px',
    background: 'transparent',
    border: '1px solid rgba(255,255,255,0.12)',
    borderRadius: '12px',
    color: '#94a3b8',
    fontSize: '14px',
    fontWeight: 500,
    textDecoration: 'none',
    transition: 'all 0.2s ease',
    fontFamily: '"Inter", sans-serif',
  },
  footer: {
    textAlign: 'center',
    marginTop: '24px',
    fontSize: '12px',
    color: '#334155',
  },
};
