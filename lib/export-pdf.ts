import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';
import type { CostRow, CostSummary } from './types';

export interface PdfExportOptions {
  title: string;
  rows: CostRow[];
  summary: CostSummary;
}

function formatCurrency(value: number) {
  return `RM ${value.toFixed(2)}`;
}

export async function exportCostingPdf({ title, rows, summary }: PdfExportOptions) {
  const doc = new jsPDF({ orientation: 'portrait', unit: 'pt', format: 'a4' });
  const pageWidth = doc.internal.pageSize.getWidth();

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(18);
  doc.setTextColor('#D91C1C');
  doc.text(title, 40, 50);

  doc.setFontSize(12);
  doc.setTextColor('#000');
  doc.text('Kyros Red F&B Cost Calculator', 40, 70);

  autoTable(doc, {
    head: [['Item', 'Unit', 'Cost/Unit (RM)', 'Qty', 'Total (RM)']],
    body: rows.map((row) => [
      row.ingredientName,
      row.unit,
      row.cost_per_unit.toFixed(2),
      row.quantity.toString(),
      row.totalCost.toFixed(2)
    ]),
    startY: 90,
    theme: 'grid',
    styles: {
      halign: 'left'
    },
    headStyles: {
      fillColor: [217, 28, 28],
      textColor: 255
    }
  });

  let y = (doc as any).lastAutoTable?.finalY ?? 120;
  y += 30;

  doc.setFont('helvetica', 'bold');
  doc.text('Summary', 40, y);
  doc.setFont('helvetica', 'normal');
  y += 20;

  const summaryEntries = [
    ['Subtotal', formatCurrency(summary.subtotal)],
    ['Misc (10%)', formatCurrency(summary.miscAmount)],
    ['Total Cost', formatCurrency(summary.totalCost)],
    ['Selling Price', formatCurrency(summary.sellingPrice)],
    ['Cost %', `${summary.costPercentage.toFixed(1)}%`]
  ];

  summaryEntries.forEach(([label, value]) => {
    doc.text(label, 40, y);
    doc.text(value, pageWidth - 40 - doc.getTextWidth(value), y);
    y += 18;
  });

  doc.save(`fbcalc_costing_${new Date().toISOString().slice(0, 10)}.pdf`);
}
