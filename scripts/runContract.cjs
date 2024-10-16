// runContract.js
const { execSync } = require('child_process');

// Get the filename passed as an argument, e.g., `hub.ts`
const file = process.argv[2];

if (!file) {
  console.error('Please specify a file to run, e.g., `yarn start:contract hub.ts`');
  process.exit(1);
}

// Construct the full path to the file in the contracts folder
const filePath = `src/contracts/${file}`;

try {
  // Run the file using `tsx`
  execSync(`npx tsx ${filePath}`, { stdio: 'inherit' });
} catch (error) {
  console.error(`Error executing the file ${filePath}`);
  process.exit(1);
}
