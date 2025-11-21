const fs = require('fs');
const path = require('path');

const excludedDirs = [
  '.git', 'node_modules', '.next', 'dist', 'build',
  'cache', '.cache', '.vs', 'bin', 'obj',
  '.idea', 'coverage', '.vscode'
];

function generateDirectoryTree(startPath, level = 0, output = []) {
  try {
    const items = fs.readdirSync(startPath, { withFileTypes: true });
    const indent = ' '.repeat(level);

    // Sort directories and files separately
    const directories = items.filter(item => item.isDirectory()).sort((a, b) => a.name.localeCompare(b.name));
    const files = items.filter(item => !item.isDirectory()).sort((a, b) => a.name.localeCompare(b.name));

    // Process directories
    for (const dir of directories) {
      if (!excludedDirs.includes(dir.name)) {
        output.push(`${indent}+-- ${dir.name}/`);
        generateDirectoryTree(path.join(startPath, dir.name), level + 1, output);
      }
    }

    // Process files
    for (const file of files) {
      output.push(`${indent}+-- ${file.name}`);
    }

    return output;
  } catch (error) {
    output.push(`Error processing path '${startPath}': ${error.message}`);
    return output;
  }
}

// Main execution
const fullPath = process.cwd(); // Gets current working directory
const outputList = [`Directory structure for: ${fullPath}`, ''];

try {
  generateDirectoryTree(fullPath, 0, outputList);
  fs.writeFileSync('ZDIRECTORY.txt', outputList.join('\n'), 'utf8');
  console.log('Directory tree has been saved to ZDIRECTORY.txt');
} catch (error) {
  console.error('Failed to generate directory tree:', error.message);
}