import React, { useEffect } from 'react';
import { AppRouter } from './router';
import { migrateOperatorsAndAdmins } from './scripts/migrateOperators';

function App() {
  useEffect(() => {
    // Run the migration once when the app loads
    migrateOperatorsAndAdmins();
  }, []);

  return <AppRouter />;
}

export default App;
