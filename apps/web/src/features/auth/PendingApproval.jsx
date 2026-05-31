import React from 'react';
import { Link as RouterLink } from 'react-router-dom';
import { signOut } from 'firebase/auth';
import { auth } from '../../api/firebase';
import { useAuth } from '../../providers/AuthProvider';

export const PendingApproval = () => {
  const { currentUser, userProfile } = useAuth();

  const handleSignOut = async () => {
    try {
      await signOut(auth);
    } catch (err) {
      console.error('Sign-out error:', err);
    }
  };

  const displayName = currentUser?.displayName || userProfile?.displayName || 'there';
  const email = currentUser?.email || userProfile?.email || '';

  return (
    <div style={styles.page}>
      <div style={styles.orb1} />
      <div style={styles.orb2} />
      <div style={styles.gridOverlay} />

      <div style={styles.container}>
        {/* Logo */}
        <div style={styles.brand}>
          <img src="/ridesync-logo.jpeg" alt="RideSync" style={styles.logoImg} />
        </div>

        {/* Card */}
        <div style={styles.card}>
          {/* Icon */}
          <div style={styles.iconWrap}>
            <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
              <circle cx="24" cy="24" r="23" stroke="rgba(245,158,11,0.3)" strokeWidth="2"/>
              <circle cx="24" cy="24" r="16" fill="rgba(245,158,11,0.08)" stroke="rgba(245,158,11,0.2)" strokeWidth="1.5"/>
              <path d="M24 16v9" stroke="#f59e0b" strokeWidth="2.5" strokeLinecap="round"/>
              <circle cx="24" cy="30" r="1.5" fill="#f59e0b"/>
            </svg>
          </div>

          <h2 style={styles.title}>Account Pending Approval</h2>
          <p style={styles.subtitle}>
            Hi <strong style={{ color: '#f8fafc' }}>{displayName}</strong>, your account has been created
            but is awaiting admin approval before you can access the RideSync portal.
          </p>

          {/* Status pill */}
          <div style={styles.statusRow}>
            <span style={styles.statusDot} />
            <span style={styles.statusText}>Pending review</span>
            <span style={styles.emailTag}>{email}</span>
          </div>

          {/* Steps */}
          <div style={styles.steps}>
            <div style={styles.step}>
              <div style={{ ...styles.stepIcon, background: 'rgba(34,197,94,0.1)', border: '1px solid rgba(34,197,94,0.25)' }}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                  <path d="M9 12l2 2 4-4" stroke="#22c55e" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <circle cx="12" cy="12" r="10" stroke="#22c55e" strokeWidth="1.5"/>
                </svg>
              </div>
              <div>
                <p style={styles.stepTitle}>Account created</p>
                <p style={styles.stepDesc}>Your credentials have been registered securely.</p>
              </div>
            </div>

            <div style={styles.stepConnector} />

            <div style={styles.step}>
              <div style={{ ...styles.stepIcon, background: 'rgba(245,158,11,0.08)', border: '1px solid rgba(245,158,11,0.2)' }}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                  <circle cx="12" cy="12" r="10" stroke="#f59e0b" strokeWidth="1.5"/>
                  <path d="M12 8v4M12 16v.01" stroke="#f59e0b" strokeWidth="1.5" strokeLinecap="round"/>
                </svg>
              </div>
              <div>
                <p style={styles.stepTitle}>Admin review <span style={styles.pendingBadge}>In progress</span></p>
                <p style={styles.stepDesc}>An administrator will review and approve your account.</p>
              </div>
            </div>

            <div style={styles.stepConnector} />

            <div style={styles.step}>
              <div style={{ ...styles.stepIcon, background: 'rgba(100,116,139,0.08)', border: '1px solid rgba(100,116,139,0.15)' }}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                  <path d="M9 18l6-6-6-6" stroke="#475569" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>
              <div>
                <p style={{ ...styles.stepTitle, color: '#475569' }}>Access granted</p>
                <p style={styles.stepDesc}>You'll be able to sign in once approved.</p>
              </div>
            </div>
          </div>

          {/* Info box */}
          <div style={styles.infoBox}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" style={{ flexShrink: 0 }}>
              <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" stroke="#60a5fa" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
              <polyline points="22,6 12,13 2,6" stroke="#60a5fa" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            <p style={styles.infoText}>
              You'll receive an email notification at <strong style={{ color: '#93c5fd' }}>{email}</strong> once your account is approved. If you haven't heard back in 24 hours, contact your system administrator.
            </p>
          </div>

          {/* Actions */}
          <div style={styles.actions}>
            <button
              id="pending-signout-btn"
              onClick={handleSignOut}
              style={styles.signOutBtn}
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                <polyline points="16 17 21 12 16 7" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                <line x1="21" y1="12" x2="9" y2="12" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
              Sign Out
            </button>
          </div>
        </div>

        <p style={styles.footer}>© 2025 RideSync LK · All rights reserved</p>
      </div>

      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');
        * { box-sizing: border-box; margin: 0; padding: 0; }
        @keyframes orb1Float { 0%,100% { transform: translate(0,0) scale(1); } 50% { transform: translate(40px,-60px) scale(1.1); } }
        @keyframes orb2Float { 0%,100% { transform: translate(0,0) scale(1); } 50% { transform: translate(-50px,40px) scale(0.9); } }
        @keyframes fadeUp { from { opacity: 0; transform: translateY(24px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes pulse { 0%,100% { opacity:1; } 50% { opacity: 0.4; } }

        #pending-signout-btn:hover {
          background: rgba(239,68,68,0.15) !important;
          border-color: rgba(239,68,68,0.4) !important;
          color: #fca5a5 !important;
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
    padding: '32px 20px',
  },
  orb1: {
    position: 'fixed',
    top: '-10%',
    left: '-5%',
    width: '500px',
    height: '500px',
    borderRadius: '50%',
    background: 'radial-gradient(circle, rgba(245,158,11,0.12) 0%, transparent 70%)',
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
    background: 'radial-gradient(circle, rgba(99,102,241,0.1) 0%, transparent 70%)',
    animation: 'orb2Float 10s ease-in-out infinite',
    pointerEvents: 'none',
  },
  gridOverlay: {
    position: 'fixed',
    inset: 0,
    backgroundImage: 'linear-gradient(rgba(255,255,255,0.025) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.025) 1px, transparent 1px)',
    backgroundSize: '60px 60px',
    pointerEvents: 'none',
  },
  container: {
    position: 'relative',
    zIndex: 10,
    width: '100%',
    maxWidth: '520px',
    animation: 'fadeUp 0.6s ease-out',
  },
  brand: {
    textAlign: 'center',
    marginBottom: '28px',
  },
  logoImg: {
    width: '200px',
    height: 'auto',
    objectFit: 'contain',
    filter: 'drop-shadow(0 0 20px rgba(245,158,11,0.35))',
  },
  card: {
    background: 'rgba(30, 41, 59, 0.72)',
    backdropFilter: 'blur(24px)',
    WebkitBackdropFilter: 'blur(24px)',
    border: '1px solid rgba(255,255,255,0.08)',
    borderRadius: '24px',
    padding: '40px 36px',
    boxShadow: '0 32px 80px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.06)',
  },
  iconWrap: {
    display: 'flex',
    justifyContent: 'center',
    marginBottom: '20px',
  },
  title: {
    fontSize: '22px',
    fontWeight: 700,
    color: '#f8fafc',
    textAlign: 'center',
    marginBottom: '12px',
  },
  subtitle: {
    fontSize: '14px',
    color: '#64748b',
    textAlign: 'center',
    lineHeight: 1.7,
    marginBottom: '20px',
  },
  statusRow: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    justifyContent: 'center',
    marginBottom: '28px',
    flexWrap: 'wrap',
  },
  statusDot: {
    width: '8px',
    height: '8px',
    borderRadius: '50%',
    background: '#f59e0b',
    animation: 'pulse 2s ease-in-out infinite',
    flexShrink: 0,
  },
  statusText: {
    fontSize: '12px',
    fontWeight: 600,
    color: '#f59e0b',
    textTransform: 'uppercase',
    letterSpacing: '0.05em',
  },
  emailTag: {
    fontSize: '12px',
    color: '#475569',
    background: 'rgba(255,255,255,0.05)',
    border: '1px solid rgba(255,255,255,0.08)',
    borderRadius: '100px',
    padding: '2px 10px',
  },
  steps: {
    display: 'flex',
    flexDirection: 'column',
    gap: 0,
    marginBottom: '24px',
    background: 'rgba(15,23,42,0.4)',
    border: '1px solid rgba(255,255,255,0.06)',
    borderRadius: '16px',
    padding: '20px',
  },
  step: {
    display: 'flex',
    alignItems: 'flex-start',
    gap: '14px',
  },
  stepConnector: {
    width: '1px',
    height: '18px',
    background: 'rgba(255,255,255,0.08)',
    marginLeft: '19px',
    marginTop: '4px',
    marginBottom: '4px',
  },
  stepIcon: {
    width: '38px',
    height: '38px',
    borderRadius: '50%',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    flexShrink: 0,
  },
  stepTitle: {
    fontSize: '13px',
    fontWeight: 600,
    color: '#cbd5e1',
    marginBottom: '2px',
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
  },
  stepDesc: {
    fontSize: '12px',
    color: '#475569',
    lineHeight: 1.5,
  },
  pendingBadge: {
    fontSize: '10px',
    fontWeight: 600,
    color: '#f59e0b',
    background: 'rgba(245,158,11,0.1)',
    border: '1px solid rgba(245,158,11,0.25)',
    borderRadius: '100px',
    padding: '1px 8px',
    letterSpacing: '0.04em',
  },
  infoBox: {
    display: 'flex',
    gap: '10px',
    alignItems: 'flex-start',
    background: 'rgba(59,130,246,0.06)',
    border: '1px solid rgba(59,130,246,0.2)',
    borderRadius: '12px',
    padding: '14px 16px',
    marginBottom: '24px',
  },
  infoText: {
    fontSize: '13px',
    color: '#64748b',
    lineHeight: 1.6,
  },
  actions: {
    display: 'flex',
    justifyContent: 'center',
  },
  signOutBtn: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    height: '42px',
    padding: '0 24px',
    background: 'transparent',
    border: '1px solid rgba(255,255,255,0.1)',
    borderRadius: '10px',
    color: '#94a3b8',
    fontSize: '14px',
    fontWeight: 500,
    fontFamily: '"Inter", sans-serif',
    cursor: 'pointer',
    transition: 'all 0.2s ease',
  },
  footer: {
    textAlign: 'center',
    marginTop: '24px',
    fontSize: '12px',
    color: '#334155',
  },
};
