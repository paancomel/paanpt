import { useCallback, useMemo, useState } from 'react';
import Head from 'next/head';
import { Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import CostTable from '@/components/CostTable';
import { exportCostingExcel } from '@/lib/export-excel';
import { exportCostingPdf } from '@/lib/export-pdf';
import type { CostRow, CostSummary, MenuDraft } from '@/lib/types';
import ingredientsFixture from '@/data/ingredients.json';

const lineData = [
  { date: 'Sep 1', avg: 3.1 },
  { date: 'Sep 8', avg: 3.3 },
  { date: 'Sep 15', avg: 3.28 },
  { date: 'Sep 22', avg: 3.25 },
  { date: 'Sep 29', avg: 3.32 },
  { date: 'Oct 6', avg: 3.35 }
];

export default function HomePage() {
  const [sellingPrice, setSellingPrice] = useState<number>(12.9);
  const [miscPct, setMiscPct] = useState<number>(0.1);
  const [rows, setRows] = useState<CostRow[]>([]);
  const [summary, setSummary] = useState<CostSummary | null>(null);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  const handleTableChange = useCallback((updatedRows: CostRow[], updatedSummary: CostSummary) => {
    setRows(updatedRows);
    setSummary(updatedSummary);
  }, []);

  const handleSave = useCallback(async () => {
    if (!summary) return;

    setSaving(true);
    setMessage(null);
    const menuDraft: MenuDraft = {
      id: 'menu_kebab',
      name: 'Kyros Kebab',
      selling_price: summary.sellingPrice,
      misc_pct: miscPct,
      items: rows.map((row) => ({
        ingredient_id: row.ingredient_id,
        unit: row.unit,
        cost_per_unit: row.cost_per_unit,
        quantity: row.quantity
      }))
    };

    try {
      const response = await fetch('/api/github/save-menu', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(menuDraft)
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error ?? 'Failed to save menu');
      }

      setMessage('Menu saved to GitHub successfully.');
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Failed to save menu');
    } finally {
      setSaving(false);
    }
  }, [miscPct, rows, summary]);

  const handleExportPdf = useCallback(() => {
    if (!summary) return;
    exportCostingPdf({
      title: 'Kyros Kebab Costing',
      rows,
      summary
    });
  }, [rows, summary]);

  const handleExportExcel = useCallback(() => {
    if (!summary) return;
    exportCostingExcel({
      title: 'Kyros Kebab',
      rows,
      summary
    });
  }, [rows, summary]);

  const averageCost = useMemo(() => {
    const ingredientWithAvg = ingredientsFixture.find((item) => item.id === 'ing_beef');
    return ingredientWithAvg?.approved_price?.unit_cost ?? 0;
  }, []);

  return (
    <>
      <Head>
        <title>Kyros Red F&amp;B Cost Calculator</title>
      </Head>

      <main className="mx-auto max-w-6xl gap-6 px-6 py-10 lg:flex">
        <section className="lg:w-2/3">
          <div className="mb-4 flex flex-wrap items-center gap-4">
            <div>
              <h1 className="text-2xl font-semibold text-slate-900">F&amp;B Cost Calculator</h1>
              <p className="text-sm text-slate-600">Build menu costings, combos, and SOP-ready data with Kyros Red.</p>
            </div>
            <span className="rounded-full bg-kyros-red/10 px-3 py-1 text-sm font-medium text-kyros-red">
              RM Currency • GitHub Storage
            </span>
          </div>

          <div className="card mb-6 p-4">
            <div className="grid gap-4 sm:grid-cols-3">
              <label className="text-sm">
                <span className="text-slate-600">Selling Price (RM)</span>
                <input
                  type="number"
                  value={sellingPrice}
                  step="0.1"
                  onChange={(event) => setSellingPrice(Number(event.target.value))}
                  className="mt-1 block w-full rounded-md border-slate-300 text-sm shadow-sm focus:border-kyros-red focus:ring-kyros-red"
                />
              </label>
              <label className="text-sm">
                <span className="text-slate-600">Misc Percentage</span>
                <input
                  type="number"
                  value={miscPct * 100}
                  step="1"
                  onChange={(event) => setMiscPct(Number(event.target.value) / 100)}
                  className="mt-1 block w-full rounded-md border-slate-300 text-sm shadow-sm focus:border-kyros-red focus:ring-kyros-red"
                />
              </label>
              <div className="flex items-end">
                <button type="button" className="btn-secondary w-full">Create Combo Menu</button>
              </div>
            </div>
          </div>

          <CostTable sellingPrice={sellingPrice} miscPct={miscPct} onChange={handleTableChange} />

          <div className="mt-6 flex flex-wrap items-center gap-3">
            <button type="button" className="btn-primary" onClick={handleSave} disabled={saving}>
              {saving ? 'Saving...' : 'Save to GitHub'}
            </button>
            <button type="button" className="btn-secondary" onClick={handleExportPdf}>
              Export PDF
            </button>
            <button type="button" className="btn-secondary" onClick={handleExportExcel}>
              Export Excel
            </button>
          </div>

          {message && <p className="mt-4 text-sm text-slate-600">{message}</p>}
        </section>

        <aside className="mt-10 space-y-6 lg:mt-0 lg:w-1/3">
          <div className="card space-y-4 p-6">
            <div>
              <h2 className="text-lg font-semibold text-slate-900">Ingredient Price Trend</h2>
              <p className="text-sm text-slate-500">30-day average for Beef Slice</p>
            </div>
            <div className="h-52 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={lineData}>
                  <XAxis dataKey="date" stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} />
                  <YAxis stroke="#94a3b8" fontSize={12} tickFormatter={(value) => `RM ${value.toFixed(2)}`} width={80} />
                  <Tooltip formatter={(value: number) => `RM ${value.toFixed(2)}`} labelStyle={{ color: '#0f172a' }} />
                  <Line type="monotone" dataKey="avg" stroke="#D91C1C" strokeWidth={3} dot={false} />
                </LineChart>
              </ResponsiveContainer>
            </div>
            <div className="flex items-center justify-between rounded-lg bg-kyros-red/10 px-4 py-3 text-sm">
              <span className="font-medium text-kyros-red">30-Day Avg</span>
              <span className="font-semibold text-slate-900">RM {averageCost.toFixed(3)}</span>
            </div>
          </div>

          <div className="card space-y-3 p-6 text-sm text-slate-600">
            <h3 className="text-base font-semibold text-slate-900">What&apos;s Next</h3>
            <ul className="list-disc space-y-2 pl-5">
              <li>Auto-generate SOP cards and QR-ready outlet mode.</li>
              <li>Supplier quote intake with OCR to append CSV history.</li>
              <li>Benchmark pricing snapshots per outlet and platform.</li>
              <li>GitHub PR approvals to manage role-based access.</li>
            </ul>
          </div>
        </aside>
      </main>
    </>
  );
}
