(function () {
  const { __ } = wp.i18n;

  const state = {
    isConfigured: Boolean(KyrosFnbConfig?.isConfigured),
    loading: true,
    saving: false,
    menu: null,
    sha: null,
    ingredients: [],
    categories: [],
  };

  const root = document.getElementById('kyros-fnb-app');
  if (!root) {
    return;
  }

  const currencyFormatter = new Intl.NumberFormat('en-MY', {
    style: 'currency',
    currency: 'MYR',
    minimumFractionDigits: 2,
  });

  function setLoading(isLoading) {
    state.loading = isLoading;
    render();
  }

  function showError(message) {
    wp.data.dispatch('core/notices').createNotice('error', message, {
      isDismissible: true,
    });
  }

  async function fetchJson(endpoint) {
    const response = await fetch(`${KyrosFnbConfig.restUrl}/${endpoint}`, {
      headers: {
        'X-WP-Nonce': KyrosFnbConfig.nonce,
      },
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(text || __('Request failed', 'kyros-fnb'));
    }

    return response.json();
  }

  async function loadData() {
    try {
      setLoading(true);
      const [menuRes, ingredientsRes, categoriesRes] = await Promise.all([
        fetchJson('menu'),
        fetchJson('ingredients'),
        fetchJson('categories'),
      ]);

      state.menu = menuRes.menu || {};
      state.sha = menuRes.sha || null;
      state.ingredients = ingredientsRes.ingredients || [];
      state.categories = categoriesRes.categories || [];

      if (!Array.isArray(state.menu.items)) {
        state.menu.items = [];
      }
    } catch (error) {
      console.error(error);
      showError(__('Unable to load menu data. Fallback sample data will be used.', 'kyros-fnb'));
      if (!state.menu) {
        state.menu = { items: [] };
      }
    } finally {
      setLoading(false);
    }
  }

  function computeTotals() {
    const items = state.menu.items || [];
    const subtotal = items.reduce((acc, item) => acc + (Number(item.cost_per_unit) || 0) * (Number(item.quantity) || 0), 0);
    const miscPct = Number(state.menu.misc_pct) || 0;
    const misc = subtotal * miscPct;
    const selling = Number(state.menu.selling_price) || 0;
    const total = subtotal + misc;
    const costPercent = selling ? (total / selling) * 100 : 0;

    return { subtotal, misc, total, selling, costPercent };
  }

  function handleItemChange(index, field, value) {
    const item = state.menu.items[index];
    if (!item) {
      return;
    }

    if (field === 'ingredient_id') {
      const ingredient = state.ingredients.find((ing) => ing.id === value);
      item.ingredient_id = value;
      item.ingredient_name = ingredient ? ingredient.name : '';
      if (ingredient?.approved_price?.unit_cost) {
        item.cost_per_unit = Number(ingredient.approved_price.unit_cost);
      }
      item.unit = ingredient?.base_unit || item.unit || '';
    } else if (field === 'cost_per_unit' || field === 'quantity') {
      item[field] = Number(value) || 0;
    } else {
      item[field] = value;
    }

    render();
  }

  function addIngredientRow() {
    state.menu.items.push({
      ingredient_id: '',
      ingredient_name: '',
      unit: '',
      cost_per_unit: 0,
      quantity: 0,
    });
    render();
  }

  function removeIngredientRow(index) {
    state.menu.items.splice(index, 1);
    render();
  }

  function updateMenuField(field, value) {
    if (field === 'misc_pct') {
      state.menu.misc_pct = Number(value) || 0;
    } else if (field === 'selling_price' || field === 'yield_qty') {
      state.menu[field] = Number(value) || 0;
    } else {
      state.menu[field] = value;
    }
    render();
  }

  function exportPdf() {
    if (!window.jspdf || !window.jspdf.jsPDF) {
      showError(__('PDF library failed to load. Please refresh and try again.', 'kyros-fnb'));
      return;
    }

    const { subtotal, misc, total, selling, costPercent } = computeTotals();
    const doc = new window.jspdf.jsPDF({ format: 'a4', unit: 'pt' });
    const margin = 40;
    const brandColor = '#d91c1c';

    doc.setFillColor(217, 28, 28);
    doc.rect(0, 0, 595, 70, 'F');
    doc.setTextColor('#ffffff');
    doc.setFontSize(20);
    doc.text('Kyros F&B Cost Calculator', margin, 45);

    doc.setTextColor('#000000');
    doc.setFontSize(14);
    doc.text(`Menu: ${state.menu.name || 'Untitled Menu'}`, margin, 100);
    doc.setFontSize(11);
    doc.text(`Yield: ${state.menu.yield_qty || 1} ${state.menu.yield_unit || 'serving'}`, margin, 120);

    const rows = (state.menu.items || []).map((item) => [
      item.ingredient_name || item.ingredient_id || __('New Ingredient', 'kyros-fnb'),
      item.unit || '-',
      currencyFormatter.format(Number(item.cost_per_unit) || 0),
      Number(item.quantity) || 0,
      currencyFormatter.format((Number(item.cost_per_unit) || 0) * (Number(item.quantity) || 0)),
    ]);

    doc.autoTable({
      startY: 140,
      head: [[__('Item', 'kyros-fnb'), __('Unit', 'kyros-fnb'), __('Cost/Unit', 'kyros-fnb'), __('Quantity', 'kyros-fnb'), __('Total', 'kyros-fnb')]],
      body: rows,
      theme: 'striped',
      styles: { fillColor: [249, 243, 243], textColor: '#000' },
      headStyles: { fillColor: brandColor, textColor: '#fff' },
    });

    const summaryY = doc.lastAutoTable.finalY + 20;
    doc.setFontSize(12);
    doc.setTextColor(brandColor);
    doc.text(__('Summary', 'kyros-fnb'), margin, summaryY);
    doc.setTextColor('#000000');
    const miscPct = Number(state.menu.misc_pct) || 0;
    const summaryLines = [
      `${__('Subtotal', 'kyros-fnb')}: ${currencyFormatter.format(subtotal)}`,
      `${__('Misc', 'kyros-fnb')} (${(miscPct * 100).toFixed(1)}%): ${currencyFormatter.format(misc)}`,
      `${__('Total Cost', 'kyros-fnb')}: ${currencyFormatter.format(total)}`,
      `${__('Selling Price', 'kyros-fnb')}: ${currencyFormatter.format(selling)}`,
      `${__('Cost %', 'kyros-fnb')}: ${costPercent.toFixed(1)}%`,
    ];

    summaryLines.forEach((line, index) => {
      doc.text(line, margin, summaryY + 20 + index * 16);
    });

    const filename = `fbcalc_menu_${(state.menu.id || 'menu').replace(/[^a-z0-9_-]/gi, '')}_${formatTimestamp()}.pdf`;
    doc.save(filename);
  }

  function exportExcel() {
    if (!window.XLSX) {
      showError(__('Excel library failed to load. Please refresh and try again.', 'kyros-fnb'));
      return;
    }

    const items = (state.menu.items || []).map((item) => ({
      Item: item.ingredient_name || item.ingredient_id || __('New Ingredient', 'kyros-fnb'),
      Unit: item.unit || '-',
      CostPerUnit: Number(item.cost_per_unit) || 0,
      Quantity: Number(item.quantity) || 0,
      Total: (Number(item.cost_per_unit) || 0) * (Number(item.quantity) || 0),
    }));

    const worksheet = window.XLSX.utils.json_to_sheet(items, {
      header: ['Item', 'Unit', 'CostPerUnit', 'Quantity', 'Total'],
    });

    const range = window.XLSX.utils.decode_range(worksheet['!ref']);
    for (let row = range.s.r + 1; row <= range.e.r; row += 1) {
      const costCell = window.XLSX.utils.encode_cell({ r: row, c: 2 });
      const qtyCell = window.XLSX.utils.encode_cell({ r: row, c: 3 });
      const totalCell = window.XLSX.utils.encode_cell({ r: row, c: 4 });
      worksheet[totalCell] = { f: `${costCell}*${qtyCell}` };
      worksheet[costCell].z = '[$RM-421]#,##0.00';
    }
    worksheet[window.XLSX.utils.encode_cell({ r: range.e.r, c: 4 })].z = '[$RM-421]#,##0.00';

    const workbook = window.XLSX.utils.book_new();
    window.XLSX.utils.book_append_sheet(workbook, worksheet, 'Menu');

    const summary = computeTotals();
    const summarySheet = window.XLSX.utils.aoa_to_sheet([
      ['Metric', 'Value'],
      ['Subtotal', summary.subtotal],
      ['Misc', summary.misc],
      ['Total', summary.total],
      ['Selling Price', summary.selling],
      ['Cost %', summary.costPercent],
    ]);

    const summaryRange = window.XLSX.utils.decode_range(summarySheet['!ref']);
    for (let row = summaryRange.s.r + 1; row <= summaryRange.e.r; row += 1) {
      const valueCell = window.XLSX.utils.encode_cell({ r: row, c: 1 });
      if (row <= summaryRange.s.r + 4) {
        summarySheet[valueCell].z = '[$RM-421]#,##0.00';
      } else {
        summarySheet[valueCell].z = '0.0%';
      }
    }

    window.XLSX.utils.book_append_sheet(workbook, summarySheet, 'Summary');

    const filename = `fbcalc_menu_${(state.menu.id || 'menu').replace(/[^a-z0-9_-]/gi, '')}_${formatTimestamp()}.xlsx`;
    window.XLSX.writeFile(workbook, filename);
  }

  function formatTimestamp() {
    const now = new Date();
    const pad = (num) => String(num).padStart(2, '0');
    return `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}-${pad(now.getHours())}${pad(now.getMinutes())}`;
  }

  async function saveMenu() {
    if (!state.isConfigured) {
      showError(__('GitHub credentials are missing. Please configure them in Settings.', 'kyros-fnb'));
      return;
    }

    try {
      state.saving = true;
      render();
      const response = await fetch(`${KyrosFnbConfig.restUrl}/menu`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-WP-Nonce': KyrosFnbConfig.nonce,
        },
        body: JSON.stringify({
          content: state.menu,
          message: `feat(menu): update ${state.menu.name || 'menu'}`,
          sha: state.sha,
        }),
      });

      if (!response.ok) {
        throw new Error(await response.text());
      }

      const data = await response.json();
      state.sha = data.content?.sha || data.sha || state.sha;
      wp.data.dispatch('core/notices').createNotice('success', __('Menu saved to GitHub.', 'kyros-fnb'), {
        isDismissible: true,
      });
    } catch (error) {
      console.error(error);
      showError(__('Saving to GitHub failed. Check your credentials and repository permissions.', 'kyros-fnb'));
    } finally {
      state.saving = false;
      render();
    }
  }

  function renderSummary() {
    const { subtotal, misc, total, selling, costPercent } = computeTotals();
    return `
      <div class="kyros-fnb-summary">
        <div class="kyros-fnb-card">
          <h3>${__('Subtotal', 'kyros-fnb')}</h3>
          <p>${currencyFormatter.format(subtotal)}</p>
        </div>
        <div class="kyros-fnb-card">
          <h3>${__('Misc', 'kyros-fnb')} (${((Number(state.menu.misc_pct) || 0) * 100).toFixed(1)}%)</h3>
          <p>${currencyFormatter.format(misc)}</p>
        </div>
        <div class="kyros-fnb-card">
          <h3>${__('Total Cost', 'kyros-fnb')}</h3>
          <p>${currencyFormatter.format(total)}</p>
        </div>
        <div class="kyros-fnb-card">
          <h3>${__('Selling Price', 'kyros-fnb')}</h3>
          <p>${currencyFormatter.format(selling)}</p>
        </div>
        <div class="kyros-fnb-card">
          <h3>${__('Cost %', 'kyros-fnb')}</h3>
          <p>${costPercent.toFixed(1)}%</p>
        </div>
      </div>
    `;
  }

  function renderToolbar() {
    return `
      <div class="kyros-fnb-toolbar">
        <button type="button" class="button button-primary kyros-fnb-button-primary" data-action="save" ${state.saving || !state.isConfigured ? 'disabled' : ''}>
          ${state.isConfigured ? (state.saving ? __('Saving…', 'kyros-fnb') : __('Save to GitHub', 'kyros-fnb')) : __('Configure GitHub to Save', 'kyros-fnb')}
        </button>
        <button type="button" class="button" data-action="add-row">${__('Add Ingredient', 'kyros-fnb')}</button>
        <button type="button" class="button" data-action="export-pdf">${__('Export PDF', 'kyros-fnb')}</button>
        <button type="button" class="button" data-action="export-excel">${__('Export Excel', 'kyros-fnb')}</button>
      </div>
    `;
  }

  function renderTable() {
    const rows = (state.menu.items || []).map((item, index) => {
      const ingredientOptions = state.ingredients
        .map((ingredient) => {
          const selected = ingredient.id === item.ingredient_id ? 'selected' : '';
          return `<option value="${ingredient.id}" ${selected}>${ingredient.name}</option>`;
        })
        .join('');
      const total = (Number(item.cost_per_unit) || 0) * (Number(item.quantity) || 0);
      return `
        <tr data-index="${index}">
          <td>
            <select data-field="ingredient_id">
              <option value="">${__('Select ingredient', 'kyros-fnb')}</option>
              ${ingredientOptions}
            </select>
          </td>
          <td><input type="text" data-field="unit" value="${item.unit || ''}" /></td>
          <td><input type="number" step="0.0001" min="0" data-field="cost_per_unit" value="${Number(item.cost_per_unit) || 0}" /></td>
          <td><input type="number" step="0.0001" min="0" data-field="quantity" value="${Number(item.quantity) || 0}" /></td>
          <td>${currencyFormatter.format(total)}</td>
          <td><button type="button" class="button-link delete" data-field="delete">${__('Remove', 'kyros-fnb')}</button></td>
        </tr>
      `;
    });

    return `
      <table class="widefat">
        <thead>
          <tr>
            <th>${__('Item', 'kyros-fnb')}</th>
            <th>${__('Unit', 'kyros-fnb')}</th>
            <th>${__('Cost/Unit', 'kyros-fnb')}</th>
            <th>${__('Quantity', 'kyros-fnb')}</th>
            <th>${__('Total', 'kyros-fnb')}</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          ${rows.join('')}
        </tbody>
      </table>
    `;
  }

  function renderMeta() {
    return `
      <div class="kyros-fnb-meta">
        <table class="form-table">
          <tr>
            <th><label for="kyros-menu-name">${__('Menu Name', 'kyros-fnb')}</label></th>
            <td><input type="text" id="kyros-menu-name" data-menu-field="name" value="${state.menu.name || ''}" /></td>
          </tr>
          <tr>
            <th><label for="kyros-menu-yield">${__('Yield Quantity', 'kyros-fnb')}</label></th>
            <td><input type="number" min="0" step="0.01" id="kyros-menu-yield" data-menu-field="yield_qty" value="${Number(state.menu.yield_qty) || 0}" /></td>
          </tr>
          <tr>
            <th><label for="kyros-menu-unit">${__('Yield Unit', 'kyros-fnb')}</label></th>
            <td><input type="text" id="kyros-menu-unit" data-menu-field="yield_unit" value="${state.menu.yield_unit || ''}" /></td>
          </tr>
          <tr>
            <th><label for="kyros-menu-selling">${__('Selling Price', 'kyros-fnb')}</label></th>
            <td><input type="number" min="0" step="0.01" id="kyros-menu-selling" data-menu-field="selling_price" value="${Number(state.menu.selling_price) || 0}" /></td>
          </tr>
          <tr>
            <th><label for="kyros-menu-misc">${__('Misc %', 'kyros-fnb')}</label></th>
            <td><input type="number" min="0" step="0.01" id="kyros-menu-misc" data-menu-field="misc_pct" value="${Number(state.menu.misc_pct) || 0}" /></td>
          </tr>
        </table>
      </div>
    `;
  }

  function renderChartPlaceholder() {
    return `
      <div class="kyros-fnb-chart">
        ${__('Chart placeholder – integrate with Chart.js or Recharts if desired.', 'kyros-fnb')}
      </div>
    `;
  }

  function render() {
    if (state.loading) {
      root.innerHTML = `<p>${__('Loading menu data…', 'kyros-fnb')}</p>`;
      return;
    }

    root.innerHTML = `
      ${renderToolbar()}
      ${renderMeta()}
      ${renderTable()}
      ${renderSummary()}
      ${renderChartPlaceholder()}
    `;
  }

  root.addEventListener('change', (event) => {
    const row = event.target.closest('tr[data-index]');
    if (row) {
      const index = Number(row.dataset.index);
      const field = event.target.dataset.field;
      if (field) {
        handleItemChange(index, field, event.target.value);
      }
    }

    const menuField = event.target.dataset.menuField;
    if (menuField) {
      updateMenuField(menuField, event.target.value);
    }
  });

  root.addEventListener('input', (event) => {
    const row = event.target.closest('tr[data-index]');
    if (row) {
      const index = Number(row.dataset.index);
      const field = event.target.dataset.field;
      if (field) {
        handleItemChange(index, field, event.target.value);
      }
    }

    const menuField = event.target.dataset.menuField;
    if (menuField) {
      updateMenuField(menuField, event.target.value);
    }
  });

  root.addEventListener('click', (event) => {
    const action = event.target.dataset.action;
    if (action === 'add-row') {
      addIngredientRow();
      return;
    }
    if (action === 'export-pdf') {
      exportPdf();
      return;
    }
    if (action === 'export-excel') {
      exportExcel();
      return;
    }
    if (action === 'save') {
      saveMenu();
      return;
    }

    if (event.target.dataset.field === 'delete') {
      const row = event.target.closest('tr[data-index]');
      if (row) {
        removeIngredientRow(Number(row.dataset.index));
      }
    }
  });

  loadData();
})();
