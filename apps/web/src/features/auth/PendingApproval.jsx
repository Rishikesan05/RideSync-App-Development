import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../providers/AuthProvider';

export const PendingApproval = () => {
  const { currentUser, userProfile, signOutUser } = useAuth();
  const navigate = useNavigate();

  const handleSignOut = async () => {
    await signOutUser();
    navigate('/login', { replace: true });
  };

  const displayName = currentUser?.displayName || userProfile?.displayName || 'there';
  const email = currentUser?.email || userProfile?.email || '';

  return (
    <div style={styles.page}>

      <div style={styles.orb2} />


      <div className="ticket-container" style={styles.container}>
        {/* Logo */}
        <div className="outside-brand" style={styles.brand}>
          <img src="/ridesync-logo.jpeg" alt="RideSync" style={styles.logoImg} />
        </div>

        {/* Card */}
        <div className="ticket-card" style={styles.card}>
          {/* Left Section */}
          <div className="ticket-left" style={styles.ticketTop}>
            {/* Desktop Brand inside Left ticket stub */}
            <div className="desktop-only-brand" style={{ ...styles.brand, marginBottom: '24px' }}>
              <img
                src="/ridesync-logo.jpeg"
                alt="RideSync"
                style={{ ...styles.logoImg, width: '160px', marginBottom: '4px' }}
              />
              <p style={{ fontSize: '11px', letterSpacing: '0.08em', textTransform: 'uppercase', color: '#64748b', textAlign: 'center', fontWeight: 500 }}>Admin Portal</p>
            </div>

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
          </div>

          {/* Ticket Divider */}
          <div className="ticket-divider-container" style={styles.ticketDivider}>
            <div className="ticket-notch-left" style={styles.notchLeft} />
            <div className="ticket-perforation-line" style={styles.perforation} />
            <div className="ticket-notch-right" style={styles.notchRight} />
          </div>

          {/* Right Section */}
          <div className="ticket-right" style={styles.ticketBottom}>
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
                    <path d="M9 18l6-6-6-6" stroke="#64748b" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </div>
                <div>
                  <p style={{ ...styles.stepTitle, color: '#64748b' }}>Access granted</p>
                  <p style={{ ...styles.stepDesc, color: '#5b6c80' }}>You'll be able to sign in once approved.</p>
                </div>
              </div>
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
        </div>

        <p style={styles.footer}>© 2025 RideSync LK · All rights reserved</p>
      </div>

      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');
        * { box-sizing: border-box; margin: 0; padding: 0; }

        @keyframes orb2Float { 0%,100% { transform: translate(0,0) scale(1); } 50% { transform: translate(-50px,40px) scale(0.9); } }
        @keyframes fadeUp { from { opacity: 0; transform: translateY(24px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes pulse { 0%,100% { opacity:1; } 50% { opacity: 0.4; } }

        #pending-signout-btn:hover {
          background: rgba(239,68,68,0.15) !important;
          border-color: rgba(239,68,68,0.4) !important;
          color: #fca5a5 !important;
        }

        /* Desktop (Landscape) Ticket Styles */
        @media (min-width: 768px) {
          .ticket-container {
            max-width: 860px !important;
          }
          .ticket-card {
            display: flex !important;
            flex-direction: row !important;
            padding: 0 !important;
            align-items: stretch !important;
          }
          .ticket-left {
            width: 44% !important;
            padding: 40px 36px !important;
            display: flex !important;
            flex-direction: column !important;
            justify-content: center !important;
          }
          .ticket-right {
            width: 56% !important;
            padding: 40px 36px !important;
            display: flex !important;
            flex-direction: column !important;
            justify-content: center !important;
          }
          .ticket-divider-container {
            display: flex !important;
            flex-direction: column !important;
            align-items: center !important;
            justify-content: space-between !important;
            width: 24px !important;
            height: auto !important;
            margin: 0 -12px !important;
            position: relative !important;
            z-index: 2 !important;
          }
          .ticket-notch-left {
            width: 24px !important;
            height: 24px !important;
            border-radius: 50% !important;
            background: #0f172a !important;
            border: 1px solid rgba(245, 158, 11, 0.25) !important;
            margin-top: -12px !important;
            margin-left: 0 !important;
            box-shadow: inset 0 -4px 8px rgba(0, 0, 0, 0.4) !important;
          }
          .ticket-notch-right {
            width: 24px !important;
            height: 24px !important;
            border-radius: 50% !important;
            background: #0f172a !important;
            border: 1px solid rgba(245, 158, 11, 0.25) !important;
            margin-bottom: -12px !important;
            margin-right: 0 !important;
            box-shadow: inset 0 4px 8px rgba(0, 0, 0, 0.4) !important;
          }
          .ticket-perforation-line {
            flex: 1 !important;
            border-left: 2px dashed rgba(245, 158, 11, 0.25) !important;
            border-top: none !important;
            width: 1px !important;
            height: 100% !important;
            margin: 8px 0 !important;
          }
          .desktop-only-brand {
            display: block !important;
          }
          .outside-brand {
            display: none !important;
          }
        }

        /* Mobile/Tablet (Portrait Stacked) Styles */
        @media (max-width: 767px) {
          .ticket-card {
            flex-direction: column !important;
          }
          .ticket-left {
            width: 100% !important;
          }
          .ticket-right {
            width: 100% !important;
          }
          .ticket-divider-container {
            display: flex !important;
            flex-direction: row !important;
            align-items: center !important;
            justify-content: space-between !important;
            margin: 24px -37px !important;
            height: 24px !important;
          }
          .ticket-notch-left {
            width: 24px !important;
            height: 24px !important;
            border-radius: 50% !important;
            background: #0f172a !important;
            border: 1px solid rgba(245, 158, 11, 0.25) !important;
            margin-left: -12px !important;
            box-shadow: inset -4px 0 8px rgba(0, 0, 0, 0.4) !important;
          }
          .ticket-notch-right {
            width: 24px !important;
            height: 24px !important;
            border-radius: 50% !important;
            background: #0f172a !important;
            border: 1px solid rgba(245, 158, 11, 0.25) !important;
            margin-right: -12px !important;
            box-shadow: inset 4px 0 8px rgba(0, 0, 0, 0.4) !important;
          }
          .ticket-perforation-line {
            flex: 1 !important;
            border-top: 2px dashed rgba(245, 158, 11, 0.25) !important;
            height: 1px !important;
            margin: 0 8px !important;
          }
          .desktop-only-brand {
            display: none !important;
          }
          .outside-brand {
            display: block !important;
          }
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
    border: '1px solid rgba(245, 158, 11, 0.25)',
    borderTop: '4px solid #f59e0b',
    borderRadius: '24px',
    padding: '40px 36px',
    boxShadow: '0 32px 80px rgba(0,0,0,0.5), 0 0 50px rgba(245, 158, 11, 0.12), inset 0 1px 0 rgba(255,255,255,0.06)',
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
    color: '#94a3b8',
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
    color: '#94a3b8',
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
    color: '#94a3b8',
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
    color: '#5b6c80',
  },
  ticketTop: {
    width: '100%',
  },
  ticketBottom: {
    width: '100%',
  },
  ticketDivider: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    margin: '24px -37px',
    position: 'relative',
    height: '24px',
  },
  notchLeft: {
    width: '24px',
    height: '24px',
    borderRadius: '50%',
    background: '#0f172a',
    border: '1px solid rgba(245, 158, 11, 0.25)',
    marginLeft: '-12px',
    boxShadow: 'inset -4px 0 8px rgba(0, 0, 0, 0.4)',
    zIndex: 2,
  },
  notchRight: {
    width: '24px',
    height: '24px',
    borderRadius: '50%',
    background: '#0f172a',
    border: '1px solid rgba(245, 158, 11, 0.25)',
    marginRight: '-12px',
    boxShadow: 'inset 4px 0 8px rgba(0, 0, 0, 0.4)',
    zIndex: 2,
  },
  perforation: {
    flex: 1,
    borderTop: '2px dashed rgba(245, 158, 11, 0.25)',
    height: '1px',
    margin: '0 8px',
  },
};
