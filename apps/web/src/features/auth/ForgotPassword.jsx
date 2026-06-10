import React, { useState } from 'react';
import { Link as RouterLink } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { sendPasswordResetEmail } from 'firebase/auth';
import { auth } from '../../api/firebase';

const forgotSchema = z.object({
  email: z.string().email('Please enter a valid email address'),
});

export const ForgotPassword = () => {
  const [status, setStatus] = useState('idle'); // idle | success | error
  const [errorMsg, setErrorMsg] = useState('');
  const [sentEmail, setSentEmail] = useState('');

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm({ resolver: zodResolver(forgotSchema) });

  const onSubmit = async (data) => {
    setErrorMsg('');
    try {
      await sendPasswordResetEmail(auth, data.email);
      setSentEmail(data.email);
      setStatus('success');
    } catch (error) {
      console.error('Password reset error:', error);
      switch (error.code) {
        case 'auth/user-not-found':
          // For security, show success even if user not found
          setSentEmail(data.email);
          setStatus('success');
          break;
        case 'auth/invalid-email':
          setErrorMsg('Invalid email address format.');
          setStatus('error');
          break;
        case 'auth/too-many-requests':
          setErrorMsg('Too many requests. Please wait a moment before trying again.');
          setStatus('error');
          break;
        default:
          setErrorMsg('Failed to send reset email. Please try again.');
          setStatus('error');
      }
    }
  };

  return (
    <div style={styles.page}>

      <div style={styles.orb2} />
      <div style={styles.orb3} />


      <div style={styles.container}>
        {/* Brand */}
        <div style={styles.brand}>
          <img
            src="/ridesync-logo.jpeg"
            alt="RideSync"
            style={styles.logoImg}
          />
          <p style={styles.brandSub}>Password Recovery</p>
        </div>

        {/* Back Link */}
        <RouterLink to="/login" style={styles.backLink} id="forgot-back-btn">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
            <path d="M19 12H5M12 5l-7 7 7 7" stroke="#94a3b8" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          Back to login
        </RouterLink>

        {/* Card */}
        <div style={styles.card}>
          {status === 'success' ? (
            /* Success State */
            <div style={styles.successState}>
              <div style={styles.successIconWrap}>
                <svg width="56" height="56" viewBox="0 0 56 56" fill="none">
                  <circle cx="28" cy="28" r="27" stroke="rgba(245,158,11,0.3)" strokeWidth="2"/>
                  <circle cx="28" cy="28" r="20" fill="rgba(245,158,11,0.1)"/>
                  <path d="M18 28h20M28 18l10 10-10 10" stroke="#f59e0b" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>
              <h2 style={styles.successTitle}>Check your inbox</h2>
              <p style={styles.successText}>
                We've sent a password reset link to
              </p>
              <div style={styles.emailBadge}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" style={{flexShrink: 0}}>
                  <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" stroke="#f59e0b" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                  <polyline points="22,6 12,13 2,6" stroke="#f59e0b" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
                <span style={styles.emailText}>{sentEmail}</span>
              </div>
              <p style={styles.successNote}>
                Didn't receive it? Check your spam folder or{' '}
                <button
                  style={styles.resendBtn}
                  id="forgot-resend-btn"
                  onClick={() => setStatus('idle')}
                >
                  try again
                </button>
              </p>
              <RouterLink to="/login" style={styles.backToLoginBtn} id="forgot-success-login-btn">
                Back to Sign In
              </RouterLink>
            </div>
          ) : (
            /* Form State */
            <>
              <div style={styles.cardHeader}>
                <div style={styles.iconCircle}>
                  <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2" stroke="#f59e0b" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                    <path d="M7 11V7a5 5 0 0 1 10 0v4" stroke="#f59e0b" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                    <circle cx="12" cy="16" r="1.5" fill="#f59e0b"/>
                  </svg>
                </div>
                <h2 style={styles.cardTitle}>Forgot your password?</h2>
                <p style={styles.cardSubtitle}>
                  No worries! Enter your email address and we'll send you a link to reset your password.
                </p>
              </div>

              {status === 'error' && (
                <div style={styles.errorBanner}>
                  <svg width="16" height="16" viewBox="0 0 16 16" fill="none" style={{flexShrink: 0}}>
                    <circle cx="8" cy="8" r="7" stroke="#f87171" strokeWidth="1.5"/>
                    <path d="M8 5v3M8 11v.5" stroke="#f87171" strokeWidth="1.5" strokeLinecap="round"/>
                  </svg>
                  <span>{errorMsg}</span>
                </div>
              )}

              <form onSubmit={handleSubmit(onSubmit)} style={styles.form} noValidate>
                <div style={styles.fieldGroup}>
                  <label style={styles.label} htmlFor="forgot-email">Email Address</label>
                  <div style={styles.inputWrapper}>
                    <svg style={styles.inputIcon} width="18" height="18" viewBox="0 0 24 24" fill="none">
                      <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                      <polyline points="22,6 12,13 2,6" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                    <input
                      id="forgot-email"
                      type="email"
                      placeholder="admin@ridesync.lk"
                      style={{ ...styles.input, ...(errors.email ? styles.inputError : {}) }}
                      {...register('email')}
                      autoComplete="email"
                    />
                  </div>
                  {errors.email && <p style={styles.fieldError}>{errors.email.message}</p>}
                </div>

                <button
                  id="forgot-submit-btn"
                  type="submit"
                  disabled={isSubmitting}
                  style={{ ...styles.submitBtn, ...(isSubmitting ? styles.submitBtnDisabled : {}) }}
                >
                  {isSubmitting ? (
                    <span style={styles.spinnerWrap}>
                      <span style={styles.spinner} />
                      Sending reset link…
                    </span>
                  ) : (
                    <>
                      Send Reset Link
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" style={{marginLeft: 8}}>
                        <line x1="22" y1="2" x2="11" y2="13" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                        <polygon points="22 2 15 22 11 13 2 9 22 2" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none"/>
                      </svg>
                    </>
                  )}
                </button>
              </form>

              {/* Tips */}
              <div style={styles.tipsBox}>
                <p style={styles.tipsTitle}>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" style={{flexShrink: 0}}>
                    <circle cx="12" cy="12" r="10" stroke="#f59e0b" strokeWidth="1.5"/>
                    <path d="M12 8v4M12 16v.01" stroke="#f59e0b" strokeWidth="1.5" strokeLinecap="round"/>
                  </svg>
                  Tips
                </p>
                <ul style={styles.tipsList}>
                  <li>Check your spam or junk folder</li>
                  <li>The link expires in 1 hour</li>
                  <li>Use the same email you signed up with</li>
                </ul>
              </div>

              <p style={styles.loginPrompt}>
                Remember your password?{' '}
                <RouterLink to="/login" style={styles.loginLink} id="forgot-go-login-link">
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

        @keyframes orb2Float { 0%,100% { transform: translate(0,0) scale(1); } 50% { transform: translate(-50px,40px) scale(0.9); } }
        @keyframes orb3Float { 0%,100% { transform: translate(0,0) scale(1); } 50% { transform: translate(30px,50px) scale(1.05); } }
        @keyframes spin { to { transform: rotate(360deg); } }
        @keyframes fadeUp { from { opacity: 0; transform: translateY(24px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes successPop { 0% { opacity: 0; transform: scale(0.85); } 60% { transform: scale(1.03); } 100% { opacity: 1; transform: scale(1); } }

        #forgot-submit-btn:hover:not(:disabled) {
          transform: translateY(-2px);
          box-shadow: 0 8px 30px rgba(245, 158, 11, 0.5) !important;
        }
        #forgot-submit-btn:active:not(:disabled) { transform: translateY(0); }

        #forgot-back-btn:hover {
          color: #f8fafc !important;
          background: rgba(245, 158, 11, 0.1) !important;
          border-color: rgba(245, 158, 11, 0.4) !important;
          transform: translateY(-1px);
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
        }
        #forgot-back-btn:active {
          transform: translateY(0);
        }

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
    position: 'relative',
  },
  backLink: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: '8px',
    color: '#94a3b8',
    background: 'rgba(30, 41, 59, 0.5)',
    backdropFilter: 'blur(8px)',
    WebkitBackdropFilter: 'blur(8px)',
    border: '1px solid rgba(255, 255, 255, 0.08)',
    borderRadius: '10px',
    padding: '8px 16px',
    textDecoration: 'none',
    fontSize: '13px',
    fontWeight: 500,
    marginBottom: '16px',
    transition: 'all 0.25s ease',
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
    marginBottom: '28px',
    textAlign: 'center',
  },
  iconCircle: {
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'center',
    width: '64px',
    height: '64px',
    borderRadius: '50%',
    background: 'rgba(245,158,11,0.1)',
    border: '1px solid rgba(245,158,11,0.2)',
    marginBottom: '16px',
  },
  cardTitle: {
    fontSize: '22px',
    fontWeight: 700,
    color: '#f8fafc',
    marginBottom: '8px',
  },
  cardSubtitle: {
    fontSize: '14px',
    color: '#64748b',
    lineHeight: 1.6,
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
  inputError: {
    borderColor: 'rgba(239,68,68,0.5)',
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
  tipsBox: {
    marginTop: '20px',
    background: 'rgba(245,158,11,0.05)',
    border: '1px solid rgba(245,158,11,0.15)',
    borderRadius: '12px',
    padding: '14px 16px',
  },
  tipsTitle: {
    fontSize: '13px',
    fontWeight: 600,
    color: '#f59e0b',
    marginBottom: '8px',
    display: 'flex',
    alignItems: 'center',
    gap: '6px',
  },
  tipsList: {
    listStyle: 'none',
    display: 'flex',
    flexDirection: 'column',
    gap: '4px',
    paddingLeft: '20px',
  },
  loginPrompt: {
    textAlign: 'center',
    marginTop: '20px',
    fontSize: '14px',
    color: '#475569',
  },
  loginLink: {
    color: '#f59e0b',
    textDecoration: 'none',
    fontWeight: 600,
  },
  // Success state
  successState: {
    textAlign: 'center',
    padding: '16px 0',
    animation: 'successPop 0.5s ease-out',
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    gap: '12px',
  },
  successIconWrap: {
    marginBottom: '4px',
  },
  successTitle: {
    fontSize: '22px',
    fontWeight: 700,
    color: '#f8fafc',
  },
  successText: {
    fontSize: '14px',
    color: '#64748b',
    marginBottom: '4px',
  },
  emailBadge: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: '8px',
    background: 'rgba(245,158,11,0.1)',
    border: '1px solid rgba(245,158,11,0.2)',
    borderRadius: '100px',
    padding: '6px 14px',
    fontSize: '13px',
    fontWeight: 500,
  },
  emailText: {
    color: '#f59e0b',
    wordBreak: 'break-all',
  },
  successNote: {
    fontSize: '13px',
    color: '#475569',
    lineHeight: 1.6,
  },
  resendBtn: {
    background: 'none',
    border: 'none',
    color: '#f59e0b',
    fontWeight: 600,
    cursor: 'pointer',
    fontSize: '13px',
    padding: 0,
    fontFamily: '"Inter", sans-serif',
    textDecoration: 'underline',
  },
  backToLoginBtn: {
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: '8px',
    height: '46px',
    padding: '0 32px',
    background: 'linear-gradient(135deg, #f59e0b, #d97706)',
    color: '#0f172a',
    border: 'none',
    borderRadius: '12px',
    fontSize: '14px',
    fontWeight: 700,
    textDecoration: 'none',
    transition: 'all 0.2s ease',
    boxShadow: '0 4px 20px rgba(245,158,11,0.35)',
  },
  footer: {
    textAlign: 'center',
    marginTop: '24px',
    fontSize: '12px',
    color: '#334155',
  },
};
