export interface SupplierQuote {
  date: string;
  supplier_id: string;
  ingredient_id: string;
  pack_size: number;
  pack_unit: string;
  pack_cost: number;
  unit_cost: number;
}

export interface SupplierContact {
  phone?: string;
  email?: string;
}

export interface Supplier {
  id: string;
  name: string;
  contacts?: SupplierContact;
}

export interface IngredientApprovedPrice {
  unit_cost: number;
  currency: string;
  quoted_at: string;
  supplier_id: string;
}

export interface Ingredient {
  id: string;
  name: string;
  category_id: string;
  base_unit: string;
  sku: string;
  approved_price?: IngredientApprovedPrice;
}

export interface MenuItemInput {
  ingredient_id: string;
  unit: string;
  cost_per_unit: number;
  quantity: number;
}

export interface MenuDraft {
  id: string;
  name: string;
  selling_price: number;
  misc_pct: number;
  items: MenuItemInput[];
}

export interface GitHubFileResponse<T> {
  content: T;
  sha: string;
}

export interface GitHubPutPayload {
  message: string;
  content: string;
  sha?: string;
  branch?: string;
}

export interface GitHubPutResponse {
  content: {
    path: string;
    sha: string;
    html_url: string;
  };
  commit: {
    sha: string;
    message: string;
    html_url: string;
  };
}

export interface CostRow extends MenuItemInput {
  ingredientName: string;
  totalCost: number;
}

export interface CostSummary {
  subtotal: number;
  miscAmount: number;
  totalCost: number;
  sellingPrice: number;
  costPercentage: number;
}
