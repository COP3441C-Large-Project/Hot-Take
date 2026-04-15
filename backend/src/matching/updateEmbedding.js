const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

/**
 * pass parameters to the Python script via stdin and get the updated embedding result
 *  IF THIS WRAPPER IS IN PROJECT CODE, NEEDS TO PULL ACTUAL USER PARAMS FROM USER DATA IN CACHE. 
 *  CACHE SHOULD LOAD USER DATA ON SERVER STARTUP.
 *  IMPLEMENT A MAP: USER ID -> PARAMS
 *  WRITE Updated_embedding TO DISK AND CACHE(Using map)
 * Update user embedding by calling the Python script
 * @param {Object} params - Parameters for embedding update
 * @param {Array<number>} params.userEmbedding - Current user embedding
 * @param {string} params.newPrompt - New prompt text
 * @param {number} params.lastUpdateTimestamp - Last update timestamp (seconds)
 * @param {Array<number>} params.lastEmbedding - Previous embedding
 * @returns {Promise<Object>} Updated embedding result
 */

async function updateEmbedding(params) {
  return new Promise((resolve, reject) => {
    const pythonScript = path.join(__dirname, 'update.py');
    const venvPython = process.platform === 'win32'
      ? path.join(__dirname, '1env', 'Scripts', 'python.exe')
      : path.join(__dirname, '1env', 'bin', 'python');
    const pythonCommand = fs.existsSync(venvPython) ? venvPython : 'python';

    // Spawn Python process
    const pythonProcess = spawn(pythonCommand, [
      pythonScript,
      JSON.stringify(params)
    ]);

    let stdout = '';
    let stderr = '';

    // Collect stdout
    pythonProcess.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    // Collect stderr
    pythonProcess.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    // Handle process exit
    pythonProcess.on('close', (code) => {
      if (code !== 0) {
        reject(new Error(`Python process exited with code ${code}: ${stderr}`));
        return;
      }

      try {
        const result = JSON.parse(stdout);
        resolve(result);
      } catch (error) {
        reject(new Error(`Failed to parse Python output: ${stdout}`));
      }
    });

    // Handle errors
    pythonProcess.on('error', (error) => {
      reject(error);
    });
  });
}

// Example usage
async function main() {
  const params = {
    userEmbedding: Array(384).fill(0).map(() => Math.random()),
    newPrompt: "I am very opiniated! Math is the best subject in everything! Theology isn't even a real subject! I am a genius and everyone else is an idiot! I am the smartest person in the world! I am so smart that I can solve any problem in seconds! I am a genius and everyone else is just a bunch of idiots! I am the smartest person in the world and everyone else is just a bunch of idiots! I am so smart that I can solve any problem in seconds! I am a genius and everyone else is just a bunch of idiots! I am the smartest person in the world and everyone else is just a bunch of idiots! I am so smart that I can solve any problem in seconds! I am a genius and everyone else is just a bunch of idiots! I am the smartest person in the world and everyone else is just a bunch of idiots! I am so smart that I can solve any problem in seconds! I am a genius and everyone else is just a bunch of idiots! I am the smartest person in the world and everyone else is just a bunch of idiots! I am so smart that I can solve any problem in seconds!",
    lastUpdateTimestamp: Math.floor(Date.now() / 1000) - (7 * 24 * 60 * 60), // 7 days ago
    lastEmbedding: Array(384).fill(0).map(() => Math.random())
  };

  try {
    console.log('Updating embedding...');
    const result = await updateEmbedding(params);
    console.log('Result:', JSON.stringify(result, null, 2));
  } catch (error) {
    console.error('Error:', error.message);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { updateEmbedding };
