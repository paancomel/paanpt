import type { CostRow, CostSummary } from './types';
import * as XLSX from 'xlsx';

export interface ExcelExportOptions {
  title: string;
  rows: CostRow[];
  summary: CostSummary;
}

export function exportCostingExcel({ title, rows, summary }: ExcelExportOptions) {
  const worksheetData: (string | number | XLSX.CellObject)[][] = [
    ['Item', 'Unit', 'Cost/Unit (RM)', 'Quantity', 'Total (RM)'],
    ...rows.map((row, index) => [
      row.ingredientName,
      row.unit,
      row.cost_per_unit,
      row.quantity,
      { t: 'n', f: `C${index + 2}*D${index + 2}` }
    ])
  ];

  const ws = XLSX.utils.aoa_to_sheet(worksheetData);
  const lastRow = rows.length + 2;

  XLSX.utils.sheet_add_aoa(
    ws,
    [
      ['Subtotal', null, null, null, summary.subtotal],
      ['Misc (10%)', null, null, null, summary.miscAmount],
      ['Total Cost', null, null, null, summary.totalCost],
      ['Selling Price', null, null, null, summary.sellingPrice],
      ['Cost %', null, null, null, summary.costPercentage / 100]
    ],
    { origin: `A${lastRow}` }
  );

  const range = XLSX.utils.decode_range(ws['!ref'] || `A1:E${lastRow + 4}`);
  for (let R = 1; R <= rows.length; R += 1) {
    const cellAddress = XLSX.utils.encode_cell({ r: R, c: 4 });
    const cell = ws[cellAddress];
    if (cell && typeof cell === 'object') {
      cell.z = '[$RM-421] #,##0.00';
    }
  }

  ['E', 'A'].forEach((column) => {
    for (let R = 1; R <= range.e.r; R += 1) {
      const cell = ws[`${column}${R + 1}`];
      if (cell && typeof cell === 'object') {
        cell.z = column === 'E' ? '[$RM-421] #,##0.00' : undefined;
      }
    }
  });

  ws['!cols'] = [
    { wch: 28 },
    { wch: 10 },
    { wch: 16 },
    { wch: 12 },
    { wch: 16 }
  ];

  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'Costing');
  const fileName = `fbcalc_costing_${title.replace(/\s+/g, '-').toLowerCase()}_${
    new Date().toISOString().replace(/[-:]/g, '').slice(0, 15)
  }.xlsx`;
  XLSX.writeFile(wb, fileName);
}
