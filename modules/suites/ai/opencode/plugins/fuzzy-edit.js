import fs from "node:fs/promises";
import path from "node:path";

function levenshtein(a, b) {
  if (a === b) return 0;
  if (a.length === 0) return b.length;
  if (b.length === 0) return a.length;
  const matrix = [];
  for (let i = 0; i <= b.length; i++) matrix[i] = [i];
  for (let j = 0; j <= a.length; j++) matrix[0][j] = j;
  for (let i = 1; i <= b.length; i++) {
    for (let j = 1; j <= a.length; j++) {
      if (b.charAt(i - 1) === a.charAt(j - 1)) {
        matrix[i][j] = matrix[i - 1][j - 1];
      } else {
        matrix[i][j] = Math.min(
          matrix[i - 1][j - 1] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j] + 1
        );
      }
    }
  }
  return matrix[b.length][a.length];
}

export default {
  id: "fuzzy-edit",
  setup: async (api) => {
    // 1. Before Execution Hook: Intercepts and repairs edit payloads before native engine runs
    api.tool.hook("execute.before", async (event) => {
      // Anti-Sed Guard: Block raw sed -i calls on source files to prevent line-arithmetic corruption
      if (event.tool === "bash") {
        const cmd = String(event.input?.command ?? "");
        if (
          /\bsed\s+-[a-zA-Z]*i\b/.test(cmd) &&
          !cmd.includes("/tmp") &&
          !cmd.includes("/dev/null")
        ) {
          throw new Error(
            "Agent-Guard: Modifying files via raw 'sed -i' is prohibited to prevent line-arithmetic corruption. Please use the 'edit' or 'write' tool instead."
          );
        }
      }

      // Whitespace & Typo Tolerant Edit Tool (Aider-style relative indent + Levenshtein match)
      if (event.tool === "edit" && event.input?.oldString) {
        const { path: filePath, oldString, newString } = event.input;
        const fullPath = path.isAbsolute(filePath)
          ? filePath
          : path.join(process.cwd(), filePath);

        let content;
        try {
          content = await fs.readFile(fullPath, "utf8");
        } catch {
          return;
        }

        // If exact match succeeds, nothing to do
        if (content.includes(oldString)) return;

        // Strip accidental outer markdown code fences (e.g. ```nix ... ```)
        let cleanOld = oldString
          .replace(/^```[a-zA-Z0-9_-]*\r?\n/, "")
          .replace(/\r?\n?```\s*$/, "");
        let cleanNew = newString
          .replace(/^```[a-zA-Z0-9_-]*\r?\n/, "")
          .replace(/\r?\n?```\s*$/, "");

        if (content.includes(cleanOld)) {
          event.input.oldString = cleanOld;
          event.input.newString = cleanNew;
          return;
        }

        const fileLines = content.split("\n");
        const targetLines = cleanOld.split("\n").map((l) => l.trim());

        let matchIndex = -1;
        let isTypoMatch = false;

        // Pass 1: Line-trimmed match (ignores indentation discrepancies)
        for (let i = 0; i <= fileLines.length - targetLines.length; i++) {
          let match = true;
          for (let j = 0; j < targetLines.length; j++) {
            if (fileLines[i + j].trim() !== targetLines[j]) {
              match = false;
              break;
            }
          }
          if (match) {
            matchIndex = i;
            break;
          }
        }

        // Pass 2: Levenshtein typo match (catches perceptual slips like 'sites' vs 'suites')
        if (matchIndex === -1 && targetLines.length > 0) {
          for (let i = 0; i <= fileLines.length - targetLines.length; i++) {
            let match = true;
            for (let j = 0; j < targetLines.length; j++) {
              const fLine = fileLines[i + j].trim();
              const tLine = targetLines[j];
              const maxDistance = Math.max(1, Math.floor(tLine.length * 0.15));
              if (levenshtein(fLine, tLine) > maxDistance) {
                match = false;
                break;
              }
            }
            if (match) {
              matchIndex = i;
              isTypoMatch = true;
              break;
            }
          }
        }

        if (matchIndex !== -1) {
          const exactOldLines = fileLines.slice(matchIndex, matchIndex + targetLines.length);
          const exactOldString = exactOldLines.join("\n");

          const actualIndent = exactOldLines[0].match(/^\s*/)[0];
          const modelIndent = cleanOld.split("\n")[0].match(/^\s*/)[0];

          let adjustedNewString = cleanNew;
          if (modelIndent !== actualIndent) {
            adjustedNewString = cleanNew
              .split("\n")
              .map((line) => {
                if (line.startsWith(modelIndent)) {
                  return actualIndent + line.slice(modelIndent.length);
                }
                return line;
              })
              .join("\n");
          }

          // If typo match occurred, fix occurrences of typo'd anchor in adjustedNewString
          if (isTypoMatch) {
            const origOldLines = cleanOld.split("\n");
            for (let j = 0; j < origOldLines.length; j++) {
              const origOld = origOldLines[j].trim();
              const realFile = exactOldLines[j].trim();
              if (origOld !== realFile && adjustedNewString.includes(origOld)) {
                adjustedNewString = adjustedNewString.replaceAll(origOld, realFile);
              }
            }
          }

          event.input.oldString = exactOldString;
          event.input.newString = adjustedNewString;
        }
      }
    });

    // 2. After Execution Hook: Intercepts tool output and provides negative-proof annotations
    api.tool.hook("execute.after", async (event) => {
      // Negative-Proof Annotator: Halt infinite search loops when 0 matches are found
      const cmd = String(event.input?.command ?? "");
      const isSearch =
        event.tool === "grep" ||
        event.tool === "glob" ||
        cmd.includes("grep") ||
        cmd.includes("rg") ||
        cmd.includes("find");

      if (isSearch && event.result) {
        const contentArr = event.result.content;
        const totalText = Array.isArray(contentArr)
          ? contentArr.map((c) => c.text ?? "").join("\n")
          : String(event.result.output ?? "");

        if (
          !totalText.trim() ||
          totalText.trim() === "(no output)" ||
          totalText.trim() === "[]" ||
          totalText.trim() === '""' ||
          totalText.includes("Found 0 matches")
        ) {
          event.result.content = [
            {
              type: "text",
              text: "(no output — 0 matches found. The target pattern does not exist in this search space. Do not repeat the same search; accept this negative proof and state your findings to the user.)",
            },
          ];
        }
      }

      // Ambiguous Tool Failures & Silent Exits: Prevent assuming success on failed commands
      if (event.tool === "bash" && event.status === "error") {
        if (!event.result?.content || event.result.content.length === 0) {
          event.result = event.result ?? {};
          event.result.content = [
            {
              type: "text",
              text: "[CRITICAL: Command exited with a non-zero failure code and produced no output. Do not assume success.]",
            },
          ];
        }
      }
    });
  },
};
