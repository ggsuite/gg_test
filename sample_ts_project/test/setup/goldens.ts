// @license
// Copyright (c) 2025 Rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import { mkdir, readFile, writeFile } from 'fs/promises';
import { dirname, join, relative } from 'path';
import { expect } from 'vitest';


/// If this is set to true, the golden files will be updated.
export const shouldUpdateGoldens = () => {
  return process.env['UPDATE_GOLDENS'] === 'true';
};

/**
 * Updates the golden file with the given content.
 * @param filexName - The golden file to compare with
 * @param expected - The expected golden content
 */
export const expectGolden = (fileName: string) => {
  return {
    toBe: async (expected: any) => {
      // Stringify json
      if (typeof expected !== 'string') {
        expected = JSON.stringify(expected, null, 2);
      }

      // Get golden file path
      const goldensDir = join(__dirname, '..', 'goldens');
      const filePath = join(goldensDir, fileName);
      const filePathRelative = relative(process.cwd(), filePath);

      // Write golden file
      if (shouldUpdateGoldens()) {
        await mkdir(dirname(filePath), { recursive: true });
        await writeFile(filePath, expected);
      }

      // Check if golden file exists
      let needsGoldenUpdate: boolean = true;
      try {
        const golden = await readFile(filePath, 'utf8');
        needsGoldenUpdate = golden !== expected;
      } catch {
        needsGoldenUpdate = true;
      }

      // Fail if golden file needs update
      if (needsGoldenUpdate) {
        expect.fail(
          `Run »pnpm updateGoldens« and review "${filePathRelative}".`,
        );
      }
    },
  };
};
