import React, { createContext, useContext, useState, useEffect } from 'react';
import { onAuthStateChanged } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
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
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      setCurrentUser(user);

      if (user) {
        try {
          const profileSnap = await getDoc(doc(db, 'users', user.uid));
          setUserProfile(profileSnap.exists() ? profileSnap.data() : false);
        } catch (err) {
          // If Firestore read fails (e.g. permission denied for pending users),
          // treat it as no profile so they land on the pending page.
          console.warn('Could not fetch user profile:', err);
          setUserProfile(false);
        }
      } else {
        setUserProfile(null);
      }

      setLoading(false);
    });

    return unsubscribe;
  }, []);

  /**
   * Call this after a sign-up or profile update so the cached
   * userProfile stays in sync without a full page reload.
   */
  const refreshUserProfile = async () => {
    if (!currentUser) return;
    try {
      const profileSnap = await getDoc(doc(db, 'users', currentUser.uid));
      setUserProfile(profileSnap.exists() ? profileSnap.data() : false);
    } catch (err) {
      console.warn('Could not refresh user profile:', err);
    }
  };

  const isAdmin = userProfile && userProfile.role === 'admin';

  const value = {
    currentUser,
    userProfile,
    isAdmin,
    loading,
    refreshUserProfile,
  };

  return (
    <AuthContext.Provider value={value}>
      {!loading && children}
    </AuthContext.Provider>
  );
};
