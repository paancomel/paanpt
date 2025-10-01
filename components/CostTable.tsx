import { useEffect, useMemo, useState } from 'react';
import ingredientsFixture from '@/data/ingredients.json';
import type { CostRow, CostSummary, Ingredient } from '@/lib/types';

type CostRowEditable = CostRow;

const defaultIngredients: Ingredient[] = ingredientsFixture as Ingredient[];

const initialRows: CostRowEditable[] = defaultIngredients.slice(0, 3).map((ingredient) => ({
  ingredient_id: ingredient.id,
  ingredientName: ingredient.name,
  unit: ingredient.base_unit,
  cost_per_unit: ingredient.approved_price?.unit_cost ?? 0,
  quantity: ingredient.id === 'ing_beef' ? 120 : ingredient.id === 'ing_sauce_base' ? 40 : 1,
  totalCost:
    (ingredient.approved_price?.unit_cost ?? 0) *
    (ingredient.id === 'ing_beef' ? 120 : ingredient.id === 'ing_sauce_base' ? 40 : 1)
}));

const calculateSummary = (rows: CostRowEditable[], sellingPrice: number, miscPct: number): CostSummary => {
  const subtotal = rows.reduce((acc, row) => acc + row.totalCost, 0);
  const miscAmount = subtotal * miscPct;
  const totalCost = subtotal + miscAmount;
  const costPercentage = sellingPrice > 0 ? (totalCost / sellingPrice) * 100 : 0;

  return {
    subtotal,
    miscAmount,
    totalCost,
    sellingPrice,
    costPercentage
  };
};

export interface CostTableProps {
  sellingPrice: number;
  miscPct: number;
  onChange?: (rows: CostRowEditable[], summary: CostSummary) => void;
}

export const CostTable = ({ sellingPrice, miscPct, onChange }: CostTableProps) => {
  const [rows, setRows] = useState<CostRowEditable[]>(initialRows);

  const summary = useMemo(() => calculateSummary(rows, sellingPrice, miscPct), [rows, sellingPrice, miscPct]);

  useEffect(() => {
    onChange?.(rows, summary);
  }, [rows, summary, onChange]);

  const updateRow = (index: number, updates: Partial<CostRowEditable>) => {
    setRows((prev) => {
      const updated = prev.map((row, i) =>
        i === index
          ? {
              ...row,
              ...updates,
              totalCost: ((updates.cost_per_unit ?? row.cost_per_unit) * (updates.quantity ?? row.quantity)) || 0
            }
          : row
      );
      return updated;
    });
  };

  const handleIngredientSelect = (index: number, ingredientId: string) => {
    const ingredient = defaultIngredients.find((item) => item.id === ingredientId);
    if (!ingredient) return;

    updateRow(index, {
      ingredient_id: ingredient.id,
      ingredientName: ingredient.name,
      unit: ingredient.base_unit,
      cost_per_unit: ingredient.approved_price?.unit_cost ?? 0,
      quantity: 1
    });
  };

  const addRow = () => {
    const ingredient = defaultIngredients[0];
    setRows((prev) => [
      ...prev,
      {
        ingredient_id: ingredient?.id ?? `pending_${prev.length + 1}`,
        ingredientName: ingredient?.name ?? 'New Ingredient',
        unit: ingredient?.base_unit ?? 'unit',
        cost_per_unit: ingredient?.approved_price?.unit_cost ?? 0,
        quantity: 1,
        totalCost: ingredient?.approved_price?.unit_cost ?? 0
      }
    ]);
  };

  const removeRow = (index: number) => {
    setRows((prev) => prev.filter((_, i) => i !== index));
  };

  return (
    <div className="card p-6">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-slate-900">F&amp;B Cost Table</h2>
        <button type="button" className="btn-secondary" onClick={addRow}>
          Add Ingredient
        </button>
      </div>

      <div className="mt-4 overflow-x-auto">
        <table className="min-w-full divide-y divide-slate-200 text-sm">
          <thead className="bg-slate-100 text-left text-xs font-semibold uppercase tracking-wide text-slate-600">
            <tr>
              <th className="px-4 py-3">Item</th>
              <th className="px-4 py-3">Unit</th>
              <th className="px-4 py-3">Cost / Unit (RM)</th>
              <th className="px-4 py-3">Quantity</th>
              <th className="px-4 py-3">Total (RM)</th>
              <th className="px-4 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-200 bg-white">
            {rows.map((row, index) => (
              <tr key={index} className="align-top">
                <td className="px-4 py-3">
                  <select
                    value={row.ingredient_id}
                    onChange={(event) => handleIngredientSelect(index, event.target.value)}
                    className="mt-1 block w-full rounded-md border-slate-300 text-sm shadow-sm focus:border-kyros-red focus:ring-kyros-red"
                  >
                    {defaultIngredients.map((ingredient) => (
                      <option key={ingredient.id} value={ingredient.id}>
                        {ingredient.name}
                      </option>
                    ))}
                  </select>
                  <p className="mt-1 text-xs text-slate-500">SKU: {row.ingredient_id}</p>
                </td>
                <td className="px-4 py-3">
                  <input
                    type="text"
                    value={row.unit}
                    onChange={(event) => updateRow(index, { unit: event.target.value })}
                    className="mt-1 block w-24 rounded-md border-slate-300 text-sm shadow-sm focus:border-kyros-red focus:ring-kyros-red"
                  />
                </td>
                <td className="px-4 py-3">
                  <input
                    type="number"
                    value={row.cost_per_unit}
                    step="0.001"
                    onChange={(event) => updateRow(index, { cost_per_unit: Number(event.target.value) })}
                    className="mt-1 block w-32 rounded-md border-slate-300 text-sm shadow-sm focus:border-kyros-red focus:ring-kyros-red"
                  />
                </td>
                <td className="px-4 py-3">
                  <input
                    type="number"
                    value={row.quantity}
                    step="0.1"
                    onChange={(event) => updateRow(index, { quantity: Number(event.target.value) })}
                    className="mt-1 block w-24 rounded-md border-slate-300 text-sm shadow-sm focus:border-kyros-red focus:ring-kyros-red"
                  />
                </td>
                <td className="px-4 py-3 font-medium text-slate-900">RM {row.totalCost.toFixed(2)}</td>
                <td className="px-4 py-3 text-right">
                  <button
                    type="button"
                    className="text-sm font-medium text-red-500 hover:text-red-600"
                    onClick={() => removeRow(index)}
                    disabled={rows.length <= 1}
                  >
                    Remove
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="mt-6 grid gap-3 text-sm">
        <div className="flex items-center justify-between">
          <span className="text-slate-600">Total Ingredient Cost</span>
          <span className="font-semibold">RM {summary.subtotal.toFixed(2)}</span>
        </div>
        <div className="flex items-center justify-between">
          <span className="text-slate-600">Misc ({(miscPct * 100).toFixed(0)}%)</span>
          <span className="font-semibold">RM {summary.miscAmount.toFixed(2)}</span>
        </div>
        <div className="flex items-center justify-between border-t border-dashed border-slate-200 pt-3 text-base font-semibold">
          <span>Total Cost</span>
          <span>RM {summary.totalCost.toFixed(2)}</span>
        </div>
        <div className="flex items-center justify-between">
          <span className="text-slate-600">Selling Price</span>
          <span className="font-semibold">RM {sellingPrice.toFixed(2)}</span>
        </div>
        <div className="flex items-center justify-between text-base">
          <span className="font-semibold text-slate-700">Cost %</span>
          <span className="font-semibold text-kyros-red">{summary.costPercentage.toFixed(1)}%</span>
        </div>
      </div>
    </div>
  );
};

export default CostTable;
