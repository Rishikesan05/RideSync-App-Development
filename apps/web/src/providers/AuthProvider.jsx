import React, { createContext, useContext, useState, useEffect } from 'react';
import { onAuthStateChanged, signOut } from 'firebase/auth';
import { doc, onSnapshot } from 'firebase/firestore';
import { auth, db } from '../api/firebase';

const AuthContext = createContext();

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }) => {
  const [currentUser, setCurrentUser] = useState(null);
  // userProfile holds the Firestore /users/{uid} document data (includes role).
  // null  = not fetched yet or no document
  // false = fetched but no document found (treat as 'pending')
  const [userProfile, setUserProfile] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let profileUnsub = null; // holds the Firestore real-time listener

    const authUnsub = onAuthStateChanged(auth, (user) => {
      setCurrentUser(user);

      // Tear down any previous Firestore listener
      if (profileUnsub) {
        profileUnsub();
        profileUnsub = null;
      }

      if (user) {
        // Real-time listener — fires immediately AND whenever the
        // /users/{uid} document changes (e.g. admin approves the role).
        // This means role changes in Firestore are reflected instantly
        // without requiring the user to sign out and sign back in.
        profileUnsub = onSnapshot(
          doc(db, 'users', user.uid),
          (snap) => {
            setUserProfile(snap.exists() ? snap.data() : false);
            setLoading(false);
          },
          (err) => {
            // Permission denied for pending users — treat as no profile
            console.warn('Could not fetch user profile:', err);
            setUserProfile(false);
            setLoading(false);
          }
        );
      } else {
        setUserProfile(null);
        setLoading(false);
      }
    });

    // Clean up both listeners on unmount
    return () => {
      authUnsub();
      if (profileUnsub) profileUnsub();
    };
  }, []);

  /**
   * refreshUserProfile is kept for compatibility but is now a no-op —
   * the onSnapshot listener handles live updates automatically.
   */
  const refreshUserProfile = () => {};

  /**
   * Sign the current user out and clear the profile.
   * Components should call this instead of importing signOut directly.
   */
  const signOutUser = async () => {
    try {
      await signOut(auth);
      // onAuthStateChanged fires → sets currentUser=null, userProfile=null
    } catch (err) {
      console.error('Sign-out error:', err);
    }
  };

  const isAdmin = userProfile && userProfile.role === 'admin';
  const isOperator = userProfile && (userProfile.role === 'operator' || userProfile.role === 'operator_pending');

  const value = {
    currentUser,
    userProfile,
    isAdmin,
    isOperator,
    loading,
    refreshUserProfile,
    signOutUser,
  };

  return (
    <AuthContext.Provider value={value}>
      {!loading && children}
    </AuthContext.Provider>
  );
};
