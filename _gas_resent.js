/*******************************************************
 * 同一B列（漢字・熟語）でグルーピングし、識別詞（F列）を付与
 *
 * 【識別子付与ルール - 最終完全版】
 *
 * 【グループ内の優先順位決定】
 * 1. C列の優先順位数字（小さいほど優先）で基本順序を決定
 * 2. 優先順位の差が1以内の場合、A列の文字数が少ない方を優先
 *
 * 【識別子付与】
 * 1. 優先順位1位（並び替え後の1行目）：F列は空欄
 * 2. 2行目以降：
 *    - 頭文字が既存行と異なる → 頭文字のみ
 *    - 頭文字が既存行と同じ → 頭文字＋差別化文字
 *
 * 【差別化文字の選定（頭文字が同じ場合）】
 * - 原則：子音で差別化
 * - 子音で差別化できない場合：母音も使用
 *******************************************************/

function assignIdentifiersComplete() {
  const SHEET_NAME = null;
  const DATA_START_ROW = 1;
  const COL_A = 1, COL_B = 2, COL_C = 3, COL_F = 6, COL_G = 7;
  const PRIORITY_THRESHOLD = 1.0;

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = SHEET_NAME ? ss.getSheetByName(SHEET_NAME) : ss.getActiveSheet();
  if (!sheet) { throw new Error('対象シートが見つかりません。'); }

  const lastRow = sheet.getLastRow();
  if (lastRow < DATA_START_ROW) {
    SpreadsheetApp.getActive().toast('処理対象のデータがありません。');
    return;
  }

  const lastCol = Math.max(COL_F, COL_G);
  const range = sheet.getRange(DATA_START_ROW, 1, lastRow - DATA_START_ROW + 1, lastCol);
  const values = range.getValues();

  // ========== B列でグルーピング ==========
  const groups = new Map();
  for (let i = 0; i < values.length; i++) {
    const b = toStr(values[i][COL_B - 1]).trim();
    if (!b) continue;
    const cNum = parseFloat(values[i][COL_C - 1]);
    const rowData = {
      rowIdx: i,
      aValue: toStr(values[i][COL_A - 1]).trim(),
      bValue: b,
      cValue: !Number.isNaN(cNum) ? cNum : 999999,
      aLength: toStr(values[i][COL_A - 1]).trim().length
    };
    if (!groups.has(b)) { groups.set(b, []); }
    groups.get(b).push(rowData);
  }

  // ========== 各グループを処理 ==========
  for (const [bValue, groupRows] of groups.entries()) {
    if (groupRows.length < 2) continue;

    for (const row of groupRows) { values[row.rowIdx][COL_G - 1] = 'グルーピング済み'; }

    // 並び替え：優先順位を考慮し、差が1以内なら文字数優先
    groupRows.sort((a, b) => {
      const priorityDiff = Math.abs(a.cValue - b.cValue);
      if (priorityDiff <= PRIORITY_THRESHOLD) {
        if (a.aLength !== b.aLength) { return a.aLength - b.aLength; }
        return a.cValue - b.cValue;
      } else {
        return a.cValue - b.cValue;
      }
    });

    const processedRows = groupRows.map((row) => {
      const lower = row.aValue.toLowerCase();
      const chars = toChars(lower);
      const headInfo = findHead(chars);
      const head = headInfo.char || '';
      const afterHead = extractAfterHead(chars, headInfo.index);
      return { ...row, head: head, consonantsOnly: afterHead.consonants, allChars: afterHead.all };
    });

    // 頭文字ごとにグループ化
    const headGroups = new Map();
    processedRows.forEach((row, sortedIndex) => {
      row.sortedIndex = sortedIndex;
      if (!headGroups.has(row.head)) { headGroups.set(row.head, []); }
      headGroups.get(row.head).push(row);
    });

    const usedIdentifiers = new Set();

    headGroups.forEach((sameHeadRows, head) => {
      if (sameHeadRows.length === 1) {
        const row = sameHeadRows[0];
        let identifier = (row.sortedIndex === 0) ? '' : head;
        if (identifier && usedIdentifiers.has(identifier)) {
          let suffix = 2; let candidate = identifier + suffix;
          while (usedIdentifiers.has(candidate)) { suffix++; candidate = identifier + suffix; }
          identifier = candidate;
        }
        values[row.rowIdx][COL_F - 1] = identifier;
        if (identifier) usedIdentifiers.add(identifier);
      } else {
        // 同じ頭文字が複数
        const seenConsonantsAtOrder = new Map();
        const seenAllCharsAtOrder = new Map();
        sameHeadRows.sort((a, b) => a.sortedIndex - b.sortedIndex);

        sameHeadRows.forEach((row, indexInHeadGroup) => {
          let identifier = '';
          if (row.sortedIndex === 0) {
            identifier = '';
          } else if (indexInHeadGroup === 0) {
            identifier = head;
          } else {
            const consonantDivergent = findFirstDivergent(row.consonantsOnly, seenConsonantsAtOrder);
            if (consonantDivergent) {
              identifier = head + consonantDivergent.char;
            } else {
              const allCharDivergent = findFirstDivergent(row.allChars, seenAllCharsAtOrder);
              if (allCharDivergent) { identifier = head + allCharDivergent.char; }
              else { identifier = head; }
            }
            if (usedIdentifiers.has(identifier)) {
              let suffix = 2; let candidate = identifier + suffix;
              while (usedIdentifiers.has(candidate)) { suffix++; candidate = identifier + suffix; }
              identifier = candidate;
            }
          }
          values[row.rowIdx][COL_F - 1] = identifier;
          if (identifier) usedIdentifiers.add(identifier);
          updateSeenChars(row.consonantsOnly, seenConsonantsAtOrder);
          updateSeenChars(row.allChars, seenAllCharsAtOrder);
        });
      }
    });
  }

  range.setValues(values);
  SpreadsheetApp.getActive().toast('識別詞の付与が完了しました（優先順位・文字数考慮版）');
}

// ==================== 補助関数群 ====================
function toStr(value) { return (value === null || value === undefined) ? '' : String(value); }
function toChars(str) { return Array.from(str); }
function isValidLetter(char) { return /^[a-zĉĝĥĵŝŭ]$/i.test(char); }
function isVowel(char) { return /^[aeiou]$/i.test(char); }
function isConsonant(char) { return isValidLetter(char) && !isVowel(char); }

function findHead(chars) {
  for (let i = 0; i < chars.length; i++) {
    const ch = chars[i];
    if (isValidLetter(ch)) { return { index: i, char: ch.toLowerCase() }; }
  }
  return { index: -1, char: '' };
}

function extractAfterHead(chars, headIndex) {
  const consonants = []; const all = [];
  const startIndex = (headIndex >= 0) ? headIndex + 1 : 0;
  for (let i = startIndex; i < chars.length; i++) {
    const ch = chars[i];
    if (isValidLetter(ch)) {
      const lowerChar = ch.toLowerCase();
      all.push(lowerChar);
      if (isConsonant(ch)) { consonants.push(lowerChar); }
    }
  }
  return { consonants: consonants, all: all };
}

function findFirstDivergent(charArray, seenAtOrder) {
  for (let i = 0; i < charArray.length; i++) {
    const order = i + 1; const char = charArray[i];
    const seenSet = seenAtOrder.get(order);
    if (!seenSet || !seenSet.has(char)) { return { char: char, order: order }; }
  }
  return null;
}

function updateSeenChars(charArray, seenAtOrder) {
  for (let i = 0; i < charArray.length; i++) {
    const order = i + 1; const char = charArray[i];
    if (!seenAtOrder.has(order)) { seenAtOrder.set(order, new Set()); }
    seenAtOrder.get(order).add(char);
  }
}
