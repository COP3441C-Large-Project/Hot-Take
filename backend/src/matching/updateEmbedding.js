import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export async function updateEmbedding(params) {
  return new Promise((resolve, reject) => {
    const pythonScript = path.join(__dirname, 'update.py');
    const configuredPython = process.env.MATCHING_PYTHON_PATH;
    const candidateInterpreters = [
      configuredPython,
      '/home/ivie/COP4331-Large-Project/backend/src/.env/bin/python',
      process.platform === 'win32'
        ? path.join(__dirname, '1env', 'Scripts', 'python.exe')
        : path.join(__dirname, '1env', 'bin', 'python'),
    ].filter(Boolean);

    const pythonCommand = candidateInterpreters.find((candidate) => fs.existsSync(candidate)) ?? 'python';

    const pythonProcess = spawn(pythonCommand, [
      pythonScript,
      JSON.stringify(params),
    ]);

    let stdout = '';
    let stderr = '';

    pythonProcess.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    pythonProcess.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    pythonProcess.on('close', (code) => {
      if (code !== 0) {
        reject(new Error(`Python process exited with code ${code}: ${stderr}`));
        return;
      }

      try {
        resolve(JSON.parse(stdout));
      } catch {
        reject(new Error(`Failed to parse Python output: ${stdout}`));
      }
    });

    pythonProcess.on('error', (error) => {
      reject(error);
    });
  });
}
